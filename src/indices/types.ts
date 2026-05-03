export interface IndexEntry {
  currency: string;
  localPrice: number;
}

export interface PriceIndex {
  id: string;
  label: string;
  lookup(alpha3: string): IndexEntry | null;
  territories(): string[];
}

export const EURO_AREA = [
  "AUT", "BEL", "CYP", "DEU", "ESP", "EST", "FIN", "FRA", "GRC", "HRV",
  "IRL", "ITA", "LTU", "LUX", "LVA", "MLT", "NLD", "PRT", "SVK", "SVN",
];

export function withEuro(
  map: Record<string, IndexEntry>,
  euroPrice: number,
): Record<string, IndexEntry> {
  const result = { ...map };
  for (const t of EURO_AREA) {
    if (!(t in result)) {
      result[t] = { currency: "EUR", localPrice: euroPrice };
    }
  }
  return result;
}

export function indexFromMap(
  id: string,
  label: string,
  data: Record<string, IndexEntry>,
): PriceIndex {
  return {
    id,
    label,
    lookup: (t) => data[t] ?? null,
    territories: () => Object.keys(data),
  };
}
