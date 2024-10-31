-- migrate:up
CREATE TYPE cuisine_type AS ENUM (
  -- Asian Cuisines
  'chinese',
  'japanese',
  'korean',
  'vietnamese',
  'thai',
  'indian',
  'indonesian',
  'malaysian',
  'filipino',
  'singaporean',
  'taiwanese',
  'tibetan',
  'nepalese',
  -- European Cuisines
  'italian',
  'french',
  'spanish',
  'greek',
  'german',
  'british',
  'irish',
  'portuguese',
  'hungarian',
  'polish',
  'russian',
  'swedish',
  'norwegian',
  'danish',
  'dutch',
  'belgian',
  'swiss',
  'austrian',
  -- Middle Eastern Cuisines
  'turkish',
  'lebanese',
  'iranian',
  'israeli',
  'moroccan',
  'egyptian',
  'syrian',
  'iraqi',
  'saudi',
  -- American Cuisines
  'american',
  'mexican',
  'brazilian',
  'peruvian',
  'argentinian',
  'colombian',
  'venezuelan',
  'caribbean',
  'cuban',
  'cajun',
  'creole',
  'canadian',
  -- African Cuisines
  'ethiopian',
  'nigerian',
  'south_african',
  'kenyan',
  'ghanaian',
  'senegalese',
  'tanzanian',
  'other'
);

CREATE TYPE unit_type AS ENUM (
  -- Metric Volume (base: milliliters)
  'ml',
  'cl',
  'dl',
  'l',
  -- Metric Weight (base: grams)
  'g',
  'kg',
  -- Universal Cooking Measures
  'tsp',
  'tbsp',
  'cup',
  -- Universal Count/Other
  'piece',
  'pinch',
  'bunch',
  'clove',
  'can',
  'package',
  'slice',
  'to_taste',
  'unit'
);

CREATE TABLE recipes (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id),
  title TEXT NOT NULL,
  prep_time INTEGER,
  cook_time INTEGER,
  servings INTEGER,
  source_url TEXT,
  image_url TEXT,
  cuisine_type cuisine_type,
  rating INTEGER CHECK (
    rating BETWEEN 1
    AND 5
  ),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE TABLE ingredients (
  id UUID PRIMARY KEY,
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  quantity DECIMAL(10, 2),
  unit unit_type,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

CREATE TABLE instructions (
  id UUID PRIMARY KEY,
  recipe_id UUID NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
  step_number INTEGER NOT NULL,
  instruction TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ
);

-- migrate:down
DROP TABLE instructions;

DROP TABLE ingredients;

DROP TABLE recipes;

DROP TYPE unit_type;

DROP TYPE cuisine_type;