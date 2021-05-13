SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: monthly_reports_insert_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.monthly_reports_insert_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
        IF  ( NEW.type = 'AdultOnlyHouseholdsSubPop::Reporting::MonthlyReports::AdultOnlyHouseholds' ) THEN
              INSERT INTO warehouse_partitioned_monthly_reports_adult_only_households VALUES (NEW.*);
           ELSIF  ( NEW.type = 'AdultsWithChildrenSubPop::Reporting::MonthlyReports::AdultsWithChildren' ) THEN
              INSERT INTO warehouse_partitioned_monthly_reports_adults_with_children VALUES (NEW.*);
           ELSIF  ( NEW.type = 'ChildOnlyHouseholdsSubPop::Reporting::MonthlyReports::ChildOnlyHouseholds' ) THEN
              INSERT INTO warehouse_partitioned_monthly_reports_child_only_households VALUES (NEW.*);
           ELSIF  ( NEW.type = 'ClientsSubPop::Reporting::MonthlyReports::Clients' ) THEN
              INSERT INTO warehouse_partitioned_monthly_reports_clients VALUES (NEW.*);
           ELSIF  ( NEW.type = 'NonVeteransSubPop::Reporting::MonthlyReports::NonVeterans' ) THEN
              INSERT INTO warehouse_partitioned_monthly_reports_non_veterans VALUES (NEW.*);
           ELSIF  ( NEW.type = 'VeteransSubPop::Reporting::MonthlyReports::Veterans' ) THEN
              INSERT INTO warehouse_partitioned_monthly_reports_veterans VALUES (NEW.*);
          
        ELSE
          INSERT INTO warehouse_partitioned_monthly_reports_unknown VALUES (NEW.*);
          END IF;
          RETURN NULL;
      END;
      $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: warehouse_data_quality_report_enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_data_quality_report_enrollments (
    id integer NOT NULL,
    report_id integer,
    client_id integer,
    project_id integer,
    project_name character varying,
    project_type integer,
    enrollment_id integer,
    enrolled boolean,
    active boolean,
    entered boolean,
    exited boolean,
    adult boolean,
    head_of_household boolean,
    household_id character varying,
    household_type character varying,
    age integer,
    dob date,
    entry_date date,
    exit_date date,
    days_to_add_entry_date integer,
    days_to_add_exit_date integer,
    dob_after_entry_date boolean,
    most_recent_service_within_range date,
    service_within_last_30_days boolean,
    service_after_exit boolean,
    days_of_service integer,
    destination_id integer,
    name_complete boolean DEFAULT false,
    name_missing boolean DEFAULT false,
    name_refused boolean DEFAULT false,
    name_not_collected boolean DEFAULT false,
    name_partial boolean DEFAULT false,
    ssn_complete boolean DEFAULT false,
    ssn_missing boolean DEFAULT false,
    ssn_refused boolean DEFAULT false,
    ssn_not_collected boolean DEFAULT false,
    ssn_partial boolean DEFAULT false,
    gender_complete boolean DEFAULT false,
    gender_missing boolean DEFAULT false,
    gender_refused boolean DEFAULT false,
    gender_not_collected boolean DEFAULT false,
    gender_partial boolean DEFAULT false,
    dob_complete boolean DEFAULT false,
    dob_missing boolean DEFAULT false,
    dob_refused boolean DEFAULT false,
    dob_not_collected boolean DEFAULT false,
    dob_partial boolean DEFAULT false,
    veteran_complete boolean DEFAULT false,
    veteran_missing boolean DEFAULT false,
    veteran_refused boolean DEFAULT false,
    veteran_not_collected boolean DEFAULT false,
    veteran_partial boolean DEFAULT false,
    ethnicity_complete boolean DEFAULT false,
    ethnicity_missing boolean DEFAULT false,
    ethnicity_refused boolean DEFAULT false,
    ethnicity_not_collected boolean DEFAULT false,
    ethnicity_partial boolean DEFAULT false,
    race_complete boolean DEFAULT false,
    race_missing boolean DEFAULT false,
    race_refused boolean DEFAULT false,
    race_not_collected boolean DEFAULT false,
    race_partial boolean DEFAULT false,
    disabling_condition_complete boolean DEFAULT false,
    disabling_condition_missing boolean DEFAULT false,
    disabling_condition_refused boolean DEFAULT false,
    disabling_condition_not_collected boolean DEFAULT false,
    disabling_condition_partial boolean DEFAULT false,
    destination_complete boolean DEFAULT false,
    destination_missing boolean DEFAULT false,
    destination_refused boolean DEFAULT false,
    destination_not_collected boolean DEFAULT false,
    destination_partial boolean DEFAULT false,
    prior_living_situation_complete boolean DEFAULT false,
    prior_living_situation_missing boolean DEFAULT false,
    prior_living_situation_refused boolean DEFAULT false,
    prior_living_situation_not_collected boolean DEFAULT false,
    prior_living_situation_partial boolean DEFAULT false,
    income_at_entry_complete boolean DEFAULT false,
    income_at_entry_missing boolean DEFAULT false,
    income_at_entry_refused boolean DEFAULT false,
    income_at_entry_not_collected boolean DEFAULT false,
    income_at_entry_partial boolean DEFAULT false,
    income_at_exit_complete boolean DEFAULT false,
    income_at_exit_missing boolean DEFAULT false,
    income_at_exit_refused boolean DEFAULT false,
    income_at_exit_not_collected boolean DEFAULT false,
    income_at_exit_partial boolean DEFAULT false,
    income_at_annual_assessment_complete boolean DEFAULT false,
    income_at_annual_assessment_missing boolean DEFAULT false,
    income_at_annual_assessment_refused boolean DEFAULT false,
    income_at_annual_assessment_not_collected boolean DEFAULT false,
    income_at_annual_assessment_partial boolean DEFAULT false,
    should_have_income_annual_assessment boolean DEFAULT false,
    include_in_income_change_calculation boolean,
    income_at_entry_earned integer,
    income_at_entry_non_employment_cash integer,
    income_at_entry_overall integer,
    income_at_entry_response integer,
    income_at_annual_earned integer,
    income_at_annual_non_employment_cash integer,
    income_at_annual_overall integer,
    income_at_later_date_response integer,
    income_at_later_date_earned integer,
    income_at_later_date_non_employment_cash integer,
    income_at_later_date_overall integer,
    income_at_annual_response integer,
    days_to_move_in_date integer,
    days_ph_before_move_in_date integer,
    incorrect_household_type boolean DEFAULT false,
    first_name character varying,
    last_name character varying,
    ssn character varying,
    gender integer,
    name_data_quality integer,
    ssn_data_quality integer,
    dob_data_quality integer,
    veteran_status integer,
    disabling_condition integer,
    prior_living_situation integer,
    ethnicity integer,
    race character varying,
    enrollment_date_created date,
    exit_date_created date,
    move_in_date date,
    calculated_at timestamp without time zone NOT NULL,
    income_at_penultimate_earned integer,
    income_at_penultimate_non_employment_cash integer,
    income_at_penultimate_overall integer,
    income_at_penultimate_response integer
);


