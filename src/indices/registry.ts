import { BIG_MAC } from "./big-mac.js";
import { APPLE_MUSIC } from "./apple-music.js";
import { NETFLIX } from "./netflix.js";
import { WORLD_BANK } from "./world-bank.js";
import type { PriceIndex } from "./types.js";

export type { PriceIndex } from "./types.js";

export const INDEXES: PriceIndex[] = [BIG_MAC, APPLE_MUSIC, NETFLIX, WORLD_BANK];

export function indexById(id: string): PriceIndex | null {
  return INDEXES.find((i) => i.id === id) ?? null;
}

export function allBaseTerritories(): string[] {
  const set = new Set<string>();
  for (const i of INDEXES) for (const t of i.territories()) set.add(t);
  return Array.from(set);
}
