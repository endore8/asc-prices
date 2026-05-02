export interface PriceIndex {
  id: string;
  label: string;
}

export const INDEXES: PriceIndex[] = [
  { id: "big-mac",     label: "Big Mac Index" },
  { id: "apple-music", label: "Apple Music Index" },
  { id: "netflix",     label: "Netflix Index" },
  { id: "world-bank",  label: "World Bank PPP" },
];
