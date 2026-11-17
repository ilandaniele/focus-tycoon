import { authenticate } from "../auth";
import type { Env } from "../env";
import { HttpError, json, readJson } from "../http";
import { pushSchema, type Transaction } from "../schemas";

const INSERT_SQL = `INSERT INTO resource_transactions
  (player_id, idem_key, delta_coins, delta_nature, delta_xp, reason, client_at, server_at)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  ON CONFLICT (player_id, idem_key) DO NOTHING
  RETURNING id`;

export async function pushTransactions(request: Request, env: Env): Promise<Response> {
  const playerId = await authenticate(request, env.DB);
  const { success } = await env.SYNC_LIMITER.limit({ key: playerId });
  if (!success) throw new HttpError(429, "rate_limited");
  const parsed = pushSchema.safeParse(await readJson(request));
  if (!parsed.success) throw new HttpError(400, "invalid_body");
  const statement = env.DB.prepare(INSERT_SQL);
  const now = Date.now();
  const results = await env.DB.batch(parsed.data.transactions.map((row) => bindRow(statement, playerId, row, now)));
  const accepted = results.reduce((sum, result) => sum + result.results.length, 0);
  return json({ received: parsed.data.transactions.length, accepted });
}

function bindRow(statement: D1PreparedStatement, playerId: string, row: Transaction, now: number): D1PreparedStatement {
  return statement.bind(playerId, row.idem_key, row.delta_coins, row.delta_nature, row.delta_xp, row.reason, row.client_at, now);
}
