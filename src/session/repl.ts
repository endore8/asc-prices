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
import { INDEXES } from "../indices/registry.js";
import { calculateBigMacTargets, type PriceDiff } from "../pricing/calculate.js";

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
    await runProductAction(product, prices, baseCountry);
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
  const idx = indexId ? INDEXES.find((i) => i.id === indexId) : null;
  if (!idx) return;

  if (idx.id === "big-mac") {
    await runBigMacPreview(product, prices, baseCountry);
    return;
  }
  console.log(`(${idx.label} preview is not yet implemented)\n`);
}

async function runBigMacPreview(
  product: Product,
  prices: PriceRow[],
  baseCountry: string,
): Promise<void> {
  if (product.kind !== "subscription") {
    console.log("(Big Mac preview only supports subscriptions today.)\n");
    return;
  }
  if (prices.length === 0) {
    console.log("No current prices to compare against.\n");
    return;
  }

  const basePrice = prices.find((p) => p.territory === baseCountry);
  const baseCurrency = basePrice?.currency ?? "?";
  const initial = basePrice ? Number(basePrice.customerPrice).toFixed(2) : "";
  const message = basePrice
    ? `Base price ${baseCurrency} for ${baseCountry} (current price as default):`
    : `Base price for ${baseCountry} (no current price set — enter manually):`;

  const { base } = await prompt<{ base: string }>({
    type: "input",
    name: "base",
    message,
    initial,
    validate: (v: string) => {
      const n = parseFloat(v);
      return Number.isFinite(n) && n > 0 ? true : "enter a positive number";
    },
  });
  const baseValue = parseFloat(base);

  const diffs = calculateBigMacTargets(baseValue, baseCountry, prices);
  printDiffTable(diffs);
  console.log(
    "Targets are calculated PPP-equivalents in local currency. They will be snapped\n" +
      "to the nearest Apple price point at apply time (apply is not yet implemented).\n",
  );
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
