export const RETENTION_DAYS = 730;
const DAY_MS = 24 * 60 * 60 * 1000;

const PURGE_SQL = `DELETE FROM players WHERE id IN (
  SELECT player_id FROM player_resources WHERE updated_at < ?
)`;

export async function purgeInactivePlayers(db: D1Database, now: number): Promise<number> {
  const result = await db.prepare(PURGE_SQL).bind(now - RETENTION_DAYS * DAY_MS).run();
  return result.meta.changes;
}
