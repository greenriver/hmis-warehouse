--
-- PostgreSQL database dump
--

-- Dumped from database version 11.7
-- Dumped by pg_dump version 12.2

-- Started on 2020-06-10 17:57:54 UTC

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

SET default_tablespace = '';

--
-- Name: access_group_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.access_group_members (
    id integer NOT NULL,
    access_group_id integer,
    user_id integer,
    deleted_at timestamp without time zone
);


--
-- Name: access_group_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.access_group_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_group_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.access_group_members_id_seq OWNED BY public.access_group_members.id;


--
-- Name: access_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.access_groups (
    id integer NOT NULL,
    name character varying,
    user_id integer,
    coc_codes character varying[] DEFAULT '{}'::character varying[],
    deleted_at timestamp without time zone
);


--
-- Name: access_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.access_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.access_groups_id_seq OWNED BY public.access_groups.id;


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
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_logs_id_seq
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
-- Name: agencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agencies (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    expose_publically boolean DEFAULT false NOT NULL
);


--
-- Name: agencies_consent_limits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agencies_consent_limits (
    consent_limit_id bigint NOT NULL,
    agency_id bigint NOT NULL
);


--
-- Name: agencies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agencies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agencies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agencies_id_seq OWNED BY public.agencies.id;


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
-- Name: consent_limits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.consent_limits (
    id bigint NOT NULL,
    name character varying NOT NULL,
    description text,
    color character varying,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: consent_limits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.consent_limits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: consent_limits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.consent_limits_id_seq OWNED BY public.consent_limits.id;


--
-- Name: data_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_sources (
    id integer NOT NULL,
    name character varying,
    file_path character varying,
    last_imported_at timestamp without time zone,
    newest_updated_at date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    source_type character varying
);


--
-- Name: data_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_sources_id_seq OWNED BY public.data_sources.id;


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
-- Name: glacier_archives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.glacier_archives (
    id integer NOT NULL,
    glacier_vault_id integer NOT NULL,
    upload_id text NOT NULL,
    archive_id text,
    checksum text,
    location text,
    status character varying DEFAULT 'initialized'::character varying NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    size_in_bytes bigint,
    upload_started_at timestamp without time zone,
    upload_finished_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    notes text,
    job_id character varying,
    archive_name character varying
);


--
-- Name: glacier_archives_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.glacier_archives_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: glacier_archives_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.glacier_archives_id_seq OWNED BY public.glacier_archives.id;


--
-- Name: glacier_vaults; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.glacier_vaults (
    id integer NOT NULL,
    name character varying NOT NULL,
    vault_created_at timestamp without time zone,
    last_upload_attempt_at timestamp without time zone,
    last_upload_success_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: glacier_vaults_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.glacier_vaults_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: glacier_vaults_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.glacier_vaults_id_seq OWNED BY public.glacier_vaults.id;


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
-- Name: login_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.login_activities (
    id integer NOT NULL,
    scope character varying,
    strategy character varying,
    identity character varying,
    success boolean,
    failure_reason character varying,
    user_id integer,
    user_type character varying,
    context character varying,
    ip character varying,
    user_agent text,
    referrer text,
    city character varying,
    region character varying,
    country character varying,
    created_at timestamp without time zone
);


--
-- Name: login_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.login_activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: login_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.login_activities_id_seq OWNED BY public.login_activities.id;


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
-- Name: old_passwords; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.old_passwords (
    id integer NOT NULL,
    encrypted_password character varying NOT NULL,
    password_archivable_type character varying NOT NULL,
    password_archivable_id integer NOT NULL,
    password_salt character varying,
    created_at timestamp without time zone
);


--
-- Name: old_passwords_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.old_passwords_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: old_passwords_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.old_passwords_id_seq OWNED BY public.old_passwords.id;


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
    delayed_job_id integer,
    file_id integer
);


--
-- Name: report_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.report_results_id_seq
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
    report_results_summary_id integer,
    enabled boolean DEFAULT true NOT NULL
);


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reports_id_seq
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
    can_edit_users boolean DEFAULT false,
    can_view_full_ssn boolean DEFAULT false,
    can_view_full_dob boolean DEFAULT false,
    can_view_imports boolean DEFAULT false,
    can_edit_roles boolean DEFAULT false,
    can_view_censuses boolean DEFAULT false,
    can_view_census_details boolean DEFAULT false,
    can_view_projects boolean DEFAULT false,
    can_view_organizations boolean DEFAULT false,
    can_view_client_window boolean DEFAULT false,
    can_upload_hud_zips boolean DEFAULT false,
    can_view_hiv_status boolean DEFAULT false,
    can_view_dmh_status boolean DEFAULT false,
    can_administer_health boolean DEFAULT false,
    can_edit_client_health boolean DEFAULT false,
    can_view_client_health boolean DEFAULT false,
    health_role boolean DEFAULT false NOT NULL,
    can_edit_project_groups boolean DEFAULT false,
    can_edit_projects boolean DEFAULT false,
    can_edit_organizations boolean DEFAULT false,
    can_edit_data_sources boolean DEFAULT false,
    can_edit_anything_super_user boolean DEFAULT false,
    can_manage_assessments boolean DEFAULT false,
    can_edit_translations boolean DEFAULT false,
    can_manage_config boolean DEFAULT false,
    can_manage_client_files boolean DEFAULT false,
    can_manage_window_client_files boolean DEFAULT false,
    can_edit_dq_grades boolean DEFAULT false,
    can_view_vspdat boolean DEFAULT false,
    can_edit_vspdat boolean DEFAULT false,
    can_create_clients boolean DEFAULT false,
    can_view_client_history_calendar boolean DEFAULT false,
    can_view_aggregate_health boolean DEFAULT false,
    can_assign_users_to_clients boolean DEFAULT false,
    can_view_client_user_assignments boolean DEFAULT false,
    can_export_hmis_data boolean DEFAULT false,
    can_search_window boolean DEFAULT false,
    can_see_own_file_uploads boolean DEFAULT false,
    can_submit_vspdat boolean DEFAULT false,
    can_edit_client_notes boolean DEFAULT false,
    can_edit_window_client_notes boolean DEFAULT false,
    can_confirm_housing_release boolean DEFAULT false,
    can_see_own_window_client_notes boolean DEFAULT false,
    can_track_anomalies boolean DEFAULT false,
    can_view_all_reports boolean DEFAULT false,
    can_assign_reports boolean DEFAULT false,
    can_view_assigned_reports boolean DEFAULT false,
    can_manage_cohorts boolean DEFAULT false,
    can_edit_cohort_clients boolean DEFAULT false,
    can_edit_assigned_cohorts boolean DEFAULT false,
    can_view_assigned_cohorts boolean DEFAULT false,
    can_manage_organization_users boolean DEFAULT false,
    can_add_administrative_event boolean DEFAULT false,
    can_view_project_data_quality_client_details boolean DEFAULT false,
    can_see_clients_in_window_for_assigned_data_sources boolean DEFAULT false,
    can_manage_health_agency boolean DEFAULT false NOT NULL,
    can_approve_patient_assignments boolean DEFAULT false,
    can_manage_claims boolean DEFAULT false,
    can_manage_all_patients boolean DEFAULT false,
    can_manage_patients_for_own_agency boolean DEFAULT false,
    can_manage_care_coordinators boolean DEFAULT false,
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
    can_manage_accountable_care_organizations boolean DEFAULT false,
    can_edit_warehouse_alerts boolean DEFAULT false,
    can_view_member_health_reports boolean DEFAULT false,
    can_upload_deidentified_hud_hmis_files boolean DEFAULT false,
    can_upload_whitelisted_hud_hmis_files boolean DEFAULT false,
    can_upload_dashboard_extras boolean DEFAULT false,
    can_view_all_user_client_assignments boolean DEFAULT false,
    can_audit_users boolean DEFAULT false,
    can_audit_clients boolean DEFAULT false,
    can_export_anonymous_hmis_data boolean DEFAULT false,
    can_view_youth_intake boolean DEFAULT false,
    can_edit_youth_intake boolean DEFAULT false,
    can_view_all_secure_uploads boolean DEFAULT false,
    can_unsubmit_submitted_claims boolean DEFAULT false,
    can_view_assigned_secure_uploads boolean DEFAULT false,
    can_manage_agency boolean DEFAULT false,
    can_manage_all_agencies boolean DEFAULT false,
    can_view_own_agency_youth_intake boolean DEFAULT false,
    can_edit_own_agency_youth_intake boolean DEFAULT false,
    can_view_clients_with_roi_in_own_coc boolean DEFAULT false,
    can_enable_2fa boolean DEFAULT false,
    can_view_ce_assessment boolean DEFAULT false,
    can_edit_ce_assessment boolean DEFAULT false,
    can_submit_ce_assessment boolean DEFAULT false,
    can_edit_help boolean DEFAULT false,
    enforced_2fa boolean DEFAULT false,
    can_view_all_hud_reports boolean DEFAULT false,
    can_view_own_hud_reports boolean DEFAULT false,
    can_edit_access_groups boolean DEFAULT false,
    can_view_confidential_enrollment_details boolean DEFAULT false,
    can_impersonate_users boolean DEFAULT false,
    can_manage_ad_hoc_data_sources boolean DEFAULT false,
    can_view_client_ad_hoc_data_sources boolean DEFAULT false,
    training_required boolean DEFAULT false,
    can_use_strict_search boolean DEFAULT false,
    can_use_separated_consent boolean DEFAULT false,
    can_delete_projects boolean DEFAULT false,
    can_delete_data_sources boolean DEFAULT false,
    can_see_health_emergency boolean DEFAULT false,
    can_edit_health_emergency_screening boolean DEFAULT false,
    can_edit_health_emergency_clinical boolean DEFAULT false,
    can_see_health_emergency_history boolean DEFAULT false,
    can_edit_health_emergency_medical_restriction boolean DEFAULT false,
    can_see_health_emergency_medical_restriction boolean DEFAULT false,
    can_see_health_emergency_screening boolean DEFAULT false,
    can_see_health_emergency_clinical boolean DEFAULT false,
    can_edit_health_emergency_contact_tracing boolean DEFAULT false,
    receives_medical_restriction_notifications boolean DEFAULT false
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
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
-- Name: taggings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.taggings (
    id integer NOT NULL,
    tag_id integer,
    taggable_type character varying,
    taggable_id integer,
    tagger_type character varying,
    tagger_id integer,
    context character varying(128),
    created_at timestamp without time zone
);


