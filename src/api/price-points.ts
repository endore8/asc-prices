import type { AscClient } from "./client.js";

export interface SubscriptionPricePoint {
  id: string;
  customerPriceRaw: string;
  customerPrice: number;
  proceeds: number;
}

interface SubPricePointsResponse {
  data: Array<{
    id: string;
    type: "subscriptionPricePoints";
    attributes: { customerPrice: string; proceeds: string };
  }>;
  links?: { next?: string };
}

export async function listSubscriptionPricePoints(
  client: AscClient,
  subscriptionId: string,
  territoryAlpha3: string,
): Promise<SubscriptionPricePoint[]> {
  const seen = new Map<string, SubscriptionPricePoint>();
  let path: string | null =
    `/v1/subscriptions/${encodeURIComponent(subscriptionId)}/pricePoints` +
    `?filter[territory]=${encodeURIComponent(territoryAlpha3)}` +
    `&fields[subscriptionPricePoints]=customerPrice,proceeds` +
    `&limit=200`;

  while (path) {
    const res: SubPricePointsResponse = await client.get<SubPricePointsResponse>(path);
    for (const d of res.data) {
      const cp = d.attributes.customerPrice;
      if (seen.has(cp)) continue;
      const num = parseFloat(cp);
      if (!Number.isFinite(num)) continue;
      seen.set(cp, {
        id: d.id,
        customerPriceRaw: cp,
        customerPrice: num,
        proceeds: parseFloat(d.attributes.proceeds),
      });
    }
    path = res.links?.next ?? null;
  }

  return Array.from(seen.values()).sort((a, b) => a.customerPrice - b.customerPrice);
}
