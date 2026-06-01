CREATE TABLE IF NOT EXISTS poi (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  category TEXT
);

CREATE INDEX IF NOT EXISTS idx_poi_category ON poi(category);