--
-- Name: taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.taggings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.taggings_id_seq OWNED BY public.taggings.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id integer NOT NULL,
    name character varying,
    taggings_count integer DEFAULT 0
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


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
            WHEN (COALESCE(pg_stat_all_tables.last_vacuum, '1999-01-01 00:00:00+00'::timestamp with time zone) > COALESCE(pg_stat_all_tables.last_autovacuum, '1999-01-01 00:00:00+00'::timestamp with time zone)) THEN pg_stat_all_tables.last_vacuum
            ELSE COALESCE(pg_stat_all_tables.last_autovacuum, '1999-01-01 00:00:00+00'::timestamp with time zone)
        END AS last_vacuum,
        CASE
            WHEN (COALESCE(pg_stat_all_tables.last_analyze, '1999-01-01 00:00:00+00'::timestamp with time zone) > COALESCE(pg_stat_all_tables.last_autoanalyze, '1999-01-01 00:00:00+00'::timestamp with time zone)) THEN pg_stat_all_tables.last_analyze
            ELSE COALESCE(pg_stat_all_tables.last_autoanalyze, '1999-01-01 00:00:00+00'::timestamp with time zone)
        END AS last_analyze,
    (pg_stat_all_tables.vacuum_count + pg_stat_all_tables.autovacuum_count) AS vacuum_count,
    (pg_stat_all_tables.analyze_count + pg_stat_all_tables.autoanalyze_count) AS analyze_count
   FROM pg_stat_all_tables
  WHERE (pg_stat_all_tables.schemaname <> ALL (ARRAY['pg_toast'::name, 'information_schema'::name, 'pg_catalog'::name]));


