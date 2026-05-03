import iso3166 from "iso-3166-1";

const REGION_NAMES = new Intl.DisplayNames(["en"], { type: "region" });

export function territoryName(alpha3: string): string {
  const entry = iso3166.whereAlpha3(alpha3);
  if (!entry) return "";
  return REGION_NAMES.of(entry.alpha2) ?? entry.country;
}
