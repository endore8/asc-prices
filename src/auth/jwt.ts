import jwt from "jsonwebtoken";

export interface JwtParams {
  keyId: string;
  issuerId: string;
  privateKey: string;
}

const AUDIENCE = "appstoreconnect-v1";
const TTL_SECONDS = 19 * 60;

export function generateToken(params: JwtParams): { token: string; expiresAt: number } {
  const now = Math.floor(Date.now() / 1000);
  const exp = now + TTL_SECONDS;

  const token = jwt.sign(
    { iss: params.issuerId, iat: now, exp, aud: AUDIENCE },
    params.privateKey,
    { algorithm: "ES256", header: { alg: "ES256", kid: params.keyId, typ: "JWT" } },
  );

  return { token, expiresAt: exp * 1000 };
}