--
-- Name: toddstats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.toddstats AS
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
            WHEN (COALESCE(pg_stat_all_tables.last_vacuum, '1999-01-01 00:00:00+00'::timestamp with time zone) > COALESCE(pg_stat_all_tables.last_autovacuum, '1999-01-01 00:00:00+00'::timestamp with time zone)) THEN pg_stat_all_tables.last_vacuum
            ELSE COALESCE(pg_stat_all_tables.last_autovacuum, '1999-01-01 00:00:00+00'::timestamp with time zone)
        END AS last_vacuum,
        CASE
            WHEN (COALESCE(pg_stat_all_tables.last_analyze, '1999-01-01 00:00:00+00'::timestamp with time zone) > COALESCE(pg_stat_all_tables.last_autoanalyze, '1999-01-01 00:00:00+00'::timestamp with time zone)) THEN pg_stat_all_tables.last_analyze
            ELSE COALESCE(pg_stat_all_tables.last_autoanalyze, '1999-01-01 00:00:00+00'::timestamp with time zone)
        END AS last_analyze,
    (pg_stat_all_tables.vacuum_count + pg_stat_all_tables.autovacuum_count) AS vacuum_count,
    (pg_stat_all_tables.analyze_count + pg_stat_all_tables.autoanalyze_count) AS analyze_count
   FROM pg_stat_all_tables
  WHERE (pg_stat_all_tables.schemaname <> ALL (ARRAY['pg_toast'::name, 'information_schema'::name, 'pg_catalog'::name]));


--
-- Name: tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tokens (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    token character varying NOT NULL,
    path character varying NOT NULL,
    expires_at timestamp without time zone
);