--
-- Name: warehouse_data_quality_report_enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_data_quality_report_enrollments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_data_quality_report_enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse_data_quality_report_enrollments_id_seq OWNED BY public.warehouse_data_quality_report_enrollments.id;


--
-- Name: warehouse_data_quality_report_project_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_data_quality_report_project_groups (
    id integer NOT NULL,
    report_id integer,
    unit_inventory integer,
    bed_inventory integer,
    average_nightly_clients integer,
    average_nightly_households integer,
    average_bed_utilization integer,
    average_unit_utilization integer,
    nightly_client_census jsonb,
    nightly_household_census jsonb,
    calculated_at timestamp without time zone NOT NULL
);


--
-- Name: warehouse_data_quality_report_project_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_data_quality_report_project_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_data_quality_report_project_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse_data_quality_report_project_groups_id_seq OWNED BY public.warehouse_data_quality_report_project_groups.id;


--
-- Name: warehouse_data_quality_report_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_data_quality_report_projects (
    id integer NOT NULL,
    report_id integer,
    project_id integer,
    project_name character varying,
    organization_name character varying,
    project_type integer,
    operating_start_date date,
    coc_code character varying,
    funder character varying,
    inventory_information_dates character varying,
    geocode character varying,
    geography_type character varying,
    unit_inventory integer,
    bed_inventory integer,
    housing_type integer,
    average_nightly_clients integer,
    average_nightly_households integer,
    average_bed_utilization integer,
    average_unit_utilization integer,
    nightly_client_census jsonb,
    nightly_household_census jsonb,
    calculated_at timestamp without time zone NOT NULL
);


