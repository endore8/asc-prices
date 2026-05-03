import Table from "cli-table3";
import { prompt } from "../util/prompt.js";
import {
  promptCredentials,
  hydrateCredentials,
  selectApp,
  selectBaseCountry,
  selectProduct,
  type Credentials,
  type Product,
} from "./prompt.js";
import { loadConfig, saveConfig, configPath } from "../storage/config.js";
import { TokenCache } from "../auth/session.js";
import { AscClient } from "../api/client.js";
import { listApps } from "../api/apps.js";
import { listSubscriptions } from "../api/subscriptions.js";
import { listInAppPurchases } from "../api/iaps.js";
import { listSubscriptionPrices, type PriceRow } from "../api/prices.js";
import { listSubscriptionPricePoints } from "../api/price-points.js";
import { INDEXES, indexById, type PriceIndex } from "../indices/registry.js";
import { calculatePppTargets, type PriceDiff } from "../pricing/calculate.js";

export async function runSession(): Promise<void> {
  const { creds, baseCountry } = await getSessionContext();
  const client = new AscClient(new TokenCache(creds));

  console.log("Fetching your apps…");
  const apps = await listApps(client);

  for (;;) {
    const app = await selectApp(apps);
    console.log(`\nWorking on: ${app.name} (${app.bundleId})\n`);

    console.log("Fetching subscriptions and in-app purchases…");
    const [subs, iaps] = await Promise.all([
      listSubscriptions(client, app.id),
      listInAppPurchases(client, app.id),
    ]);

    if (subs.length === 0 && iaps.length === 0) {
      console.log(`No subscriptions or in-app purchases found for "${app.name}".\n`);
      if (apps.length === 1) return;
      continue;
    }

    const product = await selectProduct(subs, iaps);
    console.log(`\nSelected: ${product.name} (${product.productId})\n`);

    const prices = await showCurrentPrices(client, product);
    await runProductAction(client, product, prices, baseCountry);
    return;
  }
}

async function getSessionContext(): Promise<{ creds: Credentials; baseCountry: string }> {
  const existing = await loadConfig();
  let creds: Credentials | null = null;
  let dirty = false;

  if (existing) {
    try {
      creds = await hydrateCredentials({
        keyPath: existing.keyPath,
        keyId: existing.keyId,
        issuerId: existing.issuerId,
      });
      console.log(`Using cached credentials (Key ID: ${creds.keyId}).`);
    } catch (err) {
      console.error(
        `Failed to use cached credentials: ${err instanceof Error ? err.message : err}`,
      );
      console.log("Re-entering credentials.\n");
    }
  }

  if (!creds) {
    creds = await promptCredentials();
    dirty = true;
  }

  let baseCountry = existing?.baseCountry;
  if (!baseCountry) {
    baseCountry = await selectBaseCountry();
    dirty = true;
  }

  if (dirty) {
    await saveConfig({
      keyPath: creds.keyPath,
      keyId: creds.keyId,
      issuerId: creds.issuerId,
      baseCountry,
    });
    console.log(`Saved config to ${configPath()}\n`);
  }

  return { creds, baseCountry };
}

async function showCurrentPrices(client: AscClient, product: Product): Promise<PriceRow[]> {
  if (product.kind !== "subscription") {
    console.log("(In-app purchase price display is not yet implemented.)\n");
    return [];
  }
  console.log("Fetching current prices…");
  const rows = await listSubscriptionPrices(client, product.id);
  printPriceTable(rows);
  return rows;
}

function printPriceTable(rows: PriceRow[]): void {
  if (rows.length === 0) {
    console.log("No prices set for this product.\n");
    return;
  }
  const table = new Table({
    head: ["Code", "Territory", "Currency", "Customer Price", "Proceeds"],
  });
  for (const r of rows) {
    table.push([r.territory, r.territoryName, r.currency, r.customerPrice, r.proceeds]);
  }
  console.log(table.toString());
  console.log();
}

