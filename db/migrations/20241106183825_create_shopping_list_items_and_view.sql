-- migrate:up
CREATE TYPE unit_type_family AS ENUM ('weight', 'volume', 'other');

CREATE TABLE shopping_list_items (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  planned_meal_id UUID REFERENCES planned_meals(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  unit unit_type,
  unit_family unit_type_family,
  quantity DECIMAL,
  meal_date DATE,
  checked BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL
);

CREATE VIEW aggregated_shopping_list AS WITH normalized_quantities AS (
  SELECT
    id,
    user_id,
    name,
    unit,
    unit_family,
    CASE
      WHEN unit_family = 'weight' THEN CASE
        unit
        WHEN 'kg' THEN quantity * 1000
        WHEN 'g' THEN quantity
        ELSE NULL
      END
      WHEN unit_family = 'volume' THEN CASE
        unit
        WHEN 'l' THEN quantity * 1000
        WHEN 'dl' THEN quantity * 100
        WHEN 'cl' THEN quantity * 10
        WHEN 'ml' THEN quantity
        ELSE NULL
      END
      ELSE quantity
    END AS normalized_quantity,
    meal_date,
    checked
  FROM
    shopping_list_items
  WHERE
    meal_date IS NULL
    OR meal_date >= NOW()
),
weight_volume_items AS (
  SELECT
    array_agg(id) as ids,
    user_id,
    name,
    unit_family,
    CASE
      WHEN unit_family = 'weight' THEN CASE
        WHEN SUM(normalized_quantity) >= 1000 THEN 'kg' :: unit_type
        ELSE 'g' :: unit_type
      END
      WHEN unit_family = 'volume' THEN CASE
        WHEN SUM(normalized_quantity) >= 1000 THEN 'l' :: unit_type
        WHEN SUM(normalized_quantity) >= 100 THEN 'dl' :: unit_type
        WHEN SUM(normalized_quantity) >= 10 THEN 'cl' :: unit_type
        ELSE 'ml' :: unit_type
      END
    END as unit,
    CASE
      WHEN unit_family = 'weight' THEN CASE
        WHEN SUM(normalized_quantity) >= 1000 THEN ROUND(SUM(normalized_quantity) / 1000, 2)
        ELSE SUM(normalized_quantity)
      END
      WHEN unit_family = 'volume' THEN CASE
        WHEN SUM(normalized_quantity) >= 1000 THEN ROUND(SUM(normalized_quantity) / 1000, 2)
        WHEN SUM(normalized_quantity) >= 100 THEN ROUND(SUM(normalized_quantity) / 100, 2)
        WHEN SUM(normalized_quantity) >= 10 THEN ROUND(SUM(normalized_quantity) / 10, 2)
        ELSE SUM(normalized_quantity)
      END
    END as quantity,
    MIN(meal_date) as earliest_meal_date,
    bool_and(checked) as checked
  FROM
    normalized_quantities
  WHERE
    unit_family IN ('weight', 'volume')
  GROUP BY
    user_id,
    name,
    unit_family
),
other_items AS (
  SELECT
    array_agg(id) as ids,
    user_id,
    name,
    unit_family,
    unit,
    SUM(normalized_quantity) as quantity,
    MIN(meal_date) as earliest_meal_date,
    bool_and(checked) as checked
  FROM
    normalized_quantities
  WHERE
    unit_family = 'other'
    OR unit_family IS NULL
  GROUP BY
    user_id,
    name,
    unit_family,
    unit
)
SELECT
  ids,
  user_id,
  name,
  unit,
  unit_family,
  quantity,
  earliest_meal_date AS meal_date,
  EXTRACT(
    ISODOW
    FROM
      earliest_meal_date
  ) AS week_day,
  checked
FROM
  weight_volume_items
UNION
ALL
SELECT
  ids,
  user_id,
  name,
  unit,
  unit_family,
  quantity,
  earliest_meal_date AS meal_date,
  EXTRACT(
    ISODOW
    FROM
      earliest_meal_date
  ) AS week_day,
  checked
FROM
  other_items
ORDER BY
  name,
  unit;

-- migrate:down
DROP VIEW aggregated_shopping_list;

DROP TABLE shopping_list_items;

DROP TYPE unit_type_family;