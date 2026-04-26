import type { AscClient } from "./client.js";

export interface App {
  id: string;
  name: string;
  bundleId: string;
  sku: string;
}

interface AppsResponse {
  data: Array<{
    id: string;
    type: "apps";
    attributes: { name: string; bundleId: string; sku: string };
  }>;
}

export async function listApps(client: AscClient): Promise<App[]> {
  const res = await client.get<AppsResponse>("/v1/apps?limit=200&fields[apps]=name,bundleId,sku");
  return res.data.map((d) => ({
    id: d.id,
    name: d.attributes.name,
    bundleId: d.attributes.bundleId,
    sku: d.attributes.sku,
  }));
}