--
-- Name: warehouse_data_quality_report_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_data_quality_report_projects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_data_quality_report_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse_data_quality_report_projects_id_seq OWNED BY public.warehouse_data_quality_report_projects.id;


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
    individual_adult boolean DEFAULT false,
    age_at_search_start integer,
    age_at_search_end integer,
    age_at_housed_date integer,
    age_at_housing_exit integer,
    head_of_household boolean DEFAULT false,
    hmis_project_id character varying
);


--
-- Name: warehouse_houseds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_houseds_id_seq
    AS integer
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
-- Name: warehouse_monthly_client_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_monthly_client_ids (
    id integer NOT NULL,
    report_type character varying NOT NULL,
    client_id integer NOT NULL
);


--
-- Name: warehouse_monthly_client_ids_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_monthly_client_ids_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_monthly_client_ids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse_monthly_client_ids_id_seq OWNED BY public.warehouse_monthly_client_ids.id;


--
-- Name: warehouse_partitioned_monthly_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_partitioned_monthly_reports (
    id bigint NOT NULL,
    month integer NOT NULL,
    year integer NOT NULL,
    type character varying,
    client_id integer NOT NULL,
    age_at_entry integer,
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
    enrollment_id integer,
    mid_month date
);


--
-- Name: warehouse_partitioned_monthly_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_partitioned_monthly_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_partitioned_monthly_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse_partitioned_monthly_reports_id_seq OWNED BY public.warehouse_partitioned_monthly_reports.id;


--
-- Name: warehouse_partitioned_monthly_reports_adult_only_households; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_partitioned_monthly_reports_adult_only_households (
    id bigint DEFAULT nextval('public.warehouse_partitioned_monthly_reports_id_seq'::regclass) NOT NULL,
    month integer NOT NULL,
    year integer NOT NULL,
    type character varying,
    client_id integer NOT NULL,
    age_at_entry integer,
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
    enrollment_id integer,
    mid_month date
);


--
-- Name: warehouse_partitioned_monthly_reports_adults_with_children; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_partitioned_monthly_reports_adults_with_children (
    id bigint DEFAULT nextval('public.warehouse_partitioned_monthly_reports_id_seq'::regclass) NOT NULL,
    month integer NOT NULL,
    year integer NOT NULL,
    type character varying,
    client_id integer NOT NULL,
    age_at_entry integer,
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
    enrollment_id integer,
    mid_month date
);


--
-- Name: warehouse_partitioned_monthly_reports_child_only_households; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_partitioned_monthly_reports_child_only_households (
    id bigint DEFAULT nextval('public.warehouse_partitioned_monthly_reports_id_seq'::regclass) NOT NULL,
    month integer NOT NULL,
    year integer NOT NULL,
    type character varying,
    client_id integer NOT NULL,
    age_at_entry integer,
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
    enrollment_id integer,
    mid_month date
);


