import { bearerToken, hashToken } from "../auth";
import type { Env } from "../env";
import { HttpError, json } from "../http";

const BALANCE_SQL = `SELECT r.coins, r.nature, r.xp FROM players p
  JOIN player_resources r ON r.player_id = p.id
  WHERE p.token_hash = ?`;

export async function getResources(request: Request, env: Env): Promise<Response> {
  const tokenHash = await hashToken(bearerToken(request));
  const balance = await env.DB.prepare(BALANCE_SQL).bind(tokenHash).first();
  if (!balance) throw new HttpError(401, "unauthorized");
  return json(balance);
}
