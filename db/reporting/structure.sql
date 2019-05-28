--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.15
-- Dumped by pg_dump version 10.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: warehouse_houseds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_houseds (
    id integer NOT NULL,
    search_start date,
    search_end date,
    housed_date date,
    housing_exit date,
    project_type integer,
    destination integer,
    service_project character varying,
    residential_project character varying,
    client_id integer NOT NULL,
    source character varying,
    dob date,
    race character varying,
    ethnicity integer,
    gender integer,
    veteran_status integer,
    month_year date,
    ph_destination character varying,
    project_id integer,
    presented_as_individual boolean DEFAULT false,
    children_only boolean DEFAULT false,
    individual_adult boolean DEFAULT false
);


--
-- Name: warehouse_houseds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_houseds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_houseds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse_houseds_id_seq OWNED BY public.warehouse_houseds.id;


--
-- Name: warehouse_monthly_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_monthly_reports (
    id integer NOT NULL,
    month integer NOT NULL,
    year integer NOT NULL,
    type character varying,
    client_id integer NOT NULL,
    head_of_household integer DEFAULT 0 NOT NULL,
    household_id character varying,
    project_id integer NOT NULL,
    organization_id integer NOT NULL,
    destination_id integer,
    first_enrollment boolean DEFAULT false NOT NULL,
    enrolled boolean DEFAULT false NOT NULL,
    active boolean DEFAULT false NOT NULL,
    entered boolean DEFAULT false NOT NULL,
    exited boolean DEFAULT false NOT NULL,
    project_type integer NOT NULL,
    entry_date date,
    exit_date date,
    days_since_last_exit integer,
    prior_exit_project_type integer,
    prior_exit_destination_id integer,
    calculated_at timestamp without time zone NOT NULL,
    enrollment_id integer NOT NULL
);


--
-- Name: warehouse_monthly_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_monthly_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_monthly_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse_monthly_reports_id_seq OWNED BY public.warehouse_monthly_reports.id;


--
-- Name: warehouse_returns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_returns (
    id integer NOT NULL,
    service_history_enrollment_id integer NOT NULL,
    record_type character varying NOT NULL,
    age integer,
    service_type integer,
    client_id integer NOT NULL,
    project_type integer,
    first_date_in_program date NOT NULL,
    last_date_in_program date,
    project_id integer,
    destination integer,
    project_name character varying,
    organization_id integer,
    unaccompanied_youth boolean,
    parenting_youth boolean,
    start_date date,
    end_date date,
    length_of_stay integer
);


--
-- Name: warehouse_returns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_returns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_returns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse_returns_id_seq OWNED BY public.warehouse_returns.id;


--
-- Name: warehouse_houseds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_houseds ALTER COLUMN id SET DEFAULT nextval('public.warehouse_houseds_id_seq'::regclass);


--
-- Name: warehouse_monthly_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_monthly_reports ALTER COLUMN id SET DEFAULT nextval('public.warehouse_monthly_reports_id_seq'::regclass);


--
-- Name: warehouse_returns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_returns ALTER COLUMN id SET DEFAULT nextval('public.warehouse_returns_id_seq'::regclass);


--
-- Name: warehouse_houseds warehouse_houseds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_houseds
    ADD CONSTRAINT warehouse_houseds_pkey PRIMARY KEY (id);


--
-- Name: warehouse_monthly_reports warehouse_monthly_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_monthly_reports
    ADD CONSTRAINT warehouse_monthly_reports_pkey PRIMARY KEY (id);


--
-- Name: warehouse_returns warehouse_returns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_returns
    ADD CONSTRAINT warehouse_returns_pkey PRIMARY KEY (id);


--
-- Name: index_warehouse_houseds_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_houseds_on_client_id ON public.warehouse_houseds USING btree (client_id);


--
-- Name: index_warehouse_houseds_on_housed_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_houseds_on_housed_date ON public.warehouse_houseds USING btree (housed_date);


--
-- Name: index_warehouse_houseds_on_housing_exit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_houseds_on_housing_exit ON public.warehouse_houseds USING btree (housing_exit);


--
-- Name: index_warehouse_houseds_on_search_end; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_houseds_on_search_end ON public.warehouse_houseds USING btree (search_end);


--
-- Name: index_warehouse_houseds_on_search_start; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_houseds_on_search_start ON public.warehouse_houseds USING btree (search_start);


--
-- Name: index_warehouse_monthly_reports_on_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_monthly_reports_on_active ON public.warehouse_monthly_reports USING btree (active);


--
-- Name: index_warehouse_monthly_reports_on_enrolled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_monthly_reports_on_enrolled ON public.warehouse_monthly_reports USING btree (enrolled);


--
-- Name: index_warehouse_monthly_reports_on_entered; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_monthly_reports_on_entered ON public.warehouse_monthly_reports USING btree (entered);


--
-- Name: index_warehouse_monthly_reports_on_exited; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_monthly_reports_on_exited ON public.warehouse_monthly_reports USING btree (exited);


--
-- Name: index_warehouse_monthly_reports_on_head_of_household; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_monthly_reports_on_head_of_household ON public.warehouse_monthly_reports USING btree (head_of_household);


--
-- Name: index_warehouse_monthly_reports_on_household_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_monthly_reports_on_household_id ON public.warehouse_monthly_reports USING btree (household_id);


--
-- Name: index_warehouse_monthly_reports_on_month; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_monthly_reports_on_month ON public.warehouse_monthly_reports USING btree (month);


--
-- Name: index_warehouse_monthly_reports_on_organization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_monthly_reports_on_organization_id ON public.warehouse_monthly_reports USING btree (organization_id);


--
-- Name: index_warehouse_monthly_reports_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_monthly_reports_on_project_id ON public.warehouse_monthly_reports USING btree (project_id);


--
-- Name: index_warehouse_monthly_reports_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_monthly_reports_on_type ON public.warehouse_monthly_reports USING btree (type);


--
-- Name: index_warehouse_monthly_reports_on_year; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_monthly_reports_on_year ON public.warehouse_monthly_reports USING btree (year);


--
-- Name: index_warehouse_returns_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_returns_on_client_id ON public.warehouse_returns USING btree (client_id);


--
-- Name: index_warehouse_returns_on_first_date_in_program; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_returns_on_first_date_in_program ON public.warehouse_returns USING btree (first_date_in_program);


--
-- Name: index_warehouse_returns_on_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_returns_on_project_type ON public.warehouse_returns USING btree (project_type);


--
-- Name: index_warehouse_returns_on_record_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_returns_on_record_type ON public.warehouse_returns USING btree (record_type);


--
-- Name: index_warehouse_returns_on_service_history_enrollment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_returns_on_service_history_enrollment_id ON public.warehouse_returns USING btree (service_history_enrollment_id);


--
-- Name: index_warehouse_returns_on_service_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_returns_on_service_type ON public.warehouse_returns USING btree (service_type);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20180911173239');

INSERT INTO schema_migrations (version) VALUES ('20180911173649');

INSERT INTO schema_migrations (version) VALUES ('20180917194028');

INSERT INTO schema_migrations (version) VALUES ('20180925175825');

INSERT INTO schema_migrations (version) VALUES ('20181204193329');

INSERT INTO schema_migrations (version) VALUES ('20190503193707');

INSERT INTO schema_migrations (version) VALUES ('20190509162439');

