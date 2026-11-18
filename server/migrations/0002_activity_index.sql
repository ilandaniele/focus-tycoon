-- Supports the daily purge of players with no sync activity for 24 months.
CREATE INDEX player_resources_updated_at ON player_resources (updated_at);
