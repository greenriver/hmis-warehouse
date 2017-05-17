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
    patient_id integer,
    appointment_time timestamp without time zone,
    id_in_source character varying
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
    patient_id integer,
    id_in_source character varying
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
    gender character varying
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
    patient_id integer,
    id_in_source character varying
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
-- Name: visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE visits (
    id integer NOT NULL,
    date_of_service date,
    department character varying,
    visit_type character varying,
    provider character varying,
    id_in_source character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    patient_id integer
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

ALTER TABLE ONLY visits ALTER COLUMN id SET DEFAULT nextval('visits_id_seq'::regclass);


--
-- Name: appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


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
-- Name: visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY visits
    ADD CONSTRAINT visits_pkey PRIMARY KEY (id);


--
-- Name: index_appointments_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_appointments_on_patient_id ON appointments USING btree (patient_id);


--
-- Name: index_medications_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_medications_on_patient_id ON medications USING btree (patient_id);


--
-- Name: index_problems_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_problems_on_patient_id ON problems USING btree (patient_id);


--
-- Name: index_visits_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_visits_on_patient_id ON visits USING btree (patient_id);


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

