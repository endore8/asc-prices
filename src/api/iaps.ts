import type { AscClient } from "./client.js";

export type IapType = "CONSUMABLE" | "NON_CONSUMABLE" | "NON_RENEWING_SUBSCRIPTION";

export interface InAppPurchase {
  id: string;
  name: string;
  productId: string;
  iapType: IapType;
}

interface IapsResponse {
  data: Array<{
    id: string;
    type: "inAppPurchases";
    attributes: { name: string; productId: string; inAppPurchaseType: IapType };
  }>;
}

export async function listInAppPurchases(client: AscClient, appId: string): Promise<InAppPurchase[]> {
  const res = await client.get<IapsResponse>(
    `/v1/apps/${appId}/inAppPurchasesV2` +
      `?fields[inAppPurchases]=name,productId,inAppPurchaseType` +
      `&limit=200`,
  );
  return res.data.map((d) => ({
    id: d.id,
    name: d.attributes.name,
    productId: d.attributes.productId,
    iapType: d.attributes.inAppPurchaseType,
  }));
}
