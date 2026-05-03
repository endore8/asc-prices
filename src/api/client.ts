import type { TokenCache } from "../auth/session.js";

const BASE_URL = "https://api.appstoreconnect.apple.com";

export class AscClient {
  constructor(private readonly tokens: TokenCache) {}

  async get<T>(pathOrUrl: string): Promise<T> {
    const url = pathOrUrl.startsWith("http") ? pathOrUrl : `${BASE_URL}${pathOrUrl}`;
    const res = await fetch(url, {
      headers: {
        Authorization: `Bearer ${this.tokens.getToken()}`,
        Accept: "application/json",
      },
    });
    if (!res.ok) {
      const body = await res.text().catch(() => "");
      throw new Error(`ASC ${res.status} ${res.statusText}: ${body || pathOrUrl}`);
    }
    return (await res.json()) as T;
  }
}
