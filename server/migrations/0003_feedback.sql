-- Beta feedback sent from the game. Deleted with the player.
CREATE TABLE feedback (
  id INTEGER PRIMARY KEY,
  player_id TEXT NOT NULL REFERENCES players(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('bug', 'idea', 'other')),
  message TEXT NOT NULL CHECK (length(message) BETWEEN 1 AND 1000),
  app_version TEXT NOT NULL CHECK (length(app_version) BETWEEN 1 AND 32),
  platform TEXT NOT NULL CHECK (length(platform) BETWEEN 1 AND 16),
  created_at INTEGER NOT NULL
);

CREATE INDEX feedback_player_id ON feedback (player_id);
