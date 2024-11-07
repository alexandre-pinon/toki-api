-- migrate:up
ALTER TABLE
  recipes
ADD
  CONSTRAINT recipes_servings_check CHECK (servings > 0),
ALTER COLUMN
  servings
SET
  NOT NULL;

-- migrate:down
ALTER TABLE
  recipes DROP CONSTRAINT recipes_servings_check,
ALTER COLUMN
  servings DROP NOT NULL;