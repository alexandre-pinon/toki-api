-- migrate:up
ALTER TABLE
  planned_meals
ADD
  CONSTRAINT user_id_meal_type_meal_date UNIQUE(user_id, meal_type, meal_date);

-- migrate:down
ALTER TABLE
  planned_meals DROP CONSTRAINT user_id_meal_type_meal_date;