import type { PriceRow } from "../api/prices.js";
import type { PriceIndex } from "../indices/registry.js";

export interface PriceDiff {
  territory: string;
  territoryName: string;
  currency: string;
  current: number | null;
  target: number | null;
  deltaPct: number | null;
  note?: string;
}

const NO_MINOR_UNITS = new Set(["JPY", "KRW", "VND", "IDR", "CLP", "ISK", "HUF"]);

export function calculatePppTargets(
  basePrice: number,
  baseTerritory: string,
  rows: PriceRow[],
  index: PriceIndex,
): PriceDiff[] {
  const baseEntry = index.lookup(baseTerritory);
  if (!baseEntry) {
    throw new Error(`base country ${baseTerritory} has no ${index.label} data`);
  }

  return rows.map((row) => {
    const current = parseLocal(row.customerPrice);
    const entry = index.lookup(row.territory);

    if (!entry) {
      return diffWithNote(row, current, `no ${index.label} data`);
    }
    if (entry.currency !== row.currency) {
      return diffWithNote(
        row,
        current,
        `currency mismatch (${index.label} uses ${entry.currency})`,
      );
    }

    const raw = basePrice * (entry.localPrice / baseEntry.localPrice);
    const target = roundForCurrency(raw, row.currency);
    const deltaPct =
      current !== null && current > 0 ? ((target - current) / current) * 100 : null;

    return {
      territory: row.territory,
      territoryName: row.territoryName,
      currency: row.currency,
      current,
      target,
      deltaPct,
    };
  });
}

function diffWithNote(row: PriceRow, current: number | null, note: string): PriceDiff {
  return {
    territory: row.territory,
    territoryName: row.territoryName,
    currency: row.currency,
    current,
    target: null,
    deltaPct: null,
    note,
  };
}

function parseLocal(s: string): number | null {
  const n = parseFloat(s);
  return Number.isFinite(n) ? n : null;
}

function roundForCurrency(value: number, currency: string): number {
  if (NO_MINOR_UNITS.has(currency)) return Math.round(value);
  return Math.round(value * 100) / 100;
}
