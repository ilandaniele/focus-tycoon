import { bearerToken, generateToken, hashToken } from "../auth";
import type { Env } from "../env";
import { clientIp, HttpError, json, noContent } from "../http";
import { purgeInactivePlayers } from "../retention";

export async function createPlayer(request: Request, env: Env): Promise<Response> {
  const { success } = await env.SIGNUP_LIMITER.limit({ key: clientIp(request) });
  if (!success) throw new HttpError(429, "rate_limited");
  const playerId = crypto.randomUUID();
  const token = generateToken();
  const now = Date.now();
  await env.DB.batch([
    env.DB.prepare("INSERT INTO players (id, token_hash, created_at) VALUES (?, ?, ?)").bind(playerId, await hashToken(token), now),
    purgeInactivePlayers(env.DB, now),
  ]);
  return json({ player_id: playerId, token }, 201);
}

export async function deletePlayer(request: Request, env: Env): Promise<Response> {
  const tokenHash = await hashToken(bearerToken(request));
  const deleted = await env.DB.prepare("DELETE FROM players WHERE token_hash = ? RETURNING id").bind(tokenHash).first();
  if (!deleted) throw new HttpError(401, "unauthorized");
  return noContent();
}