--
-- Name: warehouse_partitioned_monthly_reports_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_partitioned_monthly_reports_clients (
    id bigint DEFAULT nextval('public.warehouse_partitioned_monthly_reports_id_seq'::regclass) NOT NULL,
    month integer NOT NULL,
    year integer NOT NULL,
    type character varying,
    client_id integer NOT NULL,
    age_at_entry integer,
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
    enrollment_id integer,
    mid_month date
);


--
-- Name: warehouse_partitioned_monthly_reports_non_veterans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_partitioned_monthly_reports_non_veterans (
    id bigint DEFAULT nextval('public.warehouse_partitioned_monthly_reports_id_seq'::regclass) NOT NULL,
    month integer NOT NULL,
    year integer NOT NULL,
    type character varying,
    client_id integer NOT NULL,
    age_at_entry integer,
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
    enrollment_id integer,
    mid_month date
);


--
-- Name: warehouse_partitioned_monthly_reports_unknown; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_partitioned_monthly_reports_unknown (
    id bigint DEFAULT nextval('public.warehouse_partitioned_monthly_reports_id_seq'::regclass) NOT NULL,
    month integer NOT NULL,
    year integer NOT NULL,
    type character varying,
    client_id integer NOT NULL,
    age_at_entry integer,
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
    enrollment_id integer,
    mid_month date
);


--
-- Name: warehouse_partitioned_monthly_reports_veterans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_partitioned_monthly_reports_veterans (
    id bigint DEFAULT nextval('public.warehouse_partitioned_monthly_reports_id_seq'::regclass) NOT NULL,
    month integer NOT NULL,
    year integer NOT NULL,
    type character varying,
    client_id integer NOT NULL,
    age_at_entry integer,
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
    enrollment_id integer,
    mid_month date
);


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
    length_of_stay integer,
    gender integer,
    race character varying,
    ethnicity character varying,
    hmis_project_id character varying
);


--
-- Name: warehouse_returns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_returns_id_seq
    AS integer
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
-- Name: warehouse_data_quality_report_enrollments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_data_quality_report_enrollments ALTER COLUMN id SET DEFAULT nextval('public.warehouse_data_quality_report_enrollments_id_seq'::regclass);


--
-- Name: warehouse_data_quality_report_project_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_data_quality_report_project_groups ALTER COLUMN id SET DEFAULT nextval('public.warehouse_data_quality_report_project_groups_id_seq'::regclass);


--
-- Name: warehouse_data_quality_report_projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_data_quality_report_projects ALTER COLUMN id SET DEFAULT nextval('public.warehouse_data_quality_report_projects_id_seq'::regclass);


--
-- Name: warehouse_houseds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_houseds ALTER COLUMN id SET DEFAULT nextval('public.warehouse_houseds_id_seq'::regclass);


--
-- Name: warehouse_monthly_client_ids id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_monthly_client_ids ALTER COLUMN id SET DEFAULT nextval('public.warehouse_monthly_client_ids_id_seq'::regclass);


--
-- Name: warehouse_partitioned_monthly_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_partitioned_monthly_reports ALTER COLUMN id SET DEFAULT nextval('public.warehouse_partitioned_monthly_reports_id_seq'::regclass);


