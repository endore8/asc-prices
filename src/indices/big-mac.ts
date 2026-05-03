import { indexFromMap, withEuro, type IndexEntry, type PriceIndex } from "./types.js";

const SINGLE: Record<string, IndexEntry> = {
  USA: { currency: "USD", localPrice: 5.79 },
  ARG: { currency: "ARS", localPrice: 6200 },
  AUS: { currency: "AUD", localPrice: 7.50 },
  BRA: { currency: "BRL", localPrice: 25.00 },
  GBR: { currency: "GBP", localPrice: 4.49 },
  CAN: { currency: "CAD", localPrice: 7.49 },
  CHL: { currency: "CLP", localPrice: 5750 },
  CHN: { currency: "CNY", localPrice: 25.00 },
  COL: { currency: "COP", localPrice: 18500 },
  CZE: { currency: "CZK", localPrice: 119 },
  DNK: { currency: "DKK", localPrice: 36 },
  EGY: { currency: "EGP", localPrice: 100 },
  HKG: { currency: "HKD", localPrice: 23.00 },
  HUN: { currency: "HUF", localPrice: 1300 },
  IND: { currency: "INR", localPrice: 230 },
  IDN: { currency: "IDR", localPrice: 35000 },
  ISR: { currency: "ILS", localPrice: 19 },
  JPN: { currency: "JPY", localPrice: 480 },
  MYS: { currency: "MYR", localPrice: 12.00 },
  MEX: { currency: "MXN", localPrice: 95 },
  NZL: { currency: "NZD", localPrice: 8.50 },
  NOR: { currency: "NOK", localPrice: 75 },
  PHL: { currency: "PHP", localPrice: 213 },
  POL: { currency: "PLN", localPrice: 23.00 },
  SAU: { currency: "SAR", localPrice: 18.00 },
  SGP: { currency: "SGD", localPrice: 6.50 },
  ZAF: { currency: "ZAR", localPrice: 60.00 },
  KOR: { currency: "KRW", localPrice: 5500 },
  SWE: { currency: "SEK", localPrice: 60.00 },
  CHE: { currency: "CHF", localPrice: 7.20 },
  TWN: { currency: "TWD", localPrice: 75 },
  THA: { currency: "THB", localPrice: 130 },
  TUR: { currency: "TRY", localPrice: 250 },
  ARE: { currency: "AED", localPrice: 18 },
  UKR: { currency: "UAH", localPrice: 100 },
  VNM: { currency: "VND", localPrice: 80000 },
};

const DATA = withEuro(SINGLE, 5.20);

export const BIG_MAC: PriceIndex = indexFromMap("big-mac", "Big Mac Index", DATA);
