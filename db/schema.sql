SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: cuisine_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.cuisine_type AS ENUM (
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
    'turkish',
    'lebanese',
    'iranian',
    'israeli',
    'moroccan',
    'egyptian',
    'syrian',
    'iraqi',
    'saudi',
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
    'ethiopian',
    'nigerian',
    'south_african',
    'kenyan',
    'ghanaian',
    'senegalese',
    'tanzanian',
    'other'
);


--
-- Name: meal_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.meal_type AS ENUM (
    'breakfast',
    'lunch',
    'dinner',
    'snack'
);


--
-- Name: unit_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.unit_type AS ENUM (
    'ml',
    'cl',
    'dl',
    'l',
    'g',
    'kg',
    'tsp',
    'tbsp',
    'cup',
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


--
-- Name: unit_type_family; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.unit_type_family AS ENUM (
    'weight',
    'volume',
    'other'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: shopping_list_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shopping_list_items (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    planned_meal_id uuid,
    name text NOT NULL,
    unit public.unit_type,
    unit_family public.unit_type_family,
    quantity numeric,
    meal_date date,
    checked boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: aggregated_shopping_list; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.aggregated_shopping_list AS
 WITH normalized_quantities AS (
         SELECT shopping_list_items.id,
            shopping_list_items.user_id,
            shopping_list_items.name,
            shopping_list_items.unit,
            shopping_list_items.unit_family,
                CASE
                    WHEN (shopping_list_items.unit_family = 'weight'::public.unit_type_family) THEN
                    CASE shopping_list_items.unit
                        WHEN 'kg'::public.unit_type THEN (shopping_list_items.quantity * (1000)::numeric)
                        WHEN 'g'::public.unit_type THEN shopping_list_items.quantity
                        ELSE NULL::numeric
                    END
                    WHEN (shopping_list_items.unit_family = 'volume'::public.unit_type_family) THEN
                    CASE shopping_list_items.unit
                        WHEN 'l'::public.unit_type THEN (shopping_list_items.quantity * (1000)::numeric)
                        WHEN 'dl'::public.unit_type THEN (shopping_list_items.quantity * (100)::numeric)
                        WHEN 'cl'::public.unit_type THEN (shopping_list_items.quantity * (10)::numeric)
                        WHEN 'ml'::public.unit_type THEN shopping_list_items.quantity
                        ELSE NULL::numeric
                    END
                    ELSE shopping_list_items.quantity
                END AS normalized_quantity,
            shopping_list_items.meal_date,
            shopping_list_items.checked
           FROM public.shopping_list_items
          WHERE ((shopping_list_items.meal_date IS NULL) OR (shopping_list_items.meal_date >= CURRENT_DATE))
        ), weight_volume_items AS (
         SELECT array_agg(normalized_quantities.id) AS ids,
            normalized_quantities.user_id,
            normalized_quantities.name,
            normalized_quantities.unit_family,
                CASE
                    WHEN (normalized_quantities.unit_family = 'weight'::public.unit_type_family) THEN
                    CASE
                        WHEN (sum(normalized_quantities.normalized_quantity) >= (1000)::numeric) THEN 'kg'::public.unit_type
                        ELSE 'g'::public.unit_type
                    END
                    WHEN (normalized_quantities.unit_family = 'volume'::public.unit_type_family) THEN
                    CASE
                        WHEN (sum(normalized_quantities.normalized_quantity) >= (1000)::numeric) THEN 'l'::public.unit_type
                        WHEN (sum(normalized_quantities.normalized_quantity) >= (100)::numeric) THEN 'dl'::public.unit_type
                        WHEN (sum(normalized_quantities.normalized_quantity) >= (10)::numeric) THEN 'cl'::public.unit_type
                        ELSE 'ml'::public.unit_type
                    END
                    ELSE NULL::public.unit_type
                END AS unit,
                CASE
                    WHEN (normalized_quantities.unit_family = 'weight'::public.unit_type_family) THEN
                    CASE
                        WHEN (sum(normalized_quantities.normalized_quantity) >= (1000)::numeric) THEN round((sum(normalized_quantities.normalized_quantity) / (1000)::numeric), 2)
                        ELSE sum(normalized_quantities.normalized_quantity)
                    END
                    WHEN (normalized_quantities.unit_family = 'volume'::public.unit_type_family) THEN
                    CASE
                        WHEN (sum(normalized_quantities.normalized_quantity) >= (1000)::numeric) THEN round((sum(normalized_quantities.normalized_quantity) / (1000)::numeric), 2)
                        WHEN (sum(normalized_quantities.normalized_quantity) >= (100)::numeric) THEN round((sum(normalized_quantities.normalized_quantity) / (100)::numeric), 2)
                        WHEN (sum(normalized_quantities.normalized_quantity) >= (10)::numeric) THEN round((sum(normalized_quantities.normalized_quantity) / (10)::numeric), 2)
                        ELSE sum(normalized_quantities.normalized_quantity)
                    END
                    ELSE NULL::numeric
                END AS quantity,
            min(normalized_quantities.meal_date) AS earliest_meal_date,
            bool_and(normalized_quantities.checked) AS checked
           FROM normalized_quantities
          WHERE (normalized_quantities.unit_family = ANY (ARRAY['weight'::public.unit_type_family, 'volume'::public.unit_type_family]))
          GROUP BY normalized_quantities.user_id, normalized_quantities.name, normalized_quantities.unit_family
        ), other_items AS (
         SELECT array_agg(normalized_quantities.id) AS ids,
            normalized_quantities.user_id,
            normalized_quantities.name,
            normalized_quantities.unit_family,
            normalized_quantities.unit,
            sum(normalized_quantities.normalized_quantity) AS quantity,
            min(normalized_quantities.meal_date) AS earliest_meal_date,
            bool_and(normalized_quantities.checked) AS checked
           FROM normalized_quantities
          WHERE ((normalized_quantities.unit_family = 'other'::public.unit_type_family) OR (normalized_quantities.unit_family IS NULL))
          GROUP BY normalized_quantities.user_id, normalized_quantities.name, normalized_quantities.unit_family, normalized_quantities.unit
        )
 SELECT weight_volume_items.ids,
    weight_volume_items.user_id,
    weight_volume_items.name,
    weight_volume_items.unit,
    weight_volume_items.unit_family,
    weight_volume_items.quantity,
    weight_volume_items.earliest_meal_date AS meal_date,
    EXTRACT(isodow FROM weight_volume_items.earliest_meal_date) AS week_day,
    weight_volume_items.checked
   FROM weight_volume_items
UNION ALL
 SELECT other_items.ids,
    other_items.user_id,
    other_items.name,
    other_items.unit,
    other_items.unit_family,
    other_items.quantity,
    other_items.earliest_meal_date AS meal_date,
    EXTRACT(isodow FROM other_items.earliest_meal_date) AS week_day,
    other_items.checked
   FROM other_items
  ORDER BY 3, 4;


--
-- Name: ingredients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ingredients (
    id uuid NOT NULL,
    recipe_id uuid NOT NULL,
    name text NOT NULL,
    quantity numeric(10,2),
    unit public.unit_type,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone
);


--
-- Name: instructions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.instructions (
    id uuid NOT NULL,
    recipe_id uuid NOT NULL,
    step_number integer NOT NULL,
    instruction text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone
);


--
-- Name: planned_meals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.planned_meals (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    recipe_id uuid NOT NULL,
    meal_date date NOT NULL,
    meal_type public.meal_type NOT NULL,
    servings integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    CONSTRAINT planned_meals_servings_check CHECK ((servings > 0))
);


--
-- Name: recipes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recipes (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    title text NOT NULL,
    prep_time integer,
    cook_time integer,
    servings integer NOT NULL,
    source_url text,
    image_url text,
    cuisine_type public.cuisine_type,
    rating integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    CONSTRAINT recipes_rating_check CHECK (((rating >= 1) AND (rating <= 5))),
    CONSTRAINT recipes_servings_check CHECK ((servings > 0))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refresh_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    revoked_at timestamp with time zone,
    replaced_at timestamp with time zone,
    replaced_by uuid
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying(128) NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    email text NOT NULL,
    name text NOT NULL,
    google_id text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    password_hash text
);


--
-- Name: ingredients ingredients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT ingredients_pkey PRIMARY KEY (id);


--
-- Name: instructions instructions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instructions
    ADD CONSTRAINT instructions_pkey PRIMARY KEY (id);


--
-- Name: planned_meals planned_meals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planned_meals
    ADD CONSTRAINT planned_meals_pkey PRIMARY KEY (id);


--
-- Name: recipes recipes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes
    ADD CONSTRAINT recipes_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: shopping_list_items shopping_list_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopping_list_items
    ADD CONSTRAINT shopping_list_items_pkey PRIMARY KEY (id);


--
-- Name: instructions step_number_recipe_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instructions
    ADD CONSTRAINT step_number_recipe_id UNIQUE (step_number, recipe_id);


--
-- Name: planned_meals user_id_meal_type_meal_date; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planned_meals
    ADD CONSTRAINT user_id_meal_type_meal_date UNIQUE (user_id, meal_type, meal_date) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: ingredients ingredients_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ingredients
    ADD CONSTRAINT ingredients_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id) ON DELETE CASCADE;


--
-- Name: instructions instructions_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instructions
    ADD CONSTRAINT instructions_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id) ON DELETE CASCADE;


--
-- Name: planned_meals planned_meals_recipe_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planned_meals
    ADD CONSTRAINT planned_meals_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id) ON DELETE CASCADE;


