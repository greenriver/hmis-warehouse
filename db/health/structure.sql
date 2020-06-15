--
-- PostgreSQL database dump
--

-- Dumped from database version 11.7
-- Dumped by pg_dump version 12.2

-- Started on 2020-06-10 18:00:30 UTC

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
-- Name: accountable_care_organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accountable_care_organizations (
    id integer NOT NULL,
    name character varying,
    short_name character varying,
    mco_pid integer,
    mco_sl character varying,
    active boolean DEFAULT true NOT NULL
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
    updated_at timestamp without time zone
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
    health_file_id integer
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
    transaction_acknowledgement_id integer
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
    reviewer character varying
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
    trace_id character varying(10)
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
    failed_at timestamp without time zone
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
    deleted_at timestamp without time zone
);


--
-- Name: ed_ip_visits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ed_ip_visits_id_seq
    AS integer
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
    deleted_at timestamp without time zone
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
    updated_at timestamp without time zone
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
    patient_id integer
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
    deleted_at timestamp without time zone
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
    removal_acknowledged boolean DEFAULT false,
    effective_date timestamp without time zone,
    disenrollment_date date,
    stop_reason_description character varying,
    pending_disenrollment_date date
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
    previous_aco_name character varying
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
    epic_source_id character varying
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
-- Name: health_goals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_goals ALTER COLUMN id SET DEFAULT nextval('public.health_goals_id_seq'::regclass);


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
-- Name: team_members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_members ALTER COLUMN id SET DEFAULT nextval('public.team_members_id_seq'::regclass);


--
-- Name: teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams ALTER COLUMN id SET DEFAULT nextval('public.teams_id_seq'::regclass);


--
-- Name: transaction_acknowledgements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transaction_acknowledgements ALTER COLUMN id SET DEFAULT nextval('public.transaction_acknowledgements_id_seq'::regclass);


--
-- Name: user_care_coordinators id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_care_coordinators ALTER COLUMN id SET DEFAULT nextval('public.user_care_coordinators_id_seq'::regclass);


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
-- Name: health_goals health_goals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_goals
    ADD CONSTRAINT health_goals_pkey PRIMARY KEY (id);


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
-- Name: index_ed_ip_visits_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ed_ip_visits_on_created_at ON public.ed_ip_visits USING btree (created_at);


--
-- Name: index_ed_ip_visits_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ed_ip_visits_on_deleted_at ON public.ed_ip_visits USING btree (deleted_at);


--
-- Name: index_ed_ip_visits_on_ed_ip_visit_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ed_ip_visits_on_ed_ip_visit_file_id ON public.ed_ip_visits USING btree (ed_ip_visit_file_id);


--
-- Name: index_ed_ip_visits_on_medicaid_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ed_ip_visits_on_medicaid_id ON public.ed_ip_visits USING btree (medicaid_id);


--
-- Name: index_ed_ip_visits_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ed_ip_visits_on_updated_at ON public.ed_ip_visits USING btree (updated_at);


--
-- Name: index_eligibility_inquiries_on_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_eligibility_inquiries_on_batch_id ON public.eligibility_inquiries USING btree (batch_id);


--
-- Name: index_epic_case_notes_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_epic_case_notes_on_patient_id ON public.epic_case_notes USING btree (patient_id);


--
-- Name: index_epic_goals_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_epic_goals_on_patient_id ON public.epic_goals USING btree (patient_id);


--
-- Name: index_health_files_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_files_on_type ON public.health_files USING btree (type);


--
-- Name: index_health_goals_on_patient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_goals_on_patient_id ON public.health_goals USING btree (patient_id);


--
-- Name: index_health_goals_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_goals_on_user_id ON public.health_goals USING btree (user_id);


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
-- Name: index_patients_on_medicaid_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_patients_on_medicaid_id ON public.patients USING btree (medicaid_id);


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
-- Name: index_transaction_acknowledgements_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_transaction_acknowledgements_on_deleted_at ON public.transaction_acknowledgements USING btree (deleted_at);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: patients_client_id_constraint; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX patients_client_id_constraint ON public.patients USING btree (client_id) WHERE (deleted_at IS NULL);


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
-- Name: team_members fk_rails_ecf5238646; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_members
    ADD CONSTRAINT fk_rails_ecf5238646 FOREIGN KEY (patient_id) REFERENCES public.patients(id);


-- Completed on 2020-06-10 18:03:26 UTC

--
-- PostgreSQL database dump complete
--

