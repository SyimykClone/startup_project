CREATE TABLE IF NOT EXISTS poi_visits (
  user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  poi_id INT NOT NULL REFERENCES poi(id) ON DELETE CASCADE,
  visited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, poi_id)
);

CREATE INDEX IF NOT EXISTS idx_poi_visits_user_id ON poi_visits(user_id);
CREATE INDEX IF NOT EXISTS idx_poi_visits_poi_id ON poi_visits(poi_id);
