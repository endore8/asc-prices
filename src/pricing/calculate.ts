import type { PriceRow } from "../api/prices.js";
import { bigMacLookup } from "../indices/big-mac.js";

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

export function calculateBigMacTargets(
  basePrice: number,
  baseTerritory: string,
  rows: PriceRow[],
): PriceDiff[] {
  const baseEntry = bigMacLookup(baseTerritory);
  if (!baseEntry) {
    throw new Error(`base country ${baseTerritory} has no Big Mac data`);
  }

  return rows.map((row) => {
    const current = parseLocal(row.customerPrice);
    const entry = bigMacLookup(row.territory);

    if (!entry) {
      return diffWithNote(row, current, "no Big Mac data");
    }
    if (entry.currency !== row.currency) {
      return diffWithNote(row, current, `currency mismatch (Big Mac uses ${entry.currency})`);
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
