import type { TokenCache } from "../auth/session.js";

const BASE_URL = "https://api.appstoreconnect.apple.com";

export class AscClient {
  constructor(private readonly tokens: TokenCache) {}

  async get<T>(pathAndQuery: string): Promise<T> {
    const res = await fetch(`${BASE_URL}${pathAndQuery}`, {
      headers: {
        Authorization: `Bearer ${this.tokens.getToken()}`,
        Accept: "application/json",
      },
    });
    if (!res.ok) {
      const body = await res.text().catch(() => "");
      throw new Error(`ASC ${res.status} ${res.statusText}: ${body || pathAndQuery}`);
    }
    return (await res.json()) as T;
  }
}
