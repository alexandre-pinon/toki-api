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
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


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


SET default_tablespace = '';

SET default_table_access_method = heap;

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
    recipe_id uuid,
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
    servings integer,
    source_url text,
    image_url text,
    cuisine_type public.cuisine_type,
    rating integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    CONSTRAINT recipes_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
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
-- Name: instructions step_number_recipe_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.instructions
    ADD CONSTRAINT step_number_recipe_id UNIQUE (step_number, recipe_id);


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
    ADD CONSTRAINT planned_meals_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.recipes(id) ON DELETE SET NULL;


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
    ('20241103162845');
