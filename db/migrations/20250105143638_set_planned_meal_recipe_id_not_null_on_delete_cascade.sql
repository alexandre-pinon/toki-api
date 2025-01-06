-- migrate:up
ALTER TABLE
  planned_meals
ALTER COLUMN
  recipe_id
SET
  NOT NULL;

ALTER TABLE
  planned_meals DROP CONSTRAINT planned_meals_recipe_id_fkey;

ALTER TABLE
  planned_meals
ADD
  CONSTRAINT planned_meals_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE CASCADE;

-- migrate:down
ALTER TABLE
  planned_meals
ALTER COLUMN
  recipe_id DROP NOT NULL;

ALTER TABLE
  planned_meals DROP CONSTRAINT planned_meals_recipe_id_fkey;

ALTER TABLE
  planned_meals
ADD
  CONSTRAINT planned_meals_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES recipes(id) ON DELETE
SET
  NULL;