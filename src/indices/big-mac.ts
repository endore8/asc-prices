export interface BigMacEntry {
  currency: string;
  localPrice: number;
}

const SINGLE: Record<string, BigMacEntry> = {
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

const EURO_AREA = [
  "AUT", "BEL", "CYP", "DEU", "ESP", "EST", "FIN", "FRA", "GRC", "HRV",
  "IRL", "ITA", "LTU", "LUX", "LVA", "MLT", "NLD", "PRT", "SVK", "SVN",
];
const EURO_PRICE = 5.20;

const DATA: Record<string, BigMacEntry> = { ...SINGLE };
for (const t of EURO_AREA) {
  DATA[t] = { currency: "EUR", localPrice: EURO_PRICE };
}

export function bigMacLookup(territoryAlpha3: string): BigMacEntry | null {
  return DATA[territoryAlpha3] ?? null;
}

export function bigMacTerritories(): string[] {
  return Object.keys(DATA);
}
