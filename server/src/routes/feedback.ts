import { bearerToken, hashToken } from "../auth";
import type { Env } from "../env";
import { HttpError, noContent, readJson } from "../http";
import { feedbackSchema } from "../schemas";

const INSERT_SQL = `INSERT INTO feedback (player_id, category, message, app_version, platform, created_at)
  SELECT id, ?, ?, ?, ?, ? FROM players WHERE token_hash = ?
  RETURNING id`;

export async function postFeedback(request: Request, env: Env): Promise<Response> {
  const tokenHash = await hashToken(bearerToken(request));
  const { success } = await env.FEEDBACK_LIMITER.limit({ key: tokenHash });
  if (!success) throw new HttpError(429, "rate_limited");
  const parsed = feedbackSchema.safeParse(await readJson(request));
  if (!parsed.success) throw new HttpError(400, "invalid_body");
  const { category, message, app_version, platform } = parsed.data;
  const inserted = await env.DB.prepare(INSERT_SQL).bind(category, message, app_version, platform, Date.now(), tokenHash).first();
  if (!inserted) throw new HttpError(401, "unauthorized");
  return noContent();
}
