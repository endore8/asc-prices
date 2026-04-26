import type { AscClient } from "./client.js";

export interface Subscription {
  id: string;
  name: string;
  productId: string;
  groupName: string;
}

interface SubscriptionGroupsResponse {
  data: Array<{
    id: string;
    type: "subscriptionGroups";
    attributes: { referenceName: string };
    relationships?: { subscriptions?: { data?: Array<{ id: string; type: string }> } };
  }>;
  included?: Array<{
    id: string;
    type: string;
    attributes: { name: string; productId: string };
  }>;
}

export async function listSubscriptions(client: AscClient, appId: string): Promise<Subscription[]> {
  const res = await client.get<SubscriptionGroupsResponse>(
    `/v1/apps/${appId}/subscriptionGroups` +
      `?include=subscriptions` +
      `&fields[subscriptionGroups]=referenceName,subscriptions` +
      `&fields[subscriptions]=name,productId` +
      `&limit=200`,
  );

  const subById = new Map<string, { name: string; productId: string }>();
  for (const inc of res.included ?? []) {
    if (inc.type === "subscriptions") {
      subById.set(inc.id, { name: inc.attributes.name, productId: inc.attributes.productId });
    }
  }

  const out: Subscription[] = [];
  for (const group of res.data) {
    const groupName = group.attributes.referenceName;
    const refs = group.relationships?.subscriptions?.data ?? [];
    for (const ref of refs) {
      const sub = subById.get(ref.id);
      if (!sub) continue;
      out.push({ id: ref.id, name: sub.name, productId: sub.productId, groupName });
    }
  }
  return out;
}
