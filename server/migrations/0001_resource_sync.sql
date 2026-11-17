-- Resource sync: anonymous players, server-side balances and the idempotent transaction ledger.
-- Balances change only through the transaction trigger, never by direct writes from the API.

CREATE TABLE players (
  id TEXT PRIMARY KEY,
  token_hash TEXT NOT NULL UNIQUE,
  created_at INTEGER NOT NULL
);

CREATE TABLE player_resources (
  player_id TEXT PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
  coins INTEGER NOT NULL DEFAULT 0 CHECK (coins >= 0),
  nature INTEGER NOT NULL DEFAULT 0 CHECK (nature >= 0),
  xp INTEGER NOT NULL DEFAULT 0 CHECK (xp >= 0),
  updated_at INTEGER NOT NULL
);

CREATE TABLE resource_transactions (
  id INTEGER PRIMARY KEY,
  player_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  idem_key TEXT NOT NULL CHECK (length(idem_key) BETWEEN 1 AND 128),
  delta_coins INTEGER NOT NULL,
  delta_nature INTEGER NOT NULL,
  delta_xp INTEGER NOT NULL CHECK (delta_xp >= 0),
  reason TEXT NOT NULL CHECK (length(reason) BETWEEN 1 AND 32),
  client_at TEXT NOT NULL,
  server_at INTEGER NOT NULL,
  UNIQUE (player_id, idem_key)
);

CREATE INDEX resource_transactions_recent ON resource_transactions (player_id, server_at DESC);

CREATE TRIGGER create_resources_for_player
AFTER INSERT ON players
BEGIN
  INSERT INTO player_resources (player_id, updated_at) VALUES (NEW.id, NEW.created_at);
END;

CREATE TRIGGER apply_resource_transaction
AFTER INSERT ON resource_transactions
BEGIN
  UPDATE player_resources
     SET coins = max(0, coins + NEW.delta_coins),
         nature = max(0, nature + NEW.delta_nature),
         xp = xp + NEW.delta_xp,
         updated_at = NEW.server_at
   WHERE player_id = NEW.player_id;
END;
