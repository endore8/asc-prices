import { indexFromMap, withEuro, type IndexEntry, type PriceIndex } from "./types.js";

const SINGLE: Record<string, IndexEntry> = {
  USA: { currency: "USD", localPrice: 10.99 },
  ARG: { currency: "ARS", localPrice: 1750 },
  AUS: { currency: "AUD", localPrice: 12.99 },
  BRA: { currency: "BRL", localPrice: 21.90 },
  GBR: { currency: "GBP", localPrice: 10.99 },
  CAN: { currency: "CAD", localPrice: 10.99 },
  CHL: { currency: "CLP", localPrice: 5500 },
  CHN: { currency: "CNY", localPrice: 11.00 },
  COL: { currency: "COP", localPrice: 16900 },
  CZE: { currency: "CZK", localPrice: 159.00 },
  DNK: { currency: "DKK", localPrice: 79.00 },
  EGY: { currency: "EGP", localPrice: 79.99 },
  HKG: { currency: "HKD", localPrice: 88.00 },
  HUN: { currency: "HUF", localPrice: 1690 },
  IND: { currency: "INR", localPrice: 99.00 },
  IDN: { currency: "IDR", localPrice: 49000 },
  ISR: { currency: "ILS", localPrice: 19.90 },
  JPN: { currency: "JPY", localPrice: 1080 },
  MYS: { currency: "MYR", localPrice: 16.90 },
  MEX: { currency: "MXN", localPrice: 115.00 },
  NZL: { currency: "NZD", localPrice: 14.99 },
  NOR: { currency: "NOK", localPrice: 99.00 },
  PHL: { currency: "PHP", localPrice: 149.00 },
  POL: { currency: "PLN", localPrice: 24.99 },
  SAU: { currency: "SAR", localPrice: 19.99 },
  SGP: { currency: "SGD", localPrice: 11.00 },
  ZAF: { currency: "ZAR", localPrice: 59.99 },
  KOR: { currency: "KRW", localPrice: 11900 },
  SWE: { currency: "SEK", localPrice: 109.00 },
  CHE: { currency: "CHF", localPrice: 12.95 },
  TWN: { currency: "TWD", localPrice: 170 },
  THA: { currency: "THB", localPrice: 169.00 },
  TUR: { currency: "TRY", localPrice: 39.99 },
  ARE: { currency: "AED", localPrice: 19.99 },
  UKR: { currency: "UAH", localPrice: 79.00 },
  VNM: { currency: "VND", localPrice: 79000 },
};

const DATA = withEuro(SINGLE, 10.99);

export const APPLE_MUSIC: PriceIndex = indexFromMap(
  "apple-music",
  "Apple Music Index",
  DATA,
);
