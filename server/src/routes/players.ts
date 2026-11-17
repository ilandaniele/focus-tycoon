import { generateToken, hashToken } from "../auth";
import type { Env } from "../env";
import { clientIp, HttpError, json } from "../http";

export async function createPlayer(request: Request, env: Env): Promise<Response> {
  const { success } = await env.SIGNUP_LIMITER.limit({ key: clientIp(request) });
  if (!success) throw new HttpError(429, "rate_limited");
  const playerId = crypto.randomUUID();
  const token = generateToken();
  await env.DB.prepare("INSERT INTO players (id, token_hash, created_at) VALUES (?, ?, ?)")
    .bind(playerId, await hashToken(token), Date.now())
    .run();
  return json({ player_id: playerId, token }, 201);
}