--
-- Name: planned_meals planned_meals_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.planned_meals
    ADD CONSTRAINT planned_meals_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: recipes recipes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recipes
    ADD CONSTRAINT recipes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: refresh_tokens refresh_tokens_replaced_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_replaced_by_fkey FOREIGN KEY (replaced_by) REFERENCES public.refresh_tokens(id) ON DELETE SET NULL;


--
-- Name: refresh_tokens refresh_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: shopping_list_items shopping_list_items_planned_meal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopping_list_items
    ADD CONSTRAINT shopping_list_items_planned_meal_id_fkey FOREIGN KEY (planned_meal_id) REFERENCES public.planned_meals(id) ON DELETE CASCADE;


--
-- Name: shopping_list_items shopping_list_items_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shopping_list_items
    ADD CONSTRAINT shopping_list_items_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--


--
-- Dbmate schema migrations
--

INSERT INTO public.schema_migrations (version) VALUES
    ('20241020174630'),
    ('20241024184328'),
    ('20241025064421'),
    ('20241027075135'),
    ('20241027142537'),
    ('20241027143255'),
    ('20241031081330'),
    ('20241103140034'),
    ('20241103162845'),
    ('20241106183825'),
    ('20241107075043'),
    ('20241107083217'),
    ('20250105143638');
