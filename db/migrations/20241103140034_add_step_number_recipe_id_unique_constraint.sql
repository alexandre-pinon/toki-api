-- migrate:up
ALTER TABLE
  instructions
ADD
  CONSTRAINT step_number_recipe_id UNIQUE (step_number, recipe_id);

-- migrate:down
ALTER TABLE
  instructions DROP CONSTRAINT step_number_recipe_id;