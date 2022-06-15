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

SET default_table_access_method = heap;

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
    AS integer
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
    deleted_at timestamp without time zone,
    system jsonb DEFAULT '[]'::jsonb,
    must_exist boolean DEFAULT false NOT NULL
);


--
-- Name: access_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.access_groups_id_seq
    AS integer
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
-- Name: account_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_requests (
    id bigint NOT NULL,
    email character varying NOT NULL,
    first_name character varying,
    last_name character varying,
    phone character varying,
    status character varying NOT NULL,
    details text,
    accepted_at timestamp without time zone,
    accepted_by integer,
    rejection_reason character varying,
    rejected_at timestamp without time zone,
    rejected_by integer,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: account_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_requests_id_seq OWNED BY public.account_requests.id;


--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    name character varying NOT NULL,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    key character varying NOT NULL,
    filename character varying NOT NULL,
    content_type character varying,
    metadata text,
    service_name character varying NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


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
-- Name: cas_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cas_reports (
    id integer NOT NULL,
    client_id integer NOT NULL,
    match_id integer NOT NULL,
    decision_id integer NOT NULL,
    decision_order integer NOT NULL,
    match_step character varying NOT NULL,
    decision_status character varying NOT NULL,
    current_step boolean DEFAULT false NOT NULL,
    active_match boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    elapsed_days integer DEFAULT 0 NOT NULL,
    client_last_seen_date timestamp without time zone,
    criminal_hearing_date timestamp without time zone,
    decline_reason character varying,
    not_working_with_client_reason character varying,
    administrative_cancel_reason character varying,
    client_spoken_with_services_agency boolean,
    cori_release_form_submitted boolean
);


--
-- Name: cas_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cas_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cas_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cas_reports_id_seq OWNED BY public.cas_reports.id;


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
-- Name: db_credentials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.db_credentials (
    id bigint NOT NULL,
    user_id bigint,
    role character varying NOT NULL,
    adaptor character varying NOT NULL,
    username character varying NOT NULL,
    encrypted_password bytea NOT NULL,
    encrypted_password_iv bytea NOT NULL,
    database character varying NOT NULL,
    host character varying,
    port character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: db_credentials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.db_credentials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: db_credentials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.db_credentials_id_seq OWNED BY public.db_credentials.id;


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
-- Name: encryption_secrets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.encryption_secrets (
    id bigint NOT NULL,
    version_stage character varying NOT NULL,
    version_id character varying NOT NULL,
    previous boolean DEFAULT true NOT NULL,
    current boolean DEFAULT true NOT NULL,
    rotated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: encryption_secrets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.encryption_secrets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: encryption_secrets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.encryption_secrets_id_seq OWNED BY public.encryption_secrets.id;


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
    AS integer
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
    file_id integer,
    support_file_id integer,
    export_id integer
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
    can_view_census_details boolean DEFAULT false,
    can_edit_users boolean DEFAULT false,
    can_view_full_ssn boolean DEFAULT false,
    can_view_full_dob boolean DEFAULT false,
    can_view_hiv_status boolean DEFAULT false,
    can_view_dmh_status boolean DEFAULT false,
    can_view_imports boolean DEFAULT false,
    can_edit_roles boolean DEFAULT false,
    can_view_projects boolean DEFAULT false,
    can_view_organizations boolean DEFAULT false,
    can_view_client_window boolean DEFAULT false,
    can_upload_hud_zips boolean DEFAULT false,
    can_administer_health boolean DEFAULT false,
    can_edit_client_health boolean DEFAULT false,
    can_view_client_health boolean DEFAULT false,
    health_role boolean DEFAULT false NOT NULL,
    can_edit_project_groups boolean DEFAULT false,
    can_edit_anything_super_user boolean DEFAULT false,
    can_edit_projects boolean DEFAULT false,
    can_edit_organizations boolean DEFAULT false,
    can_edit_data_sources boolean DEFAULT false,
    can_edit_translations boolean DEFAULT false,
    can_manage_assessments boolean DEFAULT false,
    can_manage_config boolean DEFAULT false,
    can_edit_dq_grades boolean DEFAULT false,
    can_manage_client_files boolean DEFAULT false,
    can_manage_window_client_files boolean DEFAULT false,
    can_view_vspdat boolean DEFAULT false,
    can_edit_vspdat boolean DEFAULT false,
    can_create_clients boolean DEFAULT false,
    can_view_client_history_calendar boolean DEFAULT false,
    can_view_aggregate_health boolean DEFAULT false,
    can_assign_users_to_clients boolean DEFAULT false,
    can_view_client_user_assignments boolean DEFAULT false,
    can_export_hmis_data boolean DEFAULT false,
    can_confirm_housing_release boolean DEFAULT false,
    can_see_own_file_uploads boolean DEFAULT false,
    can_search_window boolean DEFAULT false,
    can_submit_vspdat boolean DEFAULT false,
    can_edit_client_notes boolean DEFAULT false,
    can_edit_window_client_notes boolean DEFAULT false,
    can_see_own_window_client_notes boolean DEFAULT false,
    can_track_anomalies boolean DEFAULT false,
    can_view_all_reports boolean DEFAULT false,
    can_assign_reports boolean DEFAULT false,
    can_view_assigned_reports boolean DEFAULT false,
    can_view_reports boolean DEFAULT false,
    can_manage_cohorts boolean DEFAULT false,
    can_edit_cohort_clients boolean DEFAULT false,
    can_edit_assigned_cohorts boolean DEFAULT false,
    can_view_assigned_cohorts boolean DEFAULT false,
    can_manage_organization_users boolean DEFAULT false,
    can_add_administrative_event boolean DEFAULT false,
    can_view_project_data_quality_client_details boolean DEFAULT false,
    can_manage_health_agency boolean DEFAULT false NOT NULL,
    can_approve_patient_assignments boolean DEFAULT false,
    can_manage_claims boolean DEFAULT false,
    can_manage_all_patients boolean DEFAULT false,
    can_manage_patients_for_own_agency boolean DEFAULT false,
    can_edit_all_patient_items boolean DEFAULT false,
    can_edit_patient_items_for_own_agency boolean DEFAULT false,
    can_create_care_plans_for_own_agency boolean DEFAULT false,
    can_view_all_patients boolean DEFAULT false,
    can_view_patients_for_own_agency boolean DEFAULT false,
    can_add_case_management_notes boolean DEFAULT false,
    can_see_clients_in_window_for_assigned_data_sources boolean DEFAULT false,
    can_approve_patient_items_for_agency boolean DEFAULT false,
    can_approve_cha boolean DEFAULT false,
    can_approve_ssm boolean DEFAULT false,
    can_approve_release boolean DEFAULT false,
    can_approve_participation boolean DEFAULT false,
    can_manage_care_coordinators boolean DEFAULT false,
    can_manage_accountable_care_organizations boolean DEFAULT false,
    can_view_member_health_reports boolean DEFAULT false,
    can_edit_warehouse_alerts boolean DEFAULT false,
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
    can_view_all_hud_reports boolean DEFAULT false,
    can_view_own_hud_reports boolean DEFAULT false,
    enforced_2fa boolean DEFAULT false,
    can_edit_access_groups boolean DEFAULT false,
    can_view_confidential_project_names boolean DEFAULT false,
    can_manage_ad_hoc_data_sources boolean DEFAULT false,
    can_view_client_ad_hoc_data_sources boolean DEFAULT false,
    can_impersonate_users boolean DEFAULT false,
    can_use_strict_search boolean DEFAULT false,
    can_use_separated_consent boolean DEFAULT false,
    can_delete_projects boolean DEFAULT false,
    can_delete_data_sources boolean DEFAULT false,
    training_required boolean DEFAULT false,
    can_edit_health_emergency_clinical boolean DEFAULT false,
    can_see_health_emergency boolean DEFAULT false,
    can_edit_health_emergency_screening boolean DEFAULT false,
    can_see_health_emergency_history boolean DEFAULT false,
    can_edit_health_emergency_medical_restriction boolean DEFAULT false,
    can_see_health_emergency_medical_restriction boolean DEFAULT false,
    can_see_health_emergency_screening boolean DEFAULT false,
    can_see_health_emergency_clinical boolean DEFAULT false,
    can_edit_health_emergency_contact_tracing boolean DEFAULT false,
    receives_medical_restriction_notifications boolean DEFAULT false,
    can_download_cohorts boolean DEFAULT false,
    can_use_service_register boolean DEFAULT false,
    can_manage_auto_client_de_duplication boolean DEFAULT false,
    can_view_all_window_notes boolean DEFAULT false,
    can_decrypt_pii boolean DEFAULT false,
    can_delete_youth_intake boolean DEFAULT false,
    can_administer_assigned_reports boolean DEFAULT false,
    can_view_enrollment_details boolean DEFAULT false,
    can_view_full_client_dashboard boolean DEFAULT false,
    can_view_limited_client_dashboard boolean DEFAULT false,
    can_view_cached_client_enrollments boolean DEFAULT false,
    can_search_all_clients boolean DEFAULT false,
    can_import_project_groups boolean DEFAULT false,
    can_view_client_locations boolean DEFAULT false,
    _report boolean DEFAULT false,
    can_view_project_related_filters boolean DEFAULT false,
    can_manage_sessions boolean DEFAULT false,
    can_generate_homeless_verification_pdfs boolean DEFAULT false,
    can_manage_own_ad_hoc_data_sources boolean DEFAULT false,
    can_view_service_register_on_client boolean DEFAULT false,
    can_view_all_vprs boolean DEFAULT false,
    can_view_my_vprs boolean DEFAULT false,
    can_search_own_clients boolean DEFAULT false,
    can_report_on_confidential_projects boolean DEFAULT false
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
-- Name: test_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_addresses (
    id bigint NOT NULL,
    test_person_id integer,
    street character varying
);


--
-- Name: test_addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_addresses_id_seq OWNED BY public.test_addresses.id;


--
-- Name: test_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_clients (
    id bigint NOT NULL,
    "FirstName" character varying,
    "encrypted_FirstName" character varying,
    "encrypted_FirstName_iv" character varying
);


--
-- Name: test_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_clients_id_seq OWNED BY public.test_clients.id;


--
-- Name: test_people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.test_people (
    id bigint NOT NULL,
    encrypted_first_name character varying,
    encrypted_first_name_iv character varying,
    email character varying,
    hair character varying
);


--
-- Name: test_people_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.test_people_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_people_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.test_people_id_seq OWNED BY public.test_people.id;


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
-- Name: two_factors_memorized_devices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.two_factors_memorized_devices (
    id bigint NOT NULL,
    user_id bigint,
    uuid character varying,
    name character varying,
    expires_at timestamp without time zone,
    session_id integer,
    log_in_ip character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: two_factors_memorized_devices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.two_factors_memorized_devices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: two_factors_memorized_devices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.two_factors_memorized_devices_id_seq OWNED BY public.two_factors_memorized_devices.id;


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
    last_training_completed date,
    provider character varying,
    uid character varying,
    provider_raw_info json,
    uuid character varying,
    receive_account_request_notifications boolean DEFAULT false,
    provider_set_at timestamp without time zone,
    exclude_from_directory boolean DEFAULT false,
    exclude_phone_from_directory boolean DEFAULT false,
    notify_on_new_account boolean DEFAULT false NOT NULL
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
-- Name: account_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_requests ALTER COLUMN id SET DEFAULT nextval('public.account_requests_id_seq'::regclass);


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: activity_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_logs ALTER COLUMN id SET DEFAULT nextval('public.activity_logs_id_seq'::regclass);


--
-- Name: agencies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agencies ALTER COLUMN id SET DEFAULT nextval('public.agencies_id_seq'::regclass);


--
-- Name: cas_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_reports ALTER COLUMN id SET DEFAULT nextval('public.cas_reports_id_seq'::regclass);


--
-- Name: clients_unduplicated id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients_unduplicated ALTER COLUMN id SET DEFAULT nextval('public.clients_unduplicated_id_seq'::regclass);


--
-- Name: consent_limits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consent_limits ALTER COLUMN id SET DEFAULT nextval('public.consent_limits_id_seq'::regclass);


--
-- Name: db_credentials id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.db_credentials ALTER COLUMN id SET DEFAULT nextval('public.db_credentials_id_seq'::regclass);


--
-- Name: delayed_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs ALTER COLUMN id SET DEFAULT nextval('public.delayed_jobs_id_seq'::regclass);


--
-- Name: encryption_secrets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encryption_secrets ALTER COLUMN id SET DEFAULT nextval('public.encryption_secrets_id_seq'::regclass);


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
-- Name: test_addresses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_addresses ALTER COLUMN id SET DEFAULT nextval('public.test_addresses_id_seq'::regclass);


--
-- Name: test_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_clients ALTER COLUMN id SET DEFAULT nextval('public.test_clients_id_seq'::regclass);


--
-- Name: test_people id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_people ALTER COLUMN id SET DEFAULT nextval('public.test_people_id_seq'::regclass);


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
-- Name: two_factors_memorized_devices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factors_memorized_devices ALTER COLUMN id SET DEFAULT nextval('public.two_factors_memorized_devices_id_seq'::regclass);


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
-- Name: account_requests account_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_requests
    ADD CONSTRAINT account_requests_pkey PRIMARY KEY (id);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


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
-- Name: cas_reports cas_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_reports
    ADD CONSTRAINT cas_reports_pkey PRIMARY KEY (id);


--
-- Name: clients_unduplicated clients_unduplicated_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients_unduplicated
    ADD CONSTRAINT clients_unduplicated_pkey PRIMARY KEY (id);


--
-- Name: consent_limits consent_limits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consent_limits
    ADD CONSTRAINT consent_limits_pkey PRIMARY KEY (id);


--
-- Name: db_credentials db_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.db_credentials
    ADD CONSTRAINT db_credentials_pkey PRIMARY KEY (id);


--
-- Name: delayed_jobs delayed_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.delayed_jobs
    ADD CONSTRAINT delayed_jobs_pkey PRIMARY KEY (id);


--
-- Name: encryption_secrets encryption_secrets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encryption_secrets
    ADD CONSTRAINT encryption_secrets_pkey PRIMARY KEY (id);


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
-- Name: test_addresses test_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_addresses
    ADD CONSTRAINT test_addresses_pkey PRIMARY KEY (id);


--
-- Name: test_clients test_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_clients
    ADD CONSTRAINT test_clients_pkey PRIMARY KEY (id);


--
-- Name: test_people test_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.test_people
    ADD CONSTRAINT test_people_pkey PRIMARY KEY (id);


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
-- Name: two_factors_memorized_devices two_factors_memorized_devices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factors_memorized_devices
    ADD CONSTRAINT two_factors_memorized_devices_pkey PRIMARY KEY (id);


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
-- Name: activity_logs_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX activity_logs_created_at_idx ON public.activity_logs USING brin (created_at);


--
-- Name: created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX created_at_idx ON public.activity_logs USING brin (created_at);


--
-- Name: delayed_jobs_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX delayed_jobs_priority ON public.delayed_jobs USING btree (priority, run_at);


--
-- Name: index_account_requests_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_requests_on_user_id ON public.account_requests USING btree (user_id);


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


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
-- Name: index_cas_reports_on_client_id_and_match_id_and_decision_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cas_reports_on_client_id_and_match_id_and_decision_id ON public.cas_reports USING btree (client_id, match_id, decision_id);


--
-- Name: index_consent_limits_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_consent_limits_on_name ON public.consent_limits USING btree (name);


--
-- Name: index_db_credentials_on_user_id_and_role; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_db_credentials_on_user_id_and_role ON public.db_credentials USING btree (user_id, role);


--
-- Name: index_encryption_secrets_on_version_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_encryption_secrets_on_version_id ON public.encryption_secrets USING btree (version_id);


--
-- Name: index_encryption_secrets_on_version_stage; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_encryption_secrets_on_version_stage ON public.encryption_secrets USING btree (version_stage);


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
-- Name: index_two_factors_memorized_devices_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_two_factors_memorized_devices_on_user_id ON public.two_factors_memorized_devices USING btree (user_id);


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
-- Name: index_users_on_uid_and_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_uid_and_provider ON public.users USING btree (uid, provider);


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
-- Name: glacier_archives fk_rails_6121d2e55f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.glacier_archives
    ADD CONSTRAINT fk_rails_6121d2e55f FOREIGN KEY (glacier_vault_id) REFERENCES public.glacier_vaults(id);


--
-- Name: two_factors_memorized_devices fk_rails_65991dd82f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factors_memorized_devices
    ADD CONSTRAINT fk_rails_65991dd82f FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: reports fk_rails_b231202c9b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_rails_b231202c9b FOREIGN KEY (report_results_summary_id) REFERENCES public.report_results_summaries(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: report_results fk_rails_cd0d43bf48; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_results
    ADD CONSTRAINT fk_rails_cd0d43bf48 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: db_credentials fk_rails_d5f512c153; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.db_credentials
    ADD CONSTRAINT fk_rails_d5f512c153 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20160615125048'),
('20160616140826'),
('20160628182622'),
('20160701172807'),
('20160705145733'),
('20160708134220'),
('20160708140847'),
('20160708172039'),
('20160708174624'),
('20160708180500'),
('20160711124428'),
('20160711132731'),
('20160711143807'),
('20160711144914'),
('20160722162801'),
('20160725151439'),
('20160726210214'),
('20160829142445'),
('20160829155417'),
('20160906154014'),
('20160907123023'),
('20160907185535'),
('20160921165937'),
('20161005204310'),
('20161006160330'),
('20161012152230'),
('20161012161240'),
('20161103123424'),
('20161107160154'),
('20161111151851'),
('20161111181757'),
('20161111205317'),
('20161119003439'),
('20161213140009'),
('20161214144658'),
('20161215163027'),
('20161216003217'),
('20161219184752'),
('20170505132237'),
('20170517200539'),
('20170526162435'),
('20170619210146'),
('20170619235354'),
('20170627154145'),
('20170627182531'),
('20170703125950'),
('20170705123919'),
('20170721143408'),
('20170721143409'),
('20170726141503'),
('20170731202132'),
('20170801194526'),
('20170815161947'),
('20170830180506'),
('20170830223244'),
('20170901153110'),
('20170922130841'),
('20170922183847'),
('20170927131448'),
('20170928194909'),
('20171004172953'),
('20171023174425'),
('20171024183915'),
('20171025122843'),
('20171026201120'),
('20171026203139'),
('20171027124054'),
('20171027192753'),
('20171102123227'),
('20171108145620'),
('20171108184341'),
('20171115185203'),
('20171121011445'),
('20171204133242'),
('20171204164243'),
('20180203234329'),
('20180211172808'),
('20180226145540'),
('20180301214751'),
('20180403182327'),
('20180410152130'),
('20180413221626'),
('20180416160927'),
('20180416213522'),
('20180419165841'),
('20180504140026'),
('20180511004923'),
('20180521172429'),
('20180521190108'),
('20180530200118'),
('20180601185917'),
('20180612175806'),
('20180613133940'),
('20180627165639'),
('20180629134948'),
('20180629135738'),
('20180629145712'),
('20180710174713'),
('20180716141934'),
('20180716181011'),
('20180722112728'),
('20180801164521'),
('20180810210623'),
('20180821195006'),
('20181001172617'),
('20181012132645'),
('20181024200910'),
('20181024231159'),
('20181025123951'),
('20181025135153'),
('20181030144345'),
('20181030203357'),
('20181031172440'),
('20181105154441'),
('20181128180134'),
('20181211174411'),
('20190129210815'),
('20190327174142'),
('20190327192234'),
('20190417142558'),
('20190717133521'),
('20190717134445'),
('20190717164100'),
('20190717185326'),
('20190801193258'),
('20190802144446'),
('20190802150742'),
('20190813124815'),
('20190821125609'),
('20190828190416'),
('20190911124324'),
('20190916190551'),
('20191008130933'),
('20191008132105'),
('20191008163710'),
('20191011122814'),
('20191012175639'),
('20191012223328'),
('20191014153813'),
('20191015142006'),
('20191017230529'),
('20191021191814'),
('20191021194633'),
('20191022140448'),
('20191022181527'),
('20191029172244'),
('20191104165453'),
('20191104165454'),
('20191104165455'),
('20191104165456'),
('20191104165457'),
('20191104165458'),
('20191105181656'),
('20191115192256'),
('20191124135043'),
('20191124135304'),
('20191227161954'),
('20191230140045'),
('20200104160008'),
('20200207133048'),
('20200212135100'),
('20200212142604'),
('20200212152652'),
('20200217163759'),
('20200217164324'),
('20200219145902'),
('20200325201541'),
('20200327222948'),
('20200328122429'),
('20200330180135'),
('20200401161139'),
('20200402002149'),
('20200410003006'),
('20200612141235'),
('20200612150045'),
('20200612182702'),
('20200709125338'),
('20200716133200'),
('20200720151331'),
('20200720221319'),
('20200721151558'),
('20200721152000'),
('20200721153111'),
('20200721153237'),
('20200722021319'),
('20200722150322'),
('20200723051505'),
('20200724150317'),
('20200724181711'),
('20200727061729'),
('20200728185654'),
('20201105132926'),
('20201216141634'),
('20201217155258'),
('20201221141550'),
('20201221183603'),
('20210105183208'),
('20210127180420'),
('20210127181709'),
('20210203195412'),
('20210205193320'),
('20210206022724'),
('20210301141302'),
('20210315191809'),
('20210315200648'),
('20210317190501'),
('20210317215206'),
('20210402181911'),
('20210419203457'),
('20210506185609'),
('20210506185752'),
('20210507151459'),
('20210518132857'),
('20210607135335'),
('20210616141644'),
('20210616142134'),
('20210617140852'),
('20210618123018'),
('20210622204223'),
('20210719143827'),
('20210819132153'),
('20220127152605'),
('20220216174239'),
('20220309140327'),
('20220314183405'),
('20220518143528'),
('20220609133835'),
('20220613211706'),
('20220613212850'),
('20220615155458');


