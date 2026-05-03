import { indexFromMap, withEuro, type IndexEntry, type PriceIndex } from "./types.js";

const SINGLE: Record<string, IndexEntry> = {
  USA: { currency: "USD", localPrice: 1.00 },
  ARG: { currency: "ARS", localPrice: 330 },
  AUS: { currency: "AUD", localPrice: 1.47 },
  BRA: { currency: "BRL", localPrice: 2.43 },
  GBR: { currency: "GBP", localPrice: 0.69 },
  CAN: { currency: "CAD", localPrice: 1.27 },
  CHL: { currency: "CLP", localPrice: 461 },
  CHN: { currency: "CNY", localPrice: 4.21 },
  COL: { currency: "COP", localPrice: 1444 },
  CZE: { currency: "CZK", localPrice: 13.7 },
  DNK: { currency: "DKK", localPrice: 7.10 },
  EGY: { currency: "EGP", localPrice: 8.07 },
  HKG: { currency: "HKD", localPrice: 6.05 },
  HUN: { currency: "HUF", localPrice: 188 },
  IND: { currency: "INR", localPrice: 21.5 },
  IDN: { currency: "IDR", localPrice: 4684 },
  ISR: { currency: "ILS", localPrice: 3.78 },
  JPN: { currency: "JPY", localPrice: 102 },
  MYS: { currency: "MYR", localPrice: 1.65 },
  MEX: { currency: "MXN", localPrice: 10.2 },
  NZL: { currency: "NZD", localPrice: 1.47 },
  NOR: { currency: "NOK", localPrice: 9.65 },
  PHL: { currency: "PHP", localPrice: 19.5 },
  POL: { currency: "PLN", localPrice: 1.85 },
  SAU: { currency: "SAR", localPrice: 1.78 },
  SGP: { currency: "SGD", localPrice: 0.83 },
  ZAF: { currency: "ZAR", localPrice: 7.41 },
  KOR: { currency: "KRW", localPrice: 882 },
  SWE: { currency: "SEK", localPrice: 8.85 },
  CHE: { currency: "CHF", localPrice: 1.16 },
  TWN: { currency: "TWD", localPrice: 14.4 },
  THA: { currency: "THB", localPrice: 12.4 },
  TUR: { currency: "TRY", localPrice: 4.05 },
  ARE: { currency: "AED", localPrice: 2.16 },
  UKR: { currency: "UAH", localPrice: 9.5 },
  VNM: { currency: "VND", localPrice: 7615 },
};

const DATA = withEuro(SINGLE, 0.74);

export const WORLD_BANK: PriceIndex = indexFromMap(
  "world-bank",
  "World Bank PPP",
  DATA,
);
