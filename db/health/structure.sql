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

SET default_table_access_method = heap;

--
-- Name: accountable_care_organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accountable_care_organizations (
    id integer NOT NULL,
    name character varying,
    short_name character varying,
    mco_pid integer,
    mco_sl character varying,
    active boolean DEFAULT true NOT NULL,
    edi_name character varying,
    e_d_receiver_text character varying,
    e_d_file_prefix character varying,
    vpr_name character varying
);


--
-- Name: accountable_care_organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accountable_care_organizations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accountable_care_organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accountable_care_organizations_id_seq OWNED BY public.accountable_care_organizations.id;


--
-- Name: agencies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agencies (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    acceptable_domains character varying
);


--
-- Name: agencies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agencies_id_seq
    AS integer
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
-- Name: agency_patient_referrals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agency_patient_referrals (
    id integer NOT NULL,
    agency_id integer NOT NULL,
    patient_referral_id integer NOT NULL,
    claimed boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


--
-- Name: agency_patient_referrals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agency_patient_referrals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agency_patient_referrals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agency_patient_referrals_id_seq OWNED BY public.agency_patient_referrals.id;


--
-- Name: agency_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agency_users (
    id integer NOT NULL,
    agency_id integer NOT NULL,
    user_id integer NOT NULL
);


--
-- Name: agency_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agency_users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agency_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agency_users_id_seq OWNED BY public.agency_users.id;


--
-- Name: appointments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appointments (
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
    patient_id character varying,
    data_source_id integer DEFAULT 6 NOT NULL
);


--
-- Name: appointments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.appointments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: appointments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.appointments_id_seq OWNED BY public.appointments.id;


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
-- Name: backup_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.backup_plans (
    id bigint NOT NULL,
    patient_id bigint,
    description character varying,
    backup_plan character varying,
    person character varying,
    phone character varying,
    address text,
    plan_created_on date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: backup_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.backup_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: backup_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.backup_plans_id_seq OWNED BY public.backup_plans.id;


--
-- Name: careplan_equipment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.careplan_equipment (
    id integer NOT NULL,
    careplan_id integer,
    equipment_id integer
);


--
-- Name: careplan_equipment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.careplan_equipment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: careplan_equipment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.careplan_equipment_id_seq OWNED BY public.careplan_equipment.id;


--
-- Name: careplan_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.careplan_services (
    id integer NOT NULL,
    careplan_id integer,
    service_id integer
);


--
-- Name: careplan_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.careplan_services_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: careplan_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.careplan_services_id_seq OWNED BY public.careplan_services.id;


--
-- Name: careplans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.careplans (
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
    updated_at timestamp without time zone,
    patient_signed_on timestamp without time zone,
    provider_signed_on timestamp without time zone,
    locked boolean DEFAULT false NOT NULL,
    initial_date timestamp without time zone,
    review_date timestamp without time zone,
    patient_health_problems text,
    patient_strengths text,
    patient_goals text,
    patient_barriers text,
    status character varying,
    responsible_team_member_id integer,
    provider_id integer,
    representative_id integer,
    responsible_team_member_signed_on timestamp without time zone,
    representative_signed_on timestamp without time zone,
    service_archive text,
    equipment_archive text,
    team_members_archive text,
    goals_archive text,
    patient_signature_requested_at timestamp without time zone,
    provider_signature_requested_at timestamp without time zone,
    health_file_id integer,
    member_understands_contingency boolean,
    member_verbalizes_understanding boolean,
    backup_plan_archive text,
    future_issues_0 character varying,
    future_issues_1 character varying,
    future_issues_2 character varying,
    future_issues_3 character varying,
    future_issues_4 character varying,
    future_issues_5 character varying,
    future_issues_6 character varying,
    future_issues_7 character varying,
    future_issues_8 character varying,
    future_issues_9 character varying,
    future_issues_10 character varying,
    patient_signature_mode character varying,
    provider_signature_mode character varying
);


--
-- Name: careplans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.careplans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: careplans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.careplans_id_seq OWNED BY public.careplans.id;


--
-- Name: claims; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims (
    id integer NOT NULL,
    user_id integer,
    max_date date,
    job_id integer,
    max_isa_control_number integer,
    max_group_control_number integer,
    max_st_number integer,
    claims_file text,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    error character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    submitted_at timestamp without time zone,
    precalculated_at timestamp without time zone,
    result character varying,
    transaction_acknowledgement_id integer,
    test_file boolean DEFAULT false
);


--
-- Name: claims_amount_paid_location_month; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_amount_paid_location_month (
    id integer NOT NULL,
    medicaid_id character varying NOT NULL,
    year integer,
    month integer,
    ip integer,
    emerg integer,
    respite integer,
    op integer,
    rx integer,
    other integer,
    total integer,
    year_month character varying,
    study_period character varying
);


--
-- Name: claims_amount_paid_location_month_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_amount_paid_location_month_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_amount_paid_location_month_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_amount_paid_location_month_id_seq OWNED BY public.claims_amount_paid_location_month.id;


--
-- Name: claims_claim_volume_location_month; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_claim_volume_location_month (
    id integer NOT NULL,
    medicaid_id character varying NOT NULL,
    year integer,
    month integer,
    ip integer,
    emerg integer,
    respite integer,
    op integer,
    rx integer,
    other integer,
    total integer,
    year_month character varying,
    study_period character varying
);


--
-- Name: claims_claim_volume_location_month_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_claim_volume_location_month_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_claim_volume_location_month_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_claim_volume_location_month_id_seq OWNED BY public.claims_claim_volume_location_month.id;


--
-- Name: claims_ed_nyu_severity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_ed_nyu_severity (
    id integer NOT NULL,
    medicaid_id character varying NOT NULL,
    category character varying,
    indiv_pct double precision,
    sdh_pct double precision,
    baseline_visits double precision,
    implementation_visits double precision
);


--
-- Name: claims_ed_nyu_severity_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_ed_nyu_severity_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_ed_nyu_severity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_ed_nyu_severity_id_seq OWNED BY public.claims_ed_nyu_severity.id;


--
-- Name: claims_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_id_seq OWNED BY public.claims.id;


--
-- Name: claims_reporting_ccs_lookups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_reporting_ccs_lookups (
    id bigint NOT NULL,
    hcpcs_start character varying NOT NULL,
    hcpcs_end character varying NOT NULL,
    ccs_id integer NOT NULL,
    ccs_label character varying NOT NULL,
    effective_start date NOT NULL,
    effective_end date NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: claims_reporting_ccs_lookups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_reporting_ccs_lookups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_reporting_ccs_lookups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_reporting_ccs_lookups_id_seq OWNED BY public.claims_reporting_ccs_lookups.id;


--
-- Name: claims_reporting_cp_payment_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_reporting_cp_payment_details (
    id bigint NOT NULL,
    cp_payment_upload_id bigint NOT NULL,
    medicaid_id character varying NOT NULL,
    cp_enrollment_start_date date NOT NULL,
    paid_dos date NOT NULL,
    payment_date date NOT NULL,
    amount_paid numeric(10,2),
    adjustment_amount numeric(10,2),
    member_cp_assignment_plan character varying,
    cp_name_dsrip character varying,
    cp_name_official character varying,
    cp_pid character varying,
    cp_sl character varying,
    month_payment_issued character varying,
    paid_num_icn character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: claims_reporting_cp_payment_details_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_reporting_cp_payment_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_reporting_cp_payment_details_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_reporting_cp_payment_details_id_seq OWNED BY public.claims_reporting_cp_payment_details.id;


--
-- Name: claims_reporting_cp_payment_uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_reporting_cp_payment_uploads (
    id bigint NOT NULL,
    user_id bigint,
    original_filename character varying,
    content bytea,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    deleted_at timestamp without time zone
);


--
-- Name: claims_reporting_cp_payment_uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_reporting_cp_payment_uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_reporting_cp_payment_uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_reporting_cp_payment_uploads_id_seq OWNED BY public.claims_reporting_cp_payment_uploads.id;


--
-- Name: claims_reporting_engagement_trends; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_reporting_engagement_trends (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    options jsonb,
    results jsonb,
    processing_errors character varying,
    completed_at timestamp without time zone,
    started_at timestamp without time zone,
    failed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: claims_reporting_engagement_trends_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_reporting_engagement_trends_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_reporting_engagement_trends_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_reporting_engagement_trends_id_seq OWNED BY public.claims_reporting_engagement_trends.id;


--
-- Name: claims_reporting_imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_reporting_imports (
    id bigint NOT NULL,
    source_url character varying NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    successful boolean,
    status_message character varying,
    content_hash character varying,
    content bytea,
    importer character varying,
    method character varying,
    args jsonb,
    env jsonb,
    results jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: claims_reporting_imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_reporting_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_reporting_imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_reporting_imports_id_seq OWNED BY public.claims_reporting_imports.id;


--
-- Name: claims_reporting_medical_claims; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_reporting_medical_claims (
    id bigint NOT NULL,
    member_id character varying(50) NOT NULL,
    claim_number character varying(30) NOT NULL,
    line_number character varying(10) NOT NULL,
    cp_pidsl character varying(50),
    cp_name character varying(255),
    aco_pidsl character varying(50),
    aco_name character varying(255),
    pcc_pidsl character varying(50),
    pcc_name character varying(255),
    pcc_npi character varying(50),
    pcc_taxid character varying(50),
    mco_pidsl character varying(50),
    mco_name character varying(50),
    source character varying(50),
    claim_type character varying(255),
    member_dob date,
    patient_status character varying(255),
    service_start_date date,
    service_end_date date,
    admit_date date,
    discharge_date date,
    type_of_bill character varying(255),
    admit_source character varying(255),
    admit_type character varying(255),
    frequency_code character varying(255),
    paid_date date,
    billed_amount numeric(19,4),
    allowed_amount numeric(19,4),
    paid_amount numeric(19,4),
    admit_diagnosis character varying(50),
    dx_1 character varying(50),
    dx_2 character varying(50),
    dx_3 character varying(50),
    dx_4 character varying(50),
    dx_5 character varying(50),
    dx_6 character varying(50),
    dx_7 character varying(50),
    dx_8 character varying(50),
    dx_9 character varying(50),
    dx_10 character varying(50),
    dx_11 character varying(50),
    dx_12 character varying(50),
    dx_13 character varying(50),
    dx_14 character varying(50),
    dx_15 character varying(50),
    dx_16 character varying(50),
    dx_17 character varying(50),
    dx_18 character varying(50),
    dx_19 character varying(50),
    dx_20 character varying(50),
    dx_21 character varying(50),
    dx_22 character varying(50),
    dx_23 character varying(50),
    dx_24 character varying(50),
    dx_25 character varying(50),
    e_dx_1 character varying(50),
    e_dx_2 character varying(50),
    e_dx_3 character varying(50),
    e_dx_4 character varying(50),
    e_dx_5 character varying(50),
    e_dx_6 character varying(50),
    e_dx_7 character varying(50),
    e_dx_8 character varying(50),
    e_dx_9 character varying(50),
    e_dx_10 character varying(50),
    e_dx_11 character varying(50),
    e_dx_12 character varying(50),
    icd_version character varying(50),
    surgical_procedure_code_1 character varying(50),
    surgical_procedure_code_2 character varying(50),
    surgical_procedure_code_3 character varying(50),
    surgical_procedure_code_4 character varying(50),
    surgical_procedure_code_5 character varying(50),
    surgical_procedure_code_6 character varying(50),
    revenue_code character varying(50),
    place_of_service_code character varying(50),
    procedure_code character varying(50),
    procedure_modifier_1 character varying(50),
    procedure_modifier_2 character varying(50),
    procedure_modifier_3 character varying(50),
    procedure_modifier_4 character varying(50),
    drg_code character varying(50),
    drg_version_code character varying(50),
    severity_of_illness character varying(50),
    service_provider_npi character varying(50),
    id_provider_servicing character varying(50),
    servicing_taxid character varying(50),
    servicing_provider_name character varying(512),
    servicing_provider_type character varying(255),
    servicing_provider_taxonomy character varying(255),
    servicing_address character varying(512),
    servicing_city character varying(255),
    servicing_state character varying(255),
    servicing_zip character varying(50),
    billing_npi character varying(50),
    id_provider_billing character varying(50),
    billing_taxid character varying(50),
    billing_provider_name character varying(512),
    billing_provider_type character varying(50),
    billing_provider_taxonomy character varying(50),
    billing_address character varying(512),
    billing_city character varying(255),
    billing_state character varying(255),
    billing_zip character varying(50),
    claim_status character varying(255),
    disbursement_code character varying(255),
    enrolled_flag character varying(50),
    referral_circle_ind character varying(50),
    mbhp_flag character varying(50),
    present_on_admission_1 character varying(50),
    present_on_admission_2 character varying(50),
    present_on_admission_3 character varying(50),
    present_on_admission_4 character varying(50),
    present_on_admission_5 character varying(50),
    present_on_admission_6 character varying(50),
    present_on_admission_7 character varying(50),
    present_on_admission_8 character varying(50),
    present_on_admission_9 character varying(50),
    present_on_admission_10 character varying(50),
    present_on_admission_11 character varying(50),
    present_on_admission_12 character varying(50),
    present_on_admission_13 character varying(50),
    present_on_admission_14 character varying(50),
    present_on_admission_15 character varying(50),
    present_on_admission_16 character varying(50),
    present_on_admission_17 character varying(50),
    present_on_admission_18 character varying(50),
    present_on_admission_19 character varying(50),
    present_on_admission_20 character varying(50),
    present_on_admission_21 character varying(50),
    present_on_admission_22 character varying(50),
    present_on_admission_23 character varying(50),
    present_on_admission_24 character varying(50),
    present_on_admission_25 character varying(50),
    e_dx_present_on_admission_1 character varying(50),
    e_dx_present_on_admission_2 character varying(50),
    e_dx_present_on_admission_3 character varying(50),
    e_dx_present_on_admission_4 character varying(50),
    e_dx_present_on_admission_5 character varying(50),
    e_dx_present_on_admission_6 character varying(50),
    e_dx_present_on_admission_7 character varying(50),
    e_dx_present_on_admission_8 character varying(50),
    e_dx_present_on_admission_9 character varying(50),
    e_dx_present_on_admission_10 character varying(50),
    e_dx_present_on_admission_11 character varying(50),
    e_dx_present_on_admission_12 character varying(50),
    quantity numeric(12,4),
    price_method character varying(50),
    ccs_id character varying,
    cde_cos_rollup character varying(50),
    cde_cos_category character varying(50),
    cde_cos_subcategory character varying(50),
    ind_mco_aco_cvd_svc character varying(50),
    enrolled_days integer DEFAULT 0,
    engaged_days integer DEFAULT 0,
    cde_ndc character varying(48)
);


--
-- Name: COLUMN claims_reporting_medical_claims.enrolled_days; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_medical_claims.enrolled_days IS 'Est. number of days the member has been enrolled as of the service start date.';


--
-- Name: COLUMN claims_reporting_medical_claims.engaged_days; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_medical_claims.engaged_days IS 'Est. number of days the member has been engaged by a CP as of the service start date.';


--
-- Name: claims_reporting_medical_claims_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_reporting_medical_claims_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_reporting_medical_claims_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_reporting_medical_claims_id_seq OWNED BY public.claims_reporting_medical_claims.id;


--
-- Name: claims_reporting_member_diagnosis_classifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_reporting_member_diagnosis_classifications (
    id bigint NOT NULL,
    member_id character varying NOT NULL,
    currently_assigned boolean,
    currently_engaged boolean,
    ast boolean,
    cpd boolean,
    cir boolean,
    dia boolean,
    spn boolean,
    gbt boolean,
    obs boolean,
    hyp boolean,
    hep boolean,
    sch boolean,
    pbd boolean,
    das boolean,
    pid boolean,
    sia boolean,
    sud boolean,
    other_bh boolean,
    coi boolean,
    high_er boolean,
    psychoses boolean,
    other_ip_psych boolean,
    high_util boolean,
    er_visits integer,
    ip_admits integer,
    ip_admits_psychoses integer,
    antipsy_day integer,
    engaged_member_days integer,
    engaged_member_months integer,
    antipsy_denom integer,
    antidep_day integer,
    antidep_denom integer,
    moodstab_day integer,
    moodstab_denom integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.ast; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.ast IS 'asthma';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.cpd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.cpd IS 'copd';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.cir; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.cir IS 'cardiac disease';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.dia; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.dia IS 'diabetes';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.spn; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.spn IS 'degenerative spinal disease/chronic pain';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.gbt; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.gbt IS 'gi and biliary tract disease';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.obs; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.obs IS 'obesity';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.hyp; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.hyp IS 'hypertension';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.hep; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.hep IS 'hepatitis';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.sch; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.sch IS 'schizophrenia';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.pbd; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.pbd IS 'psychoses/bipolar disorders';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.das; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.das IS 'depression/anxiety/stress reactions';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.pid; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.pid IS 'personality/impulse disorder';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.sia; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.sia IS 'suicidal ideation/attempt';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.sud; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.sud IS 'substance Abuse Disorder';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.other_bh; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.other_bh IS 'other behavioral health';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.coi; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.coi IS 'cohort of interest';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.high_er; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.high_er IS '5+ ER Visits with No IP Psych Admission';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.psychoses; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.psychoses IS '1+ Psychoses Admissions';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.other_ip_psych; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.other_ip_psych IS '+ IP Psych Admissions';


--
-- Name: COLUMN claims_reporting_member_diagnosis_classifications.high_util; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.claims_reporting_member_diagnosis_classifications.high_util IS '3+ inpatient stays or 5+ emergency room visits throughout their claims experience';


--
-- Name: claims_reporting_member_diagnosis_classifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_reporting_member_diagnosis_classifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_reporting_member_diagnosis_classifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_reporting_member_diagnosis_classifications_id_seq OWNED BY public.claims_reporting_member_diagnosis_classifications.id;


--
-- Name: claims_reporting_member_enrollment_rosters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_reporting_member_enrollment_rosters (
    id bigint NOT NULL,
    member_id character varying(50) NOT NULL,
    performance_year character varying(50),
    region character varying(50),
    service_area character varying(50),
    aco_pidsl character varying(50),
    aco_name character varying(255),
    pcc_pidsl character varying(50),
    pcc_name character varying(255),
    pcc_npi character varying(50),
    pcc_taxid character varying(50),
    mco_pidsl character varying(50),
    mco_name character varying(50),
    enrolled_flag character varying(50),
    enroll_type character varying(50),
    enroll_stop_reason character varying(50),
    rating_category_char_cd character varying(255),
    ind_dds character varying(50),
    ind_dmh character varying(50),
    ind_dta character varying(50),
    ind_dss character varying(50),
    cde_hcb_waiver character varying(50),
    cde_waiver_category character varying(50),
    span_start_date date NOT NULL,
    span_end_date date,
    span_mem_days integer,
    cp_prov_type character varying(255),
    cp_plan_type character varying(255),
    cp_pidsl character varying(50),
    cp_prov_name character varying(512),
    cp_enroll_dt date,
    cp_disenroll_dt date,
    cp_start_rsn character varying(255),
    cp_stop_rsn character varying(255),
    ind_medicare_a character varying(50),
    ind_medicare_b character varying(50),
    tpl_coverage_cat character varying(50),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    engagement_date date,
    engaged_days integer,
    enrollment_end_at_engagement_calculation date,
    first_claim_date date,
    pre_engagement_days integer DEFAULT 0
);


--
-- Name: claims_reporting_member_enrollment_rosters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_reporting_member_enrollment_rosters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_reporting_member_enrollment_rosters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_reporting_member_enrollment_rosters_id_seq OWNED BY public.claims_reporting_member_enrollment_rosters.id;


--
-- Name: claims_reporting_member_rosters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_reporting_member_rosters (
    id bigint NOT NULL,
    member_id character varying(50) NOT NULL,
    nam_first character varying(255),
    nam_last character varying(255),
    cp_pidsl character varying(50),
    cp_name character varying(255),
    aco_pidsl character varying(50),
    aco_name character varying(255),
    mco_pidsl character varying(50),
    mco_name character varying(50),
    sex character varying(50),
    date_of_birth date,
    mailing_address_1 character varying(512),
    mailing_address_2 character varying(512),
    mailing_city character varying(255),
    mailing_state character varying(255),
    mailing_zip character varying(50),
    residential_address_1 character varying(512),
    residential_address_2 character varying(512),
    residential_city character varying(255),
    residential_state character varying(255),
    residential_zip character varying(50),
    race character varying(50),
    phone_number character varying(50),
    primary_language_s character varying(255),
    primary_language_w character varying(255),
    sdh_nss7_score character varying(50),
    sdh_homelessness character varying(50),
    sdh_addresses_flag character varying(50),
    sdh_other_disabled character varying(50),
    sdh_spmi character varying(50),
    raw_risk_score character varying(50),
    normalized_risk_score character varying(50),
    raw_dxcg_risk_score character varying(50),
    last_office_visit date,
    last_ed_visit date,
    last_ip_visit date,
    enrolled_flag character varying(50),
    enrollment_status character varying(50),
    cp_claim_dt date,
    qualifying_hcpcs character varying(50),
    qualifying_hcpcs_nm character varying(255),
    qualifying_dsc character varying(512),
    email character varying(512),
    head_of_household character varying(512),
    sdh_smi character varying(50)
);


--
-- Name: claims_reporting_member_rosters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_reporting_member_rosters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_reporting_member_rosters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_reporting_member_rosters_id_seq OWNED BY public.claims_reporting_member_rosters.id;


--
-- Name: claims_reporting_quality_measures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_reporting_quality_measures (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    options jsonb,
    results jsonb,
    processing_errors character varying,
    completed_at timestamp without time zone,
    started_at timestamp without time zone,
    failed_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: claims_reporting_quality_measures_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_reporting_quality_measures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_reporting_quality_measures_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_reporting_quality_measures_id_seq OWNED BY public.claims_reporting_quality_measures.id;


--
-- Name: claims_reporting_rx_claims; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_reporting_rx_claims (
    id bigint NOT NULL,
    member_id character varying(50) NOT NULL,
    claim_number character varying(30) NOT NULL,
    line_number character varying(10) NOT NULL,
    cp_pidsl character varying(50),
    cp_name character varying(255),
    aco_pidsl character varying(50),
    aco_name character varying(255),
    pcc_pidsl character varying(50),
    pcc_name character varying(255),
    pcc_npi character varying(50),
    pcc_taxid character varying(50),
    mco_pidsl character varying(50),
    mco_name character varying(50),
    source character varying(50),
    claim_type character varying(255),
    member_dob date,
    refill_quantity character varying(20),
    service_start_date date,
    service_end_date date,
    paid_date date,
    days_supply integer,
    billed_amount numeric(19,4),
    allowed_amount numeric(19,4),
    paid_amount numeric(19,4),
    prescriber_npi character varying(50),
    id_prescriber_servicing character varying(50),
    prescriber_taxid character varying(50),
    prescriber_name character varying(255),
    prescriber_type character varying(50),
    prescriber_taxonomy character varying(50),
    prescriber_address character varying(512),
    prescriber_city character varying(255),
    prescriber_state character varying(255),
    prescriber_zip character varying(50),
    billing_npi character varying(50),
    id_provider_billing character varying(50),
    billing_taxid character varying(50),
    billing_provider_name character varying(255),
    billing_provider_type character varying(50),
    billing_provider_taxonomy character varying(50),
    billing_address character varying(512),
    billing_city character varying(255),
    billing_state character varying(255),
    billing_zip character varying(50),
    ndc_code character varying(50),
    dosage_form_code character varying(50),
    therapeutic_class character varying(50),
    daw_ind character varying(50),
    gcn character varying(50),
    claim_status character varying(50),
    disbursement_code character varying(50),
    enrolled_flag character varying(50),
    drug_name character varying(512),
    brand_vs_generic_indicator integer,
    price_method character varying(50),
    quantity numeric(12,4),
    route_of_administration character varying(255),
    cde_cos_rollup character varying(50),
    cde_cos_category character varying(50),
    cde_cos_subcategory character varying(50),
    ind_mco_aco_cvd_svc character varying(50)
);


--
-- Name: claims_reporting_rx_claims_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_reporting_rx_claims_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_reporting_rx_claims_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_reporting_rx_claims_id_seq OWNED BY public.claims_reporting_rx_claims.id;


--
-- Name: claims_roster; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_roster (
    id integer NOT NULL,
    medicaid_id character varying NOT NULL,
    last_name character varying,
    first_name character varying,
    gender character varying,
    dob date,
    race character varying,
    primary_language character varying,
    disability_flag boolean,
    norm_risk_score double precision,
    mbr_months integer,
    total_ty integer,
    ed_visits integer,
    acute_ip_admits integer,
    average_days_to_readmit integer,
    pcp character varying,
    epic_team character varying,
    member_months_baseline integer,
    member_months_implementation integer,
    cost_rank_ty integer,
    average_ed_visits_baseline double precision,
    average_ed_visits_implementation double precision,
    average_ip_admits_baseline double precision,
    average_ip_admits_implementation double precision,
    average_days_to_readmit_baseline double precision,
    average_days_to_implementation double precision,
    case_manager character varying,
    housing_status character varying,
    baseline_admits integer,
    implementation_admits integer
);


--
-- Name: claims_roster_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_roster_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_roster_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_roster_id_seq OWNED BY public.claims_roster.id;


--
-- Name: claims_top_conditions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_top_conditions (
    id integer NOT NULL,
    medicaid_id character varying NOT NULL,
    rank integer,
    description character varying,
    indiv_pct double precision,
    sdh_pct double precision,
    baseline_paid double precision,
    implementation_paid double precision
);


--
-- Name: claims_top_conditions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_top_conditions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_top_conditions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_top_conditions_id_seq OWNED BY public.claims_top_conditions.id;


--
-- Name: claims_top_ip_conditions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_top_ip_conditions (
    id integer NOT NULL,
    medicaid_id character varying NOT NULL,
    rank integer,
    description character varying,
    indiv_pct double precision,
    sdh_pct double precision,
    baseline_paid double precision,
    implementation_paid double precision
);


--
-- Name: claims_top_ip_conditions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_top_ip_conditions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_top_ip_conditions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_top_ip_conditions_id_seq OWNED BY public.claims_top_ip_conditions.id;


--
-- Name: claims_top_providers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.claims_top_providers (
    id integer NOT NULL,
    medicaid_id character varying NOT NULL,
    rank integer,
    provider_name character varying,
    indiv_pct double precision,
    sdh_pct double precision,
    baseline_paid double precision,
    implementation_paid double precision
);


--
-- Name: claims_top_providers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.claims_top_providers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: claims_top_providers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.claims_top_providers_id_seq OWNED BY public.claims_top_providers.id;


--
-- Name: comprehensive_health_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comprehensive_health_assessments (
    id integer NOT NULL,
    patient_id integer,
    user_id integer,
    health_file_id integer,
    status integer DEFAULT 0,
    reviewed_by_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    answers json,
    completed_at timestamp without time zone,
    reviewed_at timestamp without time zone,
    reviewer character varying,
    deleted_at timestamp without time zone
);


--
-- Name: comprehensive_health_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comprehensive_health_assessments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comprehensive_health_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comprehensive_health_assessments_id_seq OWNED BY public.comprehensive_health_assessments.id;


--
-- Name: cp_member_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cp_member_files (
    id integer NOT NULL,
    type character varying,
    file character varying,
    content character varying,
    user_id integer,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: cp_member_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cp_member_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cp_member_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cp_member_files_id_seq OWNED BY public.cp_member_files.id;


--
-- Name: cps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cps (
    id integer NOT NULL,
    pid character varying,
    sl character varying,
    mmis_enrollment_name character varying,
    short_name character varying,
    pt_part_1 character varying,
    pt_part_2 character varying,
    address_1 character varying,
    city character varying,
    state character varying,
    zip character varying,
    key_contact_first_name character varying,
    key_contact_last_name character varying,
    key_contact_email character varying,
    key_contact_phone character varying,
    sender boolean DEFAULT false NOT NULL,
    receiver_name character varying,
    receiver_id character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    npi character varying,
    ein character varying,
    trace_id character varying(10),
    cp_name_official character varying,
    cp_assignment_plan character varying
);


--
-- Name: cps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cps_id_seq OWNED BY public.cps.id;


--
-- Name: data_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_sources (
    id integer NOT NULL,
    name character varying,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: data_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_sources_id_seq
    AS integer
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
-- Name: disenrollment_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.disenrollment_reasons (
    id bigint NOT NULL,
    reason_code character varying,
    reason_description character varying,
    referral_reason_code character varying
);


--
-- Name: disenrollment_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.disenrollment_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: disenrollment_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.disenrollment_reasons_id_seq OWNED BY public.disenrollment_reasons.id;


--
-- Name: document_exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.document_exports (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    type character varying NOT NULL,
    user_id bigint NOT NULL,
    export_version character varying NOT NULL,
    status character varying NOT NULL,
    query_string character varying,
    file_data bytea,
    filename character varying,
    mime_type character varying
);


--
-- Name: document_exports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.document_exports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: document_exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.document_exports_id_seq OWNED BY public.document_exports.id;


--
-- Name: ed_ip_visit_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ed_ip_visit_files (
    id integer NOT NULL,
    type character varying,
    file character varying,
    content character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    failed_at timestamp without time zone,
    message character varying
);


--
-- Name: ed_ip_visit_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ed_ip_visit_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ed_ip_visit_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ed_ip_visit_files_id_seq OWNED BY public.ed_ip_visit_files.id;


--
-- Name: ed_ip_visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ed_ip_visits (
    id bigint NOT NULL,
    loaded_ed_ip_visit_id bigint,
    medicaid_id character varying,
    admit_date date,
    encounter_major_class character varying,
    deleted_at timestamp without time zone
);


--
-- Name: ed_ip_visits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ed_ip_visits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ed_ip_visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ed_ip_visits_id_seq OWNED BY public.ed_ip_visits.id;


--
-- Name: eligibility_inquiries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eligibility_inquiries (
    id integer NOT NULL,
    service_date date NOT NULL,
    inquiry character varying,
    result character varying,
    isa_control_number integer NOT NULL,
    group_control_number integer NOT NULL,
    transaction_control_number integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    internal boolean DEFAULT false,
    batch_id integer,
    has_batch boolean DEFAULT false
);


--
-- Name: eligibility_inquiries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eligibility_inquiries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eligibility_inquiries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eligibility_inquiries_id_seq OWNED BY public.eligibility_inquiries.id;


--
-- Name: eligibility_responses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eligibility_responses (
    id integer NOT NULL,
    eligibility_inquiry_id integer,
    response character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    num_eligible integer,
    num_ineligible integer,
    user_id integer,
    original_filename character varying,
    deleted_at timestamp without time zone,
    num_errors integer,
    patient_aco_changes json,
    file character varying
);


--
-- Name: eligibility_responses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eligibility_responses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eligibility_responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eligibility_responses_id_seq OWNED BY public.eligibility_responses.id;


--
-- Name: encounter_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.encounter_records (
    id bigint NOT NULL,
    encounter_report_id bigint,
    medicaid_id character varying,
    date date,
    provider_name character varying,
    contact_reached boolean,
    mode_of_contact character varying,
    dob date,
    gender character varying,
    race character varying,
    ethnicity character varying,
    veteran_status character varying,
    housing_status character varying,
    source character varying,
    encounter_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: encounter_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.encounter_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: encounter_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.encounter_records_id_seq OWNED BY public.encounter_records.id;


--
-- Name: encounter_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.encounter_reports (
    id bigint NOT NULL,
    start_date timestamp without time zone,
    end_date timestamp without time zone,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    completed_at timestamp without time zone,
    started_at timestamp without time zone
);


--
-- Name: encounter_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.encounter_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: encounter_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.encounter_reports_id_seq OWNED BY public.encounter_reports.id;


--
-- Name: enrollment_reasons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enrollment_reasons (
    id bigint NOT NULL,
    file character varying,
    name character varying,
    size character varying,
    content_type character varying,
    content bytea,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: enrollment_reasons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.enrollment_reasons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enrollment_reasons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.enrollment_reasons_id_seq OWNED BY public.enrollment_reasons.id;


--
-- Name: enrollment_rosters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enrollment_rosters (
    id integer NOT NULL,
    roster_file_id integer,
    member_id character varying,
    performance_year character varying,
    region character varying,
    service_area character varying,
    aco_pidsl character varying,
    aco_name character varying,
    pcc_pidsl character varying,
    pcc_name character varying,
    pcc_npi character varying,
    pcc_taxid character varying,
    mco_pidsl character varying,
    mco_name character varying,
    enrolled_flag character varying,
    enroll_type character varying,
    enroll_stop_reason character varying,
    rating_category_char_cd character varying,
    ind_dds character varying,
    ind_dmh character varying,
    ind_dta character varying,
    ind_dss character varying,
    cde_hcb_waiver character varying,
    cde_waiver_category character varying,
    span_start_date date,
    span_end_date date,
    span_mem_days integer,
    cp_prov_type character varying,
    cp_plan_type character varying,
    cp_pidsl character varying,
    cp_prov_name character varying,
    cp_enroll_dt date,
    cp_disenroll_dt date,
    cp_start_rsn character varying,
    cp_stop_rsn character varying,
    ind_medicare_a character varying,
    ind_medicare_b character varying,
    tpl_coverage_cat character varying
);


--
-- Name: enrollment_rosters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.enrollment_rosters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enrollment_rosters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.enrollment_rosters_id_seq OWNED BY public.enrollment_rosters.id;


--
-- Name: enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enrollments (
    id integer NOT NULL,
    user_id integer,
    content character varying,
    original_filename character varying,
    status character varying,
    new_patients integer,
    returning_patients integer,
    disenrolled_patients integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    updated_patients integer,
    processing_errors jsonb DEFAULT '[]'::jsonb,
    audit_actions jsonb DEFAULT '{}'::jsonb
);


--
-- Name: enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.enrollments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.enrollments_id_seq OWNED BY public.enrollments.id;


--
-- Name: epic_careplans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.epic_careplans (
    id integer NOT NULL,
    patient_id character varying,
    id_in_source character varying,
    encounter_id character varying,
    encounter_type character varying,
    careplan_updated_at timestamp without time zone,
    staff character varying,
    part_1 text,
    part_2 text,
    part_3 text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    data_source_id integer
);


--
-- Name: epic_careplans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.epic_careplans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: epic_careplans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.epic_careplans_id_seq OWNED BY public.epic_careplans.id;


--
-- Name: epic_case_note_qualifying_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.epic_case_note_qualifying_activities (
    id integer NOT NULL,
    patient_id character varying,
    id_in_source character varying,
    epic_case_note_source_id character varying,
    encounter_type character varying,
    update_date timestamp without time zone,
    staff character varying,
    part_1 text,
    part_2 text,
    part_3 text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    data_source_id integer
);


--
-- Name: epic_case_note_qualifying_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.epic_case_note_qualifying_activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: epic_case_note_qualifying_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.epic_case_note_qualifying_activities_id_seq OWNED BY public.epic_case_note_qualifying_activities.id;


--
-- Name: epic_case_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.epic_case_notes (
    id integer NOT NULL,
    patient_id character varying NOT NULL,
    id_in_source character varying NOT NULL,
    contact_date timestamp without time zone,
    closed character varying,
    encounter_type character varying,
    provider_name character varying,
    location character varying,
    chief_complaint_1 character varying,
    chief_complaint_1_comment character varying,
    chief_complaint_2 character varying,
    chief_complaint_2_comment character varying,
    dx_1_icd10 character varying,
    dx_1_name character varying,
    dx_2_icd10 character varying,
    dx_2_name character varying,
    homeless_status character varying,
    data_source_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: epic_case_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.epic_case_notes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: epic_case_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.epic_case_notes_id_seq OWNED BY public.epic_case_notes.id;


--
-- Name: epic_chas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.epic_chas (
    id integer NOT NULL,
    patient_id character varying,
    id_in_source character varying,
    encounter_id character varying,
    encounter_type character varying,
    cha_updated_at timestamp without time zone,
    staff character varying,
    provider_type character varying,
    reviewer_name character varying,
    reviewer_provider_type character varying,
    part_1 text,
    part_2 text,
    part_3 text,
    part_4 text,
    part_5 text,
    part_6 text,
    part_7 text,
    part_8 text,
    part_9 text,
    part_10 text,
    part_11 text,
    part_12 text,
    part_13 text,
    part_14 text,
    part_15 text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    data_source_id integer
);


--
-- Name: epic_chas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.epic_chas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: epic_chas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.epic_chas_id_seq OWNED BY public.epic_chas.id;


--
-- Name: epic_goals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.epic_goals (
    id integer NOT NULL,
    patient_id character varying NOT NULL,
    entered_by character varying,
    title character varying,
    contents character varying,
    id_in_source character varying,
    received_valid_complaint character varying,
    goal_created_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    data_source_id integer DEFAULT 6 NOT NULL
);


--
-- Name: epic_goals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.epic_goals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: epic_goals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.epic_goals_id_seq OWNED BY public.epic_goals.id;


--
-- Name: epic_housing_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.epic_housing_statuses (
    id bigint NOT NULL,
    patient_id character varying NOT NULL,
    collected_on date NOT NULL,
    status character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: epic_housing_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.epic_housing_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: epic_housing_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.epic_housing_statuses_id_seq OWNED BY public.epic_housing_statuses.id;


--
-- Name: epic_patients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.epic_patients (
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
    gender character varying,
    consent_revoked timestamp without time zone,
    medicaid_id character varying,
    housing_status character varying,
    housing_status_timestamp timestamp without time zone,
    pilot boolean DEFAULT false NOT NULL,
    data_source_id integer DEFAULT 6 NOT NULL,
    deleted_at timestamp without time zone,
    death_date date
);


--
-- Name: epic_patients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.epic_patients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: epic_patients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.epic_patients_id_seq OWNED BY public.epic_patients.id;


--
-- Name: epic_qualifying_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.epic_qualifying_activities (
    id integer NOT NULL,
    patient_id character varying NOT NULL,
    id_in_source character varying NOT NULL,
    patient_encounter_id character varying,
    entered_by character varying,
    role character varying,
    date_of_activity date,
    activity character varying,
    mode character varying,
    reached character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    data_source_id integer
);


--
-- Name: epic_qualifying_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.epic_qualifying_activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: epic_qualifying_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.epic_qualifying_activities_id_seq OWNED BY public.epic_qualifying_activities.id;


--
-- Name: epic_ssms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.epic_ssms (
    id integer NOT NULL,
    patient_id character varying,
    id_in_source character varying,
    encounter_id character varying,
    encounter_type character varying,
    ssm_updated_at timestamp without time zone,
    staff character varying,
    part_1 text,
    part_2 text,
    part_3 text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    data_source_id integer
);


--
-- Name: epic_ssms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.epic_ssms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: epic_ssms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.epic_ssms_id_seq OWNED BY public.epic_ssms.id;


--
-- Name: epic_team_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.epic_team_members (
    id integer NOT NULL,
    patient_id character varying NOT NULL,
    id_in_source character varying,
    name character varying,
    pcp_type character varying,
    relationship character varying,
    email character varying,
    phone character varying,
    processed timestamp without time zone,
    data_source_id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: epic_team_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.epic_team_members_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: epic_team_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.epic_team_members_id_seq OWNED BY public.epic_team_members.id;


--
-- Name: equipment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.equipment (
    id integer NOT NULL,
    item character varying,
    provider character varying,
    quantity integer,
    effective_date date,
    comments character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    patient_id integer,
    status character varying
);


--
-- Name: equipment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.equipment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: equipment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.equipment_id_seq OWNED BY public.equipment.id;


--
-- Name: health_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_files (
    id integer NOT NULL,
    type character varying NOT NULL,
    file character varying,
    content_type character varying,
    content bytea,
    client_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    note character varying,
    name character varying,
    size double precision,
    parent_id integer
);


--
-- Name: health_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.health_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.health_files_id_seq OWNED BY public.health_files.id;


--
-- Name: health_flexible_service_follow_ups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_flexible_service_follow_ups (
    id bigint NOT NULL,
    patient_id bigint NOT NULL,
    user_id bigint NOT NULL,
    completed_on date,
    first_name character varying,
    middle_name character varying,
    last_name character varying,
    dob date,
    delivery_first_name character varying,
    delivery_last_name character varying,
    delivery_organization character varying,
    delivery_phone character varying,
    delivery_email character varying,
    reviewer_first_name character varying,
    reviewer_last_name character varying,
    reviewer_organization character varying,
    reviewer_phone character varying,
    reviewer_email character varying,
    services_completed text,
    goal_status text,
    additional_flex_services_requested boolean,
    additional_flex_services_requested_detail text,
    agreement_to_flex_services boolean,
    agreement_to_flex_services_detail character varying,
    aco_approved_flex_services boolean,
    aco_approved_flex_services_detail character varying,
    aco_approved_flex_services_on date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: health_flexible_service_follow_ups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.health_flexible_service_follow_ups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_flexible_service_follow_ups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.health_flexible_service_follow_ups_id_seq OWNED BY public.health_flexible_service_follow_ups.id;


--
-- Name: health_flexible_service_vprs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_flexible_service_vprs (
    id bigint NOT NULL,
    patient_id bigint NOT NULL,
    user_id bigint NOT NULL,
    planned_on date,
    first_name character varying,
    middle_name character varying,
    last_name character varying,
    dob date,
    accommodations_needed character varying,
    contact_type character varying,
    phone character varying,
    email character varying,
    additional_contact_details text,
    main_contact_first_name character varying,
    main_contact_last_name character varying,
    main_contact_organization character varying,
    main_contact_phone character varying,
    main_contact_email character varying,
    reviewer_first_name character varying,
    reviewer_last_name character varying,
    reviewer_organization character varying,
    reviewer_phone character varying,
    reviewer_email character varying,
    representative_first_name character varying,
    representative_last_name character varying,
    representative_organization character varying,
    representative_phone character varying,
    representative_email character varying,
    member_agrees_to_plan boolean,
    member_agreement_notes text,
    aco_approved boolean,
    aco_approved_on date,
    aco_rejection_notes text,
    health_needs_screened_on date,
    complex_physical_health_need boolean,
    complex_physical_health_need_detail character varying,
    behavioral_health_need boolean,
    behavioral_health_need_detail character varying,
    activities_of_daily_living boolean,
    activities_of_daily_living_detail character varying,
    ed_utilization boolean,
    ed_utilization_detail character varying,
    high_risk_pregnancy boolean,
    high_risk_pregnancy_detail character varying,
    risk_factors_screened_on date,
    experiencing_homelessness boolean,
    experiencing_homelessness_detail character varying,
    at_risk_of_homelessness boolean,
    at_risk_of_homelessness_detail character varying,
    at_risk_of_nutritional_deficiency boolean,
    at_risk_of_nutritional_deficiency_detail character varying,
    health_and_risk_notes text,
    receives_snap boolean,
    receives_wic boolean,
    receives_csp boolean,
    receives_other boolean,
    receives_other_detail character varying,
    service_1_added_on date,
    service_1_goals character varying,
    service_1_category character varying,
    service_1_flex_services character varying,
    service_1_units character varying,
    service_1_delivering_entity character varying,
    service_1_steps character varying,
    service_1_aco_plan character varying,
    service_2_added_on date,
    service_2_goals character varying,
    service_2_category character varying,
    service_2_flex_services character varying,
    service_2_units character varying,
    service_2_delivering_entity character varying,
    service_2_steps character varying,
    service_2_aco_plan character varying,
    service_3_added_on date,
    service_3_goals character varying,
    service_3_category character varying,
    service_3_flex_services character varying,
    service_3_units character varying,
    service_3_delivering_entity character varying,
    service_3_steps character varying,
    service_3_aco_plan character varying,
    service_4_added_on date,
    service_4_goals character varying,
    service_4_category character varying,
    service_4_flex_services character varying,
    service_4_units character varying,
    service_4_delivering_entity character varying,
    service_4_steps character varying,
    service_4_aco_plan character varying,
    service_5_added_on date,
    service_5_goals character varying,
    service_5_category character varying,
    service_5_flex_services character varying,
    service_5_units character varying,
    service_5_delivering_entity character varying,
    service_5_steps character varying,
    service_5_aco_plan character varying,
    service_6_added_on date,
    service_6_goals character varying,
    service_6_category character varying,
    service_6_flex_services character varying,
    service_6_units character varying,
    service_6_delivering_entity character varying,
    service_6_steps character varying,
    service_6_aco_plan character varying,
    service_7_added_on date,
    service_7_goals character varying,
    service_7_category character varying,
    service_7_flex_services character varying,
    service_7_units character varying,
    service_7_delivering_entity character varying,
    service_7_steps character varying,
    service_7_aco_plan character varying,
    service_8_added_on date,
    service_8_goals character varying,
    service_8_category character varying,
    service_8_flex_services character varying,
    service_8_units character varying,
    service_8_delivering_entity character varying,
    service_8_steps character varying,
    service_8_aco_plan character varying,
    service_9_added_on date,
    service_9_goals character varying,
    service_9_category character varying,
    service_9_flex_services character varying,
    service_9_units character varying,
    service_9_delivering_entity character varying,
    service_9_steps character varying,
    service_9_aco_plan character varying,
    service_10_added_on date,
    service_10_goals character varying,
    service_10_category character varying,
    service_10_flex_services character varying,
    service_10_units character varying,
    service_10_delivering_entity character varying,
    service_10_steps character varying,
    service_10_aco_plan character varying,
    gender character varying,
    gender_detail character varying,
    sexual_orientation character varying,
    sexual_orientation_detail character varying,
    race jsonb,
    race_detail character varying,
    primary_language character varying,
    primary_language_refused boolean,
    education character varying,
    education_detail character varying,
    employment_status character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: health_flexible_service_vprs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.health_flexible_service_vprs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_flexible_service_vprs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.health_flexible_service_vprs_id_seq OWNED BY public.health_flexible_service_vprs.id;


--
-- Name: health_goals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_goals (
    id integer NOT NULL,
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
    goal_details text,
    problem text,
    start_date date,
    intervention text,
    status character varying,
    responsible_team_member_id integer,
    patient_id integer,
    timeframe text,
    action_step_0 character varying,
    timeframe_0 character varying,
    action_step_1 character varying,
    timeframe_1 character varying,
    action_step_2 character varying,
    timeframe_2 character varying,
    action_step_3 character varying,
    timeframe_3 character varying,
    action_step_4 character varying,
    timeframe_4 character varying,
    action_step_5 character varying,
    timeframe_5 character varying,
    action_step_6 character varying,
    timeframe_6 character varying,
    action_step_7 character varying,
    timeframe_7 character varying,
    action_step_8 character varying,
    timeframe_8 character varying,
    action_step_9 character varying,
    timeframe_9 character varying
);


--
-- Name: health_goals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.health_goals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_goals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.health_goals_id_seq OWNED BY public.health_goals.id;


--
-- Name: hl7_value_set_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hl7_value_set_codes (
    id bigint NOT NULL,
    value_set_name character varying NOT NULL,
    value_set_oid character varying NOT NULL,
    value_set_version character varying,
    code_system character varying NOT NULL,
    code_system_oid character varying,
    code_system_version character varying,
    code character varying NOT NULL,
    definition character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: hl7_value_set_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hl7_value_set_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hl7_value_set_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hl7_value_set_codes_id_seq OWNED BY public.hl7_value_set_codes.id;


--
-- Name: loaded_ed_ip_visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.loaded_ed_ip_visits (
    id integer NOT NULL,
    ed_ip_visit_file_id integer NOT NULL,
    medicaid_id character varying,
    last_name character varying,
    first_name character varying,
    gender character varying,
    dob date,
    admit_date date,
    discharge_date date,
    discharge_disposition character varying,
    encounter_major_class character varying,
    visit_type character varying,
    encounter_facility character varying,
    chief_complaint character varying,
    diagnosis character varying,
    attending_physician character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    member_record_number character varying,
    patient_identifier character varying,
    patient_url character varying,
    admitted_inpatient character varying
);


--
-- Name: loaded_ed_ip_visits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.loaded_ed_ip_visits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: loaded_ed_ip_visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.loaded_ed_ip_visits_id_seq OWNED BY public.loaded_ed_ip_visits.id;


--
-- Name: medications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.medications (
    id integer NOT NULL,
    start_date date,
    ordered_date date,
    name text,
    instructions text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    id_in_source character varying,
    patient_id character varying,
    data_source_id integer DEFAULT 6 NOT NULL
);


--
-- Name: medications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.medications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: medications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.medications_id_seq OWNED BY public.medications.id;


--
-- Name: member_status_report_patients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_status_report_patients (
    id integer NOT NULL,
    member_status_report_id integer,
    medicaid_id character varying(12),
    member_first_name character varying(100),
    member_last_name character varying(100),
    member_middle_initial character varying(1),
    member_suffix character varying(20),
    member_date_of_birth date,
    member_sex character varying(1),
    aco_mco_name character varying(100),
    aco_mco_pid character varying(9),
    aco_mco_sl character varying(10),
    cp_name_official character varying(100),
    cp_pid character varying(9),
    cp_sl character varying(10),
    cp_outreach_status character varying(30),
    cp_last_contact_date date,
    cp_last_contact_face character varying(1),
    cp_contact_face character varying,
    cp_participation_form_date date,
    cp_care_plan_sent_pcp_date date,
    cp_care_plan_returned_pcp_date date,
    key_contact_name_first character varying(100),
    key_contact_name_last character varying(100),
    key_contact_phone character varying(10),
    key_contact_email character varying(60),
    care_coordinator_first_name character varying(100),
    care_coordinator_last_name character varying(100),
    care_coordinator_phone character varying(10),
    care_coordinator_email character varying(60),
    record_status character varying(1),
    record_update_date date,
    export_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: member_status_report_patients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_status_report_patients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_status_report_patients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.member_status_report_patients_id_seq OWNED BY public.member_status_report_patients.id;


--
-- Name: member_status_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.member_status_reports (
    id integer NOT NULL,
    user_id integer,
    job_id integer,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    sender character varying(100),
    sent_row_num integer,
    sent_column_num integer,
    sent_export_time_stamp timestamp without time zone,
    receiver character varying,
    report_start_date date,
    report_end_date date,
    error character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    effective_date date
);


--
-- Name: member_status_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.member_status_reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: member_status_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.member_status_reports_id_seq OWNED BY public.member_status_reports.id;


--
-- Name: participation_forms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.participation_forms (
    id integer NOT NULL,
    patient_id integer,
    signature_on date,
    case_manager_id integer,
    reviewed_by_id integer,
    location character varying,
    health_file_id integer,
    reviewed_at timestamp without time zone,
    reviewer character varying
);


--
-- Name: participation_forms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.participation_forms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: participation_forms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.participation_forms_id_seq OWNED BY public.participation_forms.id;


--
-- Name: patient_referral_imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patient_referral_imports (
    id integer NOT NULL,
    file_name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: patient_referral_imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.patient_referral_imports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: patient_referral_imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.patient_referral_imports_id_seq OWNED BY public.patient_referral_imports.id;


--
-- Name: patient_referrals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patient_referrals (
    id integer NOT NULL,
    first_name character varying,
    last_name character varying,
    birthdate date,
    ssn character varying,
    medicaid_id character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    agency_id integer,
    rejected boolean DEFAULT false NOT NULL,
    rejected_reason integer DEFAULT 0 NOT NULL,
    patient_id integer,
    accountable_care_organization_id integer,
    middle_initial character varying,
    suffix character varying,
    gender character varying,
    aco_name character varying,
    aco_mco_pid integer,
    aco_mco_sl character varying,
    health_plan_id character varying,
    cp_assignment_plan character varying,
    cp_name_dsrip character varying,
    cp_name_official character varying,
    cp_pid integer,
    cp_sl character varying,
    enrollment_start_date date,
    start_reason_description character varying,
    address_line_1 character varying,
    address_line_2 character varying,
    address_city character varying,
    address_state character varying,
    address_zip character varying,
    address_zip_plus_4 character varying,
    email character varying,
    phone_cell character varying,
    phone_day character varying,
    phone_night character varying,
    primary_language character varying,
    primary_diagnosis character varying,
    secondary_diagnosis character varying,
    pcp_last_name character varying,
    pcp_first_name character varying,
    pcp_npi character varying,
    pcp_address_line_1 character varying,
    pcp_address_line_2 character varying,
    pcp_address_city character varying,
    pcp_address_state character varying,
    pcp_address_zip character varying,
    pcp_address_phone character varying,
    dmh character varying,
    dds character varying,
    eoea character varying,
    ed_visits character varying,
    snf_discharge character varying,
    identification character varying,
    record_status character varying,
    record_updated_on date,
    exported_on date,
    removal_acknowledged boolean DEFAULT false NOT NULL,
    effective_date timestamp without time zone,
    disenrollment_date date,
    stop_reason_description character varying,
    pending_disenrollment_date date,
    current boolean DEFAULT false NOT NULL,
    contributing boolean DEFAULT false NOT NULL,
    derived_referral boolean DEFAULT false,
    deleted_at timestamp without time zone,
    change_description character varying
);


--
-- Name: patient_referrals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.patient_referrals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: patient_referrals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.patient_referrals_id_seq OWNED BY public.patient_referrals.id;


--
-- Name: patients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.patients (
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
    consent_revoked timestamp without time zone,
    medicaid_id character varying,
    housing_status character varying,
    housing_status_timestamp timestamp without time zone,
    pilot boolean DEFAULT false NOT NULL,
    data_source_id integer DEFAULT 6 NOT NULL,
    engagement_date date,
    care_coordinator_id integer,
    deleted_at timestamp without time zone,
    death_date date,
    coverage_level character varying,
    coverage_inquiry_date date,
    eligibility_notification timestamp without time zone,
    aco_name character varying,
    previous_aco_name character varying,
    invalid_id boolean DEFAULT false,
    nurse_care_manager_id bigint
);


--
-- Name: patients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.patients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: patients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.patients_id_seq OWNED BY public.patients.id;


--
-- Name: premium_payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.premium_payments (
    id integer NOT NULL,
    user_id integer,
    content text,
    original_filename character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    converted_content jsonb,
    started_at timestamp without time zone,
    completed_at timestamp without time zone
);


--
-- Name: premium_payments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.premium_payments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: premium_payments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.premium_payments_id_seq OWNED BY public.premium_payments.id;


--
-- Name: problems; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.problems (
    id integer NOT NULL,
    onset_date date,
    last_assessed date,
    name text,
    comment text,
    icd10_list character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    id_in_source character varying,
    patient_id character varying,
    data_source_id integer DEFAULT 6 NOT NULL
);


--
-- Name: problems_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.problems_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: problems_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.problems_id_seq OWNED BY public.problems.id;


--
-- Name: qualifying_activities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.qualifying_activities (
    id integer NOT NULL,
    mode_of_contact character varying,
    mode_of_contact_other character varying,
    reached_client character varying,
    reached_client_collateral_contact character varying,
    activity character varying,
    source_type character varying,
    source_id integer,
    claim_submitted_on timestamp without time zone,
    date_of_activity date,
    user_id integer,
    user_full_name character varying,
    follow_up character varying,
    patient_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    claim_id integer,
    force_payable boolean DEFAULT false NOT NULL,
    naturally_payable boolean DEFAULT false NOT NULL,
    sent_at timestamp without time zone,
    duplicate_id integer,
    epic_source_id character varying,
    valid_unpayable boolean DEFAULT false NOT NULL,
    procedure_valid boolean DEFAULT false NOT NULL,
    ignored boolean DEFAULT false
);


--
-- Name: qualifying_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.qualifying_activities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: qualifying_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.qualifying_activities_id_seq OWNED BY public.qualifying_activities.id;


--
-- Name: release_forms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.release_forms (
    id integer NOT NULL,
    patient_id integer,
    user_id integer,
    signature_on date,
    file_location character varying,
    health_file_id integer,
    reviewed_by_id integer,
    reviewed_at timestamp without time zone,
    reviewer character varying
);


--
-- Name: release_forms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.release_forms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: release_forms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.release_forms_id_seq OWNED BY public.release_forms.id;


--
-- Name: rosters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rosters (
    id integer NOT NULL,
    roster_file_id integer,
    member_id character varying,
    nam_first character varying,
    nam_last character varying,
    cp_pidsl character varying,
    cp_name character varying,
    aco_pidsl character varying,
    aco_name character varying,
    mco_pidsl character varying,
    mco_name character varying,
    sex character varying,
    date_of_birth date,
    mailing_address_1 character varying,
    mailing_address_2 character varying,
    mailing_city character varying,
    mailing_state character varying,
    mailing_zip character varying,
    residential_address_1 character varying,
    residential_address_2 character varying,
    residential_city character varying,
    residential_state character varying,
    residential_zip character varying,
    race character varying,
    phone_number character varying,
    primary_language_s character varying,
    primary_language_w character varying,
    sdh_nss7_score character varying,
    sdh_homelessness character varying,
    sdh_addresses_flag character varying,
    sdh_other_disabled character varying,
    sdh_spmi character varying,
    raw_risk_score character varying,
    normalized_risk_score character varying,
    raw_dxcg_risk_score character varying,
    last_office_visit date,
    last_ed_visit date,
    last_ip_visit date,
    enrolled_flag character varying,
    enrollment_status character varying,
    cp_claim_dt date,
    qualifying_hcpcs character varying,
    qualifying_hcpcs_nm character varying,
    qualifying_dsc character varying,
    email character varying,
    head_of_household character varying
);


--
-- Name: rosters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rosters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rosters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rosters_id_seq OWNED BY public.rosters.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sdh_case_management_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sdh_case_management_notes (
    id integer NOT NULL,
    user_id integer,
    patient_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    topics text,
    title character varying,
    total_time_spent_in_minutes integer,
    date_of_contact timestamp without time zone,
    place_of_contact character varying,
    housing_status character varying,
    place_of_contact_other character varying,
    housing_status_other character varying,
    housing_placement_date timestamp without time zone,
    client_action text,
    notes_from_encounter text,
    client_phone_number character varying,
    completed_on timestamp without time zone,
    health_file_id integer,
    client_action_medication_reconciliation_clinician character varying
);


--
-- Name: sdh_case_management_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sdh_case_management_notes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sdh_case_management_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sdh_case_management_notes_id_seq OWNED BY public.sdh_case_management_notes.id;


--
-- Name: self_sufficiency_matrix_forms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.self_sufficiency_matrix_forms (
    id integer NOT NULL,
    patient_id integer,
    user_id integer,
    point_completed character varying,
    housing_score integer,
    housing_notes text,
    income_score integer,
    income_notes text,
    benefits_score integer,
    benefits_notes text,
    disabilities_score integer,
    disabilities_notes text,
    food_score integer,
    food_notes text,
    employment_score integer,
    employment_notes text,
    education_score integer,
    education_notes text,
    mobility_score integer,
    mobility_notes text,
    life_score integer,
    life_notes text,
    healthcare_score integer,
    healthcare_notes text,
    physical_health_score integer,
    physical_health_notes text,
    mental_health_score integer,
    mental_health_notes text,
    substance_abuse_score integer,
    substance_abuse_notes text,
    criminal_score integer,
    criminal_notes text,
    legal_score integer,
    legal_notes text,
    safety_score integer,
    safety_notes text,
    risk_score integer,
    risk_notes text,
    family_score integer,
    family_notes text,
    community_score integer,
    community_notes text,
    time_score integer,
    time_notes text,
    completed_at timestamp without time zone,
    collection_location character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    health_file_id integer
);


--
-- Name: self_sufficiency_matrix_forms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.self_sufficiency_matrix_forms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: self_sufficiency_matrix_forms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.self_sufficiency_matrix_forms_id_seq OWNED BY public.self_sufficiency_matrix_forms.id;


--
-- Name: services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.services (
    id integer NOT NULL,
    service_type character varying,
    provider character varying,
    hours character varying,
    days character varying,
    date_requested date,
    effective_date date,
    end_date date,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    patient_id integer,
    status character varying
);


--
-- Name: services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.services_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.services_id_seq OWNED BY public.services.id;


--
-- Name: signable_documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.signable_documents (
    id integer NOT NULL,
    signable_id integer NOT NULL,
    signable_type character varying NOT NULL,
    "primary" boolean DEFAULT true NOT NULL,
    user_id integer NOT NULL,
    hs_initial_request jsonb,
    hs_initial_response jsonb,
    hs_initial_response_at timestamp without time zone,
    hs_last_response jsonb,
    hs_last_response_at timestamp without time zone,
    hs_subject character varying DEFAULT 'Signature Request'::character varying NOT NULL,
    hs_title character varying DEFAULT 'Signature Request'::character varying NOT NULL,
    hs_message text DEFAULT 'You''ve been asked to sign a document.'::text,
    signers jsonb DEFAULT '[]'::jsonb NOT NULL,
    signed_by jsonb DEFAULT '[]'::jsonb NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    expires_at timestamp without time zone,
    health_file_id integer
);


--
-- Name: signable_documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.signable_documents_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: signable_documents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.signable_documents_id_seq OWNED BY public.signable_documents.id;


--
-- Name: signature_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.signature_requests (
    id integer NOT NULL,
    type character varying NOT NULL,
    patient_id integer NOT NULL,
    careplan_id integer NOT NULL,
    to_email character varying NOT NULL,
    to_name character varying NOT NULL,
    requestor_email character varying NOT NULL,
    requestor_name character varying NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    sent_at timestamp without time zone,
    completed_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    signable_document_id integer
);


--
-- Name: signature_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.signature_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: signature_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.signature_requests_id_seq OWNED BY public.signature_requests.id;


--
-- Name: soap_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.soap_configs (
    id integer NOT NULL,
    name character varying,
    "user" character varying,
    encrypted_pass character varying,
    encrypted_pass_iv character varying,
    sender character varying,
    receiver character varying,
    test_url character varying,
    production_url character varying
);


--
-- Name: soap_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.soap_configs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: soap_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.soap_configs_id_seq OWNED BY public.soap_configs.id;


--
-- Name: ssm_exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ssm_exports (
    id integer NOT NULL,
    user_id integer NOT NULL,
    options jsonb,
    headers jsonb,
    rows jsonb,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: ssm_exports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ssm_exports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ssm_exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ssm_exports_id_seq OWNED BY public.ssm_exports.id;


--
-- Name: status_dates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.status_dates (
    id bigint NOT NULL,
    patient_id bigint NOT NULL,
    date date NOT NULL,
    engaged boolean NOT NULL,
    enrolled boolean NOT NULL
);


--
-- Name: status_dates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.status_dates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: status_dates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.status_dates_id_seq OWNED BY public.status_dates.id;


--
-- Name: team_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_members (
    id integer NOT NULL,
    type character varying NOT NULL,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    email character varying,
    organization character varying,
    title character varying,
    last_contact date,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer,
    phone character varying,
    patient_id integer
);


--
-- Name: team_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.team_members_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: team_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.team_members_id_seq OWNED BY public.team_members.id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams (
    id integer NOT NULL,
    patient_id integer,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer,
    careplan_id integer
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teams_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.teams_id_seq OWNED BY public.teams.id;


--
-- Name: tracing_cases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tracing_cases (
    id bigint NOT NULL,
    client_id integer,
    health_emergency character varying NOT NULL,
    investigator character varying,
    date_listed date,
    alert_in_epic character varying,
    complete character varying,
    date_interviewed date,
    infectious_start_date date,
    testing_date date,
    isolation_start_date date,
    first_name character varying,
    last_name character varying,
    aliases character varying,
    dob date,
    gender integer,
    race jsonb,
    ethnicity integer,
    preferred_language character varying,
    occupation character varying,
    recent_incarceration character varying,
    notes character varying,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    day_two date,
    phone character varying,
    symptoms jsonb,
    other_symptoms character varying,
    vaccinated character varying,
    vaccine jsonb,
    vaccination_dates jsonb,
    vaccination_complete character varying
);


--
-- Name: tracing_cases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tracing_cases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracing_cases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tracing_cases_id_seq OWNED BY public.tracing_cases.id;


--
-- Name: tracing_contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tracing_contacts (
    id bigint NOT NULL,
    case_id bigint,
    date_interviewed date,
    first_name character varying,
    last_name character varying,
    aliases character varying,
    phone_number character varying,
    address character varying,
    dob date,
    estimated_age character varying,
    gender integer,
    race jsonb,
    ethnicity integer,
    preferred_language character varying,
    relationship_to_index_case character varying,
    location_of_exposure character varying,
    nature_of_exposure character varying,
    location_of_contact character varying,
    sleeping_location character varying,
    symptomatic character varying,
    symptom_onset_date date,
    referred_for_testing character varying,
    test_result character varying,
    isolated character varying,
    isolation_location character varying,
    quarantine character varying,
    quarantine_location character varying,
    notes character varying,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    investigator character varying,
    alert_in_epic character varying,
    notified character varying,
    symptoms jsonb,
    other_symptoms character varying,
    vaccinated character varying,
    vaccine jsonb,
    vaccination_dates jsonb,
    vaccination_complete character varying
);


--
-- Name: tracing_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tracing_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracing_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tracing_contacts_id_seq OWNED BY public.tracing_contacts.id;


--
-- Name: tracing_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tracing_locations (
    id bigint NOT NULL,
    case_id bigint,
    location character varying,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tracing_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tracing_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracing_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tracing_locations_id_seq OWNED BY public.tracing_locations.id;


--
-- Name: tracing_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tracing_results (
    id bigint NOT NULL,
    contact_id bigint,
    test_result character varying,
    isolated character varying,
    isolation_location character varying,
    quarantine character varying,
    quarantine_location character varying,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: tracing_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tracing_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracing_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tracing_results_id_seq OWNED BY public.tracing_results.id;


--
-- Name: tracing_site_leaders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tracing_site_leaders (
    id bigint NOT NULL,
    case_id bigint,
    site_name character varying,
    site_leader_name character varying,
    contacted_on date,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    investigator character varying
);


--
-- Name: tracing_site_leaders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tracing_site_leaders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracing_site_leaders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tracing_site_leaders_id_seq OWNED BY public.tracing_site_leaders.id;


--
-- Name: tracing_staffs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tracing_staffs (
    id bigint NOT NULL,
    case_id bigint,
    date_interviewed date,
    first_name character varying,
    last_name character varying,
    site_name character varying,
    nature_of_exposure character varying,
    symptomatic character varying,
    referred_for_testing character varying,
    test_result character varying,
    notes character varying,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    notified character varying,
    dob date,
    estimated_age character varying,
    gender integer,
    address character varying,
    phone_number character varying,
    symptoms jsonb,
    other_symptoms character varying,
    investigator character varying,
    vaccinated character varying,
    vaccine jsonb,
    vaccination_dates jsonb,
    vaccination_complete character varying
);


--
-- Name: tracing_staffs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tracing_staffs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tracing_staffs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tracing_staffs_id_seq OWNED BY public.tracing_staffs.id;


--
-- Name: transaction_acknowledgements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transaction_acknowledgements (
    id integer NOT NULL,
    user_id integer,
    content text,
    original_filename character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: transaction_acknowledgements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.transaction_acknowledgements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transaction_acknowledgements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.transaction_acknowledgements_id_seq OWNED BY public.transaction_acknowledgements.id;


--
-- Name: user_care_coordinators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_care_coordinators (
    id integer NOT NULL,
    user_id integer,
    care_coordinator_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: user_care_coordinators_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_care_coordinators_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_care_coordinators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_care_coordinators_id_seq OWNED BY public.user_care_coordinators.id;


--
-- Name: vaccinations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vaccinations (
    id bigint NOT NULL,
    client_id integer,
    epic_patient_id character varying NOT NULL,
    medicaid_id character varying,
    first_name character varying,
    last_name character varying,
    dob date,
    ssn character varying,
    vaccinated_on date NOT NULL,
    vaccinated_at character varying,
    vaccination_type character varying NOT NULL,
    follow_up_cell_phone character varying,
    existed_previously boolean DEFAULT false NOT NULL,
    data_source_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    preferred_language character varying DEFAULT 'en'::character varying,
    epic_row_created timestamp without time zone,
    epic_row_updated timestamp without time zone
);


--
-- Name: vaccinations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vaccinations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vaccinations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vaccinations_id_seq OWNED BY public.vaccinations.id;


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
-- Name: visits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visits (
    id integer NOT NULL,
    department character varying,
    visit_type character varying,
    provider character varying,
    id_in_source character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    patient_id character varying,
    date_of_service timestamp without time zone,
    data_source_id integer DEFAULT 6 NOT NULL
);


--
-- Name: visits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.visits_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: visits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.visits_id_seq OWNED BY public.visits.id;


--
-- Name: accountable_care_organizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accountable_care_organizations ALTER COLUMN id SET DEFAULT nextval('public.accountable_care_organizations_id_seq'::regclass);


--
-- Name: agencies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agencies ALTER COLUMN id SET DEFAULT nextval('public.agencies_id_seq'::regclass);


--
-- Name: agency_patient_referrals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_patient_referrals ALTER COLUMN id SET DEFAULT nextval('public.agency_patient_referrals_id_seq'::regclass);


--
-- Name: agency_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_users ALTER COLUMN id SET DEFAULT nextval('public.agency_users_id_seq'::regclass);


--
-- Name: appointments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments ALTER COLUMN id SET DEFAULT nextval('public.appointments_id_seq'::regclass);


--
-- Name: backup_plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.backup_plans ALTER COLUMN id SET DEFAULT nextval('public.backup_plans_id_seq'::regclass);


--
-- Name: careplan_equipment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.careplan_equipment ALTER COLUMN id SET DEFAULT nextval('public.careplan_equipment_id_seq'::regclass);


--
-- Name: careplan_services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.careplan_services ALTER COLUMN id SET DEFAULT nextval('public.careplan_services_id_seq'::regclass);


--
-- Name: careplans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.careplans ALTER COLUMN id SET DEFAULT nextval('public.careplans_id_seq'::regclass);


--
-- Name: claims id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims ALTER COLUMN id SET DEFAULT nextval('public.claims_id_seq'::regclass);


--
-- Name: claims_amount_paid_location_month id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_amount_paid_location_month ALTER COLUMN id SET DEFAULT nextval('public.claims_amount_paid_location_month_id_seq'::regclass);


--
-- Name: claims_claim_volume_location_month id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_claim_volume_location_month ALTER COLUMN id SET DEFAULT nextval('public.claims_claim_volume_location_month_id_seq'::regclass);


--
-- Name: claims_ed_nyu_severity id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_ed_nyu_severity ALTER COLUMN id SET DEFAULT nextval('public.claims_ed_nyu_severity_id_seq'::regclass);


--
-- Name: claims_reporting_ccs_lookups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_ccs_lookups ALTER COLUMN id SET DEFAULT nextval('public.claims_reporting_ccs_lookups_id_seq'::regclass);


--
-- Name: claims_reporting_cp_payment_details id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_cp_payment_details ALTER COLUMN id SET DEFAULT nextval('public.claims_reporting_cp_payment_details_id_seq'::regclass);


--
-- Name: claims_reporting_cp_payment_uploads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_cp_payment_uploads ALTER COLUMN id SET DEFAULT nextval('public.claims_reporting_cp_payment_uploads_id_seq'::regclass);


--
-- Name: claims_reporting_engagement_trends id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_engagement_trends ALTER COLUMN id SET DEFAULT nextval('public.claims_reporting_engagement_trends_id_seq'::regclass);


--
-- Name: claims_reporting_imports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_imports ALTER COLUMN id SET DEFAULT nextval('public.claims_reporting_imports_id_seq'::regclass);


--
-- Name: claims_reporting_medical_claims id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_medical_claims ALTER COLUMN id SET DEFAULT nextval('public.claims_reporting_medical_claims_id_seq'::regclass);


--
-- Name: claims_reporting_member_diagnosis_classifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_member_diagnosis_classifications ALTER COLUMN id SET DEFAULT nextval('public.claims_reporting_member_diagnosis_classifications_id_seq'::regclass);


--
-- Name: claims_reporting_member_enrollment_rosters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_member_enrollment_rosters ALTER COLUMN id SET DEFAULT nextval('public.claims_reporting_member_enrollment_rosters_id_seq'::regclass);


--
-- Name: claims_reporting_member_rosters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_member_rosters ALTER COLUMN id SET DEFAULT nextval('public.claims_reporting_member_rosters_id_seq'::regclass);


--
-- Name: claims_reporting_quality_measures id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_quality_measures ALTER COLUMN id SET DEFAULT nextval('public.claims_reporting_quality_measures_id_seq'::regclass);


--
-- Name: claims_reporting_rx_claims id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_rx_claims ALTER COLUMN id SET DEFAULT nextval('public.claims_reporting_rx_claims_id_seq'::regclass);


--
-- Name: claims_roster id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_roster ALTER COLUMN id SET DEFAULT nextval('public.claims_roster_id_seq'::regclass);


--
-- Name: claims_top_conditions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_top_conditions ALTER COLUMN id SET DEFAULT nextval('public.claims_top_conditions_id_seq'::regclass);


--
-- Name: claims_top_ip_conditions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_top_ip_conditions ALTER COLUMN id SET DEFAULT nextval('public.claims_top_ip_conditions_id_seq'::regclass);


--
-- Name: claims_top_providers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_top_providers ALTER COLUMN id SET DEFAULT nextval('public.claims_top_providers_id_seq'::regclass);


--
-- Name: comprehensive_health_assessments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comprehensive_health_assessments ALTER COLUMN id SET DEFAULT nextval('public.comprehensive_health_assessments_id_seq'::regclass);


--
-- Name: cp_member_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cp_member_files ALTER COLUMN id SET DEFAULT nextval('public.cp_member_files_id_seq'::regclass);


--
-- Name: cps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cps ALTER COLUMN id SET DEFAULT nextval('public.cps_id_seq'::regclass);


--
-- Name: data_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sources ALTER COLUMN id SET DEFAULT nextval('public.data_sources_id_seq'::regclass);


--
-- Name: disenrollment_reasons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disenrollment_reasons ALTER COLUMN id SET DEFAULT nextval('public.disenrollment_reasons_id_seq'::regclass);


--
-- Name: document_exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_exports ALTER COLUMN id SET DEFAULT nextval('public.document_exports_id_seq'::regclass);


--
-- Name: ed_ip_visit_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ed_ip_visit_files ALTER COLUMN id SET DEFAULT nextval('public.ed_ip_visit_files_id_seq'::regclass);


--
-- Name: ed_ip_visits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ed_ip_visits ALTER COLUMN id SET DEFAULT nextval('public.ed_ip_visits_id_seq'::regclass);


--
-- Name: eligibility_inquiries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eligibility_inquiries ALTER COLUMN id SET DEFAULT nextval('public.eligibility_inquiries_id_seq'::regclass);


--
-- Name: eligibility_responses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eligibility_responses ALTER COLUMN id SET DEFAULT nextval('public.eligibility_responses_id_seq'::regclass);


--
-- Name: encounter_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encounter_records ALTER COLUMN id SET DEFAULT nextval('public.encounter_records_id_seq'::regclass);


--
-- Name: encounter_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encounter_reports ALTER COLUMN id SET DEFAULT nextval('public.encounter_reports_id_seq'::regclass);


--
-- Name: enrollment_reasons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_reasons ALTER COLUMN id SET DEFAULT nextval('public.enrollment_reasons_id_seq'::regclass);


--
-- Name: enrollment_rosters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_rosters ALTER COLUMN id SET DEFAULT nextval('public.enrollment_rosters_id_seq'::regclass);


--
-- Name: enrollments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments ALTER COLUMN id SET DEFAULT nextval('public.enrollments_id_seq'::regclass);


--
-- Name: epic_careplans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_careplans ALTER COLUMN id SET DEFAULT nextval('public.epic_careplans_id_seq'::regclass);


--
-- Name: epic_case_note_qualifying_activities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_case_note_qualifying_activities ALTER COLUMN id SET DEFAULT nextval('public.epic_case_note_qualifying_activities_id_seq'::regclass);


--
-- Name: epic_case_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_case_notes ALTER COLUMN id SET DEFAULT nextval('public.epic_case_notes_id_seq'::regclass);


--
-- Name: epic_chas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_chas ALTER COLUMN id SET DEFAULT nextval('public.epic_chas_id_seq'::regclass);


--
-- Name: epic_goals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_goals ALTER COLUMN id SET DEFAULT nextval('public.epic_goals_id_seq'::regclass);


--
-- Name: epic_housing_statuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_housing_statuses ALTER COLUMN id SET DEFAULT nextval('public.epic_housing_statuses_id_seq'::regclass);


--
-- Name: epic_patients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_patients ALTER COLUMN id SET DEFAULT nextval('public.epic_patients_id_seq'::regclass);


--
-- Name: epic_qualifying_activities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_qualifying_activities ALTER COLUMN id SET DEFAULT nextval('public.epic_qualifying_activities_id_seq'::regclass);


--
-- Name: epic_ssms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_ssms ALTER COLUMN id SET DEFAULT nextval('public.epic_ssms_id_seq'::regclass);


--
-- Name: epic_team_members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_team_members ALTER COLUMN id SET DEFAULT nextval('public.epic_team_members_id_seq'::regclass);


--
-- Name: equipment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipment ALTER COLUMN id SET DEFAULT nextval('public.equipment_id_seq'::regclass);


--
-- Name: health_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_files ALTER COLUMN id SET DEFAULT nextval('public.health_files_id_seq'::regclass);


--
-- Name: health_flexible_service_follow_ups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_flexible_service_follow_ups ALTER COLUMN id SET DEFAULT nextval('public.health_flexible_service_follow_ups_id_seq'::regclass);


--
-- Name: health_flexible_service_vprs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_flexible_service_vprs ALTER COLUMN id SET DEFAULT nextval('public.health_flexible_service_vprs_id_seq'::regclass);


--
-- Name: health_goals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_goals ALTER COLUMN id SET DEFAULT nextval('public.health_goals_id_seq'::regclass);


--
-- Name: hl7_value_set_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hl7_value_set_codes ALTER COLUMN id SET DEFAULT nextval('public.hl7_value_set_codes_id_seq'::regclass);


--
-- Name: loaded_ed_ip_visits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loaded_ed_ip_visits ALTER COLUMN id SET DEFAULT nextval('public.loaded_ed_ip_visits_id_seq'::regclass);


--
-- Name: medications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medications ALTER COLUMN id SET DEFAULT nextval('public.medications_id_seq'::regclass);


--
-- Name: member_status_report_patients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_status_report_patients ALTER COLUMN id SET DEFAULT nextval('public.member_status_report_patients_id_seq'::regclass);


--
-- Name: member_status_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_status_reports ALTER COLUMN id SET DEFAULT nextval('public.member_status_reports_id_seq'::regclass);


--
-- Name: participation_forms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participation_forms ALTER COLUMN id SET DEFAULT nextval('public.participation_forms_id_seq'::regclass);


--
-- Name: patient_referral_imports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_referral_imports ALTER COLUMN id SET DEFAULT nextval('public.patient_referral_imports_id_seq'::regclass);


--
-- Name: patient_referrals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_referrals ALTER COLUMN id SET DEFAULT nextval('public.patient_referrals_id_seq'::regclass);


--
-- Name: patients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients ALTER COLUMN id SET DEFAULT nextval('public.patients_id_seq'::regclass);


--
-- Name: premium_payments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.premium_payments ALTER COLUMN id SET DEFAULT nextval('public.premium_payments_id_seq'::regclass);


--
-- Name: problems id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.problems ALTER COLUMN id SET DEFAULT nextval('public.problems_id_seq'::regclass);


--
-- Name: qualifying_activities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qualifying_activities ALTER COLUMN id SET DEFAULT nextval('public.qualifying_activities_id_seq'::regclass);


--
-- Name: release_forms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.release_forms ALTER COLUMN id SET DEFAULT nextval('public.release_forms_id_seq'::regclass);


--
-- Name: rosters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rosters ALTER COLUMN id SET DEFAULT nextval('public.rosters_id_seq'::regclass);


--
-- Name: sdh_case_management_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sdh_case_management_notes ALTER COLUMN id SET DEFAULT nextval('public.sdh_case_management_notes_id_seq'::regclass);


--
-- Name: self_sufficiency_matrix_forms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.self_sufficiency_matrix_forms ALTER COLUMN id SET DEFAULT nextval('public.self_sufficiency_matrix_forms_id_seq'::regclass);


--
-- Name: services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services ALTER COLUMN id SET DEFAULT nextval('public.services_id_seq'::regclass);


--
-- Name: signable_documents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signable_documents ALTER COLUMN id SET DEFAULT nextval('public.signable_documents_id_seq'::regclass);


--
-- Name: signature_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signature_requests ALTER COLUMN id SET DEFAULT nextval('public.signature_requests_id_seq'::regclass);


--
-- Name: soap_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.soap_configs ALTER COLUMN id SET DEFAULT nextval('public.soap_configs_id_seq'::regclass);


--
-- Name: ssm_exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ssm_exports ALTER COLUMN id SET DEFAULT nextval('public.ssm_exports_id_seq'::regclass);


--
-- Name: status_dates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_dates ALTER COLUMN id SET DEFAULT nextval('public.status_dates_id_seq'::regclass);


--
-- Name: team_members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_members ALTER COLUMN id SET DEFAULT nextval('public.team_members_id_seq'::regclass);


--
-- Name: teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams ALTER COLUMN id SET DEFAULT nextval('public.teams_id_seq'::regclass);


--
-- Name: tracing_cases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracing_cases ALTER COLUMN id SET DEFAULT nextval('public.tracing_cases_id_seq'::regclass);


--
-- Name: tracing_contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracing_contacts ALTER COLUMN id SET DEFAULT nextval('public.tracing_contacts_id_seq'::regclass);


--
-- Name: tracing_locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracing_locations ALTER COLUMN id SET DEFAULT nextval('public.tracing_locations_id_seq'::regclass);


--
-- Name: tracing_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracing_results ALTER COLUMN id SET DEFAULT nextval('public.tracing_results_id_seq'::regclass);


--
-- Name: tracing_site_leaders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracing_site_leaders ALTER COLUMN id SET DEFAULT nextval('public.tracing_site_leaders_id_seq'::regclass);


--
-- Name: tracing_staffs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracing_staffs ALTER COLUMN id SET DEFAULT nextval('public.tracing_staffs_id_seq'::regclass);


--
-- Name: transaction_acknowledgements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_acknowledgements ALTER COLUMN id SET DEFAULT nextval('public.transaction_acknowledgements_id_seq'::regclass);


--
-- Name: user_care_coordinators id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_care_coordinators ALTER COLUMN id SET DEFAULT nextval('public.user_care_coordinators_id_seq'::regclass);


--
-- Name: vaccinations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vaccinations ALTER COLUMN id SET DEFAULT nextval('public.vaccinations_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: visits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visits ALTER COLUMN id SET DEFAULT nextval('public.visits_id_seq'::regclass);


--
-- Name: accountable_care_organizations accountable_care_organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accountable_care_organizations
    ADD CONSTRAINT accountable_care_organizations_pkey PRIMARY KEY (id);


--
-- Name: agencies agencies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agencies
    ADD CONSTRAINT agencies_pkey PRIMARY KEY (id);


--
-- Name: agency_patient_referrals agency_patient_referrals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_patient_referrals
    ADD CONSTRAINT agency_patient_referrals_pkey PRIMARY KEY (id);


--
-- Name: agency_users agency_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agency_users
    ADD CONSTRAINT agency_users_pkey PRIMARY KEY (id);


--
-- Name: appointments appointments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appointments
    ADD CONSTRAINT appointments_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: backup_plans backup_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.backup_plans
    ADD CONSTRAINT backup_plans_pkey PRIMARY KEY (id);


--
-- Name: careplan_equipment careplan_equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.careplan_equipment
    ADD CONSTRAINT careplan_equipment_pkey PRIMARY KEY (id);


--
-- Name: careplan_services careplan_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.careplan_services
    ADD CONSTRAINT careplan_services_pkey PRIMARY KEY (id);


--
-- Name: careplans careplans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.careplans
    ADD CONSTRAINT careplans_pkey PRIMARY KEY (id);


--
-- Name: claims_amount_paid_location_month claims_amount_paid_location_month_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_amount_paid_location_month
    ADD CONSTRAINT claims_amount_paid_location_month_pkey PRIMARY KEY (id);


--
-- Name: claims_claim_volume_location_month claims_claim_volume_location_month_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_claim_volume_location_month
    ADD CONSTRAINT claims_claim_volume_location_month_pkey PRIMARY KEY (id);


--
-- Name: claims_ed_nyu_severity claims_ed_nyu_severity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_ed_nyu_severity
    ADD CONSTRAINT claims_ed_nyu_severity_pkey PRIMARY KEY (id);


--
-- Name: claims claims_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims
    ADD CONSTRAINT claims_pkey PRIMARY KEY (id);


--
-- Name: claims_reporting_ccs_lookups claims_reporting_ccs_lookups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_ccs_lookups
    ADD CONSTRAINT claims_reporting_ccs_lookups_pkey PRIMARY KEY (id);


--
-- Name: claims_reporting_cp_payment_details claims_reporting_cp_payment_details_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_cp_payment_details
    ADD CONSTRAINT claims_reporting_cp_payment_details_pkey PRIMARY KEY (id);


--
-- Name: claims_reporting_cp_payment_uploads claims_reporting_cp_payment_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_cp_payment_uploads
    ADD CONSTRAINT claims_reporting_cp_payment_uploads_pkey PRIMARY KEY (id);


--
-- Name: claims_reporting_engagement_trends claims_reporting_engagement_trends_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_engagement_trends
    ADD CONSTRAINT claims_reporting_engagement_trends_pkey PRIMARY KEY (id);


--
-- Name: claims_reporting_imports claims_reporting_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_imports
    ADD CONSTRAINT claims_reporting_imports_pkey PRIMARY KEY (id);


--
-- Name: claims_reporting_medical_claims claims_reporting_medical_claims_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_medical_claims
    ADD CONSTRAINT claims_reporting_medical_claims_pkey PRIMARY KEY (id);


--
-- Name: claims_reporting_member_diagnosis_classifications claims_reporting_member_diagnosis_classifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_member_diagnosis_classifications
    ADD CONSTRAINT claims_reporting_member_diagnosis_classifications_pkey PRIMARY KEY (id);


--
-- Name: claims_reporting_member_enrollment_rosters claims_reporting_member_enrollment_rosters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_member_enrollment_rosters
    ADD CONSTRAINT claims_reporting_member_enrollment_rosters_pkey PRIMARY KEY (id);


--
-- Name: claims_reporting_member_rosters claims_reporting_member_rosters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_member_rosters
    ADD CONSTRAINT claims_reporting_member_rosters_pkey PRIMARY KEY (id);


--
-- Name: claims_reporting_quality_measures claims_reporting_quality_measures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_quality_measures
    ADD CONSTRAINT claims_reporting_quality_measures_pkey PRIMARY KEY (id);


--
-- Name: claims_reporting_rx_claims claims_reporting_rx_claims_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_rx_claims
    ADD CONSTRAINT claims_reporting_rx_claims_pkey PRIMARY KEY (id);


--
-- Name: claims_roster claims_roster_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_roster
    ADD CONSTRAINT claims_roster_pkey PRIMARY KEY (id);


--
-- Name: claims_top_conditions claims_top_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_top_conditions
    ADD CONSTRAINT claims_top_conditions_pkey PRIMARY KEY (id);


--
-- Name: claims_top_ip_conditions claims_top_ip_conditions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_top_ip_conditions
    ADD CONSTRAINT claims_top_ip_conditions_pkey PRIMARY KEY (id);


--
-- Name: claims_top_providers claims_top_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_top_providers
    ADD CONSTRAINT claims_top_providers_pkey PRIMARY KEY (id);


--
-- Name: comprehensive_health_assessments comprehensive_health_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comprehensive_health_assessments
    ADD CONSTRAINT comprehensive_health_assessments_pkey PRIMARY KEY (id);


--
-- Name: cp_member_files cp_member_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cp_member_files
    ADD CONSTRAINT cp_member_files_pkey PRIMARY KEY (id);


--
-- Name: cps cps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cps
    ADD CONSTRAINT cps_pkey PRIMARY KEY (id);


--
-- Name: data_sources data_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sources
    ADD CONSTRAINT data_sources_pkey PRIMARY KEY (id);


--
-- Name: disenrollment_reasons disenrollment_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.disenrollment_reasons
    ADD CONSTRAINT disenrollment_reasons_pkey PRIMARY KEY (id);


--
-- Name: document_exports document_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_exports
    ADD CONSTRAINT document_exports_pkey PRIMARY KEY (id);


--
-- Name: ed_ip_visit_files ed_ip_visit_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ed_ip_visit_files
    ADD CONSTRAINT ed_ip_visit_files_pkey PRIMARY KEY (id);


--
-- Name: ed_ip_visits ed_ip_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ed_ip_visits
    ADD CONSTRAINT ed_ip_visits_pkey PRIMARY KEY (id);


--
-- Name: eligibility_inquiries eligibility_inquiries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eligibility_inquiries
    ADD CONSTRAINT eligibility_inquiries_pkey PRIMARY KEY (id);


--
-- Name: eligibility_responses eligibility_responses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eligibility_responses
    ADD CONSTRAINT eligibility_responses_pkey PRIMARY KEY (id);


--
-- Name: encounter_records encounter_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encounter_records
    ADD CONSTRAINT encounter_records_pkey PRIMARY KEY (id);


--
-- Name: encounter_reports encounter_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encounter_reports
    ADD CONSTRAINT encounter_reports_pkey PRIMARY KEY (id);


--
-- Name: enrollment_reasons enrollment_reasons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_reasons
    ADD CONSTRAINT enrollment_reasons_pkey PRIMARY KEY (id);


--
-- Name: enrollment_rosters enrollment_rosters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_rosters
    ADD CONSTRAINT enrollment_rosters_pkey PRIMARY KEY (id);


--
-- Name: enrollments enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_pkey PRIMARY KEY (id);


--
-- Name: epic_careplans epic_careplans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_careplans
    ADD CONSTRAINT epic_careplans_pkey PRIMARY KEY (id);


--
-- Name: epic_case_note_qualifying_activities epic_case_note_qualifying_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_case_note_qualifying_activities
    ADD CONSTRAINT epic_case_note_qualifying_activities_pkey PRIMARY KEY (id);


--
-- Name: epic_case_notes epic_case_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_case_notes
    ADD CONSTRAINT epic_case_notes_pkey PRIMARY KEY (id);


--
-- Name: epic_chas epic_chas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_chas
    ADD CONSTRAINT epic_chas_pkey PRIMARY KEY (id);


--
-- Name: epic_goals epic_goals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_goals
    ADD CONSTRAINT epic_goals_pkey PRIMARY KEY (id);


--
-- Name: epic_housing_statuses epic_housing_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_housing_statuses
    ADD CONSTRAINT epic_housing_statuses_pkey PRIMARY KEY (id);


--
-- Name: epic_patients epic_patients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_patients
    ADD CONSTRAINT epic_patients_pkey PRIMARY KEY (id);


--
-- Name: epic_qualifying_activities epic_qualifying_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_qualifying_activities
    ADD CONSTRAINT epic_qualifying_activities_pkey PRIMARY KEY (id);


--
-- Name: epic_ssms epic_ssms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_ssms
    ADD CONSTRAINT epic_ssms_pkey PRIMARY KEY (id);


--
-- Name: epic_team_members epic_team_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.epic_team_members
    ADD CONSTRAINT epic_team_members_pkey PRIMARY KEY (id);


--
-- Name: equipment equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_pkey PRIMARY KEY (id);


--
-- Name: health_files health_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_files
    ADD CONSTRAINT health_files_pkey PRIMARY KEY (id);


--
-- Name: health_flexible_service_follow_ups health_flexible_service_follow_ups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_flexible_service_follow_ups
    ADD CONSTRAINT health_flexible_service_follow_ups_pkey PRIMARY KEY (id);


--
-- Name: health_flexible_service_vprs health_flexible_service_vprs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_flexible_service_vprs
    ADD CONSTRAINT health_flexible_service_vprs_pkey PRIMARY KEY (id);


--
-- Name: health_goals health_goals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_goals
    ADD CONSTRAINT health_goals_pkey PRIMARY KEY (id);


--
-- Name: hl7_value_set_codes hl7_value_set_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hl7_value_set_codes
    ADD CONSTRAINT hl7_value_set_codes_pkey PRIMARY KEY (id);


--
-- Name: loaded_ed_ip_visits loaded_ed_ip_visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.loaded_ed_ip_visits
    ADD CONSTRAINT loaded_ed_ip_visits_pkey PRIMARY KEY (id);


--
-- Name: medications medications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.medications
    ADD CONSTRAINT medications_pkey PRIMARY KEY (id);


--
-- Name: member_status_report_patients member_status_report_patients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_status_report_patients
    ADD CONSTRAINT member_status_report_patients_pkey PRIMARY KEY (id);


--
-- Name: member_status_reports member_status_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.member_status_reports
    ADD CONSTRAINT member_status_reports_pkey PRIMARY KEY (id);


--
-- Name: participation_forms participation_forms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participation_forms
    ADD CONSTRAINT participation_forms_pkey PRIMARY KEY (id);


--
-- Name: patient_referral_imports patient_referral_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_referral_imports
    ADD CONSTRAINT patient_referral_imports_pkey PRIMARY KEY (id);


--
-- Name: patient_referrals patient_referrals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patient_referrals
    ADD CONSTRAINT patient_referrals_pkey PRIMARY KEY (id);


--
-- Name: patients patients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.patients
    ADD CONSTRAINT patients_pkey PRIMARY KEY (id);


--
-- Name: premium_payments premium_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.premium_payments
    ADD CONSTRAINT premium_payments_pkey PRIMARY KEY (id);


--
-- Name: problems problems_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.problems
    ADD CONSTRAINT problems_pkey PRIMARY KEY (id);


--
-- Name: qualifying_activities qualifying_activities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.qualifying_activities
    ADD CONSTRAINT qualifying_activities_pkey PRIMARY KEY (id);


--
-- Name: release_forms release_forms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.release_forms
    ADD CONSTRAINT release_forms_pkey PRIMARY KEY (id);


--
-- Name: rosters rosters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rosters
    ADD CONSTRAINT rosters_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sdh_case_management_notes sdh_case_management_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sdh_case_management_notes
    ADD CONSTRAINT sdh_case_management_notes_pkey PRIMARY KEY (id);


--
-- Name: self_sufficiency_matrix_forms self_sufficiency_matrix_forms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.self_sufficiency_matrix_forms
    ADD CONSTRAINT self_sufficiency_matrix_forms_pkey PRIMARY KEY (id);


--
-- Name: services services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (id);


--
-- Name: signable_documents signable_documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signable_documents
    ADD CONSTRAINT signable_documents_pkey PRIMARY KEY (id);


--
-- Name: signature_requests signature_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.signature_requests
    ADD CONSTRAINT signature_requests_pkey PRIMARY KEY (id);


--
-- Name: soap_configs soap_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.soap_configs
    ADD CONSTRAINT soap_configs_pkey PRIMARY KEY (id);


--
-- Name: ssm_exports ssm_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ssm_exports
    ADD CONSTRAINT ssm_exports_pkey PRIMARY KEY (id);


--
-- Name: status_dates status_dates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_dates
    ADD CONSTRAINT status_dates_pkey PRIMARY KEY (id);


--
-- Name: team_members team_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_members
    ADD CONSTRAINT team_members_pkey PRIMARY KEY (id);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: tracing_cases tracing_cases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracing_cases
    ADD CONSTRAINT tracing_cases_pkey PRIMARY KEY (id);


--
-- Name: tracing_contacts tracing_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracing_contacts
    ADD CONSTRAINT tracing_contacts_pkey PRIMARY KEY (id);


--
-- Name: tracing_locations tracing_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracing_locations
    ADD CONSTRAINT tracing_locations_pkey PRIMARY KEY (id);


--
-- Name: tracing_results tracing_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracing_results
    ADD CONSTRAINT tracing_results_pkey PRIMARY KEY (id);


--
-- Name: tracing_site_leaders tracing_site_leaders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracing_site_leaders
    ADD CONSTRAINT tracing_site_leaders_pkey PRIMARY KEY (id);


--
-- Name: tracing_staffs tracing_staffs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tracing_staffs
    ADD CONSTRAINT tracing_staffs_pkey PRIMARY KEY (id);


--
-- Name: transaction_acknowledgements transaction_acknowledgements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_acknowledgements
    ADD CONSTRAINT transaction_acknowledgements_pkey PRIMARY KEY (id);


--
-- Name: user_care_coordinators user_care_coordinators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_care_coordinators
    ADD CONSTRAINT user_care_coordinators_pkey PRIMARY KEY (id);


--
-- Name: vaccinations vaccinations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vaccinations
    ADD CONSTRAINT vaccinations_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: visits visits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visits
    ADD CONSTRAINT visits_pkey PRIMARY KEY (id);


--
-- Name: claims_reporting_medical_claims_service_daterange; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX claims_reporting_medical_claims_service_daterange ON public.claims_reporting_medical_claims USING gist (daterange(service_start_date, service_end_date, '[]'::text));


--
-- Name: hl_value_set_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX hl_value_set_code ON public.hl7_value_set_codes USING btree (code, code_system);


--
-- Name: hl_value_set_code_uniq_by_code_system_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX hl_value_set_code_uniq_by_code_system_code ON public.hl7_value_set_codes USING btree (value_set_oid, code_system, code);


--
-- Name: hl_value_set_code_uniq_by_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX hl_value_set_code_uniq_by_name ON public.hl7_value_set_codes USING btree (value_set_name, code_system, code);


--
-- Name: hl_value_set_code_uniq_by_oid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX hl_value_set_code_uniq_by_oid ON public.hl7_value_set_codes USING btree (value_set_oid, code_system_oid, code);


--
-- Name: idx_cpd_on_cp_payment_upload_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cpd_on_cp_payment_upload_id ON public.claims_reporting_cp_payment_details USING btree (cp_payment_upload_id);


--
-- Name: idx_crmc_member_service_start_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_crmc_member_service_start_date ON public.claims_reporting_medical_claims USING btree (member_id, service_start_date);


--
-- Name: index_backup_plans_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_backup_plans_on_patient_id ON public.backup_plans USING btree (patient_id);


--
-- Name: index_careplans_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_careplans_on_patient_id ON public.careplans USING btree (patient_id);


--
-- Name: index_careplans_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_careplans_on_user_id ON public.careplans USING btree (user_id);


--
-- Name: index_claims_amount_paid_location_month_on_medicaid_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_amount_paid_location_month_on_medicaid_id ON public.claims_amount_paid_location_month USING btree (medicaid_id);


--
-- Name: index_claims_claim_volume_location_month_on_medicaid_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_claim_volume_location_month_on_medicaid_id ON public.claims_claim_volume_location_month USING btree (medicaid_id);


--
-- Name: index_claims_ed_nyu_severity_on_medicaid_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_ed_nyu_severity_on_medicaid_id ON public.claims_ed_nyu_severity USING btree (medicaid_id);


--
-- Name: index_claims_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_on_deleted_at ON public.claims USING btree (deleted_at);


--
-- Name: index_claims_reporting_cp_payment_details_on_paid_dos; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_reporting_cp_payment_details_on_paid_dos ON public.claims_reporting_cp_payment_details USING btree (paid_dos);


--
-- Name: index_claims_reporting_cp_payment_details_on_payment_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_reporting_cp_payment_details_on_payment_date ON public.claims_reporting_cp_payment_details USING btree (payment_date);


--
-- Name: index_claims_reporting_cp_payment_uploads_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_reporting_cp_payment_uploads_on_deleted_at ON public.claims_reporting_cp_payment_uploads USING btree (deleted_at);


--
-- Name: index_claims_reporting_cp_payment_uploads_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_reporting_cp_payment_uploads_on_user_id ON public.claims_reporting_cp_payment_uploads USING btree (user_id);


--
-- Name: index_claims_reporting_engagement_trends_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_reporting_engagement_trends_on_user_id ON public.claims_reporting_engagement_trends USING btree (user_id);


--
-- Name: index_claims_reporting_medical_claims_on_aco_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_reporting_medical_claims_on_aco_name ON public.claims_reporting_medical_claims USING btree (aco_name);


--
-- Name: index_claims_reporting_medical_claims_on_aco_pidsl; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_reporting_medical_claims_on_aco_pidsl ON public.claims_reporting_medical_claims USING btree (aco_pidsl);


--
-- Name: index_claims_reporting_medical_claims_on_service_start_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_reporting_medical_claims_on_service_start_date ON public.claims_reporting_medical_claims USING btree (service_start_date);


--
-- Name: index_claims_reporting_member_rosters_on_aco_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_reporting_member_rosters_on_aco_name ON public.claims_reporting_member_rosters USING btree (aco_name);


--
-- Name: index_claims_reporting_member_rosters_on_date_of_birth; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_reporting_member_rosters_on_date_of_birth ON public.claims_reporting_member_rosters USING btree (date_of_birth);


--
-- Name: index_claims_reporting_member_rosters_on_member_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_claims_reporting_member_rosters_on_member_id ON public.claims_reporting_member_rosters USING btree (member_id);


--
-- Name: index_claims_reporting_member_rosters_on_race; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_reporting_member_rosters_on_race ON public.claims_reporting_member_rosters USING btree (race);


--
-- Name: index_claims_reporting_member_rosters_on_sex; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_reporting_member_rosters_on_sex ON public.claims_reporting_member_rosters USING btree (sex);


--
-- Name: index_claims_reporting_quality_measures_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_reporting_quality_measures_on_user_id ON public.claims_reporting_quality_measures USING btree (user_id);


--
-- Name: index_claims_reporting_rx_claims_on_service_start_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_reporting_rx_claims_on_service_start_date ON public.claims_reporting_rx_claims USING btree (service_start_date);


--
-- Name: index_claims_roster_on_medicaid_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_roster_on_medicaid_id ON public.claims_roster USING btree (medicaid_id);


--
-- Name: index_claims_top_conditions_on_medicaid_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_top_conditions_on_medicaid_id ON public.claims_top_conditions USING btree (medicaid_id);


--
-- Name: index_claims_top_ip_conditions_on_medicaid_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_top_ip_conditions_on_medicaid_id ON public.claims_top_ip_conditions USING btree (medicaid_id);


--
-- Name: index_claims_top_providers_on_medicaid_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_claims_top_providers_on_medicaid_id ON public.claims_top_providers USING btree (medicaid_id);


--
-- Name: index_comprehensive_health_assessments_on_health_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comprehensive_health_assessments_on_health_file_id ON public.comprehensive_health_assessments USING btree (health_file_id);


--
-- Name: index_comprehensive_health_assessments_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comprehensive_health_assessments_on_patient_id ON public.comprehensive_health_assessments USING btree (patient_id);


--
-- Name: index_comprehensive_health_assessments_on_reviewed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comprehensive_health_assessments_on_reviewed_by_id ON public.comprehensive_health_assessments USING btree (reviewed_by_id);


--
-- Name: index_comprehensive_health_assessments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comprehensive_health_assessments_on_user_id ON public.comprehensive_health_assessments USING btree (user_id);


--
-- Name: index_disenrollment_reasons_on_reason_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_disenrollment_reasons_on_reason_code ON public.disenrollment_reasons USING btree (reason_code);


--
-- Name: index_document_exports_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_document_exports_on_type ON public.document_exports USING btree (type);


--
-- Name: index_document_exports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_document_exports_on_user_id ON public.document_exports USING btree (user_id);


--
-- Name: index_ed_ip_visit_files_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ed_ip_visit_files_on_created_at ON public.ed_ip_visit_files USING btree (created_at);


--
-- Name: index_ed_ip_visit_files_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ed_ip_visit_files_on_deleted_at ON public.ed_ip_visit_files USING btree (deleted_at);


--
-- Name: index_ed_ip_visit_files_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ed_ip_visit_files_on_updated_at ON public.ed_ip_visit_files USING btree (updated_at);


--
-- Name: index_ed_ip_visit_files_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ed_ip_visit_files_on_user_id ON public.ed_ip_visit_files USING btree (user_id);


--
-- Name: index_ed_ip_visits_on_loaded_ed_ip_visit_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ed_ip_visits_on_loaded_ed_ip_visit_id ON public.ed_ip_visits USING btree (loaded_ed_ip_visit_id);


--
-- Name: index_ed_ip_visits_on_medicaid_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ed_ip_visits_on_medicaid_id ON public.ed_ip_visits USING btree (medicaid_id);


--
-- Name: index_eligibility_inquiries_on_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_eligibility_inquiries_on_batch_id ON public.eligibility_inquiries USING btree (batch_id);


--
-- Name: index_encounter_records_on_encounter_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_encounter_records_on_encounter_report_id ON public.encounter_records USING btree (encounter_report_id);


--
-- Name: index_encounter_reports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_encounter_reports_on_user_id ON public.encounter_reports USING btree (user_id);


--
-- Name: index_epic_housing_statuses_on_collected_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_epic_housing_statuses_on_collected_on ON public.epic_housing_statuses USING btree (collected_on);


--
-- Name: index_epic_housing_statuses_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_epic_housing_statuses_on_patient_id ON public.epic_housing_statuses USING btree (patient_id);


--
-- Name: index_epic_patients_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_epic_patients_on_deleted_at ON public.epic_patients USING btree (deleted_at);


--
-- Name: index_health_files_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_files_on_deleted_at ON public.health_files USING btree (deleted_at);


--
-- Name: index_health_files_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_files_on_type ON public.health_files USING btree (type);


--
-- Name: index_health_flexible_service_follow_ups_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_flexible_service_follow_ups_on_created_at ON public.health_flexible_service_follow_ups USING btree (created_at);


--
-- Name: index_health_flexible_service_follow_ups_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_flexible_service_follow_ups_on_patient_id ON public.health_flexible_service_follow_ups USING btree (patient_id);


--
-- Name: index_health_flexible_service_follow_ups_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_flexible_service_follow_ups_on_updated_at ON public.health_flexible_service_follow_ups USING btree (updated_at);


--
-- Name: index_health_flexible_service_follow_ups_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_flexible_service_follow_ups_on_user_id ON public.health_flexible_service_follow_ups USING btree (user_id);


--
-- Name: index_health_flexible_service_vprs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_flexible_service_vprs_on_created_at ON public.health_flexible_service_vprs USING btree (created_at);


--
-- Name: index_health_flexible_service_vprs_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_flexible_service_vprs_on_patient_id ON public.health_flexible_service_vprs USING btree (patient_id);


--
-- Name: index_health_flexible_service_vprs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_flexible_service_vprs_on_updated_at ON public.health_flexible_service_vprs USING btree (updated_at);


--
-- Name: index_health_flexible_service_vprs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_flexible_service_vprs_on_user_id ON public.health_flexible_service_vprs USING btree (user_id);


--
-- Name: index_health_goals_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_goals_on_patient_id ON public.health_goals USING btree (patient_id);


--
-- Name: index_health_goals_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_goals_on_user_id ON public.health_goals USING btree (user_id);


--
-- Name: index_loaded_ed_ip_visits_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loaded_ed_ip_visits_on_created_at ON public.loaded_ed_ip_visits USING btree (created_at);


--
-- Name: index_loaded_ed_ip_visits_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loaded_ed_ip_visits_on_deleted_at ON public.loaded_ed_ip_visits USING btree (deleted_at);


--
-- Name: index_loaded_ed_ip_visits_on_ed_ip_visit_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loaded_ed_ip_visits_on_ed_ip_visit_file_id ON public.loaded_ed_ip_visits USING btree (ed_ip_visit_file_id);


--
-- Name: index_loaded_ed_ip_visits_on_medicaid_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loaded_ed_ip_visits_on_medicaid_id ON public.loaded_ed_ip_visits USING btree (medicaid_id);


--
-- Name: index_loaded_ed_ip_visits_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_loaded_ed_ip_visits_on_updated_at ON public.loaded_ed_ip_visits USING btree (updated_at);


--
-- Name: index_member_status_report_patients_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_member_status_report_patients_on_deleted_at ON public.member_status_report_patients USING btree (deleted_at);


--
-- Name: index_member_status_reports_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_member_status_reports_on_deleted_at ON public.member_status_reports USING btree (deleted_at);


--
-- Name: index_participation_forms_on_case_manager_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_participation_forms_on_case_manager_id ON public.participation_forms USING btree (case_manager_id);


--
-- Name: index_participation_forms_on_health_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_participation_forms_on_health_file_id ON public.participation_forms USING btree (health_file_id);


--
-- Name: index_participation_forms_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_participation_forms_on_patient_id ON public.participation_forms USING btree (patient_id);


--
-- Name: index_participation_forms_on_reviewed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_participation_forms_on_reviewed_by_id ON public.participation_forms USING btree (reviewed_by_id);


--
-- Name: index_patient_referrals_on_contributing; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patient_referrals_on_contributing ON public.patient_referrals USING btree (contributing);


--
-- Name: index_patient_referrals_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patient_referrals_on_deleted_at ON public.patient_referrals USING btree (deleted_at);


--
-- Name: index_patients_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patients_on_deleted_at ON public.patients USING btree (deleted_at);


--
-- Name: index_patients_on_medicaid_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patients_on_medicaid_id ON public.patients USING btree (medicaid_id);


--
-- Name: index_patients_on_nurse_care_manager_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patients_on_nurse_care_manager_id ON public.patients USING btree (nurse_care_manager_id);


--
-- Name: index_premium_payments_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_premium_payments_on_deleted_at ON public.premium_payments USING btree (deleted_at);


--
-- Name: index_qualifying_activities_on_claim_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_qualifying_activities_on_claim_id ON public.qualifying_activities USING btree (claim_id);


--
-- Name: index_qualifying_activities_on_date_of_activity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_qualifying_activities_on_date_of_activity ON public.qualifying_activities USING btree (date_of_activity);


--
-- Name: index_qualifying_activities_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_qualifying_activities_on_patient_id ON public.qualifying_activities USING btree (patient_id);


--
-- Name: index_qualifying_activities_on_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_qualifying_activities_on_source_id ON public.qualifying_activities USING btree (source_id);


--
-- Name: index_qualifying_activities_on_source_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_qualifying_activities_on_source_type ON public.qualifying_activities USING btree (source_type);


--
-- Name: index_release_forms_on_health_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_release_forms_on_health_file_id ON public.release_forms USING btree (health_file_id);


--
-- Name: index_release_forms_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_release_forms_on_patient_id ON public.release_forms USING btree (patient_id);


--
-- Name: index_release_forms_on_reviewed_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_release_forms_on_reviewed_by_id ON public.release_forms USING btree (reviewed_by_id);


--
-- Name: index_release_forms_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_release_forms_on_user_id ON public.release_forms USING btree (user_id);


--
-- Name: index_sdh_case_management_notes_on_health_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sdh_case_management_notes_on_health_file_id ON public.sdh_case_management_notes USING btree (health_file_id);


--
-- Name: index_signable_documents_on_signable_id_and_signable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signable_documents_on_signable_id_and_signable_type ON public.signable_documents USING btree (signable_id, signable_type);


--
-- Name: index_signature_requests_on_careplan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signature_requests_on_careplan_id ON public.signature_requests USING btree (careplan_id);


--
-- Name: index_signature_requests_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signature_requests_on_deleted_at ON public.signature_requests USING btree (deleted_at);


--
-- Name: index_signature_requests_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signature_requests_on_patient_id ON public.signature_requests USING btree (patient_id);


--
-- Name: index_signature_requests_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_signature_requests_on_type ON public.signature_requests USING btree (type);


--
-- Name: index_ssm_exports_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ssm_exports_on_created_at ON public.ssm_exports USING btree (created_at);


--
-- Name: index_ssm_exports_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ssm_exports_on_updated_at ON public.ssm_exports USING btree (updated_at);


--
-- Name: index_ssm_exports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ssm_exports_on_user_id ON public.ssm_exports USING btree (user_id);


--
-- Name: index_status_dates_on_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_status_dates_on_date ON public.status_dates USING btree (date);


--
-- Name: index_status_dates_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_status_dates_on_patient_id ON public.status_dates USING btree (patient_id);


--
-- Name: index_team_members_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_members_on_patient_id ON public.team_members USING btree (patient_id);


--
-- Name: index_team_members_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_team_members_on_type ON public.team_members USING btree (type);


--
-- Name: index_teams_on_careplan_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_teams_on_careplan_id ON public.teams USING btree (careplan_id);


--
-- Name: index_tracing_cases_on_aliases; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracing_cases_on_aliases ON public.tracing_cases USING btree (aliases);


--
-- Name: index_tracing_cases_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracing_cases_on_client_id ON public.tracing_cases USING btree (client_id);


--
-- Name: index_tracing_cases_on_first_name_and_last_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracing_cases_on_first_name_and_last_name ON public.tracing_cases USING btree (first_name, last_name);


--
-- Name: index_tracing_contacts_on_aliases; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracing_contacts_on_aliases ON public.tracing_contacts USING btree (aliases);


--
-- Name: index_tracing_contacts_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracing_contacts_on_case_id ON public.tracing_contacts USING btree (case_id);


--
-- Name: index_tracing_contacts_on_first_name_and_last_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracing_contacts_on_first_name_and_last_name ON public.tracing_contacts USING btree (first_name, last_name);


--
-- Name: index_tracing_locations_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracing_locations_on_case_id ON public.tracing_locations USING btree (case_id);


--
-- Name: index_tracing_results_on_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracing_results_on_contact_id ON public.tracing_results USING btree (contact_id);


--
-- Name: index_tracing_site_leaders_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracing_site_leaders_on_case_id ON public.tracing_site_leaders USING btree (case_id);


--
-- Name: index_tracing_staffs_on_case_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tracing_staffs_on_case_id ON public.tracing_staffs USING btree (case_id);


--
-- Name: index_transaction_acknowledgements_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transaction_acknowledgements_on_deleted_at ON public.transaction_acknowledgements USING btree (deleted_at);


--
-- Name: index_vaccinations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vaccinations_on_created_at ON public.vaccinations USING btree (created_at);


--
-- Name: index_vaccinations_on_epic_patient_id_and_vaccinated_on; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_vaccinations_on_epic_patient_id_and_vaccinated_on ON public.vaccinations USING btree (epic_patient_id, vaccinated_on);


--
-- Name: index_vaccinations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vaccinations_on_updated_at ON public.vaccinations USING btree (updated_at);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: med_claim_member_procedure_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX med_claim_member_procedure_index ON public.claims_reporting_medical_claims USING btree (member_id, procedure_code);


--
-- Name: patients_client_id_constraint; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX patients_client_id_constraint ON public.patients USING btree (client_id) WHERE (deleted_at IS NULL);


--
-- Name: unk_code_range; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unk_code_range ON public.claims_reporting_ccs_lookups USING btree (effective_start, hcpcs_start, hcpcs_end);


--
-- Name: unk_cr_medical_claim; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unk_cr_medical_claim ON public.claims_reporting_medical_claims USING btree (member_id, claim_number, line_number);


--
-- Name: unk_cr_member_enrollment_roster; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unk_cr_member_enrollment_roster ON public.claims_reporting_member_enrollment_rosters USING btree (member_id, span_start_date);


--
-- Name: unk_cr_member_roster; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unk_cr_member_roster ON public.claims_reporting_member_rosters USING btree (member_id);


--
-- Name: unk_cr_rx_claims; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unk_cr_rx_claims ON public.claims_reporting_rx_claims USING btree (member_id, claim_number, line_number);


--
-- Name: unk_crmd; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX unk_crmd ON public.claims_reporting_member_diagnosis_classifications USING btree (member_id);


--
-- Name: comprehensive_health_assessments fk_rails_43326a3c45; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comprehensive_health_assessments
    ADD CONSTRAINT fk_rails_43326a3c45 FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: health_goals fk_rails_4824321a1f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_goals
    ADD CONSTRAINT fk_rails_4824321a1f FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- Name: participation_forms fk_rails_5117a8c1ab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.participation_forms
    ADD CONSTRAINT fk_rails_5117a8c1ab FOREIGN KEY (health_file_id) REFERENCES public.health_files(id);


--
-- Name: release_forms fk_rails_c31647a6e2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.release_forms
    ADD CONSTRAINT fk_rails_c31647a6e2 FOREIGN KEY (health_file_id) REFERENCES public.health_files(id);


--
-- Name: comprehensive_health_assessments fk_rails_c82a16111f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comprehensive_health_assessments
    ADD CONSTRAINT fk_rails_c82a16111f FOREIGN KEY (health_file_id) REFERENCES public.health_files(id);


--
-- Name: sdh_case_management_notes fk_rails_c83f0aa179; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sdh_case_management_notes
    ADD CONSTRAINT fk_rails_c83f0aa179 FOREIGN KEY (health_file_id) REFERENCES public.health_files(id);


--
-- Name: claims_reporting_cp_payment_details fk_rails_cfb684843a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.claims_reporting_cp_payment_details
    ADD CONSTRAINT fk_rails_cfb684843a FOREIGN KEY (cp_payment_upload_id) REFERENCES public.claims_reporting_cp_payment_uploads(id);


--
-- Name: team_members fk_rails_ecf5238646; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_members
    ADD CONSTRAINT fk_rails_ecf5238646 FOREIGN KEY (patient_id) REFERENCES public.patients(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20170512154839'),
('20170512172314'),
('20170512172320'),
('20170512172327'),
('20170512172333'),
('20170516185409'),
('20170516190400'),
('20170516195310'),
('20170517125108'),
('20170523175542'),
('20170523181235'),
('20170529174730'),
('20170529182835'),
('20170529203247'),
('20170601172245'),
('20170602013551'),
('20170606143003'),
('20170613150635'),
('20170713184156'),
('20170831233204'),
('20170901195912'),
('20171028010225'),
('20171106180121'),
('20171107000152'),
('20180220193729'),
('20180301200541'),
('20180405154902'),
('20180411184612'),
('20180412201311'),
('20180412214425'),
('20180413045706'),
('20180413220534'),
('20180415191849'),
('20180508205550'),
('20180509194250'),
('20180515174347'),
('20180515184556'),
('20180516020528'),
('20180516032040'),
('20180516151527'),
('20180516184628'),
('20180516192022'),
('20180516223016'),
('20180517150308'),
('20180517151557'),
('20180517151558'),
('20180517170436'),
('20180517171655'),
('20180518133256'),
('20180518185643'),
('20180521132959'),
('20180521133817'),
('20180522203840'),
('20180522233624'),
('20180523121947'),
('20180523125514'),
('20180523203004'),
('20180524021249'),
('20180524121555'),
('20180524124135'),
('20180524132457'),
('20180524145220'),
('20180524175356'),
('20180525155355'),
('20180525195857'),
('20180526183114'),
('20180527115601'),
('20180527173419'),
('20180528002944'),
('20180528140032'),
('20180528144412'),
('20180530202908'),
('20180601010922'),
('20180601124144'),
('20180601152640'),
('20180601154501'),
('20180601185402'),
('20180607134202'),
('20180607140425'),
('20180607151108'),
('20180607180418'),
('20180611144138'),
('20180611145132'),
('20180611145227'),
('20180611203248'),
('20180611204954'),
('20180612171146'),
('20180612181410'),
('20180612200528'),
('20180613134407'),
('20180614133715'),
('20180614213248'),
('20180619184604'),
('20180621204422'),
('20180621211650'),
('20180627182220'),
('20180628175013'),
('20180629181555'),
('20180629203110'),
('20180630171549'),
('20180630225902'),
('20180701013424'),
('20180703200409'),
('20180707134347'),
('20180709184426'),
('20180710000126'),
('20180710163416'),
('20180711170320'),
('20180711174711'),
('20180713142425'),
('20180713162722'),
('20180713183124'),
('20180714180117'),
('20180714180735'),
('20180716125419'),
('20180716151309'),
('20180716202012'),
('20180717174942'),
('20180803195603'),
('20180807130101'),
('20180807161932'),
('20180807182636'),
('20180808174627'),
('20180808190244'),
('20180809175415'),
('20180810153634'),
('20180827173717'),
('20180827181354'),
('20180828173902'),
('20180831190828'),
('20180907122443'),
('20181026155224'),
('20190114174045'),
('20190117150120'),
('20190206194409'),
('20190328192902'),
('20190402142851'),
('20190404153621'),
('20190416180547'),
('20190416182618'),
('20190417171605'),
('20190418144540'),
('20190418152152'),
('20190419122444'),
('20190419150901'),
('20190422201024'),
('20190509155939'),
('20190513173709'),
('20190529182702'),
('20190607144129'),
('20190730122842'),
('20190809152023'),
('20190905170546'),
('20191107163343'),
('20191107164902'),
('20191107165424'),
('20191112154844'),
('20191113130108'),
('20191119200007'),
('20191206194129'),
('20191212151341'),
('20191230193236'),
('20191230194535'),
('20200110164537'),
('20200110170125'),
('20200113153534'),
('20200113160822'),
('20200124194225'),
('20200127151840'),
('20200203185425'),
('20200203203607'),
('20200204175352'),
('20200205144804'),
('20200217200315'),
('20200217200518'),
('20200218160012'),
('20200224162701'),
('20200313143927'),
('20200402012546'),
('20200402165627'),
('20200403004129'),
('20200403180901'),
('20200403184005'),
('20200403203318'),
('20200404144432'),
('20200415205728'),
('20200417132126'),
('20200421141725'),
('20200422135848'),
('20200422143107'),
('20200430201554'),
('20200508135957'),
('20200512143130'),
('20200520192050'),
('20200616201412'),
('20200617131057'),
('20200617132415'),
('20200617134354'),
('20200618132804'),
('20200629205716'),
('20200807140152'),
('20200807203051'),
('20200930152001'),
('20201013203358'),
('20201015195157'),
('20201019193122'),
('20201020125617'),
('20201020155907'),
('20201022181343'),
('20201103202932'),
('20201104164745'),
('20201104191034'),
('20201106141253'),
('20201118181257'),
('20201201192211'),
('20201201224035'),
('20201203212643'),
('20201203212706'),
('20201208220623'),
('20201209193543'),
('20201210200633'),
('20201211162854'),
('20201223182315'),
('20210111195511'),
('20210114205149'),
('20210118145142'),
('20210121151237'),
('20210122155335'),
('20210128183759'),
('20210202194001'),
('20210203164826'),
('20210204042020'),
('20210204052544'),
('20210212151557'),
('20210309150436'),
('20210318212736'),
('20210325190312'),
('20210326143558'),
('20210326150547'),
('20210327131355'),
('20210330155241'),
('20210330181230'),
('20210419174757'),
('20210422161421'),
('20210510185734'),
('20210511143037'),
('20210607182656'),
('20210726193142'),
('20210806150431'),
('20210928134057'),
('20211005200728'),
('20211006152632'),
('20211006152946'),
('20211006153817'),
('20211006154441'),
('20211006204046');



