import Table from "cli-table3";
import { prompt } from "../util/prompt.js";
import {
  promptCredentials,
  hydrateCredentials,
  selectApp,
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

export async function runSession(): Promise<void> {
  const creds = await getCredentials();
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

    await showCurrentPrices(client, product);
    await runProductAction(product);
    return;
  }
}

async function getCredentials(): Promise<Credentials> {
  const cfg = await loadConfig();
  if (cfg) {
    try {
      const creds = await hydrateCredentials({
        keyPath: cfg.keyPath,
        keyId: cfg.keyId,
        issuerId: cfg.issuerId,
      });
      console.log(`Using cached credentials (Key ID: ${creds.keyId}).`);
      return creds;
    } catch (err) {
      console.error(
        `Failed to use cached credentials: ${err instanceof Error ? err.message : err}`,
      );
      console.log("Re-entering credentials.\n");
    }
  }

  const creds = await promptCredentials();
  await saveConfig({
    keyPath: creds.keyPath,
    keyId: creds.keyId,
    issuerId: creds.issuerId,
  });
  console.log(`Saved credentials to ${configPath()}\n`);
  return creds;
}

async function showCurrentPrices(client: AscClient, product: Product): Promise<void> {
  if (product.kind !== "subscription") {
    console.log("(In-app purchase price display is not yet implemented.)\n");
    return;
  }
  console.log("Fetching current prices…");
  const rows = await listSubscriptionPrices(client, product.id);
  printPriceTable(rows);
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

async function runProductAction(product: Product): Promise<void> {
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
  if (idx) {
    console.log(`(${idx.label} preview is not yet implemented)\n`);
  }
}
