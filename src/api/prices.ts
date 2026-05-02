import iso3166 from "iso-3166-1";
import type { AscClient } from "./client.js";

export interface PriceRow {
  territory: string;
  territoryName: string;
  currency: string;
  customerPrice: string;
  proceeds: string;
}

const REGION_NAMES = new Intl.DisplayNames(["en"], { type: "region" });

function territoryName(alpha3: string): string {
  const entry = iso3166.whereAlpha3(alpha3);
  if (!entry) return "";
  return REGION_NAMES.of(entry.alpha2) ?? entry.country;
}

interface SubPricesResponse {
  data: Array<{
    id: string;
    type: "subscriptionPrices";
    relationships: {
      subscriptionPricePoint: { data: { id: string; type: string } };
      territory: { data: { id: string; type: string } };
    };
  }>;
  included?: Array<
    | {
        id: string;
        type: "subscriptionPricePoints";
        attributes: { customerPrice: string; proceeds: string };
      }
    | { id: string; type: "territories"; attributes: { currency: string } }
  >;
}

export async function listSubscriptionPrices(
  client: AscClient,
  subscriptionId: string,
): Promise<PriceRow[]> {
  const res = await client.get<SubPricesResponse>(
    `/v1/subscriptions/${encodeURIComponent(subscriptionId)}/prices` +
      `?include=subscriptionPricePoint,territory` +
      `&fields[subscriptionPrices]=subscriptionPricePoint,territory` +
      `&fields[subscriptionPricePoints]=customerPrice,proceeds` +
      `&fields[territories]=currency` +
      `&limit=200`,
  );

  const pricePoints = new Map<string, { customerPrice: string; proceeds: string }>();
  const territories = new Map<string, { currency: string }>();
  for (const inc of res.included ?? []) {
    if (inc.type === "subscriptionPricePoints") {
      pricePoints.set(inc.id, inc.attributes);
    } else if (inc.type === "territories") {
      territories.set(inc.id, inc.attributes);
    }
  }

  return res.data
    .map((d) => {
      const ppId = d.relationships.subscriptionPricePoint.data.id;
      const tId = d.relationships.territory.data.id;
      const pp = pricePoints.get(ppId);
      const t = territories.get(tId);
      return {
        territory: tId,
        territoryName: territoryName(tId),
        currency: t?.currency ?? "?",
        customerPrice: pp?.customerPrice ?? "?",
        proceeds: pp?.proceeds ?? "?",
      };
    })
    .sort((a, b) => a.territoryName.localeCompare(b.territoryName));
}
