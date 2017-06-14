--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.6
-- Dumped by pg_dump version 9.5.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
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


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: appointments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE appointments (
    id integer NOT NULL,
    appointment_type character varying,
    notes text,
    doctor character varying,
    department character varying,
    sa character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    appointment_time timestamp without time zone,
    id_in_source character varying,
    patient_id character varying
);


--
-- Name: appointments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE appointments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appointments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE appointments_id_seq OWNED BY appointments.id;


--
-- Name: careplans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE careplans (
    id integer NOT NULL,
    patient_id integer,
    user_id integer,
    sdh_enroll_date date,
    first_meeting_with_case_manager_date date,
    self_sufficiency_baseline_due_date date,
    self_sufficiency_final_due_date date,
    self_sufficiency_baseline_completed_date date,
    self_sufficiency_final_completed_date date,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: careplans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE careplans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: careplans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE careplans_id_seq OWNED BY careplans.id;


--
-- Name: health_goals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE health_goals (
    id integer NOT NULL,
    careplan_id integer,
    user_id integer,
    type character varying,
    number integer,
    name character varying,
    associated_dx character varying,
    barriers character varying,
    provider_plan character varying,
    case_manager_plan character varying,
    rn_plan character varying,
    bh_plan character varying,
    other_plan character varying,
    confidence integer,
    az_housing character varying,
    az_income character varying,
    az_non_cash_benefits character varying,
    az_disabilities character varying,
    az_food character varying,
    az_employment character varying,
    az_training character varying,
    az_transportation character varying,
    az_life_skills character varying,
    az_health_care_coverage character varying,
    az_physical_health character varying,
    az_mental_health character varying,
    az_substance_use character varying,
    az_criminal_justice character varying,
    az_legal character varying,
    az_safety character varying,
    az_risk character varying,
    az_family character varying,
    az_community character varying,
    az_time_management character varying,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    goal_details text
);


--
-- Name: health_goals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE health_goals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_goals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE health_goals_id_seq OWNED BY health_goals.id;


--
-- Name: medications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE medications (
    id integer NOT NULL,
    start_date date,
    ordered_date date,
    name text,
    instructions text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    id_in_source character varying,
    patient_id character varying
);


--
-- Name: medications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE medications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: medications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE medications_id_seq OWNED BY medications.id;


--
-- Name: patients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE patients (
    id integer NOT NULL,
    id_in_source character varying NOT NULL,
    first_name character varying,
    middle_name character varying,
    last_name character varying,
    aliases text,
    birthdate date,
    allergy_list text,
    primary_care_physician character varying,
    transgender character varying,
    race character varying,
    ethnicity character varying,
    veteran_status character varying,
    ssn character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    client_id integer,
    gender character varying,
    consent_revoked timestamp without time zone
);


--
-- Name: patients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE patients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: patients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE patients_id_seq OWNED BY patients.id;


--
-- Name: problems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE problems (
    id integer NOT NULL,
    onset_date date,
    last_assessed date,
    name text,
    comment text,
    icd10_list character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    id_in_source character varying,
    patient_id character varying
);


--
-- Name: problems_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE problems_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: problems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE problems_id_seq OWNED BY problems.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: team_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE team_members (
    id integer NOT NULL,
    type character varying NOT NULL,
    team_id integer NOT NULL,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    email character varying NOT NULL,
    organization character varying,
    title character varying,
    last_contact date,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer
);


--
-- Name: team_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE team_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE team_members_id_seq OWNED BY team_members.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE teams (
    id integer NOT NULL,
    patient_id integer,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE teams_id_seq OWNED BY teams.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE versions (
    id integer NOT NULL,
    item_type character varying NOT NULL,
    item_id integer NOT NULL,
    event character varying NOT NULL,
    whodunnit character varying,
    object text,
    created_at timestamp without time zone,
    user_id integer,
    session_id character varying,
    request_id character varying
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE versions_id_seq OWNED BY versions.id;


--
-- Name: visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE visits (
    id integer NOT NULL,
    department character varying,
    visit_type character varying,
    provider character varying,
    id_in_source character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    patient_id character varying,
    date_of_service timestamp without time zone
);


--
-- Name: visits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE visits_id_seq OWNED BY visits.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY appointments ALTER COLUMN id SET DEFAULT nextval('appointments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY careplans ALTER COLUMN id SET DEFAULT nextval('careplans_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY health_goals ALTER COLUMN id SET DEFAULT nextval('health_goals_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY medications ALTER COLUMN id SET DEFAULT nextval('medications_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY patients ALTER COLUMN id SET DEFAULT nextval('patients_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY problems ALTER COLUMN id SET DEFAULT nextval('problems_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY team_members ALTER COLUMN id SET DEFAULT nextval('team_members_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams ALTER COLUMN id SET DEFAULT nextval('teams_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions ALTER COLUMN id SET DEFAULT nextval('versions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY visits ALTER COLUMN id SET DEFAULT nextval('visits_id_seq'::regclass);


--
-- Name: appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- Name: careplans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY careplans
    ADD CONSTRAINT careplans_pkey PRIMARY KEY (id);


--
-- Name: health_goals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY health_goals
    ADD CONSTRAINT health_goals_pkey PRIMARY KEY (id);


--
-- Name: medications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY medications
    ADD CONSTRAINT medications_pkey PRIMARY KEY (id);


--
-- Name: patients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (id);


--
-- Name: problems_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY problems
    ADD CONSTRAINT problems_pkey PRIMARY KEY (id);


--
-- Name: team_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY team_members
    ADD CONSTRAINT team_members_pkey PRIMARY KEY (id);


--
-- Name: teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visits
    ADD CONSTRAINT visits_pkey PRIMARY KEY (id);


--
-- Name: index_careplans_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_careplans_on_patient_id ON careplans USING btree (patient_id);


--
-- Name: index_careplans_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_careplans_on_user_id ON careplans USING btree (user_id);


--
-- Name: index_health_goals_on_careplan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_goals_on_careplan_id ON health_goals USING btree (careplan_id);


--
-- Name: index_health_goals_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_goals_on_user_id ON health_goals USING btree (user_id);


--
-- Name: index_team_members_on_team_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_members_on_team_id ON team_members USING btree (team_id);


--
-- Name: index_team_members_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_members_on_type ON team_members USING btree (type);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON versions USING btree (item_type, item_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20170512154839');

INSERT INTO schema_migrations (version) VALUES ('20170512172314');

INSERT INTO schema_migrations (version) VALUES ('20170512172320');

INSERT INTO schema_migrations (version) VALUES ('20170512172327');

INSERT INTO schema_migrations (version) VALUES ('20170512172333');

INSERT INTO schema_migrations (version) VALUES ('20170516185409');

INSERT INTO schema_migrations (version) VALUES ('20170516190400');

INSERT INTO schema_migrations (version) VALUES ('20170516195310');

INSERT INTO schema_migrations (version) VALUES ('20170517125108');

INSERT INTO schema_migrations (version) VALUES ('20170523175542');

INSERT INTO schema_migrations (version) VALUES ('20170523181235');

INSERT INTO schema_migrations (version) VALUES ('20170529174730');

INSERT INTO schema_migrations (version) VALUES ('20170529182835');

INSERT INTO schema_migrations (version) VALUES ('20170529203247');

INSERT INTO schema_migrations (version) VALUES ('20170601172245');

INSERT INTO schema_migrations (version) VALUES ('20170602013551');

INSERT INTO schema_migrations (version) VALUES ('20170606143003');

INSERT INTO schema_migrations (version) VALUES ('20170613150635');