--
-- Name: warehouse_returns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_returns ALTER COLUMN id SET DEFAULT nextval('public.warehouse_returns_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: warehouse_data_quality_report_enrollments warehouse_data_quality_report_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_data_quality_report_enrollments
    ADD CONSTRAINT warehouse_data_quality_report_enrollments_pkey PRIMARY KEY (id);


--
-- Name: warehouse_data_quality_report_project_groups warehouse_data_quality_report_project_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_data_quality_report_project_groups
    ADD CONSTRAINT warehouse_data_quality_report_project_groups_pkey PRIMARY KEY (id);


--
-- Name: warehouse_data_quality_report_projects warehouse_data_quality_report_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_data_quality_report_projects
    ADD CONSTRAINT warehouse_data_quality_report_projects_pkey PRIMARY KEY (id);


--
-- Name: warehouse_houseds warehouse_houseds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_houseds
    ADD CONSTRAINT warehouse_houseds_pkey PRIMARY KEY (id);


--
-- Name: warehouse_monthly_client_ids warehouse_monthly_client_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_monthly_client_ids
    ADD CONSTRAINT warehouse_monthly_client_ids_pkey PRIMARY KEY (id);


--
-- Name: warehouse_partitioned_monthly_reports warehouse_partitioned_monthly_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_partitioned_monthly_reports
    ADD CONSTRAINT warehouse_partitioned_monthly_reports_pkey PRIMARY KEY (id);


--
-- Name: warehouse_returns warehouse_returns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_returns
    ADD CONSTRAINT warehouse_returns_pkey PRIMARY KEY (id);


--
-- Name: housed_p_type_h_dates_p_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX housed_p_type_h_dates_p_id ON public.warehouse_houseds USING btree (project_type, housed_date, housing_exit, project_id);


--
-- Name: housed_p_type_s_dates_h_dates_p_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX housed_p_type_s_dates_h_dates_p_id ON public.warehouse_houseds USING btree (project_type, search_start, search_end, service_project, housed_date, housing_exit, project_id);


--
-- Name: housed_p_type_s_dates_p_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX housed_p_type_s_dates_p_id ON public.warehouse_houseds USING btree (project_type, search_start, search_end, service_project, project_id);


--
-- Name: index_month_adult_only_households_act_enter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_adult_only_households_act_enter ON public.warehouse_partitioned_monthly_reports_adult_only_households USING btree (mid_month, active, entered);


--
-- Name: index_month_adult_only_households_act_exit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_adult_only_households_act_exit ON public.warehouse_partitioned_monthly_reports_adult_only_households USING btree (mid_month, active, exited);


--
-- Name: index_month_adult_only_households_age; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_adult_only_households_age ON public.warehouse_partitioned_monthly_reports_adult_only_households USING btree (age_at_entry);


--
-- Name: index_month_adult_only_households_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_adult_only_households_client_id ON public.warehouse_partitioned_monthly_reports_adult_only_households USING btree (client_id);


--
-- Name: index_month_adult_only_households_dest_enr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_adult_only_households_dest_enr ON public.warehouse_partitioned_monthly_reports_adult_only_households USING btree (mid_month, destination_id, enrolled);


--
-- Name: index_month_adult_only_households_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_month_adult_only_households_id ON public.warehouse_partitioned_monthly_reports_adult_only_households USING btree (id);


--
-- Name: index_month_adult_only_households_p_type_hoh; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_adult_only_households_p_type_hoh ON public.warehouse_partitioned_monthly_reports_adult_only_households USING btree (mid_month, project_type, head_of_household);


--
-- Name: index_month_adults_with_children_act_enter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_adults_with_children_act_enter ON public.warehouse_partitioned_monthly_reports_adults_with_children USING btree (mid_month, active, entered);


--
-- Name: index_month_adults_with_children_act_exit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_adults_with_children_act_exit ON public.warehouse_partitioned_monthly_reports_adults_with_children USING btree (mid_month, active, exited);


--
-- Name: index_month_adults_with_children_age; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_adults_with_children_age ON public.warehouse_partitioned_monthly_reports_adults_with_children USING btree (age_at_entry);


--
-- Name: index_month_adults_with_children_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_adults_with_children_client_id ON public.warehouse_partitioned_monthly_reports_adults_with_children USING btree (client_id);


--
-- Name: index_month_adults_with_children_dest_enr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_adults_with_children_dest_enr ON public.warehouse_partitioned_monthly_reports_adults_with_children USING btree (mid_month, destination_id, enrolled);


--
-- Name: index_month_adults_with_children_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_month_adults_with_children_id ON public.warehouse_partitioned_monthly_reports_adults_with_children USING btree (id);


--
-- Name: index_month_adults_with_children_p_type_hoh; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_adults_with_children_p_type_hoh ON public.warehouse_partitioned_monthly_reports_adults_with_children USING btree (mid_month, project_type, head_of_household);


--
-- Name: index_month_child_only_households_act_enter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_child_only_households_act_enter ON public.warehouse_partitioned_monthly_reports_child_only_households USING btree (mid_month, active, entered);


--
-- Name: index_month_child_only_households_act_exit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_child_only_households_act_exit ON public.warehouse_partitioned_monthly_reports_child_only_households USING btree (mid_month, active, exited);


--
-- Name: index_month_child_only_households_age; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_child_only_households_age ON public.warehouse_partitioned_monthly_reports_child_only_households USING btree (age_at_entry);


--
-- Name: index_month_child_only_households_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_child_only_households_client_id ON public.warehouse_partitioned_monthly_reports_child_only_households USING btree (client_id);


--
-- Name: index_month_child_only_households_dest_enr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_child_only_households_dest_enr ON public.warehouse_partitioned_monthly_reports_child_only_households USING btree (mid_month, destination_id, enrolled);


--
-- Name: index_month_child_only_households_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_month_child_only_households_id ON public.warehouse_partitioned_monthly_reports_child_only_households USING btree (id);


--
-- Name: index_month_child_only_households_p_type_hoh; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_child_only_households_p_type_hoh ON public.warehouse_partitioned_monthly_reports_child_only_households USING btree (mid_month, project_type, head_of_household);


--
-- Name: index_month_clients_act_enter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_clients_act_enter ON public.warehouse_partitioned_monthly_reports_clients USING btree (mid_month, active, entered);


--
-- Name: index_month_clients_act_exit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_clients_act_exit ON public.warehouse_partitioned_monthly_reports_clients USING btree (mid_month, active, exited);


--
-- Name: index_month_clients_age; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_clients_age ON public.warehouse_partitioned_monthly_reports_clients USING btree (age_at_entry);


--
-- Name: index_month_clients_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_clients_client_id ON public.warehouse_partitioned_monthly_reports_clients USING btree (client_id);


--
-- Name: index_month_clients_dest_enr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_clients_dest_enr ON public.warehouse_partitioned_monthly_reports_clients USING btree (mid_month, destination_id, enrolled);


--
-- Name: index_month_clients_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_month_clients_id ON public.warehouse_partitioned_monthly_reports_clients USING btree (id);


--
-- Name: index_month_clients_p_type_hoh; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_clients_p_type_hoh ON public.warehouse_partitioned_monthly_reports_clients USING btree (mid_month, project_type, head_of_household);


--
-- Name: index_month_non_veterans_act_enter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_non_veterans_act_enter ON public.warehouse_partitioned_monthly_reports_non_veterans USING btree (mid_month, active, entered);


--
-- Name: index_month_non_veterans_act_exit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_non_veterans_act_exit ON public.warehouse_partitioned_monthly_reports_non_veterans USING btree (mid_month, active, exited);


--
-- Name: index_month_non_veterans_age; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_non_veterans_age ON public.warehouse_partitioned_monthly_reports_non_veterans USING btree (age_at_entry);


--
-- Name: index_month_non_veterans_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_non_veterans_client_id ON public.warehouse_partitioned_monthly_reports_non_veterans USING btree (client_id);


--
-- Name: index_month_non_veterans_dest_enr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_non_veterans_dest_enr ON public.warehouse_partitioned_monthly_reports_non_veterans USING btree (mid_month, destination_id, enrolled);


--
-- Name: index_month_non_veterans_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_month_non_veterans_id ON public.warehouse_partitioned_monthly_reports_non_veterans USING btree (id);


--
-- Name: index_month_non_veterans_p_type_hoh; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_non_veterans_p_type_hoh ON public.warehouse_partitioned_monthly_reports_non_veterans USING btree (mid_month, project_type, head_of_household);


--
-- Name: index_month_remainder_act_enter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_remainder_act_enter ON public.warehouse_partitioned_monthly_reports_unknown USING btree (mid_month, active, entered);


--
-- Name: index_month_remainder_act_exit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_remainder_act_exit ON public.warehouse_partitioned_monthly_reports_unknown USING btree (mid_month, active, exited);


--
-- Name: index_month_remainder_age; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_remainder_age ON public.warehouse_partitioned_monthly_reports_unknown USING btree (age_at_entry);


--
-- Name: index_month_remainder_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_remainder_client_id ON public.warehouse_partitioned_monthly_reports_unknown USING btree (client_id);


--
-- Name: index_month_remainder_dest_enr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_remainder_dest_enr ON public.warehouse_partitioned_monthly_reports_unknown USING btree (mid_month, destination_id, enrolled);


--
-- Name: index_month_remainder_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_month_remainder_id ON public.warehouse_partitioned_monthly_reports_unknown USING btree (id);


--
-- Name: index_month_remainder_p_type_hoh; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_remainder_p_type_hoh ON public.warehouse_partitioned_monthly_reports_unknown USING btree (mid_month, project_type, head_of_household);


--
-- Name: index_month_veterans_act_enter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_veterans_act_enter ON public.warehouse_partitioned_monthly_reports_veterans USING btree (mid_month, active, entered);


--
-- Name: index_month_veterans_act_exit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_veterans_act_exit ON public.warehouse_partitioned_monthly_reports_veterans USING btree (mid_month, active, exited);


--
-- Name: index_month_veterans_age; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_veterans_age ON public.warehouse_partitioned_monthly_reports_veterans USING btree (age_at_entry);


--
-- Name: index_month_veterans_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_veterans_client_id ON public.warehouse_partitioned_monthly_reports_veterans USING btree (client_id);


--
-- Name: index_month_veterans_dest_enr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_veterans_dest_enr ON public.warehouse_partitioned_monthly_reports_veterans USING btree (mid_month, destination_id, enrolled);


--
-- Name: index_month_veterans_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_month_veterans_id ON public.warehouse_partitioned_monthly_reports_veterans USING btree (id);


--
-- Name: index_month_veterans_p_type_hoh; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_month_veterans_p_type_hoh ON public.warehouse_partitioned_monthly_reports_veterans USING btree (mid_month, project_type, head_of_household);


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
-- Name: index_warehouse_monthly_client_ids_on_report_type_and_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_monthly_client_ids_on_report_type_and_client_id ON public.warehouse_monthly_client_ids USING btree (report_type, client_id);


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
-- Name: pdq_p_groups_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pdq_p_groups_report_id ON public.warehouse_data_quality_report_project_groups USING btree (report_id);


--
-- Name: pdq_projects_report_id_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pdq_projects_report_id_project_id ON public.warehouse_data_quality_report_projects USING btree (report_id, project_id);


--
-- Name: pdq_rep_act_ent_head_enr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pdq_rep_act_ent_head_enr ON public.warehouse_data_quality_report_enrollments USING btree (report_id, active, entered, head_of_household, enrolled);


--
-- Name: pdq_rep_act_ext_head_enr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pdq_rep_act_ext_head_enr ON public.warehouse_data_quality_report_enrollments USING btree (report_id, active, exited, head_of_household, enrolled);


--
-- Name: warehouse_partitioned_monthly_reports monthly_reports_insert_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER monthly_reports_insert_trigger BEFORE INSERT ON public.warehouse_partitioned_monthly_reports FOR EACH ROW EXECUTE FUNCTION public.monthly_reports_insert_trigger();


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20180911173239'),
('20180911173649'),
('20180917194028'),
('20180925175825'),
('20181204193329'),
('20190503193707'),
('20190509162439'),
('20190518010835'),
('20190604195547'),
('20190614190744'),
('20190621150718'),
('20190621154429'),
('20190702005535'),
('20190708152330'),
('20190802160019'),
('20200106195304'),
('20200121131232'),
('20200121131602'),
('20200123193204'),
('20200128142909'),
('20200417173338'),
('20200620192228'),
('20210405180920');


