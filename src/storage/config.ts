import { promises as fs } from "node:fs";
import os from "node:os";
import path from "node:path";

export interface StoredConfig {
  keyPath: string;
  keyId: string;
  issuerId: string;
  baseCountry?: string;
  savedAt: string;
}

const DIR = path.join(os.homedir(), ".asc-prices");
const FILE = path.join(DIR, "config.json");

export async function loadConfig(): Promise<StoredConfig | null> {
  try {
    const raw = await fs.readFile(FILE, "utf8");
    const parsed = JSON.parse(raw) as StoredConfig;
    if (
      typeof parsed.keyPath !== "string" ||
      typeof parsed.keyId !== "string" ||
      typeof parsed.issuerId !== "string"
    ) {
      return null;
    }
    if (parsed.baseCountry !== undefined && typeof parsed.baseCountry !== "string") {
      delete parsed.baseCountry;
    }
    return parsed;
  } catch (err) {
    if (isErrnoException(err) && err.code === "ENOENT") return null;
    throw err;
  }
}

export async function saveConfig(cfg: Omit<StoredConfig, "savedAt">): Promise<void> {
  await fs.mkdir(DIR, { recursive: true, mode: 0o700 });
  const payload: StoredConfig = { ...cfg, savedAt: new Date().toISOString() };
  await fs.writeFile(FILE, JSON.stringify(payload, null, 2), { mode: 0o600 });
}

export async function clearConfig(): Promise<boolean> {
  try {
    await fs.unlink(FILE);
    return true;
  } catch (err) {
    if (isErrnoException(err) && err.code === "ENOENT") return false;
    throw err;
  }
}

export function configPath(): string {
  return FILE;
}

function isErrnoException(err: unknown): err is NodeJS.ErrnoException {
  return err instanceof Error && "code" in err;
}
