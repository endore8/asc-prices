import { promises as fs } from "node:fs";
import path from "node:path";
import { prompt } from "../util/prompt.js";
import type { App } from "../api/apps.js";
import type { Subscription } from "../api/subscriptions.js";
import type { InAppPurchase, IapType } from "../api/iaps.js";

export type Product =
  | { kind: "subscription"; id: string; name: string; productId: string; groupName: string }
  | { kind: "iap"; id: string; name: string; productId: string; iapType: IapType };

const IAP_LABEL: Record<IapType, string> = {
  CONSUMABLE: "Consumable",
  NON_CONSUMABLE: "Non-Consumable",
  NON_RENEWING_SUBSCRIPTION: "Non-Renewing Sub",
};

export interface Credentials {
  keyPath: string;
  keyId: string;
  issuerId: string;
  privateKey: string;
}

export async function hydrateCredentials(stored: {
  keyPath: string;
  keyId: string;
  issuerId: string;
}): Promise<Credentials> {
  const privateKey = await fs.readFile(stored.keyPath, "utf8").catch((err) => {
    throw new Error(`could not read key at ${stored.keyPath}: ${err.message}`);
  });
  return { ...stored, privateKey };
}

export async function selectProduct(
  subscriptions: Subscription[],
  iaps: InAppPurchase[],
): Promise<Product> {
  const products: Product[] = [
    ...subscriptions.map<Product>((s) => ({
      kind: "subscription",
      id: s.id,
      name: s.name,
      productId: s.productId,
      groupName: s.groupName,
    })),
    ...iaps.map<Product>((i) => ({
      kind: "iap",
      id: i.id,
      name: i.name,
      productId: i.productId,
      iapType: i.iapType,
    })),
  ];

  if (products.length === 0) {
    throw new Error("no subscriptions or in-app purchases found for this app");
  }

  const choices = products.map((p) => ({
    name: `${p.kind}:${p.id}`,
    message: `${describeProduct(p)}  ·  ${p.name}  ·  ${p.productId}`,
  }));

  const { key } = await prompt<{ key: string }>({
    type: "select",
    name: "key",
    message: "Select a product:",
    choices,
  });

  const picked = products.find((p) => `${p.kind}:${p.id}` === key);
  if (!picked) throw new Error(`unexpected product key: ${key}`);
  return picked;
}

function describeProduct(p: Product): string {
  if (p.kind === "subscription") return `[Subscription · ${p.groupName}]`;
  return `[${IAP_LABEL[p.iapType]}]`;
}

export async function selectApp(apps: App[]): Promise<App> {
  if (apps.length === 0) {
    throw new Error("no apps found on this account");
  }
  if (apps.length === 1) {
    const only = apps[0]!;
    console.log(`Single app found — selected: ${only.name} (${only.bundleId})`);
    return only;
  }
  const choices = apps.map((a) => ({
    name: a.id,
    message: `${a.name}  ·  ${a.bundleId}`,
  }));
  const { appId } = await prompt<{ appId: string }>({
    type: "select",
    name: "appId",
    message: "Select an app to work on:",
    choices,
  });
  const picked = apps.find((a) => a.id === appId);
  if (!picked) throw new Error(`unexpected app id: ${appId}`);
  return picked;
}

const HELP_TOKEN = "?";

export async function promptCredentials(): Promise<Credentials> {
  const keyPath = await promptKeyPath();

  const keyId = await resolveKeyId(keyPath);

  const { issuerId } = await prompt<{ issuerId: string }>({
    type: "input",
    name: "issuerId",
    message: "Issuer ID (UUID):",
    validate: (v: string) => (v.trim().length > 0 ? true : "issuer id is required"),
  });

  const privateKey = await fs.readFile(keyPath, "utf8").catch((err) => {
    throw new Error(`could not read key at ${keyPath}: ${err.message}`);
  });

  return {
    keyPath,
    keyId,
    issuerId: issuerId.trim(),
    privateKey,
  };
}

async function resolveKeyId(keyPath: string): Promise<string> {
  const inferred = inferKeyIdFromPath(keyPath);
  const { keyId } = await prompt<{ keyId: string }>({
    type: "input",
    name: "keyId",
    message: "Key ID (10-char string, e.g. ABC123DEFG):",
    initial: inferred ?? "",
    validate: (v: string) => (v.trim().length > 0 ? true : "key id is required"),
  });
  return keyId.trim();
}

function inferKeyIdFromPath(keyPath: string): string | null {
  const base = path.basename(keyPath);
  const match = base.match(/AuthKey_([A-Z0-9]{10})\.p8$/i);
  return match ? match[1]!.toUpperCase() : null;
}

async function promptKeyPath(): Promise<string> {
  for (;;) {
    const { keyPath } = await prompt<{ keyPath: string }>({
      type: "input",
      name: "keyPath",
      message: `Path to your .p8 file  (type "${HELP_TOKEN}" to see how to generate one):`,
      validate: (v: string) => (v.trim().length > 0 ? true : "path is required"),
    });

    const cleaned = stripWrappingQuotes(keyPath.trim());
    if (cleaned === HELP_TOKEN) {
      printAuthInstructions();
      continue;
    }

    return expandHome(cleaned);
  }
}

export function printAuthInstructions(): void {
  console.log(`
How to generate an App Store Connect API key:
  1. Open https://appstoreconnect.apple.com/access/integrations/api
  2. You must be the Account Holder or an Admin to create keys.
  3. Click the "+" button under "Active" to generate a new key.
  4. Give it a name (e.g. "asc-prices") and choose the
     "App Manager" role — sufficient for pricing changes.
  5. Click "Generate". Download the .p8 file — Apple only lets you
     download it ONCE. Store it somewhere safe (e.g. ~/.asc-prices/).
  6. From the same page, copy:
       - the Key ID    (next to your new key)
       - the Issuer ID (shown at the top of the Keys tab)

When you have the key ready, paste its path at the prompt below.
`);
}

function stripWrappingQuotes(s: string): string {
  if (s.length >= 2) {
    const first = s[0];
    const last = s[s.length - 1];
    if ((first === '"' || first === "'") && first === last) {
      return s.slice(1, -1);
    }
  }
  return s;
}

function expandHome(p: string): string {
  if (p.startsWith("~")) {
    return path.join(process.env.HOME ?? "", p.slice(1));
  }
  return path.resolve(p);
}