async function runProductAction(
  client: AscClient,
  product: Product,
  prices: PriceRow[],
  baseCountry: string,
): Promise<void> {
  const choices = [
    ...INDEXES.map((i) => ({
      name: `index:${i.id}`,
      message: `${i.label}  — preview & apply PPP-aligned prices`,
    })),
    { name: "reset", message: "Apple Standard - reset to Apple's standard prices" },
  ];

  const { action } = await prompt<{ action: string }>({
    type: "select",
    name: "action",
    message: `${product.name} — what next?`,
    choices,
  });

  if (action === "reset") {
    console.log("(reset to Apple standard prices is not yet implemented)\n");
    return;
  }
  const indexId = action.startsWith("index:") ? action.slice("index:".length) : null;
  const index = indexId ? indexById(indexId) : null;
  if (!index) return;

  await runIndexPreview(client, product, prices, baseCountry, index);
}

async function runIndexPreview(
  client: AscClient,
  product: Product,
  prices: PriceRow[],
  baseCountry: string,
  index: PriceIndex,
): Promise<void> {
  if (product.kind !== "subscription") {
    console.log(`(${index.label} preview only supports subscriptions today.)\n`);
    return;
  }
  if (prices.length === 0) {
    console.log("No current prices to compare against.\n");
    return;
  }
  if (!index.lookup(baseCountry)) {
    console.log(
      `${index.label} has no data for base country ${baseCountry}. ` +
        "Pick a different index, or update the base country (logout and re-run).\n",
    );
    return;
  }

  const baseValue = await pickBasePrice(client, product.id, prices, baseCountry);
  if (baseValue === null) return;

  console.log(`\nUsing ${index.label} (base ${baseCountry}):\n`);
  const diffs = calculatePppTargets(baseValue, baseCountry, prices, index);
  printDiffTable(diffs);
  console.log(
    "Targets are calculated PPP-equivalents in local currency. They will be snapped\n" +
      "to the nearest Apple price point at apply time (apply is not yet implemented).\n",
  );
}

async function pickBasePrice(
  client: AscClient,
  subscriptionId: string,
  prices: PriceRow[],
  baseCountry: string,
): Promise<number | null> {
  console.log(`Fetching available price points for ${baseCountry}…`);
  const points = await listSubscriptionPricePoints(client, subscriptionId, baseCountry);
  if (points.length === 0) {
    console.log(
      `No available price points for ${baseCountry}. Pick a different base country.\n`,
    );
    return null;
  }

  const baseRow = prices.find((p) => p.territory === baseCountry);
  const baseCurrency = baseRow?.currency ?? "";
  const currentPrice = baseRow ? parseFloat(baseRow.customerPrice) : null;
  const currentIdx =
    currentPrice !== null
      ? points.findIndex((p) => Math.abs(p.customerPrice - currentPrice) < 0.001)
      : -1;

  const choices = points.map((p, i) => ({
    name: p.customerPriceRaw,
    message: `${p.customerPriceRaw}${baseCurrency ? " " + baseCurrency : ""}${
      i === currentIdx ? "  (current)" : ""
    }`,
  }));

  const { picked } = await prompt<{ picked: string }>({
    type: "autocomplete",
    name: "picked",
    message: `Pick base price for ${baseCountry}:`,
    choices,
    initial: currentIdx >= 0 ? choices[currentIdx]!.name : choices[0]!.name,
    limit: 10,
    suggest(input: string, list: Array<{ message: string }>) {
      const q = input.trim();
      if (!q) return list;
      return list.filter((c) => c.message.includes(q));
    },
  });

  return parseFloat(picked);
}

function printDiffTable(diffs: PriceDiff[]): void {
  diffs.sort((a, b) => a.territoryName.localeCompare(b.territoryName));
  const table = new Table({
    head: ["Code", "Territory", "Currency", "Current", "Target", "Δ%", "Note"],
  });
  for (const d of diffs) {
    table.push([
      d.territory,
      d.territoryName,
      d.currency,
      d.current === null ? "—" : String(d.current),
      d.target === null ? "—" : String(d.target),
      d.deltaPct === null ? "—" : formatDelta(d.deltaPct),
      d.note ?? "",
    ]);
  }
  console.log(table.toString());
  console.log();
}

function formatDelta(pct: number): string {
  const sign = pct > 0 ? "+" : "";
  return `${sign}${pct.toFixed(1)}%`;
}
