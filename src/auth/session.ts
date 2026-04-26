import { generateToken, type JwtParams } from "./jwt.js";

const REFRESH_BUFFER_MS = 60 * 1000;

export class TokenCache {
  private token: string | null = null;
  private expiresAt = 0;

  constructor(private readonly params: JwtParams) {}

  getToken(): string {
    if (!this.token || Date.now() >= this.expiresAt - REFRESH_BUFFER_MS) {
      const { token, expiresAt } = generateToken(this.params);
      this.token = token;
      this.expiresAt = expiresAt;
    }
    return this.token;
  }
}
