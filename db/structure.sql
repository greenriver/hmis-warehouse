--
-- PostgreSQL database dump
--

-- Dumped from database version 10.4 (Ubuntu 10.4-2.pgdg16.04+1)
-- Dumped by pg_dump version 10.4 (Ubuntu 10.4-2.pgdg16.04+1)

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


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_logs (
    id integer NOT NULL,
    item_model character varying,
    item_id integer,
    title character varying,
    user_id integer NOT NULL,
    controller_name character varying NOT NULL,
    action_name character varying NOT NULL,
    method character varying,
    path character varying,
    ip_address character varying NOT NULL,
    session_hash character varying,
    referrer text,
    params text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_logs_id_seq OWNED BY public.activity_logs.id;


--
-- Name: client_service_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_service_history (
    unduplicated_client_id integer,
    date date,
    first_date_in_program date,
    last_date_in_program date,
    program_group_id character varying,
    program_type integer,
    program_id integer,
    age integer,
    income numeric,
    income_type integer,
    income_source_code integer,
    destination integer,
    head_of_household_id character varying,
    household_id character varying,
    database_id character varying,
    program_name character varying,
    program_tracking_method integer,
    record_type character varying,
    dc_id integer,
    housing_status_at_entry integer,
    housing_status_at_exit integer
);


--
-- Name: clients_unduplicated; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clients_unduplicated (
    id integer NOT NULL,
    client_unique_id character varying NOT NULL,
    unduplicated_client_id integer NOT NULL,
    dc_id integer
);


--
-- Name: clients_unduplicated_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clients_unduplicated_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clients_unduplicated_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clients_unduplicated_id_seq OWNED BY public.clients_unduplicated.id;


--
-- Name: delayed_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.delayed_jobs (
    id integer NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    attempts integer DEFAULT 0 NOT NULL,
    handler text NOT NULL,
    last_error text,
    run_at timestamp without time zone,
    locked_at timestamp without time zone,
    failed_at timestamp without time zone,
    locked_by character varying,
    queue character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.delayed_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delayed_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.delayed_jobs_id_seq OWNED BY public.delayed_jobs.id;


--
-- Name: imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.imports (
    id integer NOT NULL,
    file character varying,
    source character varying,
    percent_complete double precision,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    completed_at timestamp without time zone,
    deleted_at timestamp without time zone,
    unzipped_files json,
    import_errors json
);


--
-- Name: imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.imports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.imports_id_seq OWNED BY public.imports.id;


--
-- Name: index_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.index_stats AS
 WITH table_stats AS (
         SELECT psut.relname,
            psut.n_live_tup,
            ((1.0 * (psut.idx_scan)::numeric) / (GREATEST((1)::bigint, (psut.seq_scan + psut.idx_scan)))::numeric) AS index_use_ratio
           FROM pg_stat_user_tables psut
          ORDER BY psut.n_live_tup DESC
        ), table_io AS (
         SELECT psiut.relname,
            sum(psiut.heap_blks_read) AS table_page_read,
            sum(psiut.heap_blks_hit) AS table_page_hit,
            (sum(psiut.heap_blks_hit) / GREATEST((1)::numeric, (sum(psiut.heap_blks_hit) + sum(psiut.heap_blks_read)))) AS table_hit_ratio
           FROM pg_statio_user_tables psiut
          GROUP BY psiut.relname
          ORDER BY (sum(psiut.heap_blks_read)) DESC
        ), index_io AS (
         SELECT psiui.relname,
            psiui.indexrelname,
            sum(psiui.idx_blks_read) AS idx_page_read,
            sum(psiui.idx_blks_hit) AS idx_page_hit,
            ((1.0 * sum(psiui.idx_blks_hit)) / GREATEST(1.0, (sum(psiui.idx_blks_hit) + sum(psiui.idx_blks_read)))) AS idx_hit_ratio
           FROM pg_statio_user_indexes psiui
          GROUP BY psiui.relname, psiui.indexrelname
          ORDER BY (sum(psiui.idx_blks_read)) DESC
        )
 SELECT ts.relname,
    ts.n_live_tup,
    ts.index_use_ratio,
    ti.table_page_read,
    ti.table_page_hit,
    ti.table_hit_ratio,
    ii.indexrelname,
    ii.idx_page_read,
    ii.idx_page_hit,
    ii.idx_hit_ratio
   FROM ((table_stats ts
     LEFT JOIN table_io ti ON ((ti.relname = ts.relname)))
     LEFT JOIN index_io ii ON ((ii.relname = ts.relname)))
  ORDER BY ti.table_page_read DESC, ii.idx_page_read DESC;


--
-- Name: letsencrypt_plugin_challenges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.letsencrypt_plugin_challenges (
    id integer NOT NULL,
    response text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: letsencrypt_plugin_challenges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.letsencrypt_plugin_challenges_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: letsencrypt_plugin_challenges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.letsencrypt_plugin_challenges_id_seq OWNED BY public.letsencrypt_plugin_challenges.id;


--
-- Name: letsencrypt_plugin_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.letsencrypt_plugin_settings (
    id integer NOT NULL,
    private_key text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: letsencrypt_plugin_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.letsencrypt_plugin_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: letsencrypt_plugin_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.letsencrypt_plugin_settings_id_seq OWNED BY public.letsencrypt_plugin_settings.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id integer NOT NULL,
    user_id integer,
    "from" character varying NOT NULL,
    subject character varying NOT NULL,
    body text NOT NULL,
    html boolean DEFAULT false NOT NULL,
    seen_at timestamp without time zone,
    sent_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: nicknames; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nicknames (
    id integer NOT NULL,
    name character varying,
    nickname_id integer
);


--
-- Name: nicknames_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nicknames_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nicknames_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nicknames_id_seq OWNED BY public.nicknames.id;


--
-- Name: report_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_results (
    id integer NOT NULL,
    report_id integer,
    import_id integer,
    percent_complete double precision,
    results json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    completed_at timestamp without time zone,
    user_id integer,
    original_results json,
    options json,
    job_status character varying,
    validations json,
    support json,
    delayed_job_id integer
);


--
-- Name: report_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.report_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.report_results_id_seq OWNED BY public.report_results.id;


--
-- Name: report_results_summaries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_results_summaries (
    id integer NOT NULL,
    name character varying NOT NULL,
    type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    weight integer DEFAULT 0 NOT NULL
);


--
-- Name: report_results_summaries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.report_results_summaries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_results_summaries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.report_results_summaries_id_seq OWNED BY public.report_results_summaries.id;


--
-- Name: reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reports (
    id integer NOT NULL,
    name character varying NOT NULL,
    type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    weight integer DEFAULT 0 NOT NULL,
    report_results_summary_id integer
);


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reports_id_seq OWNED BY public.reports.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name character varying NOT NULL,
    verb character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    can_view_clients boolean DEFAULT false,
    can_edit_clients boolean DEFAULT false,
    can_view_censuses boolean DEFAULT false,
    can_view_census_details boolean DEFAULT false,
    can_edit_users boolean DEFAULT false,
    can_view_full_ssn boolean DEFAULT false,
    can_view_full_dob boolean DEFAULT false,
    can_view_hiv_status boolean DEFAULT false,
    can_view_dmh_status boolean DEFAULT false,
    can_view_imports boolean DEFAULT false,
    can_edit_roles boolean DEFAULT false,
    can_view_projects boolean DEFAULT false,
    can_edit_projects boolean DEFAULT false,
    can_edit_project_groups boolean DEFAULT false,
    can_view_organizations boolean DEFAULT false,
    can_edit_organizations boolean DEFAULT false,
    can_edit_data_sources boolean DEFAULT false,
    can_search_window boolean DEFAULT false,
    can_view_client_window boolean DEFAULT false,
    can_upload_hud_zips boolean DEFAULT false,
    can_edit_translations boolean DEFAULT false,
    can_manage_assessments boolean DEFAULT false,
    can_edit_anything_super_user boolean DEFAULT false,
    can_manage_client_files boolean DEFAULT false,
    can_manage_window_client_files boolean DEFAULT false,
    can_see_own_file_uploads boolean DEFAULT false,
    can_manage_config boolean DEFAULT false,
    can_edit_dq_grades boolean DEFAULT false,
    can_view_vspdat boolean DEFAULT false,
    can_edit_vspdat boolean DEFAULT false,
    can_submit_vspdat boolean DEFAULT false,
    can_create_clients boolean DEFAULT false,
    can_view_client_history_calendar boolean DEFAULT false,
    can_edit_client_notes boolean DEFAULT false,
    can_edit_window_client_notes boolean DEFAULT false,
    can_see_own_window_client_notes boolean DEFAULT false,
    can_manage_cohorts boolean DEFAULT false,
    can_edit_cohort_clients boolean DEFAULT false,
    can_edit_assigned_cohorts boolean DEFAULT false,
    can_view_assigned_cohorts boolean DEFAULT false,
    can_assign_users_to_clients boolean DEFAULT false,
    can_view_client_user_assignments boolean DEFAULT false,
    can_export_hmis_data boolean DEFAULT false,
    can_confirm_housing_release boolean DEFAULT false,
    can_track_anomalies boolean DEFAULT false,
    can_view_all_reports boolean DEFAULT false,
    can_assign_reports boolean DEFAULT false,
    can_view_assigned_reports boolean DEFAULT false,
    can_view_project_data_quality_client_details boolean DEFAULT false,
    can_manage_organization_users boolean DEFAULT false,
    can_add_administrative_event boolean DEFAULT false,
    can_administer_health boolean DEFAULT false,
    can_edit_client_health boolean DEFAULT false,
    can_view_client_health boolean DEFAULT false,
    can_view_aggregate_health boolean DEFAULT false,
    can_manage_health_agency boolean DEFAULT false,
    can_approve_patient_assignments boolean DEFAULT false,
    can_manage_claims boolean DEFAULT false,
    can_manage_all_patients boolean DEFAULT false,
    can_manage_patients_for_own_agency boolean DEFAULT false,
    can_approve_cha boolean DEFAULT false,
    can_approve_ssm boolean DEFAULT false,
    can_approve_release boolean DEFAULT false,
    can_approve_participation boolean DEFAULT false,
    can_edit_all_patient_items boolean DEFAULT false,
    can_edit_patient_items_for_own_agency boolean DEFAULT false,
    can_create_care_plans_for_own_agency boolean DEFAULT false,
    can_view_all_patients boolean DEFAULT false,
    can_view_patients_for_own_agency boolean DEFAULT false,
    can_add_case_management_notes boolean DEFAULT false,
    health_role boolean DEFAULT false NOT NULL,
    can_manage_care_coordinators boolean DEFAULT false,
    can_see_clients_in_window_for_assigned_data_sources boolean DEFAULT false
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: similarity_metrics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.similarity_metrics (
    id integer NOT NULL,
    type character varying NOT NULL,
    mean double precision DEFAULT 0.0 NOT NULL,
    standard_deviation double precision DEFAULT 0.0 NOT NULL,
    weight double precision DEFAULT 1.0 NOT NULL,
    n integer DEFAULT 0 NOT NULL,
    other_state public.hstore DEFAULT ''::public.hstore NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: similarity_metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.similarity_metrics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: similarity_metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.similarity_metrics_id_seq OWNED BY public.similarity_metrics.id;


--
-- Name: todd_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.todd_stats AS
 SELECT pg_stat_all_tables.relname,
    round((
        CASE
            WHEN ((pg_stat_all_tables.n_live_tup + pg_stat_all_tables.n_dead_tup) = 0) THEN (0)::double precision
            ELSE ((pg_stat_all_tables.n_dead_tup)::double precision / ((pg_stat_all_tables.n_dead_tup + pg_stat_all_tables.n_live_tup))::double precision)
        END * (100.0)::double precision)) AS "Frag %",
    pg_stat_all_tables.n_live_tup AS "Live rows",
    pg_stat_all_tables.n_dead_tup AS "Dead rows",
    pg_stat_all_tables.n_mod_since_analyze AS "Rows modified since analyze",
        CASE
            WHEN (COALESCE(pg_stat_all_tables.last_vacuum, '1999-01-01 00:00:00-05'::timestamp with time zone) > COALESCE(pg_stat_all_tables.last_autovacuum, '1999-01-01 00:00:00-05'::timestamp with time zone)) THEN pg_stat_all_tables.last_vacuum
            ELSE COALESCE(pg_stat_all_tables.last_autovacuum, '1999-01-01 00:00:00-05'::timestamp with time zone)
        END AS last_vacuum,
        CASE
            WHEN (COALESCE(pg_stat_all_tables.last_analyze, '1999-01-01 00:00:00-05'::timestamp with time zone) > COALESCE(pg_stat_all_tables.last_autoanalyze, '1999-01-01 00:00:00-05'::timestamp with time zone)) THEN pg_stat_all_tables.last_analyze
            ELSE COALESCE(pg_stat_all_tables.last_autoanalyze, '1999-01-01 00:00:00-05'::timestamp with time zone)
        END AS last_analyze,
    (pg_stat_all_tables.vacuum_count + pg_stat_all_tables.autovacuum_count) AS vacuum_count,
    (pg_stat_all_tables.analyze_count + pg_stat_all_tables.autoanalyze_count) AS analyze_count
   FROM pg_stat_all_tables
  WHERE (pg_stat_all_tables.schemaname <> ALL (ARRAY['pg_toast'::name, 'information_schema'::name, 'pg_catalog'::name]));


--
-- Name: translation_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.translation_keys (
    id integer NOT NULL,
    key character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: translation_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.translation_keys_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: translation_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.translation_keys_id_seq OWNED BY public.translation_keys.id;


--
-- Name: translation_texts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.translation_texts (
    id integer NOT NULL,
    text text,
    locale character varying,
    translation_key_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: translation_texts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.translation_texts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: translation_texts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.translation_texts_id_seq OWNED BY public.translation_texts.id;


--
-- Name: unique_names; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.unique_names (
    id integer NOT NULL,
    name character varying,
    double_metaphone character varying
);


--
-- Name: unique_names_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.unique_names_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: unique_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.unique_names_id_seq OWNED BY public.unique_names.id;


--
-- Name: uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.uploads (
    id integer NOT NULL,
    data_source_id integer,
    file character varying NOT NULL,
    percent_complete double precision,
    unzipped_path character varying,
    unzipped_files json,
    summary json,
    import_errors json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    deleted_at timestamp without time zone,
    user_id integer
);


--
-- Name: uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.uploads_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.uploads_id_seq OWNED BY public.uploads.id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    id integer NOT NULL,
    role_id integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_roles_id_seq OWNED BY public.user_roles.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id integer NOT NULL,
    last_name character varying NOT NULL,
    email character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    invitation_token character varying,
    invitation_created_at timestamp without time zone,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    first_name character varying,
    invitation_sent_at timestamp without time zone,
    invitation_accepted_at timestamp without time zone,
    invitation_limit integer,
    invited_by_id integer,
    invited_by_type character varying,
    invitations_count integer DEFAULT 0,
    receive_file_upload_notifications boolean DEFAULT false,
    phone character varying,
    agency character varying,
    notify_on_vispdat_completed boolean DEFAULT false,
    notify_on_client_added boolean DEFAULT false,
    notify_on_anomaly_identified boolean DEFAULT false NOT NULL,
    coc_codes character varying[] DEFAULT '{}'::character varying[],
    email_schedule character varying DEFAULT 'immediate'::character varying NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
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

CREATE SEQUENCE public.versions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: activity_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs ALTER COLUMN id SET DEFAULT nextval('public.activity_logs_id_seq'::regclass);


--
-- Name: clients_unduplicated id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients_unduplicated ALTER COLUMN id SET DEFAULT nextval('public.clients_unduplicated_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: imports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imports ALTER COLUMN id SET DEFAULT nextval('public.imports_id_seq'::regclass);


--
-- Name: letsencrypt_plugin_challenges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letsencrypt_plugin_challenges ALTER COLUMN id SET DEFAULT nextval('public.letsencrypt_plugin_challenges_id_seq'::regclass);


--
-- Name: letsencrypt_plugin_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letsencrypt_plugin_settings ALTER COLUMN id SET DEFAULT nextval('public.letsencrypt_plugin_settings_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: nicknames id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nicknames ALTER COLUMN id SET DEFAULT nextval('public.nicknames_id_seq'::regclass);


--
-- Name: report_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_results ALTER COLUMN id SET DEFAULT nextval('public.report_results_id_seq'::regclass);


--
-- Name: report_results_summaries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_results_summaries ALTER COLUMN id SET DEFAULT nextval('public.report_results_summaries_id_seq'::regclass);


--
-- Name: reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports ALTER COLUMN id SET DEFAULT nextval('public.reports_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: similarity_metrics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.similarity_metrics ALTER COLUMN id SET DEFAULT nextval('public.similarity_metrics_id_seq'::regclass);


--
-- Name: translation_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translation_keys ALTER COLUMN id SET DEFAULT nextval('public.translation_keys_id_seq'::regclass);


--
-- Name: translation_texts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translation_texts ALTER COLUMN id SET DEFAULT nextval('public.translation_texts_id_seq'::regclass);


--
-- Name: unique_names id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unique_names ALTER COLUMN id SET DEFAULT nextval('public.unique_names_id_seq'::regclass);


--
-- Name: uploads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uploads ALTER COLUMN id SET DEFAULT nextval('public.uploads_id_seq'::regclass);


--
-- Name: user_roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles ALTER COLUMN id SET DEFAULT nextval('public.user_roles_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: clients_unduplicated clients_unduplicated_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients_unduplicated
    ADD CONSTRAINT clients_unduplicated_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: imports imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imports
    ADD CONSTRAINT imports_pkey PRIMARY KEY (id);


--
-- Name: letsencrypt_plugin_challenges letsencrypt_plugin_challenges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letsencrypt_plugin_challenges
    ADD CONSTRAINT letsencrypt_plugin_challenges_pkey PRIMARY KEY (id);


--
-- Name: letsencrypt_plugin_settings letsencrypt_plugin_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.letsencrypt_plugin_settings
    ADD CONSTRAINT letsencrypt_plugin_settings_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: nicknames nicknames_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nicknames
    ADD CONSTRAINT nicknames_pkey PRIMARY KEY (id);


--
-- Name: report_results report_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_results
    ADD CONSTRAINT report_results_pkey PRIMARY KEY (id);


--
-- Name: report_results_summaries report_results_summaries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_results_summaries
    ADD CONSTRAINT report_results_summaries_pkey PRIMARY KEY (id);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: similarity_metrics similarity_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.similarity_metrics
    ADD CONSTRAINT similarity_metrics_pkey PRIMARY KEY (id);


--
-- Name: translation_keys translation_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translation_keys
    ADD CONSTRAINT translation_keys_pkey PRIMARY KEY (id);


--
-- Name: translation_texts translation_texts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.translation_texts
    ADD CONSTRAINT translation_texts_pkey PRIMARY KEY (id);


--
-- Name: unique_names unique_names_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unique_names
    ADD CONSTRAINT unique_names_pkey PRIMARY KEY (id);


--
-- Name: uploads uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uploads
    ADD CONSTRAINT uploads_pkey PRIMARY KEY (id);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_priority ON public.delayed_jobs USING btree (priority, run_at);


--
-- Name: index_activity_logs_on_controller_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_logs_on_controller_name ON public.activity_logs USING btree (controller_name);


--
-- Name: index_activity_logs_on_item_model; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_logs_on_item_model ON public.activity_logs USING btree (item_model);


--
-- Name: index_activity_logs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_logs_on_user_id ON public.activity_logs USING btree (user_id);


--
-- Name: index_imports_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_deleted_at ON public.imports USING btree (deleted_at);


--
-- Name: index_report_results_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_results_on_deleted_at ON public.report_results USING btree (deleted_at);


--
-- Name: index_report_results_on_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_results_on_report_id ON public.report_results USING btree (report_id);


--
-- Name: index_reports_on_report_results_summary_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_report_results_summary_id ON public.reports USING btree (report_results_summary_id);


--
-- Name: index_roles_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_name ON public.roles USING btree (name);


--
-- Name: index_similarity_metrics_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_similarity_metrics_on_type ON public.similarity_metrics USING btree (type);


--
-- Name: index_translation_keys_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_translation_keys_on_key ON public.translation_keys USING btree (key);


--
-- Name: index_translation_texts_on_translation_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_translation_texts_on_translation_key_id ON public.translation_texts USING btree (translation_key_id);


--
-- Name: index_uploads_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_uploads_on_deleted_at ON public.uploads USING btree (deleted_at);


--
-- Name: index_user_roles_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_roles_on_role_id ON public.user_roles USING btree (role_id);


--
-- Name: index_user_roles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_roles_on_user_id ON public.user_roles USING btree (user_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_deleted_at ON public.users USING btree (deleted_at);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_invitation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_invitation_token ON public.users USING btree (invitation_token);


--
-- Name: index_users_on_invitations_count; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invitations_count ON public.users USING btree (invitations_count);


--
-- Name: index_users_on_invited_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_invited_by_id ON public.users USING btree (invited_by_id);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON public.users USING btree (unlock_token);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: unduplicated_clients_unduplicated_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX unduplicated_clients_unduplicated_client_id ON public.clients_unduplicated USING btree (unduplicated_client_id);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- Name: user_roles fk_rails_318345354e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT fk_rails_318345354e FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_roles fk_rails_3369e0d5fc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT fk_rails_3369e0d5fc FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: reports fk_rails_b231202c9b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_rails_b231202c9b FOREIGN KEY (report_results_summary_id) REFERENCES public.report_results_summaries(id);


--
-- Name: report_results fk_rails_cd0d43bf48; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_results
    ADD CONSTRAINT fk_rails_cd0d43bf48 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES ('20160615125048');

INSERT INTO schema_migrations (version) VALUES ('20160616140826');

INSERT INTO schema_migrations (version) VALUES ('20160628182622');

INSERT INTO schema_migrations (version) VALUES ('20160701172807');

INSERT INTO schema_migrations (version) VALUES ('20160705145733');

INSERT INTO schema_migrations (version) VALUES ('20160708134220');

INSERT INTO schema_migrations (version) VALUES ('20160708140847');

INSERT INTO schema_migrations (version) VALUES ('20160708172039');

INSERT INTO schema_migrations (version) VALUES ('20160708174624');

INSERT INTO schema_migrations (version) VALUES ('20160708180500');

INSERT INTO schema_migrations (version) VALUES ('20160711124428');

INSERT INTO schema_migrations (version) VALUES ('20160711132731');

INSERT INTO schema_migrations (version) VALUES ('20160711143807');

INSERT INTO schema_migrations (version) VALUES ('20160711144914');

INSERT INTO schema_migrations (version) VALUES ('20160722162801');

INSERT INTO schema_migrations (version) VALUES ('20160725151439');

INSERT INTO schema_migrations (version) VALUES ('20160726210214');

INSERT INTO schema_migrations (version) VALUES ('20160829142445');

INSERT INTO schema_migrations (version) VALUES ('20160829155417');

INSERT INTO schema_migrations (version) VALUES ('20160906154014');

INSERT INTO schema_migrations (version) VALUES ('20160907123023');

INSERT INTO schema_migrations (version) VALUES ('20160907185535');

INSERT INTO schema_migrations (version) VALUES ('20160921165937');

INSERT INTO schema_migrations (version) VALUES ('20161005204310');

INSERT INTO schema_migrations (version) VALUES ('20161006160330');

INSERT INTO schema_migrations (version) VALUES ('20161012152230');

INSERT INTO schema_migrations (version) VALUES ('20161012161240');

INSERT INTO schema_migrations (version) VALUES ('20161103123424');

INSERT INTO schema_migrations (version) VALUES ('20161107160154');

INSERT INTO schema_migrations (version) VALUES ('20161111151851');

INSERT INTO schema_migrations (version) VALUES ('20161111181757');

INSERT INTO schema_migrations (version) VALUES ('20161111205317');

INSERT INTO schema_migrations (version) VALUES ('20161119003439');

INSERT INTO schema_migrations (version) VALUES ('20161213140009');

INSERT INTO schema_migrations (version) VALUES ('20161214144658');

INSERT INTO schema_migrations (version) VALUES ('20161215163027');

INSERT INTO schema_migrations (version) VALUES ('20161216003217');

INSERT INTO schema_migrations (version) VALUES ('20161219184752');

INSERT INTO schema_migrations (version) VALUES ('20170505132237');

INSERT INTO schema_migrations (version) VALUES ('20170517200539');

INSERT INTO schema_migrations (version) VALUES ('20170619210146');

INSERT INTO schema_migrations (version) VALUES ('20170619235354');

INSERT INTO schema_migrations (version) VALUES ('20170627154145');

INSERT INTO schema_migrations (version) VALUES ('20170627182531');

INSERT INTO schema_migrations (version) VALUES ('20170703125950');

INSERT INTO schema_migrations (version) VALUES ('20170705123919');

INSERT INTO schema_migrations (version) VALUES ('20170721143408');

INSERT INTO schema_migrations (version) VALUES ('20170721143409');

INSERT INTO schema_migrations (version) VALUES ('20170726141503');

INSERT INTO schema_migrations (version) VALUES ('20170731202132');

INSERT INTO schema_migrations (version) VALUES ('20170801194526');

INSERT INTO schema_migrations (version) VALUES ('20170815161947');

INSERT INTO schema_migrations (version) VALUES ('20170830180506');

INSERT INTO schema_migrations (version) VALUES ('20170830223244');

INSERT INTO schema_migrations (version) VALUES ('20170901153110');

INSERT INTO schema_migrations (version) VALUES ('20170922130841');

INSERT INTO schema_migrations (version) VALUES ('20170922183847');

INSERT INTO schema_migrations (version) VALUES ('20170927131448');

INSERT INTO schema_migrations (version) VALUES ('20170928194909');

INSERT INTO schema_migrations (version) VALUES ('20171004172953');

INSERT INTO schema_migrations (version) VALUES ('20171023174425');

INSERT INTO schema_migrations (version) VALUES ('20171024183915');

INSERT INTO schema_migrations (version) VALUES ('20171025122843');

INSERT INTO schema_migrations (version) VALUES ('20171026201120');

INSERT INTO schema_migrations (version) VALUES ('20171026203139');

INSERT INTO schema_migrations (version) VALUES ('20171027124054');

INSERT INTO schema_migrations (version) VALUES ('20171027192753');

INSERT INTO schema_migrations (version) VALUES ('20171102123227');

INSERT INTO schema_migrations (version) VALUES ('20171108145620');

INSERT INTO schema_migrations (version) VALUES ('20171108184341');

INSERT INTO schema_migrations (version) VALUES ('20171115185203');

INSERT INTO schema_migrations (version) VALUES ('20171121011445');

INSERT INTO schema_migrations (version) VALUES ('20171204133242');

INSERT INTO schema_migrations (version) VALUES ('20171204164243');

INSERT INTO schema_migrations (version) VALUES ('20180203234329');

INSERT INTO schema_migrations (version) VALUES ('20180211172808');

INSERT INTO schema_migrations (version) VALUES ('20180226145540');

INSERT INTO schema_migrations (version) VALUES ('20180301214751');

INSERT INTO schema_migrations (version) VALUES ('20180403182327');

INSERT INTO schema_migrations (version) VALUES ('20180410152130');

INSERT INTO schema_migrations (version) VALUES ('20180413221626');

INSERT INTO schema_migrations (version) VALUES ('20180416160927');

INSERT INTO schema_migrations (version) VALUES ('20180416213522');

INSERT INTO schema_migrations (version) VALUES ('20180419165841');

INSERT INTO schema_migrations (version) VALUES ('20180504140026');

INSERT INTO schema_migrations (version) VALUES ('20180511004923');

INSERT INTO schema_migrations (version) VALUES ('20180521172429');

INSERT INTO schema_migrations (version) VALUES ('20180521190108');

INSERT INTO schema_migrations (version) VALUES ('20180530200118');

INSERT INTO schema_migrations (version) VALUES ('20180601185917');

INSERT INTO schema_migrations (version) VALUES ('20180612175806');

INSERT INTO schema_migrations (version) VALUES ('20180613133940');

