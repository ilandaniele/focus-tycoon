import { HttpError } from "./http";

const TOKEN_BYTES = 32;

export function generateToken(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(TOKEN_BYTES));
  return btoa(String.fromCharCode(...bytes)).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

export async function hashToken(token: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(token));
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

export function bearerToken(request: Request): string {
  const header = request.headers.get("Authorization") ?? "";
  const match = /^Bearer ([A-Za-z0-9_-]{20,128})$/.exec(header);
  if (!match) throw new HttpError(401, "unauthorized");
  return match[1];
}

export async function authenticate(request: Request, db: D1Database): Promise<string> {
  const tokenHash = await hashToken(bearerToken(request));
  const player = await db.prepare("SELECT id FROM players WHERE token_hash = ?").bind(tokenHash).first<{ id: string }>();
  if (!player) throw new HttpError(401, "unauthorized");
  return player.id;
}
