import { indexFromMap, withEuro, type IndexEntry, type PriceIndex } from "./types.js";

const SINGLE: Record<string, IndexEntry> = {
  USA: { currency: "USD", localPrice: 15.49 },
  ARG: { currency: "ARS", localPrice: 4699 },
  AUS: { currency: "AUD", localPrice: 18.99 },
  BRA: { currency: "BRL", localPrice: 39.90 },
  GBR: { currency: "GBP", localPrice: 10.99 },
  CAN: { currency: "CAD", localPrice: 16.49 },
  CHL: { currency: "CLP", localPrice: 8500 },
  COL: { currency: "COP", localPrice: 35900 },
  CZE: { currency: "CZK", localPrice: 299 },
  DNK: { currency: "DKK", localPrice: 119 },
  EGY: { currency: "EGP", localPrice: 165 },
  HKG: { currency: "HKD", localPrice: 88 },
  HUN: { currency: "HUF", localPrice: 3490 },
  IND: { currency: "INR", localPrice: 499 },
  IDN: { currency: "IDR", localPrice: 153000 },
  ISR: { currency: "ILS", localPrice: 49.90 },
  JPN: { currency: "JPY", localPrice: 1490 },
  MYS: { currency: "MYR", localPrice: 35 },
  MEX: { currency: "MXN", localPrice: 219 },
  NZL: { currency: "NZD", localPrice: 19.99 },
  NOR: { currency: "NOK", localPrice: 169 },
  PHL: { currency: "PHP", localPrice: 399 },
  POL: { currency: "PLN", localPrice: 53 },
  SAU: { currency: "SAR", localPrice: 49 },
  SGP: { currency: "SGD", localPrice: 17.98 },
  ZAF: { currency: "ZAR", localPrice: 169 },
  KOR: { currency: "KRW", localPrice: 13500 },
  SWE: { currency: "SEK", localPrice: 139 },
  CHE: { currency: "CHF", localPrice: 23.50 },
  TWN: { currency: "TWD", localPrice: 330 },
  THA: { currency: "THB", localPrice: 419 },
  TUR: { currency: "TRY", localPrice: 113.99 },
  ARE: { currency: "AED", localPrice: 39 },
  VNM: { currency: "VND", localPrice: 220000 },
};

const DATA = withEuro(SINGLE, 13.49);

export const NETFLIX: PriceIndex = indexFromMap("netflix", "Netflix Index", DATA);
