-- migrate:up
CREATE TYPE meal_type AS ENUM ('breakfast', 'lunch', 'dinner', 'snack');

CREATE TABLE planned_meals (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipe_id UUID REFERENCES recipes(id) ON DELETE
  SET
    NULL,
    meal_date DATE NOT NULL,
    meal_type meal_type NOT NULL,
    servings INTEGER NOT NULL CHECK (servings > 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- migrate:down
DROP TABLE IF EXISTS planned_meals;

DROP TYPE IF EXISTS meal_type;