--
-- Name: tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tokens_id_seq OWNED BY public.tokens.id;


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
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: user_roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_roles_id_seq
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
    deprecated_agency character varying,
    notify_on_vispdat_completed boolean DEFAULT false,
    notify_on_client_added boolean DEFAULT false,
    notify_on_anomaly_identified boolean DEFAULT false NOT NULL,
    coc_codes character varying[] DEFAULT '{}'::character varying[],
    email_schedule character varying DEFAULT 'immediate'::character varying NOT NULL,
    active boolean DEFAULT true NOT NULL,
    agency_id integer,
    encrypted_otp_secret character varying,
    encrypted_otp_secret_iv character varying,
    encrypted_otp_secret_salt character varying,
    consumed_timestep integer,
    otp_required_for_login boolean DEFAULT false NOT NULL,
    unique_session_id character varying,
    last_activity_at timestamp without time zone,
    expired_at timestamp without time zone,
    confirmed_2fa integer DEFAULT 0 NOT NULL,
    otp_backup_codes character varying[],
    password_changed_at timestamp without time zone,
    training_completed boolean DEFAULT false,
    last_training_completed date
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
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
    request_id character varying,
    object_changes text,
    referenced_user_id integer,
    referenced_entity_name character varying
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
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
-- Name: warehouse_alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_alerts (
    id integer NOT NULL,
    user_id integer,
    html character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: warehouse_alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse_alerts_id_seq OWNED BY public.warehouse_alerts.id;


--
-- Name: access_group_members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_group_members ALTER COLUMN id SET DEFAULT nextval('public.access_group_members_id_seq'::regclass);


--
-- Name: access_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_groups ALTER COLUMN id SET DEFAULT nextval('public.access_groups_id_seq'::regclass);


--
-- Name: activity_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs ALTER COLUMN id SET DEFAULT nextval('public.activity_logs_id_seq'::regclass);


--
-- Name: agencies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agencies ALTER COLUMN id SET DEFAULT nextval('public.agencies_id_seq'::regclass);


--
-- Name: consent_limits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consent_limits ALTER COLUMN id SET DEFAULT nextval('public.consent_limits_id_seq'::regclass);


--
-- Name: data_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sources ALTER COLUMN id SET DEFAULT nextval('public.data_sources_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: glacier_archives id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.glacier_archives ALTER COLUMN id SET DEFAULT nextval('public.glacier_archives_id_seq'::regclass);


--
-- Name: glacier_vaults id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.glacier_vaults ALTER COLUMN id SET DEFAULT nextval('public.glacier_vaults_id_seq'::regclass);


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
-- Name: login_activities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_activities ALTER COLUMN id SET DEFAULT nextval('public.login_activities_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: nicknames id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nicknames ALTER COLUMN id SET DEFAULT nextval('public.nicknames_id_seq'::regclass);


--
-- Name: old_passwords id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.old_passwords ALTER COLUMN id SET DEFAULT nextval('public.old_passwords_id_seq'::regclass);


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
-- Name: taggings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings ALTER COLUMN id SET DEFAULT nextval('public.taggings_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens ALTER COLUMN id SET DEFAULT nextval('public.tokens_id_seq'::regclass);


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
-- Name: warehouse_alerts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_alerts ALTER COLUMN id SET DEFAULT nextval('public.warehouse_alerts_id_seq'::regclass);


--
-- Name: access_group_members access_group_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_group_members
    ADD CONSTRAINT access_group_members_pkey PRIMARY KEY (id);


--
-- Name: access_groups access_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_groups
    ADD CONSTRAINT access_groups_pkey PRIMARY KEY (id);


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: agencies agencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agencies
    ADD CONSTRAINT agencies_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: consent_limits consent_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consent_limits
    ADD CONSTRAINT consent_limits_pkey PRIMARY KEY (id);


--
-- Name: data_sources data_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sources
    ADD CONSTRAINT data_sources_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: glacier_archives glacier_archives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.glacier_archives
    ADD CONSTRAINT glacier_archives_pkey PRIMARY KEY (id);


--
-- Name: glacier_vaults glacier_vaults_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.glacier_vaults
    ADD CONSTRAINT glacier_vaults_pkey PRIMARY KEY (id);


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
-- Name: login_activities login_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_activities
    ADD CONSTRAINT login_activities_pkey PRIMARY KEY (id);


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
-- Name: old_passwords old_passwords_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.old_passwords
    ADD CONSTRAINT old_passwords_pkey PRIMARY KEY (id);


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
-- Name: taggings taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: tokens tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (id);


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
-- Name: warehouse_alerts warehouse_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_alerts
    ADD CONSTRAINT warehouse_alerts_pkey PRIMARY KEY (id);


--
-- Name: created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX created_at_idx ON public.activity_logs USING brin (created_at);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_priority ON public.delayed_jobs USING btree (priority, run_at);


--
-- Name: index_activity_logs_on_controller_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_logs_on_controller_name ON public.activity_logs USING btree (controller_name);


--
-- Name: index_activity_logs_on_created_at_and_item_model_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_logs_on_created_at_and_item_model_and_user_id ON public.activity_logs USING btree (created_at, item_model, user_id);


--
-- Name: index_activity_logs_on_item_model; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_logs_on_item_model ON public.activity_logs USING btree (item_model);


--
-- Name: index_activity_logs_on_item_model_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_logs_on_item_model_and_user_id ON public.activity_logs USING btree (item_model, user_id);


--
-- Name: index_activity_logs_on_item_model_and_user_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_logs_on_item_model_and_user_id_and_created_at ON public.activity_logs USING btree (item_model, user_id, created_at);


--
-- Name: index_activity_logs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_logs_on_user_id ON public.activity_logs USING btree (user_id);


--
-- Name: index_activity_logs_on_user_id_and_item_model_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_activity_logs_on_user_id_and_item_model_and_created_at ON public.activity_logs USING btree (user_id, item_model, created_at);


--
-- Name: index_agencies_consent_limits_on_agency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agencies_consent_limits_on_agency_id ON public.agencies_consent_limits USING btree (agency_id);


--
-- Name: index_agencies_consent_limits_on_consent_limit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_agencies_consent_limits_on_consent_limit_id ON public.agencies_consent_limits USING btree (consent_limit_id);


--
-- Name: index_consent_limits_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_consent_limits_on_name ON public.consent_limits USING btree (name);


--
-- Name: index_glacier_archives_on_glacier_vault_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_glacier_archives_on_glacier_vault_id ON public.glacier_archives USING btree (glacier_vault_id);


--
-- Name: index_glacier_archives_on_upload_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_glacier_archives_on_upload_id ON public.glacier_archives USING btree (upload_id);


--
-- Name: index_glacier_vaults_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_glacier_vaults_on_name ON public.glacier_vaults USING btree (name);


--
-- Name: index_imports_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_imports_on_deleted_at ON public.imports USING btree (deleted_at);


--
-- Name: index_login_activities_on_identity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_login_activities_on_identity ON public.login_activities USING btree (identity);


--
-- Name: index_login_activities_on_ip; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_login_activities_on_ip ON public.login_activities USING btree (ip);


--
-- Name: index_password_archivable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_password_archivable ON public.old_passwords USING btree (password_archivable_type, password_archivable_id);


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
-- Name: index_taggings_on_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_context ON public.taggings USING btree (context);


--
-- Name: index_taggings_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tag_id ON public.taggings USING btree (tag_id);


--
-- Name: index_taggings_on_taggable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable_id ON public.taggings USING btree (taggable_id);


--
-- Name: index_taggings_on_taggable_id_and_taggable_type_and_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable_id_and_taggable_type_and_context ON public.taggings USING btree (taggable_id, taggable_type, context);


--
-- Name: index_taggings_on_taggable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable_type ON public.taggings USING btree (taggable_type);


--
-- Name: index_taggings_on_tagger_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tagger_id ON public.taggings USING btree (tagger_id);


--
-- Name: index_taggings_on_tagger_id_and_tagger_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tagger_id_and_tagger_type ON public.taggings USING btree (tagger_id, tagger_type);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_name ON public.tags USING btree (name);


--
-- Name: index_tokens_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_created_at ON public.tokens USING btree (created_at);


--
-- Name: index_tokens_on_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_expires_at ON public.tokens USING btree (expires_at);


--
-- Name: index_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_token ON public.tokens USING btree (token);


--
-- Name: index_tokens_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_updated_at ON public.tokens USING btree (updated_at);


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
-- Name: taggings_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX taggings_idx ON public.taggings USING btree (tag_id, taggable_id, taggable_type, context, tagger_id, tagger_type);


--
-- Name: taggings_idy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX taggings_idy ON public.taggings USING btree (taggable_id, taggable_type, tagger_id, context);


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
-- Name: glacier_archives fk_rails_6121d2e55f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.glacier_archives
    ADD CONSTRAINT fk_rails_6121d2e55f FOREIGN KEY (glacier_vault_id) REFERENCES public.glacier_vaults(id);


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


-- Completed on 2020-06-10 17:59:02 UTC

--
-- PostgreSQL database dump complete
--

