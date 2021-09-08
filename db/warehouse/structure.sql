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


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- Name: census_levels; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.census_levels AS ENUM (
    'STATE',
    'COUNTY',
    'PLACE',
    'SLDU',
    'SLDL',
    'ZCTA5',
    'TRACT',
    'BG',
    'TABBLOCK',
    'CUSTOM'
);


--
-- Name: record_action; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.record_action AS ENUM (
    'added',
    'updated',
    'unchanged',
    'removed'
);


--
-- Name: record_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.record_type AS ENUM (
    'first',
    'entry',
    'exit',
    'service',
    'extrapolated'
);


--
-- Name: service_history_service_insert_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.service_history_service_insert_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
      IF  ( NEW.date BETWEEN DATE '2050-01-01' AND DATE '2050-12-31' ) THEN
            INSERT INTO service_history_services_2050 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2049-01-01' AND DATE '2049-12-31' ) THEN
            INSERT INTO service_history_services_2049 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2048-01-01' AND DATE '2048-12-31' ) THEN
            INSERT INTO service_history_services_2048 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2047-01-01' AND DATE '2047-12-31' ) THEN
            INSERT INTO service_history_services_2047 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2046-01-01' AND DATE '2046-12-31' ) THEN
            INSERT INTO service_history_services_2046 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2045-01-01' AND DATE '2045-12-31' ) THEN
            INSERT INTO service_history_services_2045 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2044-01-01' AND DATE '2044-12-31' ) THEN
            INSERT INTO service_history_services_2044 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2043-01-01' AND DATE '2043-12-31' ) THEN
            INSERT INTO service_history_services_2043 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2042-01-01' AND DATE '2042-12-31' ) THEN
            INSERT INTO service_history_services_2042 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2041-01-01' AND DATE '2041-12-31' ) THEN
            INSERT INTO service_history_services_2041 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2040-01-01' AND DATE '2040-12-31' ) THEN
            INSERT INTO service_history_services_2040 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2039-01-01' AND DATE '2039-12-31' ) THEN
            INSERT INTO service_history_services_2039 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2038-01-01' AND DATE '2038-12-31' ) THEN
            INSERT INTO service_history_services_2038 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2037-01-01' AND DATE '2037-12-31' ) THEN
            INSERT INTO service_history_services_2037 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2036-01-01' AND DATE '2036-12-31' ) THEN
            INSERT INTO service_history_services_2036 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2035-01-01' AND DATE '2035-12-31' ) THEN
            INSERT INTO service_history_services_2035 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2034-01-01' AND DATE '2034-12-31' ) THEN
            INSERT INTO service_history_services_2034 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2033-01-01' AND DATE '2033-12-31' ) THEN
            INSERT INTO service_history_services_2033 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2032-01-01' AND DATE '2032-12-31' ) THEN
            INSERT INTO service_history_services_2032 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2031-01-01' AND DATE '2031-12-31' ) THEN
            INSERT INTO service_history_services_2031 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2030-01-01' AND DATE '2030-12-31' ) THEN
            INSERT INTO service_history_services_2030 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2029-01-01' AND DATE '2029-12-31' ) THEN
            INSERT INTO service_history_services_2029 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2028-01-01' AND DATE '2028-12-31' ) THEN
            INSERT INTO service_history_services_2028 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2027-01-01' AND DATE '2027-12-31' ) THEN
            INSERT INTO service_history_services_2027 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2026-01-01' AND DATE '2026-12-31' ) THEN
            INSERT INTO service_history_services_2026 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2025-01-01' AND DATE '2025-12-31' ) THEN
            INSERT INTO service_history_services_2025 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2024-01-01' AND DATE '2024-12-31' ) THEN
            INSERT INTO service_history_services_2024 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31' ) THEN
            INSERT INTO service_history_services_2023 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31' ) THEN
            INSERT INTO service_history_services_2022 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31' ) THEN
            INSERT INTO service_history_services_2021 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31' ) THEN
            INSERT INTO service_history_services_2020 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2019-01-01' AND DATE '2019-12-31' ) THEN
            INSERT INTO service_history_services_2019 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2018-01-01' AND DATE '2018-12-31' ) THEN
            INSERT INTO service_history_services_2018 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2017-01-01' AND DATE '2017-12-31' ) THEN
            INSERT INTO service_history_services_2017 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2016-01-01' AND DATE '2016-12-31' ) THEN
            INSERT INTO service_history_services_2016 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2015-01-01' AND DATE '2015-12-31' ) THEN
            INSERT INTO service_history_services_2015 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2014-01-01' AND DATE '2014-12-31' ) THEN
            INSERT INTO service_history_services_2014 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2013-01-01' AND DATE '2013-12-31' ) THEN
            INSERT INTO service_history_services_2013 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2012-01-01' AND DATE '2012-12-31' ) THEN
            INSERT INTO service_history_services_2012 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2011-01-01' AND DATE '2011-12-31' ) THEN
            INSERT INTO service_history_services_2011 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2010-01-01' AND DATE '2010-12-31' ) THEN
            INSERT INTO service_history_services_2010 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2009-01-01' AND DATE '2009-12-31' ) THEN
            INSERT INTO service_history_services_2009 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2008-01-01' AND DATE '2008-12-31' ) THEN
            INSERT INTO service_history_services_2008 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2007-01-01' AND DATE '2007-12-31' ) THEN
            INSERT INTO service_history_services_2007 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2006-01-01' AND DATE '2006-12-31' ) THEN
            INSERT INTO service_history_services_2006 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2005-01-01' AND DATE '2005-12-31' ) THEN
            INSERT INTO service_history_services_2005 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2004-01-01' AND DATE '2004-12-31' ) THEN
            INSERT INTO service_history_services_2004 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2003-01-01' AND DATE '2003-12-31' ) THEN
            INSERT INTO service_history_services_2003 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2002-01-01' AND DATE '2002-12-31' ) THEN
            INSERT INTO service_history_services_2002 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31' ) THEN
            INSERT INTO service_history_services_2001 VALUES (NEW.*);
         ELSIF  ( NEW.date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31' ) THEN
            INSERT INTO service_history_services_2000 VALUES (NEW.*);
        
      ELSE
        INSERT INTO service_history_services_remainder VALUES (NEW.*);
        END IF;
        RETURN NULL;
    END;
    $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: Affiliation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Affiliation" (
    "AffiliationID" character varying,
    "ProjectID" character varying,
    "ResProjectID" character varying,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    source_hash character varying,
    pending_date_deleted timestamp without time zone
);


--
-- Name: Affiliation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Affiliation_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Affiliation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Affiliation_id_seq" OWNED BY public."Affiliation".id;


--
-- Name: Assessment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Assessment" (
    id integer NOT NULL,
    "AssessmentID" character varying(32) NOT NULL,
    "EnrollmentID" character varying NOT NULL,
    "PersonalID" character varying NOT NULL,
    "AssessmentDate" date NOT NULL,
    "AssessmentLocation" character varying NOT NULL,
    "AssessmentType" integer NOT NULL,
    "AssessmentLevel" integer NOT NULL,
    "PrioritizationStatus" integer NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateUpdated" timestamp without time zone NOT NULL,
    "UserID" character varying(32) NOT NULL,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    pending_date_deleted timestamp without time zone,
    source_hash character varying,
    synthetic boolean DEFAULT false
);


--
-- Name: AssessmentQuestions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."AssessmentQuestions" (
    id integer NOT NULL,
    "AssessmentQuestionID" character varying(32) NOT NULL,
    "AssessmentID" character varying(32) NOT NULL,
    "EnrollmentID" character varying NOT NULL,
    "PersonalID" character varying NOT NULL,
    "AssessmentQuestionGroup" character varying,
    "AssessmentQuestionOrder" integer,
    "AssessmentQuestion" character varying,
    "AssessmentAnswer" character varying,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateUpdated" timestamp without time zone NOT NULL,
    "UserID" character varying(32) NOT NULL,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    pending_date_deleted timestamp without time zone,
    source_hash character varying
);


--
-- Name: AssessmentQuestions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."AssessmentQuestions_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: AssessmentQuestions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."AssessmentQuestions_id_seq" OWNED BY public."AssessmentQuestions".id;


--
-- Name: AssessmentResults; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."AssessmentResults" (
    id integer NOT NULL,
    "AssessmentResultID" character varying(32) NOT NULL,
    "AssessmentID" character varying(32) NOT NULL,
    "EnrollmentID" character varying NOT NULL,
    "PersonalID" character varying NOT NULL,
    "AssessmentResultType" character varying,
    "AssessmentResult" character varying,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateUpdated" timestamp without time zone NOT NULL,
    "UserID" character varying(32) NOT NULL,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    pending_date_deleted timestamp without time zone,
    source_hash character varying
);


--
-- Name: AssessmentResults_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."AssessmentResults_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: AssessmentResults_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."AssessmentResults_id_seq" OWNED BY public."AssessmentResults".id;


--
-- Name: Assessment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Assessment_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Assessment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Assessment_id_seq" OWNED BY public."Assessment".id;


--
-- Name: Client; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Client" (
    "PersonalID" character varying,
    "FirstName" character varying(150),
    "MiddleName" character varying(150),
    "LastName" character varying(150),
    "NameSuffix" character varying(50),
    "NameDataQuality" integer,
    "SSN" character varying,
    "SSNDataQuality" integer,
    "DOB" date,
    "DOBDataQuality" integer,
    "AmIndAKNative" integer,
    "Asian" integer,
    "BlackAfAmerican" integer,
    "NativeHIOtherPacific" integer,
    "White" integer,
    "RaceNone" integer,
    "Ethnicity" integer,
    "Gender" integer,
    "OtherGender" character varying(50),
    "VeteranStatus" integer,
    "YearEnteredService" integer,
    "YearSeparated" integer,
    "WorldWarII" integer,
    "KoreanWar" integer,
    "VietnamWar" integer,
    "DesertStorm" integer,
    "AfghanistanOEF" integer,
    "IraqOIF" integer,
    "IraqOND" integer,
    "OtherTheater" integer,
    "MilitaryBranch" integer,
    "DischargeStatus" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    disability_verified_on timestamp without time zone,
    housing_assistance_network_released_on timestamp without time zone,
    sync_with_cas boolean DEFAULT false NOT NULL,
    dmh_eligible boolean DEFAULT false NOT NULL,
    va_eligible boolean DEFAULT false NOT NULL,
    hues_eligible boolean DEFAULT false NOT NULL,
    hiv_positive boolean DEFAULT false NOT NULL,
    housing_release_status character varying,
    chronically_homeless_for_cas boolean DEFAULT false NOT NULL,
    us_citizen boolean DEFAULT false NOT NULL,
    asylee boolean DEFAULT false NOT NULL,
    ineligible_immigrant boolean DEFAULT false NOT NULL,
    lifetime_sex_offender boolean DEFAULT false NOT NULL,
    meth_production_conviction boolean DEFAULT false NOT NULL,
    family_member boolean DEFAULT false NOT NULL,
    child_in_household boolean DEFAULT false NOT NULL,
    ha_eligible boolean DEFAULT false NOT NULL,
    api_update_in_process boolean DEFAULT false NOT NULL,
    api_update_started_at timestamp without time zone,
    api_last_updated_at timestamp without time zone,
    creator_id integer,
    cspech_eligible boolean DEFAULT false,
    consent_form_signed_on date,
    vispdat_prioritization_days_homeless integer,
    generate_history_pdf boolean DEFAULT false,
    congregate_housing boolean DEFAULT false,
    sober_housing boolean DEFAULT false,
    consent_form_id integer,
    rrh_assessment_score integer,
    ssvf_eligible boolean DEFAULT false NOT NULL,
    rrh_desired boolean DEFAULT false NOT NULL,
    youth_rrh_desired boolean DEFAULT false NOT NULL,
    rrh_assessment_contact_info character varying,
    rrh_assessment_collected_at timestamp without time zone,
    source_hash character varying,
    generate_manual_history_pdf boolean DEFAULT false NOT NULL,
    requires_wheelchair_accessibility boolean DEFAULT false,
    required_number_of_bedrooms integer DEFAULT 1,
    required_minimum_occupancy integer DEFAULT 1,
    requires_elevator_access boolean DEFAULT false,
    neighborhood_interests jsonb DEFAULT '[]'::jsonb NOT NULL,
    verified_veteran_status character varying,
    interested_in_set_asides boolean DEFAULT false,
    consent_expires_on date,
    pending_date_deleted timestamp without time zone,
    cas_match_override date,
    vash_eligible boolean DEFAULT false,
    consented_coc_codes jsonb DEFAULT '[]'::jsonb,
    income_maximization_assistance_requested boolean DEFAULT false NOT NULL,
    income_total_monthly integer,
    pending_subsidized_housing_placement boolean DEFAULT false NOT NULL,
    pathways_domestic_violence boolean DEFAULT false NOT NULL,
    rrh_th_desired boolean DEFAULT false NOT NULL,
    sro_ok boolean DEFAULT false NOT NULL,
    pathways_other_accessibility boolean DEFAULT false NOT NULL,
    pathways_disabled_housing boolean DEFAULT false NOT NULL,
    evicted boolean DEFAULT false NOT NULL,
    dv_rrh_desired boolean DEFAULT false,
    health_prioritized character varying,
    demographic_dirty boolean DEFAULT true,
    "encrypted_FirstName" character varying,
    "encrypted_FirstName_iv" character varying,
    "encrypted_MiddleName" character varying,
    "encrypted_MiddleName_iv" character varying,
    "encrypted_LastName" character varying,
    "encrypted_LastName_iv" character varying,
    "encrypted_SSN" character varying,
    "encrypted_SSN_iv" character varying,
    "encrypted_NameSuffix" character varying,
    "encrypted_NameSuffix_iv" character varying,
    soundex_first character varying,
    soundex_last character varying,
    "Female" integer,
    "Male" integer,
    "GenderOther" integer,
    "Transgender" integer,
    "Questioning" integer,
    "GenderNone" integer
);


--
-- Name: Client_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Client_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Client_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Client_id_seq" OWNED BY public."Client".id;


--
-- Name: ClientUnencrypted; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ClientUnencrypted" (
    "PersonalID" character varying,
    "FirstName" character varying(150),
    "MiddleName" character varying(150),
    "LastName" character varying(150),
    "NameSuffix" character varying(50),
    "NameDataQuality" integer,
    "SSN" character varying,
    "SSNDataQuality" integer,
    "DOB" date,
    "DOBDataQuality" integer,
    "AmIndAKNative" integer,
    "Asian" integer,
    "BlackAfAmerican" integer,
    "NativeHIOtherPacific" integer,
    "White" integer,
    "RaceNone" integer,
    "Ethnicity" integer,
    "Gender" integer,
    "OtherGender" character varying(50),
    "VeteranStatus" integer,
    "YearEnteredService" integer,
    "YearSeparated" integer,
    "WorldWarII" integer,
    "KoreanWar" integer,
    "VietnamWar" integer,
    "DesertStorm" integer,
    "AfghanistanOEF" integer,
    "IraqOIF" integer,
    "IraqOND" integer,
    "OtherTheater" integer,
    "MilitaryBranch" integer,
    "DischargeStatus" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer DEFAULT nextval('public."Client_id_seq"'::regclass) NOT NULL,
    disability_verified_on timestamp without time zone,
    housing_assistance_network_released_on timestamp without time zone,
    sync_with_cas boolean DEFAULT false NOT NULL,
    dmh_eligible boolean DEFAULT false NOT NULL,
    va_eligible boolean DEFAULT false NOT NULL,
    hues_eligible boolean DEFAULT false NOT NULL,
    hiv_positive boolean DEFAULT false NOT NULL,
    housing_release_status character varying,
    chronically_homeless_for_cas boolean DEFAULT false NOT NULL,
    us_citizen boolean DEFAULT false NOT NULL,
    asylee boolean DEFAULT false NOT NULL,
    ineligible_immigrant boolean DEFAULT false NOT NULL,
    lifetime_sex_offender boolean DEFAULT false NOT NULL,
    meth_production_conviction boolean DEFAULT false NOT NULL,
    family_member boolean DEFAULT false NOT NULL,
    child_in_household boolean DEFAULT false NOT NULL,
    ha_eligible boolean DEFAULT false NOT NULL,
    api_update_in_process boolean DEFAULT false NOT NULL,
    api_update_started_at timestamp without time zone,
    api_last_updated_at timestamp without time zone,
    creator_id integer,
    cspech_eligible boolean DEFAULT false,
    consent_form_signed_on date,
    vispdat_prioritization_days_homeless integer,
    generate_history_pdf boolean DEFAULT false,
    congregate_housing boolean DEFAULT false,
    sober_housing boolean DEFAULT false,
    consent_form_id integer,
    rrh_assessment_score integer,
    ssvf_eligible boolean DEFAULT false NOT NULL,
    rrh_desired boolean DEFAULT false NOT NULL,
    youth_rrh_desired boolean DEFAULT false NOT NULL,
    rrh_assessment_contact_info character varying,
    rrh_assessment_collected_at timestamp without time zone,
    source_hash character varying,
    generate_manual_history_pdf boolean DEFAULT false NOT NULL,
    requires_wheelchair_accessibility boolean DEFAULT false,
    required_number_of_bedrooms integer DEFAULT 1,
    required_minimum_occupancy integer DEFAULT 1,
    requires_elevator_access boolean DEFAULT false,
    neighborhood_interests jsonb DEFAULT '[]'::jsonb NOT NULL,
    verified_veteran_status character varying,
    interested_in_set_asides boolean DEFAULT false,
    consent_expires_on date,
    pending_date_deleted timestamp without time zone,
    cas_match_override date,
    vash_eligible boolean DEFAULT false,
    consented_coc_codes jsonb DEFAULT '[]'::jsonb,
    income_maximization_assistance_requested boolean DEFAULT false NOT NULL,
    income_total_monthly integer,
    pending_subsidized_housing_placement boolean DEFAULT false NOT NULL,
    pathways_domestic_violence boolean DEFAULT false NOT NULL,
    rrh_th_desired boolean DEFAULT false NOT NULL,
    sro_ok boolean DEFAULT false NOT NULL,
    pathways_other_accessibility boolean DEFAULT false NOT NULL,
    pathways_disabled_housing boolean DEFAULT false NOT NULL,
    evicted boolean DEFAULT false NOT NULL,
    dv_rrh_desired boolean DEFAULT false,
    health_prioritized character varying,
    demographic_dirty boolean DEFAULT true,
    "encrypted_FirstName" character varying,
    "encrypted_FirstName_iv" character varying,
    "encrypted_MiddleName" character varying,
    "encrypted_MiddleName_iv" character varying,
    "encrypted_LastName" character varying,
    "encrypted_LastName_iv" character varying,
    "encrypted_SSN" character varying,
    "encrypted_SSN_iv" character varying,
    "encrypted_NameSuffix" character varying,
    "encrypted_NameSuffix_iv" character varying,
    soundex_first character varying,
    soundex_last character varying
);


--
-- Name: CurrentLivingSituation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."CurrentLivingSituation" (
    id integer NOT NULL,
    "CurrentLivingSitID" character varying(32) NOT NULL,
    "EnrollmentID" character varying NOT NULL,
    "PersonalID" character varying NOT NULL,
    "InformationDate" date NOT NULL,
    "CurrentLivingSituation" integer NOT NULL,
    "VerifiedBy" character varying,
    "LeaveSituation14Days" integer,
    "SubsequentResidence" integer,
    "ResourcesToObtain" integer,
    "LeaseOwn60Day" integer,
    "MovedTwoOrMore" integer,
    "LocationDetails" character varying,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateUpdated" timestamp without time zone NOT NULL,
    "UserID" character varying(32) NOT NULL,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    pending_date_deleted timestamp without time zone,
    source_hash character varying
);


--
-- Name: CurrentLivingSituation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."CurrentLivingSituation_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: CurrentLivingSituation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."CurrentLivingSituation_id_seq" OWNED BY public."CurrentLivingSituation".id;


--
-- Name: Disabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Disabilities" (
    "DisabilitiesID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "InformationDate" date,
    "DisabilityType" integer,
    "DisabilityResponse" integer,
    "IndefiniteAndImpairs" integer,
    "DocumentationOnFile" integer,
    "ReceivingServices" integer,
    "PATHHowConfirmed" integer,
    "PATHSMIInformation" integer,
    "TCellCountAvailable" integer,
    "TCellCount" integer,
    "TCellSource" integer,
    "ViralLoadAvailable" integer,
    "ViralLoad" integer,
    "ViralLoadSource" integer,
    "DataCollectionStage" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    source_hash character varying,
    pending_date_deleted timestamp without time zone,
    "AntiRetroviral" integer
);


--
-- Name: Disabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Disabilities_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Disabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Disabilities_id_seq" OWNED BY public."Disabilities".id;


--
-- Name: EmploymentEducation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."EmploymentEducation" (
    "EmploymentEducationID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "InformationDate" date,
    "LastGradeCompleted" integer,
    "SchoolStatus" integer,
    "Employed" integer,
    "EmploymentType" integer,
    "NotEmployedReason" integer,
    "DataCollectionStage" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    source_hash character varying,
    pending_date_deleted timestamp without time zone
);


--
-- Name: EmploymentEducation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."EmploymentEducation_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: EmploymentEducation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."EmploymentEducation_id_seq" OWNED BY public."EmploymentEducation".id;


--
-- Name: Enrollment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Enrollment" (
    "EnrollmentID" character varying(50),
    "PersonalID" character varying,
    "ProjectID" character varying(50),
    "EntryDate" date,
    "HouseholdID" character varying,
    "RelationshipToHoH" integer,
    "LivingSituation" integer,
    "OtherResidencePrior" character varying,
    "LengthOfStay" integer,
    "DisablingCondition" integer,
    "EntryFromStreetESSH" integer,
    "DateToStreetESSH" date,
    "ContinuouslyHomelessOneYear" integer,
    "TimesHomelessPastThreeYears" integer,
    "MonthsHomelessPastThreeYears" integer,
    "MonthsHomelessThisTime" integer,
    "StatusDocumented" integer,
    "HousingStatus" integer,
    "DateOfEngagement" date,
    "InPermanentHousing" integer,
    "MoveInDate" date,
    "DateOfPATHStatus" date,
    "ClientEnrolledInPATH" integer,
    "ReasonNotEnrolled" integer,
    "WorstHousingSituation" integer,
    "PercentAMI" integer,
    "LastPermanentStreet" character varying,
    "LastPermanentCity" character varying(50),
    "LastPermanentState" character varying(2),
    "LastPermanentZIP" character varying(10),
    "AddressDataQuality" integer,
    "DateOfBCPStatus" date,
    "EligibleForRHY" integer,
    "ReasonNoServices" integer,
    "SexualOrientation" integer,
    "FormerWardChildWelfare" integer,
    "ChildWelfareYears" integer,
    "ChildWelfareMonths" integer,
    "FormerWardJuvenileJustice" integer,
    "JuvenileJusticeYears" integer,
    "JuvenileJusticeMonths" integer,
    "HouseholdDynamics" integer,
    "SexualOrientationGenderIDYouth" integer,
    "SexualOrientationGenderIDFam" integer,
    "HousingIssuesYouth" integer,
    "HousingIssuesFam" integer,
    "SchoolEducationalIssuesYouth" integer,
    "SchoolEducationalIssuesFam" integer,
    "UnemploymentYouth" integer,
    "UnemploymentFam" integer,
    "MentalHealthIssuesYouth" integer,
    "MentalHealthIssuesFam" integer,
    "HealthIssuesYouth" integer,
    "HealthIssuesFam" integer,
    "PhysicalDisabilityYouth" integer,
    "PhysicalDisabilityFam" integer,
    "MentalDisabilityYouth" integer,
    "MentalDisabilityFam" integer,
    "AbuseAndNeglectYouth" integer,
    "AbuseAndNeglectFam" integer,
    "AlcoholDrugAbuseYouth" integer,
    "AlcoholDrugAbuseFam" integer,
    "InsufficientIncome" integer,
    "ActiveMilitaryParent" integer,
    "IncarceratedParent" integer,
    "IncarceratedParentStatus" integer,
    "ReferralSource" integer,
    "CountOutreachReferralApproaches" integer,
    "ExchangeForSex" integer,
    "ExchangeForSexPastThreeMonths" integer,
    "CountOfExchangeForSex" integer,
    "AskedOrForcedToExchangeForSex" integer,
    "AskedOrForcedToExchangeForSexPastThreeMonths" integer,
    "WorkPlaceViolenceThreats" integer,
    "WorkplacePromiseDifference" integer,
    "CoercedToContinueWork" integer,
    "LaborExploitPastThreeMonths" integer,
    "HPScreeningScore" integer,
    "VAMCStation" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    "LOSUnderThreshold" integer,
    "PreviousStreetESSH" integer,
    "UrgentReferral" integer,
    "TimeToHousingLoss" integer,
    "ZeroIncome" integer,
    "AnnualPercentAMI" integer,
    "FinancialChange" integer,
    "HouseholdChange" integer,
    "EvictionHistory" integer,
    "SubsidyAtRisk" integer,
    "LiteralHomelessHistory" integer,
    "DisabledHoH" integer,
    "CriminalRecord" integer,
    "SexOffender" integer,
    "DependentUnder6" integer,
    "SingleParent" integer,
    "HH5Plus" integer,
    "IraqAfghanistan" integer,
    "FemVet" integer,
    "ThresholdScore" integer,
    "ERVisits" integer,
    "JailNights" integer,
    "HospitalNights" integer,
    "RunawayYouth" integer,
    processed_hash character varying,
    processed_as character varying,
    roi_permission boolean,
    last_locality character varying,
    last_zipcode character varying,
    source_hash character varying,
    pending_date_deleted timestamp without time zone,
    "SexualOrientationOther" character varying(100),
    history_generated_on date,
    original_household_id character varying,
    service_history_processing_job_id bigint,
    "MentalHealthDisorderFam" integer,
    "AlcoholDrugUseDisorderFam" integer,
    "ClientLeaseholder" integer,
    "HOHLeasesholder" integer,
    "IncarceratedAdult" integer,
    "PrisonDischarge" integer,
    "CurrentPregnant" integer,
    "CoCPrioritized" integer,
    "TargetScreenReqd" integer
);


--
-- Name: EnrollmentCoC; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."EnrollmentCoC" (
    "EnrollmentCoCID" character varying,
    "EnrollmentID" character varying,
    "ProjectID" character varying,
    "PersonalID" character varying,
    "InformationDate" date,
    "CoCCode" character varying(50),
    "DataCollectionStage" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    "HouseholdID" character varying(32),
    source_hash character varying,
    pending_date_deleted timestamp without time zone
);


--
-- Name: EnrollmentCoC_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."EnrollmentCoC_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: EnrollmentCoC_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."EnrollmentCoC_id_seq" OWNED BY public."EnrollmentCoC".id;


--
-- Name: Enrollment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Enrollment_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Enrollment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Enrollment_id_seq" OWNED BY public."Enrollment".id;


--
-- Name: Event; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Event" (
    id integer NOT NULL,
    "EventID" character varying(32) NOT NULL,
    "EnrollmentID" character varying NOT NULL,
    "PersonalID" character varying NOT NULL,
    "EventDate" date NOT NULL,
    "Event" integer NOT NULL,
    "ProbSolDivRRResult" integer,
    "ReferralCaseManageAfter" integer,
    "LocationCrisisorPHHousing" character varying,
    "ReferralResult" integer,
    "ResultDate" date,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateUpdated" timestamp without time zone NOT NULL,
    "UserID" character varying(32) NOT NULL,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    pending_date_deleted timestamp without time zone,
    source_hash character varying,
    synthetic boolean DEFAULT false
);


--
-- Name: Event_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Event_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Event_id_seq" OWNED BY public."Event".id;


--
-- Name: Exit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Exit" (
    "ExitID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "ExitDate" date,
    "Destination" integer,
    "OtherDestination" character varying,
    "AssessmentDisposition" integer,
    "OtherDisposition" character varying,
    "HousingAssessment" integer,
    "SubsidyInformation" integer,
    "ConnectionWithSOAR" integer,
    "WrittenAftercarePlan" integer,
    "AssistanceMainstreamBenefits" integer,
    "PermanentHousingPlacement" integer,
    "TemporaryShelterPlacement" integer,
    "ExitCounseling" integer,
    "FurtherFollowUpServices" integer,
    "ScheduledFollowUpContacts" integer,
    "ResourcePackage" integer,
    "OtherAftercarePlanOrAction" integer,
    "ProjectCompletionStatus" integer,
    "EarlyExitReason" integer,
    "FamilyReunificationAchieved" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    "ExchangeForSex" integer,
    "ExchangeForSexPastThreeMonths" integer,
    "CountOfExchangeForSex" integer,
    "AskedOrForcedToExchangeForSex" integer,
    "AskedOrForcedToExchangeForSexPastThreeMonths" integer,
    "WorkPlaceViolenceThreats" integer,
    "WorkplacePromiseDifference" integer,
    "CoercedToContinueWork" integer,
    "LaborExploitPastThreeMonths" integer,
    "CounselingReceived" integer,
    "IndividualCounseling" integer,
    "FamilyCounseling" integer,
    "GroupCounseling" integer,
    "SessionCountAtExit" integer,
    "PostExitCounselingPlan" integer,
    "SessionsInPlan" integer,
    "DestinationSafeClient" integer,
    "DestinationSafeWorker" integer,
    "PosAdultConnections" integer,
    "PosPeerConnections" integer,
    "PosCommunityConnections" integer,
    "AftercareDate" date,
    "AftercareProvided" integer,
    "EmailSocialMedia" integer,
    "Telephone" integer,
    "InPersonIndividual" integer,
    "InPersonGroup" integer,
    "CMExitReason" integer,
    source_hash character varying,
    pending_date_deleted timestamp without time zone
);


--
-- Name: Exit_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Exit_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Exit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Exit_id_seq" OWNED BY public."Exit".id;


--
-- Name: Export; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Export" (
    "ExportID" character varying,
    "SourceID" character varying,
    "SourceName" character varying,
    "SourceContactFirst" character varying,
    "SourceContactLast" character varying,
    "SourceContactPhone" character varying,
    "SourceContactExtension" character varying,
    "SourceContactEmail" character varying,
    "ExportDate" timestamp without time zone,
    "ExportStartDate" date,
    "ExportEndDate" date,
    "SoftwareName" character varying,
    "SoftwareVersion" character varying,
    "ExportPeriodType" integer,
    "ExportDirective" integer,
    "HashStatus" integer,
    data_source_id integer,
    id integer NOT NULL,
    "SourceType" integer,
    effective_export_end_date date,
    source_hash character varying,
    "CSVVersion" character varying
);


--
-- Name: Export_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Export_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Export_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Export_id_seq" OWNED BY public."Export".id;


--
-- Name: Funder; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Funder" (
    "FunderID" character varying,
    "ProjectID" character varying,
    "Funder" character varying,
    "GrantID" character varying,
    "StartDate" date,
    "EndDate" date,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    source_hash character varying,
    pending_date_deleted timestamp without time zone,
    "OtherFunder" character varying,
    manual_entry boolean DEFAULT false
);


--
-- Name: Funder_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Funder_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Funder_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Funder_id_seq" OWNED BY public."Funder".id;


--
-- Name: Geography; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Geography" (
    "GeographyID" character varying,
    "ProjectID" character varying,
    "CoCCode" character varying(50),
    "PrincipalSite" integer,
    "Geocode" character varying(50),
    "Address1" character varying,
    "City" character varying,
    "State" character varying(2),
    "ZIP" character varying(10),
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    "InformationDate" date,
    "Address2" character varying,
    "GeographyType" integer,
    source_hash character varying,
    geocode_override character varying(6),
    geography_type_override integer,
    information_date_override date,
    pending_date_deleted timestamp without time zone
);


--
-- Name: Geography_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Geography_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Geography_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Geography_id_seq" OWNED BY public."Geography".id;


--
-- Name: HealthAndDV; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."HealthAndDV" (
    "HealthAndDVID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "InformationDate" date,
    "DomesticViolenceVictim" integer,
    "WhenOccurred" integer,
    "CurrentlyFleeing" integer,
    "GeneralHealthStatus" integer,
    "DentalHealthStatus" integer,
    "MentalHealthStatus" integer,
    "PregnancyStatus" integer,
    "DueDate" date,
    "DataCollectionStage" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    source_hash character varying,
    pending_date_deleted timestamp without time zone,
    "LifeValue" integer,
    "SupportfromOthers" integer,
    "BounceBack" integer,
    "FeelingFrequency" integer
);


--
-- Name: HealthAndDV_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."HealthAndDV_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: HealthAndDV_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."HealthAndDV_id_seq" OWNED BY public."HealthAndDV".id;


--
-- Name: IncomeBenefits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."IncomeBenefits" (
    "IncomeBenefitsID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "InformationDate" date,
    "IncomeFromAnySource" integer,
    "TotalMonthlyIncome" numeric,
    "Earned" integer,
    "EarnedAmount" numeric,
    "Unemployment" integer,
    "UnemploymentAmount" numeric,
    "SSI" integer,
    "SSIAmount" numeric,
    "SSDI" integer,
    "SSDIAmount" numeric,
    "VADisabilityService" integer,
    "VADisabilityServiceAmount" numeric,
    "VADisabilityNonService" integer,
    "VADisabilityNonServiceAmount" numeric,
    "PrivateDisability" integer,
    "PrivateDisabilityAmount" numeric,
    "WorkersComp" integer,
    "WorkersCompAmount" numeric,
    "TANF" integer,
    "TANFAmount" numeric,
    "GA" integer,
    "GAAmount" numeric,
    "SocSecRetirement" integer,
    "SocSecRetirementAmount" numeric,
    "Pension" integer,
    "PensionAmount" numeric,
    "ChildSupport" integer,
    "ChildSupportAmount" numeric,
    "Alimony" integer,
    "AlimonyAmount" numeric,
    "OtherIncomeSource" integer,
    "OtherIncomeAmount" numeric,
    "OtherIncomeSourceIdentify" character varying,
    "BenefitsFromAnySource" integer,
    "SNAP" integer,
    "WIC" integer,
    "TANFChildCare" integer,
    "TANFTransportation" integer,
    "OtherTANF" integer,
    "RentalAssistanceOngoing" integer,
    "RentalAssistanceTemp" integer,
    "OtherBenefitsSource" integer,
    "OtherBenefitsSourceIdentify" character varying,
    "InsuranceFromAnySource" integer,
    "Medicaid" integer,
    "NoMedicaidReason" integer,
    "Medicare" integer,
    "NoMedicareReason" integer,
    "SCHIP" integer,
    "NoSCHIPReason" integer,
    "VAMedicalServices" integer,
    "NoVAMedReason" integer,
    "EmployerProvided" integer,
    "NoEmployerProvidedReason" integer,
    "COBRA" integer,
    "NoCOBRAReason" integer,
    "PrivatePay" integer,
    "NoPrivatePayReason" integer,
    "StateHealthIns" integer,
    "NoStateHealthInsReason" integer,
    "HIVAIDSAssistance" integer,
    "NoHIVAIDSAssistanceReason" integer,
    "ADAP" integer,
    "NoADAPReason" integer,
    "DataCollectionStage" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    "IndianHealthServices" integer,
    "NoIndianHealthServicesReason" integer,
    "OtherInsurance" integer,
    "OtherInsuranceIdentify" character varying(50),
    "ConnectionWithSOAR" integer,
    source_hash character varying,
    pending_date_deleted timestamp without time zone,
    "RyanWhiteMedDent" integer,
    "NoRyanWhiteReason" integer
);


--
-- Name: IncomeBenefits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."IncomeBenefits_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: IncomeBenefits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."IncomeBenefits_id_seq" OWNED BY public."IncomeBenefits".id;


--
-- Name: Inventory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Inventory" (
    "InventoryID" character varying,
    "ProjectID" character varying,
    "CoCCode" character varying(50),
    "InformationDate" date,
    "HouseholdType" integer,
    "BedType" integer,
    "Availability" integer,
    "UnitInventory" integer,
    "BedInventory" integer,
    "CHBedInventory" integer,
    "VetBedInventory" integer,
    "YouthBedInventory" integer,
    "YouthAgeGroup" integer,
    "InventoryStartDate" date,
    "InventoryEndDate" date,
    "HMISParticipatingBeds" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    source_hash character varying,
    pending_date_deleted timestamp without time zone,
    "CHVetBedInventory" integer,
    "YouthVetBedInventory" integer,
    "CHYouthBedInventory" integer,
    "OtherBedInventory" integer,
    "TargetPopulation" integer,
    "ESBedType" integer,
    coc_code_override character varying,
    inventory_start_date_override date,
    inventory_end_date_override date,
    manual_entry boolean DEFAULT false
);


--
-- Name: Inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Inventory_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Inventory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Inventory_id_seq" OWNED BY public."Inventory".id;


--
-- Name: Organization; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Organization" (
    "OrganizationID" character varying(50),
    "OrganizationName" character varying,
    "OrganizationCommonName" character varying,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    dmh boolean DEFAULT false NOT NULL,
    source_hash character varying,
    pending_date_deleted timestamp without time zone,
    "VictimServicesProvider" integer,
    "VictimServiceProvider" integer
);


--
-- Name: Organization_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Organization_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Organization_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Organization_id_seq" OWNED BY public."Organization".id;


--
-- Name: Project; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Project" (
    "ProjectID" character varying(50),
    "OrganizationID" character varying(50),
    "ProjectName" character varying,
    "ProjectCommonName" character varying,
    "ContinuumProject" integer,
    "ProjectType" integer,
    "ResidentialAffiliation" integer,
    "TrackingMethod" integer,
    "TargetPopulation" integer,
    "PITCount" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    act_as_project_type integer,
    hud_continuum_funded boolean,
    confidential boolean DEFAULT false NOT NULL,
    computed_project_type integer,
    "OperatingStartDate" date,
    "OperatingEndDate" date,
    "VictimServicesProvider" integer,
    "HousingType" integer,
    local_planning_group character varying,
    source_hash character varying,
    housing_type_override integer,
    uses_move_in_date boolean DEFAULT false NOT NULL,
    operating_start_date_override date,
    pending_date_deleted timestamp without time zone,
    "HMISParticipatingProject" integer,
    active_homeless_status_override boolean DEFAULT false,
    include_in_days_homeless_override boolean DEFAULT false,
    extrapolate_contacts boolean DEFAULT false NOT NULL,
    combine_enrollments boolean DEFAULT false,
    hmis_participating_project_override integer,
    target_population_override integer,
    tracking_method_override integer,
    operating_end_date_override date,
    "HOPWAMedAssistedLivingFac" integer
);


--
-- Name: ProjectCoC; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."ProjectCoC" (
    "ProjectCoCID" character varying(50),
    "ProjectID" character varying,
    "CoCCode" character varying(50),
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    hud_coc_code character varying,
    source_hash character varying,
    pending_date_deleted timestamp without time zone,
    "Geocode" character varying(6),
    "GeographyType" integer,
    "Address1" character varying,
    "Address2" character varying,
    "City" character varying,
    "State" character varying(2),
    "Zip" character varying(5),
    geography_type_override integer,
    geocode_override character varying(6),
    zip_override character varying,
    manual_entry boolean DEFAULT false
);


--
-- Name: ProjectCoC_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."ProjectCoC_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ProjectCoC_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."ProjectCoC_id_seq" OWNED BY public."ProjectCoC".id;


--
-- Name: Project_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Project_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Project_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Project_id_seq" OWNED BY public."Project".id;


--
-- Name: Services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Services" (
    "ServicesID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "DateProvided" date,
    "RecordType" integer,
    "TypeProvided" integer,
    "OtherTypeProvided" character varying,
    "SubTypeProvided" integer,
    "FAAmount" numeric,
    "ReferralOutcome" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    source_hash character varying,
    pending_date_deleted timestamp without time zone,
    "MovingOnOtherType" character varying
);


--
-- Name: Services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Services_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Services_id_seq" OWNED BY public."Services".id;


--
-- Name: Site; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."Site" AS
 SELECT "Geography"."GeographyID",
    "Geography"."ProjectID",
    "Geography"."CoCCode",
    "Geography"."PrincipalSite",
    "Geography"."Geocode",
    "Geography"."Address1",
    "Geography"."City",
    "Geography"."State",
    "Geography"."ZIP",
    "Geography"."DateCreated",
    "Geography"."DateUpdated",
    "Geography"."UserID",
    "Geography"."DateDeleted",
    "Geography"."ExportID",
    "Geography".data_source_id,
    "Geography".id,
    "Geography"."InformationDate",
    "Geography"."Address2",
    "Geography"."GeographyType",
    "Geography".source_hash
   FROM public."Geography";


--
-- Name: User; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."User" (
    id integer NOT NULL,
    "UserID" character varying(32) NOT NULL,
    "UserFirstName" character varying,
    "UserLastName" character varying,
    "UserPhone" character varying(10),
    "UserExtension" character varying(5),
    "UserEmail" character varying,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    pending_date_deleted timestamp without time zone,
    source_hash character varying
);


--
-- Name: User_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."User_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: User_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."User_id_seq" OWNED BY public."User".id;


--
-- Name: YouthEducationStatus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."YouthEducationStatus" (
    id bigint NOT NULL,
    "YouthEducationStatusID" character varying(32) NOT NULL,
    "EnrollmentID" character varying(32) NOT NULL,
    "PersonalID" character varying(32) NOT NULL,
    "InformationDate" date NOT NULL,
    "CurrentSchoolAttend" integer,
    "MostRecentEdStatus" integer,
    "CurrentEdStatus" integer,
    "DataCollectionStage" integer NOT NULL,
    "DateCreated" timestamp without time zone NOT NULL,
    "DateUpdated" timestamp without time zone NOT NULL,
    "UserID" character varying(32) NOT NULL,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying(32) NOT NULL,
    data_source_id integer
);


--
-- Name: YouthEducationStatus_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."YouthEducationStatus_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: YouthEducationStatus_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."YouthEducationStatus_id_seq" OWNED BY public."YouthEducationStatus".id;


--
-- Name: ad_hoc_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ad_hoc_batches (
    id integer NOT NULL,
    ad_hoc_data_source_id integer,
    description character varying NOT NULL,
    uploaded_count integer,
    matched_count integer,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    import_errors character varying,
    file character varying,
    name character varying,
    size character varying,
    content_type character varying,
    content bytea,
    user_id integer
);


--
-- Name: ad_hoc_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ad_hoc_batches_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ad_hoc_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ad_hoc_batches_id_seq OWNED BY public.ad_hoc_batches.id;


--
-- Name: ad_hoc_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ad_hoc_clients (
    id integer NOT NULL,
    ad_hoc_data_source_id integer,
    client_id integer,
    matching_client_ids jsonb,
    batch_id integer,
    first_name character varying,
    middle_name character varying,
    last_name character varying,
    ssn character varying,
    dob date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: ad_hoc_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ad_hoc_clients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ad_hoc_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ad_hoc_clients_id_seq OWNED BY public.ad_hoc_clients.id;


--
-- Name: ad_hoc_data_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ad_hoc_data_sources (
    id integer NOT NULL,
    name character varying NOT NULL,
    short_name character varying,
    description character varying,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    user_id bigint
);


--
-- Name: ad_hoc_data_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ad_hoc_data_sources_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ad_hoc_data_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ad_hoc_data_sources_id_seq OWNED BY public.ad_hoc_data_sources.id;


--
-- Name: administrative_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.administrative_events (
    id integer NOT NULL,
    user_id integer NOT NULL,
    date date NOT NULL,
    title character varying NOT NULL,
    description character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: administrative_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.administrative_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: administrative_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.administrative_events_id_seq OWNED BY public.administrative_events.id;


--
-- Name: anomalies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.anomalies (
    id integer NOT NULL,
    client_id integer,
    submitted_by integer,
    description character varying,
    status character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: anomalies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.anomalies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: anomalies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.anomalies_id_seq OWNED BY public.anomalies.id;


--
-- Name: api_client_data_source_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_client_data_source_ids (
    id integer NOT NULL,
    warehouse_id character varying,
    id_in_data_source character varying,
    site_id_in_data_source integer,
    data_source_id integer,
    client_id integer,
    last_contact date,
    temporary_high_priority boolean DEFAULT false NOT NULL
);


--
-- Name: api_client_data_source_ids_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_client_data_source_ids_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_client_data_source_ids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_client_data_source_ids_id_seq OWNED BY public.api_client_data_source_ids.id;


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
-- Name: available_file_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.available_file_tags (
    id integer NOT NULL,
    name character varying,
    "group" character varying,
    included_info character varying,
    weight integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    document_ready boolean DEFAULT false,
    notification_trigger boolean DEFAULT false,
    consent_form boolean DEFAULT false,
    note character varying,
    full_release boolean DEFAULT false NOT NULL,
    requires_effective_date boolean DEFAULT false NOT NULL,
    requires_expiration_date boolean DEFAULT false NOT NULL,
    required_for character varying,
    coc_available boolean DEFAULT false NOT NULL,
    verified_homeless_history boolean DEFAULT false NOT NULL
);


--
-- Name: available_file_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.available_file_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: available_file_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.available_file_tags_id_seq OWNED BY public.available_file_tags.id;


--
-- Name: bi_Affiliation; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_Affiliation" AS
 SELECT "Affiliation".id AS "AffiliationID",
    "Project".id AS "ProjectID",
    "Affiliation"."ResProjectID",
    "Affiliation"."DateCreated",
    "Affiliation"."DateUpdated",
    "Affiliation"."UserID",
    "Affiliation"."DateDeleted",
    "Affiliation"."ExportID",
    "Affiliation".data_source_id
   FROM (public."Affiliation"
     JOIN public."Project" ON ((("Affiliation".data_source_id = "Project".data_source_id) AND (("Affiliation"."ProjectID")::text = ("Project"."ProjectID")::text) AND ("Project"."DateDeleted" IS NULL))))
  WHERE ("Affiliation"."DateDeleted" IS NULL);


--
-- Name: warehouse_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_clients (
    id integer NOT NULL,
    id_in_source character varying NOT NULL,
    data_source_id integer,
    proposed_at timestamp without time zone,
    reviewed_at timestamp without time zone,
    reviewd_by character varying,
    approved_at timestamp without time zone,
    rejected_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    source_id integer,
    destination_id integer,
    client_match_id integer
);


--
-- Name: bi_Assessment; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_Assessment" AS
 SELECT "Assessment".id AS "AssessmentID",
    warehouse_clients.destination_id AS "PersonalID",
    "Enrollment".id AS "EnrollmentID",
    "Assessment"."AssessmentDate",
    "Assessment"."AssessmentLocation",
    "Assessment"."AssessmentType",
    "Assessment"."AssessmentLevel",
    "Assessment"."PrioritizationStatus",
    "Assessment"."DateCreated",
    "Assessment"."DateUpdated",
    "Assessment"."UserID",
    "Assessment"."DateDeleted",
    "Assessment"."ExportID",
    "Assessment".data_source_id,
    source_clients.id AS demographic_id
   FROM (((((public."Assessment"
     JOIN public."Enrollment" ON ((("Assessment".data_source_id = "Enrollment".data_source_id) AND (("Assessment"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
     LEFT JOIN public."Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
     JOIN public."Client" source_clients ON ((("Assessment".data_source_id = source_clients.data_source_id) AND (("Assessment"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
  WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("Assessment"."DateDeleted" IS NULL)));


--
-- Name: bi_AssessmentQuestions; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_AssessmentQuestions" AS
 SELECT "AssessmentQuestions".id AS "AssessmentQuestionID",
    warehouse_clients.destination_id AS "PersonalID",
    "Assessment".id AS "AssessmentID",
    "Enrollment".id AS "EnrollmentID",
    "AssessmentQuestions"."AssessmentQuestionGroup",
    "AssessmentQuestions"."AssessmentQuestionOrder",
    "AssessmentQuestions"."AssessmentQuestion",
    "AssessmentQuestions"."AssessmentAnswer",
    "AssessmentQuestions"."DateCreated",
    "AssessmentQuestions"."DateUpdated",
    "AssessmentQuestions"."UserID",
    "AssessmentQuestions"."DateDeleted",
    "AssessmentQuestions"."ExportID",
    "AssessmentQuestions".data_source_id,
    source_clients.id AS demographic_id
   FROM ((((((public."AssessmentQuestions"
     JOIN public."Enrollment" ON ((("AssessmentQuestions".data_source_id = "Enrollment".data_source_id) AND (("AssessmentQuestions"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
     LEFT JOIN public."Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
     JOIN public."Client" source_clients ON ((("AssessmentQuestions".data_source_id = source_clients.data_source_id) AND (("AssessmentQuestions"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
     JOIN public."Assessment" ON ((("AssessmentQuestions".data_source_id = "Assessment".data_source_id) AND (("AssessmentQuestions"."AssessmentID")::text = ("Assessment"."AssessmentID")::text) AND ("Assessment"."DateDeleted" IS NULL))))
  WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("AssessmentQuestions"."DateDeleted" IS NULL)));


--
-- Name: bi_AssessmentResults; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_AssessmentResults" AS
 SELECT "AssessmentResults".id AS "AssessmentResultID",
    warehouse_clients.destination_id AS "PersonalID",
    "Assessment".id AS "AssessmentID",
    "Enrollment".id AS "EnrollmentID",
    "AssessmentResults"."AssessmentResultType",
    "AssessmentResults"."AssessmentResult",
    "AssessmentResults"."DateCreated",
    "AssessmentResults"."DateUpdated",
    "AssessmentResults"."UserID",
    "AssessmentResults"."DateDeleted",
    "AssessmentResults"."ExportID",
    "AssessmentResults".data_source_id,
    source_clients.id AS demographic_id
   FROM ((((((public."AssessmentResults"
     JOIN public."Enrollment" ON ((("AssessmentResults".data_source_id = "Enrollment".data_source_id) AND (("AssessmentResults"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
     LEFT JOIN public."Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
     JOIN public."Client" source_clients ON ((("AssessmentResults".data_source_id = source_clients.data_source_id) AND (("AssessmentResults"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
     JOIN public."Assessment" ON ((("AssessmentResults".data_source_id = "Assessment".data_source_id) AND (("AssessmentResults"."AssessmentID")::text = ("Assessment"."AssessmentID")::text) AND ("Assessment"."DateDeleted" IS NULL))))
  WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("AssessmentResults"."DateDeleted" IS NULL)));


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
    source_type character varying,
    munged_personal_id boolean DEFAULT false NOT NULL,
    short_name character varying,
    visible_in_window boolean DEFAULT false NOT NULL,
    authoritative boolean DEFAULT false,
    after_create_path character varying,
    import_paused boolean DEFAULT false NOT NULL,
    authoritative_type character varying,
    source_id character varying,
    deleted_at timestamp without time zone,
    service_scannable boolean DEFAULT false NOT NULL,
    import_aggregators jsonb DEFAULT '{}'::jsonb,
    import_cleanups jsonb DEFAULT '{}'::jsonb,
    refuse_imports_with_errors boolean DEFAULT false
);


--
-- Name: bi_Client; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_Client" AS
 SELECT "Client".id AS personalid,
    4 AS "HashStatus",
    encode(sha256((public.soundex(upper(btrim(("Client"."FirstName")::text))))::bytea), 'hex'::text) AS "FirstName",
    encode(sha256((public.soundex(upper(btrim(("Client"."MiddleName")::text))))::bytea), 'hex'::text) AS "MiddleName",
    encode(sha256((public.soundex(upper(btrim(("Client"."LastName")::text))))::bytea), 'hex'::text) AS "LastName",
    encode(sha256((public.soundex(upper(btrim(("Client"."NameSuffix")::text))))::bytea), 'hex'::text) AS "NameSuffix",
    "Client"."NameDataQuality",
    concat("right"(("Client"."SSN")::text, 4), encode(sha256((lpad(("Client"."SSN")::text, 9, 'x'::text))::bytea), 'hex'::text)) AS "SSN",
    "Client"."SSNDataQuality",
    "Client"."DOB",
    "Client"."DOBDataQuality",
    "Client"."AmIndAKNative",
    "Client"."Asian",
    "Client"."BlackAfAmerican",
    "Client"."NativeHIOtherPacific",
    "Client"."White",
    "Client"."RaceNone",
    "Client"."Ethnicity",
    "Client"."Gender",
    "Client"."VeteranStatus",
    "Client"."YearEnteredService",
    "Client"."YearSeparated",
    "Client"."WorldWarII",
    "Client"."KoreanWar",
    "Client"."VietnamWar",
    "Client"."DesertStorm",
    "Client"."AfghanistanOEF",
    "Client"."IraqOIF",
    "Client"."IraqOND",
    "Client"."OtherTheater",
    "Client"."MilitaryBranch",
    "Client"."DischargeStatus",
    "Client"."DateCreated",
    "Client"."DateUpdated",
    "Client"."UserID",
    "Client"."DateDeleted",
    "Client"."ExportID"
   FROM public."Client"
  WHERE (("Client"."DateDeleted" IS NULL) AND ("Client".data_source_id IN ( SELECT data_sources.id
           FROM public.data_sources
          WHERE ((data_sources.deleted_at IS NULL) AND (data_sources.source_type IS NULL) AND (data_sources.authoritative = false)))));


--
-- Name: bi_CurrentLivingSituation; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_CurrentLivingSituation" AS
 SELECT "CurrentLivingSituation".id AS "CurrentLivingSitID",
    warehouse_clients.destination_id AS "PersonalID",
    "Enrollment".id AS "EnrollmentID",
    "CurrentLivingSituation"."InformationDate",
    "CurrentLivingSituation"."CurrentLivingSituation",
    "CurrentLivingSituation"."VerifiedBy",
    "CurrentLivingSituation"."LeaveSituation14Days",
    "CurrentLivingSituation"."SubsequentResidence",
    "CurrentLivingSituation"."ResourcesToObtain",
    "CurrentLivingSituation"."LeaseOwn60Day",
    "CurrentLivingSituation"."MovedTwoOrMore",
    "CurrentLivingSituation"."LocationDetails",
    "CurrentLivingSituation"."DateCreated",
    "CurrentLivingSituation"."DateUpdated",
    "CurrentLivingSituation"."UserID",
    "CurrentLivingSituation"."DateDeleted",
    "CurrentLivingSituation"."ExportID",
    "CurrentLivingSituation".data_source_id,
    source_clients.id AS demographic_id
   FROM (((((public."CurrentLivingSituation"
     JOIN public."Enrollment" ON ((("CurrentLivingSituation".data_source_id = "Enrollment".data_source_id) AND (("CurrentLivingSituation"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
     LEFT JOIN public."Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
     JOIN public."Client" source_clients ON ((("CurrentLivingSituation".data_source_id = source_clients.data_source_id) AND (("CurrentLivingSituation"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
  WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("CurrentLivingSituation"."DateDeleted" IS NULL)));


--
-- Name: bi_Demographics; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_Demographics" AS
 SELECT "Client".id AS personalid,
    4 AS "HashStatus",
    encode(sha256((public.soundex(upper(btrim(("Client"."FirstName")::text))))::bytea), 'hex'::text) AS "FirstName",
    encode(sha256((public.soundex(upper(btrim(("Client"."MiddleName")::text))))::bytea), 'hex'::text) AS "MiddleName",
    encode(sha256((public.soundex(upper(btrim(("Client"."LastName")::text))))::bytea), 'hex'::text) AS "LastName",
    encode(sha256((public.soundex(upper(btrim(("Client"."NameSuffix")::text))))::bytea), 'hex'::text) AS "NameSuffix",
    "Client"."NameDataQuality",
    concat("right"(("Client"."SSN")::text, 4), encode(sha256((lpad(("Client"."SSN")::text, 9, 'x'::text))::bytea), 'hex'::text)) AS "SSN",
    "Client"."SSNDataQuality",
    "Client"."DOB",
    "Client"."DOBDataQuality",
    "Client"."AmIndAKNative",
    "Client"."Asian",
    "Client"."BlackAfAmerican",
    "Client"."NativeHIOtherPacific",
    "Client"."White",
    "Client"."RaceNone",
    "Client"."Ethnicity",
    "Client"."Gender",
    "Client"."VeteranStatus",
    "Client"."YearEnteredService",
    "Client"."YearSeparated",
    "Client"."WorldWarII",
    "Client"."KoreanWar",
    "Client"."VietnamWar",
    "Client"."DesertStorm",
    "Client"."AfghanistanOEF",
    "Client"."IraqOIF",
    "Client"."IraqOND",
    "Client"."OtherTheater",
    "Client"."MilitaryBranch",
    "Client"."DischargeStatus",
    "Client"."DateCreated",
    "Client"."DateUpdated",
    "Client"."UserID",
    "Client"."DateDeleted",
    "Client"."ExportID",
    warehouse_clients.destination_id AS client_id,
    "Client".data_source_id
   FROM (public."Client"
     JOIN public.warehouse_clients ON ((warehouse_clients.source_id = "Client".id)))
  WHERE (("Client"."DateDeleted" IS NULL) AND ("Client".data_source_id IN ( SELECT data_sources.id
           FROM public.data_sources
          WHERE ((data_sources.deleted_at IS NULL) AND ((data_sources.source_type IS NOT NULL) OR (data_sources.authoritative = true))))));


--
-- Name: bi_Disabilities; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_Disabilities" AS
 SELECT "Disabilities".id AS "DisabilitiesID",
    warehouse_clients.destination_id AS "PersonalID",
    "Enrollment".id AS "EnrollmentID",
    "Disabilities"."InformationDate",
    "Disabilities"."DisabilityType",
    "Disabilities"."DisabilityResponse",
    "Disabilities"."IndefiniteAndImpairs",
    "Disabilities"."TCellCountAvailable",
    "Disabilities"."TCellCount",
    "Disabilities"."TCellSource",
    "Disabilities"."ViralLoadAvailable",
    "Disabilities"."ViralLoad",
    "Disabilities"."ViralLoadSource",
    "Disabilities"."DataCollectionStage",
    "Disabilities"."DateCreated",
    "Disabilities"."DateUpdated",
    "Disabilities"."UserID",
    "Disabilities"."DateDeleted",
    "Disabilities"."ExportID",
    "Disabilities".data_source_id,
    source_clients.id AS demographic_id
   FROM (((((public."Disabilities"
     JOIN public."Enrollment" ON ((("Disabilities".data_source_id = "Enrollment".data_source_id) AND (("Disabilities"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
     LEFT JOIN public."Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
     JOIN public."Client" source_clients ON ((("Disabilities".data_source_id = source_clients.data_source_id) AND (("Disabilities"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
  WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("Disabilities"."DateDeleted" IS NULL)));


--
-- Name: bi_EmploymentEducation; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_EmploymentEducation" AS
 SELECT "EmploymentEducation".id AS "EmploymentEducationID",
    warehouse_clients.destination_id AS "PersonalID",
    "Enrollment".id AS "EnrollmentID",
    "EmploymentEducation"."InformationDate",
    "EmploymentEducation"."LastGradeCompleted",
    "EmploymentEducation"."SchoolStatus",
    "EmploymentEducation"."Employed",
    "EmploymentEducation"."EmploymentType",
    "EmploymentEducation"."NotEmployedReason",
    "EmploymentEducation"."DataCollectionStage",
    "EmploymentEducation"."DateCreated",
    "EmploymentEducation"."DateUpdated",
    "EmploymentEducation"."UserID",
    "EmploymentEducation"."DateDeleted",
    "EmploymentEducation"."ExportID",
    "EmploymentEducation".data_source_id,
    source_clients.id AS demographic_id
   FROM (((((public."EmploymentEducation"
     JOIN public."Enrollment" ON ((("EmploymentEducation".data_source_id = "Enrollment".data_source_id) AND (("EmploymentEducation"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
     LEFT JOIN public."Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
     JOIN public."Client" source_clients ON ((("EmploymentEducation".data_source_id = source_clients.data_source_id) AND (("EmploymentEducation"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
  WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("EmploymentEducation"."DateDeleted" IS NULL)));


--
-- Name: bi_Enrollment; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_Enrollment" AS
 SELECT "Enrollment".id AS "EnrollmentID",
    warehouse_clients.destination_id AS "PersonalID",
    "Project".id AS "ProjectID",
    "Enrollment"."EntryDate",
    "Enrollment"."HouseholdID",
    "Enrollment"."RelationshipToHoH",
    "Enrollment"."LivingSituation",
    "Enrollment"."LengthOfStay",
    "Enrollment"."LOSUnderThreshold",
    "Enrollment"."PreviousStreetESSH",
    "Enrollment"."DateToStreetESSH",
    "Enrollment"."TimesHomelessPastThreeYears",
    "Enrollment"."MonthsHomelessPastThreeYears",
    "Enrollment"."DisablingCondition",
    "Enrollment"."DateOfEngagement",
    "Enrollment"."MoveInDate",
    "Enrollment"."DateOfPATHStatus",
    "Enrollment"."ClientEnrolledInPATH",
    "Enrollment"."ReasonNotEnrolled",
    "Enrollment"."WorstHousingSituation",
    "Enrollment"."PercentAMI",
    "Enrollment"."LastPermanentStreet",
    "Enrollment"."LastPermanentCity",
    "Enrollment"."LastPermanentState",
    "Enrollment"."LastPermanentZIP",
    "Enrollment"."AddressDataQuality",
    "Enrollment"."DateOfBCPStatus",
    "Enrollment"."EligibleForRHY",
    "Enrollment"."ReasonNoServices",
    "Enrollment"."RunawayYouth",
    "Enrollment"."SexualOrientation",
    "Enrollment"."SexualOrientationOther",
    "Enrollment"."FormerWardChildWelfare",
    "Enrollment"."ChildWelfareYears",
    "Enrollment"."ChildWelfareMonths",
    "Enrollment"."FormerWardJuvenileJustice",
    "Enrollment"."JuvenileJusticeYears",
    "Enrollment"."JuvenileJusticeMonths",
    "Enrollment"."UnemploymentFam",
    "Enrollment"."MentalHealthIssuesFam",
    "Enrollment"."PhysicalDisabilityFam",
    "Enrollment"."AlcoholDrugAbuseFam",
    "Enrollment"."InsufficientIncome",
    "Enrollment"."IncarceratedParent",
    "Enrollment"."ReferralSource",
    "Enrollment"."CountOutreachReferralApproaches",
    "Enrollment"."UrgentReferral",
    "Enrollment"."TimeToHousingLoss",
    "Enrollment"."ZeroIncome",
    "Enrollment"."AnnualPercentAMI",
    "Enrollment"."FinancialChange",
    "Enrollment"."HouseholdChange",
    "Enrollment"."EvictionHistory",
    "Enrollment"."SubsidyAtRisk",
    "Enrollment"."LiteralHomelessHistory",
    "Enrollment"."DisabledHoH",
    "Enrollment"."CriminalRecord",
    "Enrollment"."SexOffender",
    "Enrollment"."DependentUnder6",
    "Enrollment"."SingleParent",
    "Enrollment"."HH5Plus",
    "Enrollment"."IraqAfghanistan",
    "Enrollment"."FemVet",
    "Enrollment"."HPScreeningScore",
    "Enrollment"."ThresholdScore",
    "Enrollment"."VAMCStation",
    "Enrollment"."DateCreated",
    "Enrollment"."DateUpdated",
    "Enrollment"."UserID",
    "Enrollment"."DateDeleted",
    "Enrollment"."ExportID",
    "Enrollment".data_source_id,
    source_clients.id AS demographic_id
   FROM (((((public."Enrollment"
     JOIN public."Project" ON ((("Enrollment".data_source_id = "Project".data_source_id) AND (("Enrollment"."ProjectID")::text = ("Project"."ProjectID")::text) AND ("Project"."DateDeleted" IS NULL))))
     JOIN public."Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
     JOIN public."Client" source_clients ON ((("Enrollment".data_source_id = source_clients.data_source_id) AND (("Enrollment"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
  WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("Enrollment"."DateDeleted" IS NULL)));


--
-- Name: bi_EnrollmentCoC; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_EnrollmentCoC" AS
 SELECT "EnrollmentCoC".id AS "EnrollmentCoCID",
    warehouse_clients.destination_id AS "PersonalID",
    "Project".id AS "ProjectID",
    "Enrollment".id AS "EnrollmentID",
    "EnrollmentCoC"."HouseholdID",
    "EnrollmentCoC"."InformationDate",
    "EnrollmentCoC"."CoCCode",
    "EnrollmentCoC"."DataCollectionStage",
    "EnrollmentCoC"."DateCreated",
    "EnrollmentCoC"."DateUpdated",
    "EnrollmentCoC"."UserID",
    "EnrollmentCoC"."DateDeleted",
    "EnrollmentCoC"."ExportID",
    "EnrollmentCoC".data_source_id,
    source_clients.id AS demographic_id
   FROM ((((((public."EnrollmentCoC"
     JOIN public."Project" ON ((("EnrollmentCoC".data_source_id = "Project".data_source_id) AND (("EnrollmentCoC"."ProjectID")::text = ("Project"."ProjectID")::text) AND ("Project"."DateDeleted" IS NULL))))
     JOIN public."Enrollment" ON ((("EnrollmentCoC".data_source_id = "Enrollment".data_source_id) AND (("EnrollmentCoC"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
     LEFT JOIN public."Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
     JOIN public."Client" source_clients ON ((("EnrollmentCoC".data_source_id = source_clients.data_source_id) AND (("EnrollmentCoC"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
  WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("EnrollmentCoC"."DateDeleted" IS NULL)));


--
-- Name: bi_Event; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_Event" AS
 SELECT "Event".id AS "EventID",
    warehouse_clients.destination_id AS "PersonalID",
    "Enrollment".id AS "EnrollmentID",
    "Event"."EventDate",
    "Event"."Event",
    "Event"."ProbSolDivRRResult",
    "Event"."ReferralCaseManageAfter",
    "Event"."LocationCrisisorPHHousing",
    "Event"."ReferralResult",
    "Event"."ResultDate",
    "Event"."DateCreated",
    "Event"."DateUpdated",
    "Event"."UserID",
    "Event"."DateDeleted",
    "Event"."ExportID",
    "Event".data_source_id,
    source_clients.id AS demographic_id
   FROM (((((public."Event"
     JOIN public."Enrollment" ON ((("Event".data_source_id = "Enrollment".data_source_id) AND (("Event"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
     LEFT JOIN public."Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
     JOIN public."Client" source_clients ON ((("Event".data_source_id = source_clients.data_source_id) AND (("Event"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
  WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("Event"."DateDeleted" IS NULL)));


--
-- Name: bi_Exit; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_Exit" AS
 SELECT "Exit".id AS "ExitID",
    warehouse_clients.destination_id AS "PersonalID",
    "Enrollment".id AS "EnrollmentID",
    "Exit"."ExitDate",
    "Exit"."Destination",
    "Exit"."OtherDestination",
    "Exit"."HousingAssessment",
    "Exit"."SubsidyInformation",
    "Exit"."ProjectCompletionStatus",
    "Exit"."EarlyExitReason",
    "Exit"."ExchangeForSex",
    "Exit"."ExchangeForSexPastThreeMonths",
    "Exit"."CountOfExchangeForSex",
    "Exit"."AskedOrForcedToExchangeForSex",
    "Exit"."AskedOrForcedToExchangeForSexPastThreeMonths",
    "Exit"."WorkPlaceViolenceThreats",
    "Exit"."WorkplacePromiseDifference",
    "Exit"."CoercedToContinueWork",
    "Exit"."LaborExploitPastThreeMonths",
    "Exit"."CounselingReceived",
    "Exit"."IndividualCounseling",
    "Exit"."FamilyCounseling",
    "Exit"."GroupCounseling",
    "Exit"."SessionCountAtExit",
    "Exit"."PostExitCounselingPlan",
    "Exit"."SessionsInPlan",
    "Exit"."DestinationSafeClient",
    "Exit"."DestinationSafeWorker",
    "Exit"."PosAdultConnections",
    "Exit"."PosPeerConnections",
    "Exit"."PosCommunityConnections",
    "Exit"."AftercareDate",
    "Exit"."AftercareProvided",
    "Exit"."EmailSocialMedia",
    "Exit"."Telephone",
    "Exit"."InPersonIndividual",
    "Exit"."InPersonGroup",
    "Exit"."CMExitReason",
    "Exit"."DateCreated",
    "Exit"."DateUpdated",
    "Exit"."UserID",
    "Exit"."DateDeleted",
    "Exit"."ExportID",
    "Exit".data_source_id,
    source_clients.id AS demographic_id
   FROM ((((public."Exit"
     JOIN public."Enrollment" ON ((("Exit".data_source_id = "Enrollment".data_source_id) AND (("Exit"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
     JOIN public."Client" source_clients ON ((("Exit".data_source_id = source_clients.data_source_id) AND (("Exit"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
  WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("Exit"."DateDeleted" IS NULL)));


--
-- Name: bi_Export; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_Export" AS
 SELECT "Export".id AS "ExportID",
    "Export"."SourceType",
    "Export"."SourceID",
    "Export"."SourceName",
    "Export"."SourceContactFirst",
    "Export"."SourceContactLast",
    "Export"."SourceContactPhone",
    "Export"."SourceContactExtension",
    "Export"."SourceContactEmail",
    "Export"."ExportDate",
    "Export"."ExportStartDate",
    "Export"."ExportEndDate",
    "Export"."SoftwareName",
    "Export"."SoftwareVersion",
    "Export"."ExportPeriodType",
    "Export"."ExportDirective",
    "Export"."HashStatus",
    "Export".data_source_id
   FROM public."Export";


--
-- Name: bi_Funder; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_Funder" AS
 SELECT "Funder".id AS "FunderID",
    "Project".id AS "ProjectID",
    "Funder"."Funder",
    "Funder"."OtherFunder",
    "Funder"."GrantID",
    "Funder"."StartDate",
    "Funder"."EndDate",
    "Funder"."DateCreated",
    "Funder"."DateUpdated",
    "Funder"."UserID",
    "Funder"."DateDeleted",
    "Funder"."ExportID",
    "Funder".data_source_id
   FROM (public."Funder"
     JOIN public."Project" ON ((("Funder".data_source_id = "Project".data_source_id) AND (("Funder"."ProjectID")::text = ("Project"."ProjectID")::text) AND ("Project"."DateDeleted" IS NULL))))
  WHERE ("Funder"."DateDeleted" IS NULL);


--
-- Name: bi_HealthAndDV; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_HealthAndDV" AS
 SELECT "HealthAndDV".id AS "HealthAndDVID",
    warehouse_clients.destination_id AS "PersonalID",
    "Enrollment".id AS "EnrollmentID",
    "HealthAndDV"."InformationDate",
    "HealthAndDV"."DomesticViolenceVictim",
    "HealthAndDV"."WhenOccurred",
    "HealthAndDV"."CurrentlyFleeing",
    "HealthAndDV"."GeneralHealthStatus",
    "HealthAndDV"."DentalHealthStatus",
    "HealthAndDV"."MentalHealthStatus",
    "HealthAndDV"."PregnancyStatus",
    "HealthAndDV"."DueDate",
    "HealthAndDV"."DataCollectionStage",
    "HealthAndDV"."DateCreated",
    "HealthAndDV"."DateUpdated",
    "HealthAndDV"."UserID",
    "HealthAndDV"."DateDeleted",
    "HealthAndDV"."ExportID",
    "HealthAndDV".data_source_id,
    source_clients.id AS demographic_id
   FROM (((((public."HealthAndDV"
     JOIN public."Enrollment" ON ((("HealthAndDV".data_source_id = "Enrollment".data_source_id) AND (("HealthAndDV"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
     LEFT JOIN public."Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
     JOIN public."Client" source_clients ON ((("HealthAndDV".data_source_id = source_clients.data_source_id) AND (("HealthAndDV"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
  WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("HealthAndDV"."DateDeleted" IS NULL)));


--
-- Name: bi_IncomeBenefits; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_IncomeBenefits" AS
 SELECT "IncomeBenefits".id AS "IncomeBenefitsID",
    warehouse_clients.destination_id AS "PersonalID",
    "Enrollment".id AS "EnrollmentID",
    "IncomeBenefits"."InformationDate",
    "IncomeBenefits"."IncomeFromAnySource",
    "IncomeBenefits"."TotalMonthlyIncome",
    "IncomeBenefits"."Earned",
    "IncomeBenefits"."EarnedAmount",
    "IncomeBenefits"."Unemployment",
    "IncomeBenefits"."UnemploymentAmount",
    "IncomeBenefits"."SSI",
    "IncomeBenefits"."SSIAmount",
    "IncomeBenefits"."SSDI",
    "IncomeBenefits"."SSDIAmount",
    "IncomeBenefits"."VADisabilityService",
    "IncomeBenefits"."VADisabilityServiceAmount",
    "IncomeBenefits"."VADisabilityNonService",
    "IncomeBenefits"."VADisabilityNonServiceAmount",
    "IncomeBenefits"."PrivateDisability",
    "IncomeBenefits"."PrivateDisabilityAmount",
    "IncomeBenefits"."WorkersComp",
    "IncomeBenefits"."WorkersCompAmount",
    "IncomeBenefits"."TANF",
    "IncomeBenefits"."TANFAmount",
    "IncomeBenefits"."GA",
    "IncomeBenefits"."GAAmount",
    "IncomeBenefits"."SocSecRetirement",
    "IncomeBenefits"."SocSecRetirementAmount",
    "IncomeBenefits"."Pension",
    "IncomeBenefits"."PensionAmount",
    "IncomeBenefits"."ChildSupport",
    "IncomeBenefits"."ChildSupportAmount",
    "IncomeBenefits"."Alimony",
    "IncomeBenefits"."AlimonyAmount",
    "IncomeBenefits"."OtherIncomeSource",
    "IncomeBenefits"."OtherIncomeAmount",
    "IncomeBenefits"."OtherIncomeSourceIdentify",
    "IncomeBenefits"."BenefitsFromAnySource",
    "IncomeBenefits"."SNAP",
    "IncomeBenefits"."WIC",
    "IncomeBenefits"."TANFChildCare",
    "IncomeBenefits"."TANFTransportation",
    "IncomeBenefits"."OtherTANF",
    "IncomeBenefits"."OtherBenefitsSource",
    "IncomeBenefits"."OtherBenefitsSourceIdentify",
    "IncomeBenefits"."InsuranceFromAnySource",
    "IncomeBenefits"."Medicaid",
    "IncomeBenefits"."NoMedicaidReason",
    "IncomeBenefits"."Medicare",
    "IncomeBenefits"."NoMedicareReason",
    "IncomeBenefits"."SCHIP",
    "IncomeBenefits"."NoSCHIPReason",
    "IncomeBenefits"."VAMedicalServices",
    "IncomeBenefits"."NoVAMedReason",
    "IncomeBenefits"."EmployerProvided",
    "IncomeBenefits"."NoEmployerProvidedReason",
    "IncomeBenefits"."COBRA",
    "IncomeBenefits"."NoCOBRAReason",
    "IncomeBenefits"."PrivatePay",
    "IncomeBenefits"."NoPrivatePayReason",
    "IncomeBenefits"."StateHealthIns",
    "IncomeBenefits"."NoStateHealthInsReason",
    "IncomeBenefits"."IndianHealthServices",
    "IncomeBenefits"."NoIndianHealthServicesReason",
    "IncomeBenefits"."OtherInsurance",
    "IncomeBenefits"."OtherInsuranceIdentify",
    "IncomeBenefits"."HIVAIDSAssistance",
    "IncomeBenefits"."NoHIVAIDSAssistanceReason",
    "IncomeBenefits"."ADAP",
    "IncomeBenefits"."NoADAPReason",
    "IncomeBenefits"."ConnectionWithSOAR",
    "IncomeBenefits"."DataCollectionStage",
    "IncomeBenefits"."DateCreated",
    "IncomeBenefits"."DateUpdated",
    "IncomeBenefits"."UserID",
    "IncomeBenefits"."DateDeleted",
    "IncomeBenefits"."ExportID",
    "IncomeBenefits".data_source_id,
    source_clients.id AS demographic_id
   FROM (((((public."IncomeBenefits"
     JOIN public."Enrollment" ON ((("IncomeBenefits".data_source_id = "Enrollment".data_source_id) AND (("IncomeBenefits"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
     LEFT JOIN public."Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
     JOIN public."Client" source_clients ON ((("IncomeBenefits".data_source_id = source_clients.data_source_id) AND (("IncomeBenefits"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
  WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("IncomeBenefits"."DateDeleted" IS NULL)));


--
-- Name: bi_Inventory; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_Inventory" AS
 SELECT "Inventory".id AS "InventoryID",
    "Project".id AS "ProjectID",
    "Inventory"."CoCCode",
    "Inventory"."HouseholdType",
    "Inventory"."Availability",
    "Inventory"."UnitInventory",
    "Inventory"."BedInventory",
    "Inventory"."CHVetBedInventory",
    "Inventory"."YouthVetBedInventory",
    "Inventory"."VetBedInventory",
    "Inventory"."CHYouthBedInventory",
    "Inventory"."YouthBedInventory",
    "Inventory"."CHBedInventory",
    "Inventory"."OtherBedInventory",
    "Inventory"."ESBedType",
    "Inventory"."InventoryStartDate",
    "Inventory"."InventoryEndDate",
    "Inventory"."DateCreated",
    "Inventory"."DateUpdated",
    "Inventory"."UserID",
    "Inventory"."DateDeleted",
    "Inventory"."ExportID",
    "Inventory".data_source_id
   FROM (public."Inventory"
     JOIN public."Project" ON ((("Inventory".data_source_id = "Project".data_source_id) AND (("Inventory"."ProjectID")::text = ("Project"."ProjectID")::text) AND ("Project"."DateDeleted" IS NULL))))
  WHERE ("Inventory"."DateDeleted" IS NULL);


--
-- Name: bi_Organization; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_Organization" AS
 SELECT "Organization".id AS "OrganizationID",
    "Organization"."OrganizationName",
    "Organization"."VictimServicesProvider",
    "Organization"."OrganizationCommonName",
    "Organization"."DateCreated",
    "Organization"."DateUpdated",
    "Organization"."UserID",
    "Organization"."DateDeleted",
    "Organization"."ExportID",
    "Organization".data_source_id
   FROM public."Organization"
  WHERE ("Organization"."DateDeleted" IS NULL);


--
-- Name: bi_Project; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_Project" AS
 SELECT "Project".id AS "ProjectID",
    "Organization".id AS "OrganizationID",
    "Project"."ProjectName",
    "Project"."ProjectCommonName",
    "Project"."OperatingStartDate",
    "Project"."OperatingEndDate",
    "Project"."ContinuumProject",
    "Project"."ProjectType",
    "Project"."HousingType",
    "Project"."ResidentialAffiliation",
    "Project"."TrackingMethod",
    "Project"."HMISParticipatingProject",
    "Project"."TargetPopulation",
    "Project"."PITCount",
    "Project"."DateCreated",
    "Project"."DateUpdated",
    "Project"."UserID",
    "Project"."DateDeleted",
    "Project"."ExportID",
    "Project".data_source_id
   FROM (public."Project"
     JOIN public."Organization" ON ((("Project".data_source_id = "Organization".data_source_id) AND (("Project"."OrganizationID")::text = ("Organization"."OrganizationID")::text) AND ("Organization"."DateDeleted" IS NULL))))
  WHERE ("Project"."DateDeleted" IS NULL);


--
-- Name: bi_ProjectCoC; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_ProjectCoC" AS
 SELECT "ProjectCoC".id AS "ProjectCoCID",
    "Project".id AS "ProjectID",
    "ProjectCoC"."CoCCode",
    "ProjectCoC"."Geocode",
    "ProjectCoC"."Address1",
    "ProjectCoC"."Address2",
    "ProjectCoC"."City",
    "ProjectCoC"."State",
    "ProjectCoC"."Zip",
    "ProjectCoC"."GeographyType",
    "ProjectCoC"."DateCreated",
    "ProjectCoC"."DateUpdated",
    "ProjectCoC"."UserID",
    "ProjectCoC"."DateDeleted",
    "ProjectCoC"."ExportID",
    "ProjectCoC".data_source_id
   FROM (public."ProjectCoC"
     JOIN public."Project" ON ((("ProjectCoC".data_source_id = "Project".data_source_id) AND (("ProjectCoC"."ProjectID")::text = ("Project"."ProjectID")::text) AND ("Project"."DateDeleted" IS NULL))))
  WHERE ("ProjectCoC"."DateDeleted" IS NULL);


--
-- Name: bi_Services; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public."bi_Services" AS
 SELECT "Services".id AS "ServicesID",
    warehouse_clients.destination_id AS "PersonalID",
    "Enrollment".id AS "EnrollmentID",
    "Services"."DateProvided",
    "Services"."RecordType",
    "Services"."TypeProvided",
    "Services"."OtherTypeProvided",
    "Services"."SubTypeProvided",
    "Services"."FAAmount",
    "Services"."ReferralOutcome",
    "Services"."DateCreated",
    "Services"."DateUpdated",
    "Services"."UserID",
    "Services"."DateDeleted",
    "Services"."ExportID",
    "Services".data_source_id,
    source_clients.id AS demographic_id
   FROM (((((public."Services"
     JOIN public."Enrollment" ON ((("Services".data_source_id = "Enrollment".data_source_id) AND (("Services"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
     LEFT JOIN public."Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
     JOIN public."Client" source_clients ON ((("Services".data_source_id = source_clients.data_source_id) AND (("Services"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
  WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("Services"."DateProvided" >= (CURRENT_DATE - '5 years'::interval)) AND ("Services"."DateDeleted" IS NULL)));


--
-- Name: bi_data_sources; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bi_data_sources AS
 SELECT data_sources.id,
    data_sources.name,
    data_sources.short_name
   FROM public.data_sources
  WHERE ((data_sources.deleted_at IS NULL) AND (data_sources.deleted_at IS NULL));


--
-- Name: lookups_ethnicities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lookups_ethnicities (
    id bigint NOT NULL,
    value integer NOT NULL,
    text character varying NOT NULL
);


--
-- Name: bi_lookups_ethnicities; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bi_lookups_ethnicities AS
 SELECT lookups_ethnicities.id,
    lookups_ethnicities.value,
    lookups_ethnicities.text
   FROM public.lookups_ethnicities;


--
-- Name: lookups_funding_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lookups_funding_sources (
    id bigint NOT NULL,
    value integer NOT NULL,
    text character varying NOT NULL
);


--
-- Name: bi_lookups_funding_sources; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bi_lookups_funding_sources AS
 SELECT lookups_funding_sources.id,
    lookups_funding_sources.value,
    lookups_funding_sources.text
   FROM public.lookups_funding_sources;


--
-- Name: lookups_genders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lookups_genders (
    id bigint NOT NULL,
    value integer NOT NULL,
    text character varying NOT NULL
);


--
-- Name: bi_lookups_genders; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bi_lookups_genders AS
 SELECT lookups_genders.id,
    lookups_genders.value,
    lookups_genders.text
   FROM public.lookups_genders;


--
-- Name: lookups_living_situations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lookups_living_situations (
    id bigint NOT NULL,
    value integer NOT NULL,
    text character varying NOT NULL
);


--
-- Name: bi_lookups_living_situations; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bi_lookups_living_situations AS
 SELECT lookups_living_situations.id,
    lookups_living_situations.value,
    lookups_living_situations.text
   FROM public.lookups_living_situations;


--
-- Name: lookups_project_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lookups_project_types (
    id bigint NOT NULL,
    value integer NOT NULL,
    text character varying NOT NULL
);


--
-- Name: bi_lookups_project_types; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bi_lookups_project_types AS
 SELECT lookups_project_types.id,
    lookups_project_types.value,
    lookups_project_types.text
   FROM public.lookups_project_types;


--
-- Name: lookups_relationships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lookups_relationships (
    id bigint NOT NULL,
    value integer NOT NULL,
    text character varying NOT NULL
);


--
-- Name: bi_lookups_relationships; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bi_lookups_relationships AS
 SELECT lookups_relationships.id,
    lookups_relationships.value,
    lookups_relationships.text
   FROM public.lookups_relationships;


--
-- Name: lookups_tracking_methods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lookups_tracking_methods (
    id bigint NOT NULL,
    value integer,
    text character varying NOT NULL
);


--
-- Name: bi_lookups_tracking_methods; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bi_lookups_tracking_methods AS
 SELECT lookups_tracking_methods.id,
    lookups_tracking_methods.value,
    lookups_tracking_methods.text
   FROM public.lookups_tracking_methods;


--
-- Name: lookups_yes_no_etcs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lookups_yes_no_etcs (
    id bigint NOT NULL,
    value integer NOT NULL,
    text character varying NOT NULL
);


--
-- Name: bi_lookups_yes_no_etcs; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bi_lookups_yes_no_etcs AS
 SELECT lookups_yes_no_etcs.id,
    lookups_yes_no_etcs.value,
    lookups_yes_no_etcs.text
   FROM public.lookups_yes_no_etcs;


--
-- Name: nightly_census_by_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nightly_census_by_projects (
    id integer NOT NULL,
    date date NOT NULL,
    project_id integer NOT NULL,
    veterans integer DEFAULT 0,
    non_veterans integer DEFAULT 0,
    children integer DEFAULT 0,
    adults integer DEFAULT 0,
    youth integer DEFAULT 0,
    families integer DEFAULT 0,
    individuals integer DEFAULT 0,
    parenting_youth integer DEFAULT 0,
    parenting_juveniles integer DEFAULT 0,
    all_clients integer DEFAULT 0,
    beds integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    juveniles integer DEFAULT 0,
    unaccompanied_minors integer DEFAULT 0,
    youth_families integer DEFAULT 0,
    family_parents integer DEFAULT 0
);


--
-- Name: bi_nightly_census_by_projects; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bi_nightly_census_by_projects AS
 SELECT nightly_census_by_projects.id,
    nightly_census_by_projects.date,
    nightly_census_by_projects.project_id,
    nightly_census_by_projects.veterans,
    nightly_census_by_projects.non_veterans,
    nightly_census_by_projects.children,
    nightly_census_by_projects.adults,
    nightly_census_by_projects.all_clients,
    nightly_census_by_projects.beds
   FROM public.nightly_census_by_projects;


--
-- Name: service_history_enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_enrollments (
    id integer NOT NULL,
    client_id integer NOT NULL,
    data_source_id integer,
    date date NOT NULL,
    first_date_in_program date NOT NULL,
    last_date_in_program date,
    enrollment_group_id character varying(50),
    project_id character varying(50),
    age smallint,
    destination integer,
    head_of_household_id character varying(50),
    household_id character varying(50),
    project_name character varying(150),
    project_type smallint,
    project_tracking_method integer,
    organization_id character varying(50),
    record_type character varying(50) NOT NULL,
    housing_status_at_entry integer,
    housing_status_at_exit integer,
    service_type smallint,
    computed_project_type smallint,
    presented_as_individual boolean,
    other_clients_over_25 smallint DEFAULT 0 NOT NULL,
    other_clients_under_18 smallint DEFAULT 0 NOT NULL,
    other_clients_between_18_and_25 smallint DEFAULT 0 NOT NULL,
    unaccompanied_youth boolean DEFAULT false NOT NULL,
    parenting_youth boolean DEFAULT false NOT NULL,
    parenting_juvenile boolean DEFAULT false NOT NULL,
    children_only boolean DEFAULT false NOT NULL,
    individual_adult boolean DEFAULT false NOT NULL,
    individual_elder boolean DEFAULT false NOT NULL,
    head_of_household boolean DEFAULT false NOT NULL,
    move_in_date date,
    unaccompanied_minor boolean DEFAULT false
);


--
-- Name: bi_service_history_enrollments; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bi_service_history_enrollments AS
 SELECT service_history_enrollments.id,
    service_history_enrollments.client_id,
    service_history_enrollments.data_source_id,
    service_history_enrollments.first_date_in_program,
    service_history_enrollments.last_date_in_program,
    service_history_enrollments.age,
    service_history_enrollments.destination,
    service_history_enrollments.head_of_household_id,
    service_history_enrollments.household_id,
    service_history_enrollments.project_name,
    service_history_enrollments.project_tracking_method,
    service_history_enrollments.computed_project_type,
    service_history_enrollments.move_in_date,
    "Project".id AS project_id,
    "Enrollment".id AS enrollment_id
   FROM (((public.service_history_enrollments
     JOIN public."Client" ON ((("Client"."DateDeleted" IS NULL) AND ("Client".id = service_history_enrollments.client_id))))
     JOIN public."Project" ON ((("Project"."DateDeleted" IS NULL) AND ("Project".data_source_id = service_history_enrollments.data_source_id) AND (("Project"."ProjectID")::text = (service_history_enrollments.project_id)::text) AND (("Project"."OrganizationID")::text = (service_history_enrollments.organization_id)::text))))
     JOIN public."Enrollment" ON ((("Enrollment"."DateDeleted" IS NULL) AND ("Enrollment".data_source_id = service_history_enrollments.data_source_id) AND (("Enrollment"."EnrollmentID")::text = (service_history_enrollments.enrollment_group_id)::text) AND (("Enrollment"."ProjectID")::text = (service_history_enrollments.project_id)::text))))
  WHERE (((service_history_enrollments.record_type)::text = 'entry'::text) AND ((service_history_enrollments.last_date_in_program IS NULL) OR (service_history_enrollments.last_date_in_program >= (CURRENT_DATE - '5 years'::interval))));


--
-- Name: service_history_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services (
    id bigint NOT NULL,
    service_history_enrollment_id integer NOT NULL,
    record_type character varying(50) NOT NULL,
    date date NOT NULL,
    age smallint,
    service_type smallint,
    client_id integer,
    project_type smallint,
    homeless boolean,
    literally_homeless boolean
);


--
-- Name: bi_service_history_services; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.bi_service_history_services AS
 SELECT service_history_services.id,
    service_history_services.service_history_enrollment_id,
    service_history_services.record_type,
    service_history_services.date,
    service_history_services.age,
    service_history_services.client_id,
    service_history_services.project_type
   FROM (public.service_history_services
     JOIN public."Client" ON ((("Client"."DateDeleted" IS NULL) AND ("Client".id = service_history_services.client_id))))
  WHERE (service_history_services.date >= (CURRENT_DATE - '5 years'::interval));


--
-- Name: bo_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bo_configs (
    id integer NOT NULL,
    data_source_id integer,
    "user" character varying,
    encrypted_pass character varying,
    encrypted_pass_iv character varying,
    url character varying,
    server character varying,
    client_lookup_cuid character varying,
    touch_point_lookup_cuid character varying,
    subject_response_lookup_cuid character varying,
    site_touch_point_map_cuid character varying,
    disability_verification_cuid character varying,
    disability_touch_point_id integer,
    disability_touch_point_question_id integer
);


--
-- Name: bo_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bo_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bo_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bo_configs_id_seq OWNED BY public.bo_configs.id;


--
-- Name: cas_availabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cas_availabilities (
    id integer NOT NULL,
    client_id integer NOT NULL,
    available_at timestamp without time zone NOT NULL,
    unavailable_at timestamp without time zone,
    part_of_a_family boolean DEFAULT false NOT NULL,
    age_at_available_at integer
);


--
-- Name: cas_availabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cas_availabilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cas_availabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cas_availabilities_id_seq OWNED BY public.cas_availabilities.id;


--
-- Name: cas_ce_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cas_ce_assessments (
    id bigint NOT NULL,
    cas_client_id bigint,
    cas_non_hmis_assessment_id bigint,
    hmis_client_id bigint,
    program_id bigint,
    assessment_date date,
    assessment_location character varying,
    assessment_type integer,
    assessment_level integer,
    assessment_status integer,
    assessment_created_at timestamp without time zone,
    assessment_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: cas_ce_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cas_ce_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cas_ce_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cas_ce_assessments_id_seq OWNED BY public.cas_ce_assessments.id;


--
-- Name: cas_enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cas_enrollments (
    id integer NOT NULL,
    client_id integer,
    enrollment_id integer,
    entry_date date,
    exit_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    history json
);


--
-- Name: cas_enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cas_enrollments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cas_enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cas_enrollments_id_seq OWNED BY public.cas_enrollments.id;


--
-- Name: cas_houseds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cas_houseds (
    id integer NOT NULL,
    client_id integer NOT NULL,
    cas_client_id integer NOT NULL,
    match_id integer NOT NULL,
    housed_on date NOT NULL,
    inactivated boolean DEFAULT false
);


--
-- Name: cas_houseds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cas_houseds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cas_houseds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cas_houseds_id_seq OWNED BY public.cas_houseds.id;


--
-- Name: cas_non_hmis_client_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cas_non_hmis_client_histories (
    id integer NOT NULL,
    cas_client_id integer NOT NULL,
    available_on date NOT NULL,
    unavailable_on date,
    part_of_a_family boolean DEFAULT false NOT NULL,
    age_at_available_on integer
);


--
-- Name: cas_non_hmis_client_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cas_non_hmis_client_histories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cas_non_hmis_client_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cas_non_hmis_client_histories_id_seq OWNED BY public.cas_non_hmis_client_histories.id;


--
-- Name: cas_programs_to_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cas_programs_to_projects (
    id bigint NOT NULL,
    program_id bigint,
    project_id bigint
);


--
-- Name: cas_programs_to_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cas_programs_to_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cas_programs_to_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cas_programs_to_projects_id_seq OWNED BY public.cas_programs_to_projects.id;


--
-- Name: cas_referral_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cas_referral_events (
    id bigint NOT NULL,
    cas_client_id bigint,
    hmis_client_id bigint,
    program_id bigint,
    client_opportunity_match_id bigint,
    referral_date date,
    referral_result integer,
    referral_result_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    event integer
);


--
-- Name: cas_referral_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cas_referral_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cas_referral_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cas_referral_events_id_seq OWNED BY public.cas_referral_events.id;


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
    cori_release_form_submitted boolean,
    match_started_at timestamp without time zone,
    program_type character varying,
    shelter_agency_contacts json,
    hsa_contacts json,
    ssp_contacts json,
    admin_contacts json,
    clent_contacts json,
    hsp_contacts json,
    program_name character varying,
    sub_program_name character varying,
    terminal_status character varying,
    match_route character varying,
    cas_client_id integer,
    client_move_in_date date,
    source_data_source character varying,
    event_contact character varying,
    event_contact_agency character varying,
    vacancy_id integer,
    housing_type character varying,
    ineligible_in_warehouse boolean DEFAULT false NOT NULL,
    actor_type character varying
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
-- Name: cas_vacancies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cas_vacancies (
    id integer NOT NULL,
    program_id integer NOT NULL,
    sub_program_id integer NOT NULL,
    program_name character varying,
    sub_program_name character varying,
    program_type character varying,
    route_name character varying NOT NULL,
    vacancy_created_at timestamp without time zone NOT NULL,
    vacancy_made_available_at timestamp without time zone,
    first_matched_at timestamp without time zone
);


--
-- Name: cas_vacancies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cas_vacancies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cas_vacancies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cas_vacancies_id_seq OWNED BY public.cas_vacancies.id;


--
-- Name: ce_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ce_assessments (
    id integer NOT NULL,
    user_id integer NOT NULL,
    client_id integer NOT NULL,
    type character varying NOT NULL,
    submitted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    active boolean DEFAULT true,
    score integer DEFAULT 0,
    priority_score integer DEFAULT 0,
    assessor_id integer NOT NULL,
    location character varying,
    client_email character varying,
    military_duty boolean DEFAULT false,
    under_25 boolean DEFAULT false,
    over_60 boolean DEFAULT false,
    lgbtq boolean DEFAULT false,
    children_under_18 boolean DEFAULT false,
    fleeing_dv boolean DEFAULT false,
    living_outdoors boolean DEFAULT false,
    urgent_health_issue boolean DEFAULT false,
    location_option_1 boolean DEFAULT false,
    location_option_2 boolean DEFAULT false,
    location_option_3 boolean DEFAULT false,
    location_option_4 boolean DEFAULT false,
    location_option_5 boolean DEFAULT false,
    location_option_6 boolean DEFAULT false,
    location_option_other character varying,
    location_option_no character varying,
    homelessness integer,
    substance_use integer,
    mental_health integer,
    health_care integer,
    legal_issues integer,
    income integer,
    work integer,
    independent_living integer,
    community_involvement integer,
    survival_skills integer,
    barrier_no_rental_history boolean DEFAULT false,
    barrier_no_income boolean DEFAULT false,
    barrier_poor_credit boolean DEFAULT false,
    barrier_eviction_history boolean DEFAULT false,
    barrier_eviction_from_public_housing boolean DEFAULT false,
    barrier_bedrooms_3 boolean DEFAULT false,
    barrier_service_animal boolean DEFAULT false,
    barrier_cori_issues boolean DEFAULT false,
    barrier_registered_sex_offender boolean DEFAULT false,
    barrier_other character varying,
    preferences_studio boolean DEFAULT false,
    preferences_roomate boolean DEFAULT false,
    preferences_pets boolean DEFAULT false,
    preferences_accessible boolean DEFAULT false,
    preferences_quiet boolean DEFAULT false,
    preferences_public_transport boolean DEFAULT false,
    preferences_parks boolean DEFAULT false,
    preferences_other character varying,
    assessor_rating integer,
    homeless_six_months boolean DEFAULT false,
    mortality_hospitilization_3 boolean DEFAULT false,
    mortality_emergency_room_3 boolean DEFAULT false,
    mortality_over_60 boolean DEFAULT false,
    mortality_cirrhosis boolean DEFAULT false,
    mortality_renal_disease boolean DEFAULT false,
    mortality_frostbite boolean DEFAULT false,
    mortality_hiv boolean DEFAULT false,
    mortality_tri_morbid boolean DEFAULT false,
    lacks_access_to_shelter boolean DEFAULT false,
    high_potential_for_vicitimization boolean DEFAULT false,
    danger_of_harm boolean DEFAULT false,
    acute_medical_condition boolean DEFAULT false,
    acute_psychiatric_condition boolean DEFAULT false,
    acute_substance_abuse boolean DEFAULT false,
    location_no_preference boolean,
    vulnerability_score integer
);


--
-- Name: ce_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ce_assessments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ce_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ce_assessments_id_seq OWNED BY public.ce_assessments.id;


--
-- Name: census_by_project_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.census_by_project_types (
    id integer NOT NULL,
    "ProjectType" integer NOT NULL,
    date date NOT NULL,
    veteran boolean DEFAULT false NOT NULL,
    gender integer DEFAULT 99 NOT NULL,
    client_count integer DEFAULT 0 NOT NULL
);


--
-- Name: census_by_project_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.census_by_project_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: census_by_project_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.census_by_project_types_id_seq OWNED BY public.census_by_project_types.id;


--
-- Name: census_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.census_groups (
    id bigint NOT NULL,
    year integer NOT NULL,
    dataset character varying NOT NULL,
    name character varying NOT NULL,
    description text NOT NULL,
    created_on date
);


--
-- Name: census_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.census_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: census_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.census_groups_id_seq OWNED BY public.census_groups.id;


--
-- Name: census_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.census_values (
    id bigint NOT NULL,
    census_variable_id bigint NOT NULL,
    value numeric NOT NULL,
    full_geoid character varying NOT NULL,
    created_on date NOT NULL,
    census_level public.census_levels NOT NULL
);


--
-- Name: census_values_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.census_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: census_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.census_values_id_seq OWNED BY public.census_values.id;


--
-- Name: census_variables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.census_variables (
    id bigint NOT NULL,
    year integer NOT NULL,
    downloaded boolean DEFAULT false NOT NULL,
    dataset character varying NOT NULL,
    name character varying NOT NULL,
    label text NOT NULL,
    concept text NOT NULL,
    census_group character varying NOT NULL,
    census_attributes character varying NOT NULL,
    internal_name character varying,
    created_on date NOT NULL
);


--
-- Name: census_variables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.census_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: census_variables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.census_variables_id_seq OWNED BY public.census_variables.id;


--
-- Name: censuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.censuses (
    id integer NOT NULL,
    data_source_id integer NOT NULL,
    "ProjectType" integer NOT NULL,
    "OrganizationID" character varying NOT NULL,
    "ProjectID" character varying NOT NULL,
    date date NOT NULL,
    veteran boolean DEFAULT false NOT NULL,
    gender integer DEFAULT 99 NOT NULL,
    client_count integer DEFAULT 0 NOT NULL,
    bed_inventory integer DEFAULT 0 NOT NULL
);


--
-- Name: censuses_averaged_by_year; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.censuses_averaged_by_year (
    id integer NOT NULL,
    year integer NOT NULL,
    data_source_id integer,
    "OrganizationID" character varying,
    "ProjectID" character varying,
    "ProjectType" integer NOT NULL,
    client_count integer DEFAULT 0 NOT NULL,
    bed_inventory integer DEFAULT 0 NOT NULL,
    seasonal_inventory integer DEFAULT 0 NOT NULL,
    overflow_inventory integer DEFAULT 0 NOT NULL,
    days_of_service integer DEFAULT 0 NOT NULL
);


--
-- Name: censuses_averaged_by_year_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.censuses_averaged_by_year_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: censuses_averaged_by_year_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.censuses_averaged_by_year_id_seq OWNED BY public.censuses_averaged_by_year.id;


--
-- Name: censuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.censuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: censuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.censuses_id_seq OWNED BY public.censuses.id;


--
-- Name: children; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.children (
    id integer NOT NULL,
    first_name character varying,
    last_name character varying,
    dob date,
    family_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: children_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.children_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: children_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.children_id_seq OWNED BY public.children.id;


--
-- Name: chronics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chronics (
    id integer NOT NULL,
    date date NOT NULL,
    client_id integer NOT NULL,
    days_in_last_three_years integer,
    months_in_last_three_years integer,
    individual boolean,
    age integer,
    homeless_since date,
    dmh boolean DEFAULT false,
    trigger character varying,
    project_names character varying
);


--
-- Name: chronics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chronics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chronics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chronics_id_seq OWNED BY public.chronics.id;


--
-- Name: clh_locations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clh_locations (
    id bigint NOT NULL,
    client_id bigint,
    source_type character varying,
    source_id bigint,
    located_on date,
    lat double precision,
    lon double precision,
    collected_by character varying,
    processed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: clh_locations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clh_locations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clh_locations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clh_locations_id_seq OWNED BY public.clh_locations.id;


--
-- Name: client_matches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_matches (
    id integer NOT NULL,
    source_client_id integer NOT NULL,
    destination_client_id integer NOT NULL,
    updated_by_id integer,
    lock_version integer,
    defer_count integer,
    status character varying NOT NULL,
    score double precision,
    score_details text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: client_matches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_matches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_matches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_matches_id_seq OWNED BY public.client_matches.id;


--
-- Name: client_merge_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_merge_histories (
    id integer NOT NULL,
    merged_into integer NOT NULL,
    merged_from integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: client_merge_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_merge_histories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_merge_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_merge_histories_id_seq OWNED BY public.client_merge_histories.id;


--
-- Name: client_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_notes (
    id integer NOT NULL,
    client_id integer NOT NULL,
    user_id integer NOT NULL,
    type character varying NOT NULL,
    note text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    migrated_username character varying,
    recipients jsonb,
    sent_at timestamp without time zone,
    alert_active boolean DEFAULT true NOT NULL,
    service_id bigint,
    project_id bigint
);


--
-- Name: client_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_notes_id_seq OWNED BY public.client_notes.id;


--
-- Name: client_split_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_split_histories (
    id integer NOT NULL,
    split_into integer NOT NULL,
    split_from integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    receive_hmis boolean,
    receive_health boolean
);


--
-- Name: client_split_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_split_histories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_split_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_split_histories_id_seq OWNED BY public.client_split_histories.id;


--
-- Name: coc_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.coc_codes (
    id bigint NOT NULL,
    coc_code character varying NOT NULL,
    official_name character varying NOT NULL,
    preferred_name character varying,
    active boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: coc_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.coc_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: coc_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.coc_codes_id_seq OWNED BY public.coc_codes.id;


--
-- Name: cohort_client_changes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cohort_client_changes (
    id integer NOT NULL,
    cohort_client_id integer NOT NULL,
    cohort_id integer NOT NULL,
    user_id integer NOT NULL,
    change character varying,
    changed_at timestamp without time zone NOT NULL,
    reason character varying
);


--
-- Name: cohort_client_changes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cohort_client_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cohort_client_changes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cohort_client_changes_id_seq OWNED BY public.cohort_client_changes.id;


--
-- Name: cohort_client_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cohort_client_notes (
    id integer NOT NULL,
    cohort_client_id integer NOT NULL,
    note text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    user_id integer NOT NULL
);


--
-- Name: cohort_client_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cohort_client_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cohort_client_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cohort_client_notes_id_seq OWNED BY public.cohort_client_notes.id;


--
-- Name: cohort_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cohort_clients (
    id integer NOT NULL,
    cohort_id integer NOT NULL,
    client_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    agency character varying,
    case_manager character varying,
    housing_manager character varying,
    housing_search_agency character varying,
    housing_opportunity character varying,
    legal_barriers character varying,
    criminal_record_status character varying,
    document_ready character varying,
    sif_eligible boolean DEFAULT false,
    sensory_impaired character varying,
    housed_date date,
    destination character varying,
    sub_population character varying,
    rank integer,
    st_francis_house character varying,
    last_group_review_date date,
    pre_contemplative_last_date_approached date,
    va_eligible character varying,
    vash_eligible boolean DEFAULT false,
    chapter_115 character varying,
    first_date_homeless date,
    last_date_approached date,
    chronic boolean DEFAULT false,
    dnd_rank character varying,
    veteran boolean DEFAULT false,
    housing_track_suggested character varying,
    housing_track_enrolled character varying,
    adjusted_days_homeless integer,
    housing_navigator character varying,
    status character varying,
    ssvf_eligible character varying,
    location character varying,
    location_type character varying,
    vet_squares_confirmed character varying,
    active boolean DEFAULT true NOT NULL,
    provider character varying,
    next_step character varying,
    housing_plan text,
    document_ready_on date,
    new_lease_referral character varying,
    vulnerability_rank character varying,
    ineligible boolean DEFAULT false NOT NULL,
    adjusted_days_homeless_last_three_years integer DEFAULT 0 NOT NULL,
    original_chronic boolean DEFAULT false NOT NULL,
    not_a_vet character varying,
    primary_housing_track_suggested character varying,
    minimum_bedroom_size integer,
    special_needs character varying,
    adjusted_days_literally_homeless_last_three_years integer,
    reported boolean,
    calculated_days_homeless_on_effective_date integer,
    days_homeless_last_three_years_on_effective_date integer,
    days_literally_homeless_last_three_years_on_effective_date integer,
    destination_from_homelessness character varying,
    related_users character varying,
    disability_verification_date date,
    missing_documents character varying,
    sleeping_location character varying,
    exit_destination character varying,
    lgbtq character varying,
    school_district character varying,
    user_string_1 character varying,
    user_string_2 character varying,
    user_string_3 character varying,
    user_string_4 character varying,
    user_boolean_1 boolean,
    user_boolean_2 boolean,
    user_boolean_3 boolean,
    user_boolean_4 boolean,
    user_select_1 character varying,
    user_select_2 character varying,
    user_select_3 character varying,
    user_select_4 character varying,
    user_date_1 character varying,
    user_date_2 character varying,
    user_date_3 character varying,
    user_date_4 character varying,
    assessment_score integer,
    vispdat_score_manual integer,
    user_numeric_1 integer,
    user_numeric_2 integer,
    user_numeric_3 integer,
    user_numeric_4 integer,
    user_string_5 character varying,
    user_string_6 character varying,
    user_string_7 character varying,
    user_string_8 character varying,
    hmis_destination character varying,
    user_boolean_5 boolean,
    user_boolean_6 boolean,
    user_boolean_7 boolean,
    user_boolean_8 boolean,
    user_boolean_9 boolean,
    user_boolean_10 boolean,
    user_boolean_11 boolean,
    user_boolean_12 boolean,
    user_boolean_13 boolean,
    user_boolean_14 boolean,
    user_boolean_15 boolean,
    lgbtq_from_hmis character varying,
    days_homeless_plus_overrides integer,
    user_numeric_5 integer,
    user_numeric_6 integer,
    user_numeric_7 integer,
    user_numeric_8 integer,
    user_numeric_9 integer,
    user_numeric_10 integer,
    user_select_5 character varying,
    user_select_6 character varying,
    user_select_7 character varying,
    user_select_8 character varying,
    user_select_9 character varying,
    user_select_10 character varying,
    user_date_5 character varying,
    user_date_6 character varying,
    user_date_7 character varying,
    user_date_8 character varying,
    user_date_9 character varying,
    user_date_10 character varying,
    user_select_11 character varying,
    user_select_12 character varying,
    user_select_13 character varying,
    user_select_14 character varying,
    user_select_15 character varying,
    user_select_16 character varying,
    user_select_17 character varying,
    user_select_18 character varying,
    user_select_19 character varying,
    user_select_20 character varying,
    user_select_21 character varying,
    user_select_22 character varying,
    user_select_23 character varying,
    user_select_24 character varying,
    user_select_25 character varying,
    user_select_26 character varying,
    user_select_27 character varying,
    user_select_28 character varying,
    user_select_29 character varying,
    user_select_30 character varying,
    user_boolean_16 boolean,
    user_boolean_17 boolean,
    user_boolean_18 boolean,
    user_boolean_19 boolean,
    user_boolean_20 boolean,
    user_boolean_21 boolean,
    user_boolean_22 boolean,
    user_boolean_23 boolean,
    user_boolean_24 boolean,
    user_boolean_25 boolean,
    user_boolean_26 boolean,
    user_boolean_27 boolean,
    user_boolean_28 boolean,
    user_boolean_29 boolean,
    user_boolean_30 boolean,
    date_added_to_cohort date,
    individual_in_most_recent_homeless_enrollment boolean
);


--
-- Name: cohort_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cohort_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cohort_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cohort_clients_id_seq OWNED BY public.cohort_clients.id;


--
-- Name: cohort_column_options; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cohort_column_options (
    id integer NOT NULL,
    cohort_column character varying NOT NULL,
    weight integer,
    value character varying,
    active boolean DEFAULT true,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: cohort_column_options_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cohort_column_options_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cohort_column_options_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cohort_column_options_id_seq OWNED BY public.cohort_column_options.id;


--
-- Name: cohorts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cohorts (
    id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    effective_date date,
    column_state text,
    default_sort_direction character varying DEFAULT 'desc'::character varying,
    only_window boolean DEFAULT true NOT NULL,
    active_cohort boolean DEFAULT true NOT NULL,
    static_column_count integer DEFAULT 3 NOT NULL,
    short_name character varying,
    days_of_inactivity integer DEFAULT 90,
    show_on_client_dashboard boolean DEFAULT true NOT NULL,
    visible_in_cas boolean DEFAULT true NOT NULL,
    assessment_trigger character varying,
    tag_id integer,
    threshold_row_1 integer,
    threshold_color_1 character varying,
    threshold_label_1 character varying,
    threshold_row_2 integer,
    threshold_color_2 character varying,
    threshold_label_2 character varying,
    threshold_row_3 integer,
    threshold_color_3 character varying,
    threshold_label_3 character varying,
    threshold_row_4 integer,
    threshold_color_4 character varying,
    threshold_label_4 character varying,
    threshold_row_5 integer,
    threshold_color_5 character varying,
    threshold_label_5 character varying,
    system_cohort boolean DEFAULT false,
    type character varying DEFAULT 'GrdaWarehouse::Cohort'::character varying
);


--
-- Name: cohorts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cohorts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cohorts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cohorts_id_seq OWNED BY public.cohorts.id;


--
-- Name: combined_cohort_client_changes; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.combined_cohort_client_changes AS
 SELECT cc.id,
    cohort_clients.client_id,
    cc.cohort_client_id,
    cc.cohort_id,
    cc.user_id,
    cc.change AS entry_action,
    cc.changed_at AS entry_date,
    cc_ex.change AS exit_action,
    cc_ex.changed_at AS exit_date,
    cc_ex.reason
   FROM (((( SELECT cohort_client_changes.id,
            cohort_client_changes.cohort_client_id,
            cohort_client_changes.cohort_id,
            cohort_client_changes.user_id,
            cohort_client_changes.change,
            cohort_client_changes.changed_at,
            cohort_client_changes.reason
           FROM public.cohort_client_changes
          WHERE ((cohort_client_changes.change)::text = ANY (ARRAY[('create'::character varying)::text, ('activate'::character varying)::text]))) cc
     LEFT JOIN LATERAL ( SELECT cohort_client_changes.id,
            cohort_client_changes.cohort_client_id,
            cohort_client_changes.cohort_id,
            cohort_client_changes.user_id,
            cohort_client_changes.change,
            cohort_client_changes.changed_at,
            cohort_client_changes.reason
           FROM public.cohort_client_changes
          WHERE (((cohort_client_changes.change)::text = ANY (ARRAY[('destroy'::character varying)::text, ('deactivate'::character varying)::text])) AND (cc.cohort_client_id = cohort_client_changes.cohort_client_id) AND (cc.cohort_id = cohort_client_changes.cohort_id) AND (cc.changed_at < cohort_client_changes.changed_at))
          ORDER BY cohort_client_changes.changed_at
         LIMIT 1) cc_ex ON (true))
     JOIN public.cohort_clients ON ((cc.cohort_client_id = cohort_clients.id)))
     JOIN public."Client" ON (((cohort_clients.client_id = "Client".id) AND ("Client"."DateDeleted" IS NULL))))
  WHERE ((cc_ex.reason IS NULL) OR ((cc_ex.reason)::text <> 'Mistake'::text))
  ORDER BY cc.id;


--
-- Name: configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configs (
    id integer NOT NULL,
    project_type_override boolean DEFAULT true NOT NULL,
    eto_api_available boolean DEFAULT false NOT NULL,
    cas_available_method character varying DEFAULT 'cas_flag'::character varying NOT NULL,
    healthcare_available boolean DEFAULT false NOT NULL,
    family_calculation_method character varying DEFAULT 'adult_child'::character varying,
    site_coc_codes character varying,
    default_coc_zipcodes character varying,
    continuum_name character varying,
    cas_url character varying DEFAULT 'https://cas.boston.gov'::character varying,
    release_duration character varying DEFAULT 'Indefinite'::character varying,
    allow_partial_release boolean DEFAULT true,
    cas_flag_method character varying DEFAULT 'manual'::character varying,
    window_access_requires_release boolean DEFAULT false,
    show_partial_ssn_in_window_search_results boolean DEFAULT false,
    url_of_blank_consent_form character varying,
    ahar_psh_includes_rrh boolean DEFAULT true,
    so_day_as_month boolean DEFAULT true,
    client_details text,
    allow_multiple_file_tags boolean DEFAULT false NOT NULL,
    infer_family_from_household_id boolean DEFAULT false NOT NULL,
    chronic_definition character varying DEFAULT 'chronics'::character varying NOT NULL,
    vispdat_prioritization_scheme character varying DEFAULT 'length_of_time'::character varying NOT NULL,
    show_vispdats_on_dashboards boolean DEFAULT false,
    rrh_cas_readiness boolean DEFAULT false,
    cas_days_homeless_source character varying DEFAULT 'days_homeless'::character varying,
    consent_visible_to_all boolean DEFAULT false,
    verified_homeless_history_visible_to_all boolean DEFAULT false NOT NULL,
    only_most_recent_import boolean DEFAULT false,
    expose_coc_code boolean DEFAULT false NOT NULL,
    auto_confirm_consent boolean DEFAULT false NOT NULL,
    health_emergency character varying,
    health_emergency_tracing character varying,
    health_priority_age integer,
    multi_coc_installation boolean DEFAULT false NOT NULL,
    auto_de_duplication_accept_threshold double precision,
    auto_de_duplication_reject_threshold double precision,
    pii_encryption_type character varying DEFAULT 'none'::character varying,
    auto_de_duplication_enabled boolean DEFAULT false NOT NULL,
    request_account_available boolean DEFAULT false NOT NULL,
    dashboard_lookback date DEFAULT '2014-07-01'::date,
    domestic_violence_lookback_days integer DEFAULT 0 NOT NULL,
    support_contact_email character varying,
    completeness_goal integer DEFAULT 90,
    excess_goal integer DEFAULT 105,
    timeliness_goal integer DEFAULT 14,
    income_increase_goal integer DEFAULT 75,
    ph_destination_increase_goal integer DEFAULT 60,
    move_in_date_threshold integer DEFAULT 30,
    pf_universal_data_element_threshold integer DEFAULT 2 NOT NULL,
    pf_utilization_min integer DEFAULT 66 NOT NULL,
    pf_utilization_max integer DEFAULT 104 NOT NULL,
    pf_timeliness_threshold integer DEFAULT 3 NOT NULL,
    pf_show_income boolean DEFAULT false NOT NULL,
    pf_show_additional_timeliness boolean DEFAULT false NOT NULL,
    cas_sync_months integer DEFAULT 3,
    send_sms_for_covid_reminders boolean DEFAULT false NOT NULL,
    bypass_2fa_duration integer DEFAULT 0 NOT NULL,
    health_claims_data_path character varying,
    enable_youth_hrp boolean DEFAULT true NOT NULL,
    enable_system_cohorts boolean DEFAULT false,
    currently_homeless_cohort boolean DEFAULT false,
    show_client_last_seen_info_in_client_details boolean DEFAULT true
);


--
-- Name: configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.configs_id_seq OWNED BY public.configs.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contacts (
    id integer NOT NULL,
    type character varying NOT NULL,
    entity_id integer NOT NULL,
    email character varying NOT NULL,
    first_name character varying,
    last_name character varying,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


--
-- Name: dashboard_export_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dashboard_export_reports (
    id integer NOT NULL,
    file_id integer,
    user_id integer,
    job_id integer,
    coc_code character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone
);


--
-- Name: dashboard_export_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dashboard_export_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dashboard_export_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dashboard_export_reports_id_seq OWNED BY public.dashboard_export_reports.id;


--
-- Name: data_monitorings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.data_monitorings (
    id integer NOT NULL,
    resource_id integer NOT NULL,
    census date,
    calculated_on date,
    calculate_after date,
    value double precision,
    change double precision,
    iteration integer,
    of_iterations integer,
    type character varying
);


--
-- Name: data_monitorings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.data_monitorings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_monitorings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.data_monitorings_id_seq OWNED BY public.data_monitorings.id;


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
-- Name: direct_financial_assistances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.direct_financial_assistances (
    id integer NOT NULL,
    client_id integer,
    user_id integer,
    provided_on date,
    type_provided character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    imported boolean DEFAULT false,
    amount integer
);


--
-- Name: direct_financial_assistances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.direct_financial_assistances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: direct_financial_assistances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.direct_financial_assistances_id_seq OWNED BY public.direct_financial_assistances.id;


--
-- Name: document_exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.document_exports (
    id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    type character varying NOT NULL,
    user_id bigint NOT NULL,
    version character varying NOT NULL,
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
-- Name: enrollment_change_histories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enrollment_change_histories (
    id integer NOT NULL,
    client_id integer NOT NULL,
    "on" date NOT NULL,
    residential jsonb,
    other jsonb,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    version integer DEFAULT 1 NOT NULL,
    days_homeless integer
);


--
-- Name: enrollment_change_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.enrollment_change_histories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enrollment_change_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.enrollment_change_histories_id_seq OWNED BY public.enrollment_change_histories.id;


--
-- Name: enrollment_extras; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enrollment_extras (
    id integer NOT NULL,
    enrollment_id integer NOT NULL,
    vispdat_grand_total integer,
    vispdat_added_at date,
    vispdat_started_at date,
    vispdat_ended_at date,
    source_tab character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: enrollment_extras_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.enrollment_extras_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enrollment_extras_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.enrollment_extras_id_seq OWNED BY public.enrollment_extras.id;


--
-- Name: eto_api_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eto_api_configs (
    id integer NOT NULL,
    data_source_id integer NOT NULL,
    touchpoint_fields jsonb,
    demographic_fields jsonb,
    demographic_fields_with_attributes jsonb,
    additional_fields jsonb,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    identifier character varying,
    email character varying,
    encrypted_password character varying,
    encrypted_password_iv character varying,
    enterprise character varying,
    hud_touch_point_id character varying,
    active boolean DEFAULT false
);


--
-- Name: eto_api_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eto_api_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eto_api_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eto_api_configs_id_seq OWNED BY public.eto_api_configs.id;


--
-- Name: eto_client_lookups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eto_client_lookups (
    id integer NOT NULL,
    data_source_id integer NOT NULL,
    client_id integer NOT NULL,
    enterprise_guid character varying NOT NULL,
    site_id integer NOT NULL,
    subject_id integer NOT NULL,
    last_updated timestamp without time zone,
    participant_site_identifier integer
);


--
-- Name: eto_client_lookups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eto_client_lookups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eto_client_lookups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eto_client_lookups_id_seq OWNED BY public.eto_client_lookups.id;


--
-- Name: eto_subject_response_lookups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eto_subject_response_lookups (
    id integer NOT NULL,
    data_source_id integer NOT NULL,
    subject_id integer NOT NULL,
    response_id integer NOT NULL
);


--
-- Name: eto_subject_response_lookups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eto_subject_response_lookups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eto_subject_response_lookups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eto_subject_response_lookups_id_seq OWNED BY public.eto_subject_response_lookups.id;


--
-- Name: eto_touch_point_lookups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eto_touch_point_lookups (
    id integer NOT NULL,
    data_source_id integer NOT NULL,
    client_id integer NOT NULL,
    subject_id integer NOT NULL,
    assessment_id integer NOT NULL,
    response_id integer NOT NULL,
    last_updated timestamp without time zone,
    site_id integer
);


--
-- Name: eto_touch_point_lookups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eto_touch_point_lookups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eto_touch_point_lookups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eto_touch_point_lookups_id_seq OWNED BY public.eto_touch_point_lookups.id;


--
-- Name: eto_touch_point_response_times; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.eto_touch_point_response_times (
    id integer NOT NULL,
    touch_point_unique_identifier integer NOT NULL,
    response_unique_identifier integer NOT NULL,
    response_last_updated timestamp without time zone NOT NULL,
    subject_unique_identifier integer NOT NULL
);


--
-- Name: eto_touch_point_response_times_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.eto_touch_point_response_times_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: eto_touch_point_response_times_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.eto_touch_point_response_times_id_seq OWNED BY public.eto_touch_point_response_times.id;


--
-- Name: exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exports (
    id integer NOT NULL,
    export_id character varying,
    user_id integer,
    start_date date,
    end_date date,
    period_type integer,
    directive integer,
    hash_status integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    faked_pii boolean DEFAULT false,
    project_ids jsonb,
    include_deleted boolean DEFAULT false,
    content_type character varying,
    content bytea,
    file character varying,
    delayed_job_id integer,
    version character varying
);


--
-- Name: exports_ad_hoc_anons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exports_ad_hoc_anons (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    options jsonb,
    headers jsonb,
    rows jsonb,
    client_count integer,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: exports_ad_hoc_anons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exports_ad_hoc_anons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exports_ad_hoc_anons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exports_ad_hoc_anons_id_seq OWNED BY public.exports_ad_hoc_anons.id;


--
-- Name: exports_ad_hocs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exports_ad_hocs (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    options jsonb,
    headers jsonb,
    rows jsonb,
    client_count integer,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: exports_ad_hocs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exports_ad_hocs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exports_ad_hocs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exports_ad_hocs_id_seq OWNED BY public.exports_ad_hocs.id;


--
-- Name: exports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.exports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.exports_id_seq OWNED BY public.exports.id;


--
-- Name: fake_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fake_data (
    id integer NOT NULL,
    environment character varying NOT NULL,
    map text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    client_ids text
);


--
-- Name: fake_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fake_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fake_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fake_data_id_seq OWNED BY public.fake_data.id;


--
-- Name: federal_census_breakdowns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.federal_census_breakdowns (
    id bigint NOT NULL,
    accurate_on date,
    type character varying,
    geography_level character varying,
    geography character varying,
    measure character varying,
    value integer,
    geo_id character varying,
    race character varying,
    gender character varying,
    age_min integer,
    age_max integer,
    source character varying,
    census_variable_name character varying
);


--
-- Name: COLUMN federal_census_breakdowns.accurate_on; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.federal_census_breakdowns.accurate_on IS 'Most recent census date';


--
-- Name: COLUMN federal_census_breakdowns.geography_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.federal_census_breakdowns.geography_level IS 'State, zip, CoC (or maybe 010, 040, 050)';


--
-- Name: COLUMN federal_census_breakdowns.geography; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.federal_census_breakdowns.geography IS 'MA, 02101, MA-500';


--
-- Name: COLUMN federal_census_breakdowns.measure; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.federal_census_breakdowns.measure IS 'Detail of race, age, etc. (Asian, 50-59...)';


--
-- Name: COLUMN federal_census_breakdowns.value; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.federal_census_breakdowns.value IS 'count of population';


--
-- Name: COLUMN federal_census_breakdowns.source; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.federal_census_breakdowns.source IS 'Source of data';


--
-- Name: COLUMN federal_census_breakdowns.census_variable_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.federal_census_breakdowns.census_variable_name IS 'For debugging, variable name used in source';


--
-- Name: federal_census_breakdowns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.federal_census_breakdowns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: federal_census_breakdowns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.federal_census_breakdowns_id_seq OWNED BY public.federal_census_breakdowns.id;


--
-- Name: files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.files (
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
    visible_in_window boolean,
    migrated_username character varying,
    vispdat_id integer,
    consent_form_signed_on date,
    consent_form_confirmed boolean,
    size double precision,
    effective_date date,
    expiration_date date,
    delete_reason integer,
    delete_detail character varying,
    consent_revoked_at timestamp without time zone,
    coc_codes jsonb DEFAULT '[]'::jsonb
);


--
-- Name: files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.files_id_seq OWNED BY public.files.id;


--
-- Name: generate_service_history_batch_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.generate_service_history_batch_logs (
    id integer NOT NULL,
    generate_service_history_log_id integer,
    to_process integer,
    updated integer,
    patched integer,
    delayed_job_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: generate_service_history_batch_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.generate_service_history_batch_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: generate_service_history_batch_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.generate_service_history_batch_logs_id_seq OWNED BY public.generate_service_history_batch_logs.id;


--
-- Name: generate_service_history_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.generate_service_history_log (
    id integer NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    to_delete integer,
    to_add integer,
    to_update integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    batches integer
);


--
-- Name: generate_service_history_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.generate_service_history_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: generate_service_history_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.generate_service_history_log_id_seq OWNED BY public.generate_service_history_log.id;


--
-- Name: grades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grades (
    id integer NOT NULL,
    type character varying NOT NULL,
    grade character varying NOT NULL,
    percentage_low integer,
    percentage_high integer,
    percentage_under_low integer,
    percentage_under_high integer,
    percentage_over_low integer,
    percentage_over_high integer,
    color character varying DEFAULT '#000000'::character varying,
    weight integer DEFAULT 0 NOT NULL
);


--
-- Name: grades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grades_id_seq OWNED BY public.grades.id;


--
-- Name: group_viewable_entities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_viewable_entities (
    id integer NOT NULL,
    access_group_id integer NOT NULL,
    entity_id integer NOT NULL,
    entity_type character varying NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: group_viewable_entities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_viewable_entities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_viewable_entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_viewable_entities_id_seq OWNED BY public.group_viewable_entities.id;


--
-- Name: hap_report_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hap_report_clients (
    id bigint NOT NULL,
    client_id bigint,
    age integer,
    emancipated boolean,
    head_of_household boolean,
    household_ids character varying[],
    project_types integer[],
    veteran boolean,
    mental_health boolean,
    substance_use_disorder boolean,
    domestic_violence boolean,
    income_at_start integer,
    income_at_exit integer,
    homeless boolean,
    nights_in_shelter integer,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    head_of_household_for character varying[]
);


--
-- Name: hap_report_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hap_report_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hap_report_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hap_report_clients_id_seq OWNED BY public.hap_report_clients.id;


--
-- Name: health_emergency_ama_restrictions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_emergency_ama_restrictions (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    client_id integer NOT NULL,
    agency_id integer,
    restricted character varying,
    note character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    notes text,
    emergency_type character varying,
    notification_at timestamp without time zone,
    notification_batch_id integer
);


--
-- Name: health_emergency_ama_restrictions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.health_emergency_ama_restrictions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_emergency_ama_restrictions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.health_emergency_ama_restrictions_id_seq OWNED BY public.health_emergency_ama_restrictions.id;


--
-- Name: health_emergency_clinical_triages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_emergency_clinical_triages (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    client_id integer NOT NULL,
    agency_id integer,
    test_requested character varying,
    location character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    notes text,
    emergency_type character varying
);


--
-- Name: health_emergency_clinical_triages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.health_emergency_clinical_triages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_emergency_clinical_triages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.health_emergency_clinical_triages_id_seq OWNED BY public.health_emergency_clinical_triages.id;


--
-- Name: health_emergency_isolations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_emergency_isolations (
    id bigint NOT NULL,
    type character varying NOT NULL,
    user_id integer NOT NULL,
    client_id integer NOT NULL,
    agency_id integer,
    isolation_requested_at timestamp without time zone,
    location character varying,
    started_on date,
    scheduled_to_end_on date,
    ended_on date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    notes text,
    emergency_type character varying
);


--
-- Name: health_emergency_isolations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.health_emergency_isolations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_emergency_isolations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.health_emergency_isolations_id_seq OWNED BY public.health_emergency_isolations.id;


--
-- Name: health_emergency_test_batches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_emergency_test_batches (
    id bigint NOT NULL,
    user_id bigint,
    uploaded_count integer,
    matched_count integer,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    import_errors character varying,
    file character varying,
    name character varying,
    size character varying,
    content_type character varying,
    content bytea
);


--
-- Name: health_emergency_test_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.health_emergency_test_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_emergency_test_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.health_emergency_test_batches_id_seq OWNED BY public.health_emergency_test_batches.id;


--
-- Name: health_emergency_tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_emergency_tests (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    client_id integer NOT NULL,
    agency_id integer,
    test_requested character varying,
    location character varying,
    tested_on date,
    result character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    notes text,
    emergency_type character varying,
    notification_at timestamp without time zone,
    notification_batch_id integer
);


--
-- Name: health_emergency_tests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.health_emergency_tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_emergency_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.health_emergency_tests_id_seq OWNED BY public.health_emergency_tests.id;


--
-- Name: health_emergency_triages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_emergency_triages (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    client_id integer NOT NULL,
    agency_id integer,
    location character varying,
    exposure character varying,
    symptoms character varying,
    first_symptoms_on date,
    referred_on date,
    referred_to character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    notes text,
    emergency_type character varying
);


--
-- Name: health_emergency_triages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.health_emergency_triages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_emergency_triages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.health_emergency_triages_id_seq OWNED BY public.health_emergency_triages.id;


--
-- Name: health_emergency_uploaded_tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_emergency_uploaded_tests (
    id bigint NOT NULL,
    batch_id bigint,
    client_id integer,
    test_id integer,
    first_name character varying,
    last_name character varying,
    dob date,
    gender character varying,
    ssn character varying,
    tested_on date,
    test_location character varying,
    test_result character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    ama_restriction_id bigint
);


--
-- Name: health_emergency_uploaded_tests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.health_emergency_uploaded_tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_emergency_uploaded_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.health_emergency_uploaded_tests_id_seq OWNED BY public.health_emergency_uploaded_tests.id;


--
-- Name: health_emergency_vaccinations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.health_emergency_vaccinations (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    client_id integer NOT NULL,
    agency_id integer,
    vaccinated_on date NOT NULL,
    vaccinated_at character varying,
    follow_up_on date,
    follow_up_notification_sent_at timestamp without time zone,
    vaccination_type character varying NOT NULL,
    follow_up_cell_phone character varying,
    emergency_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    health_vaccination_id integer,
    preferred_language character varying DEFAULT 'en'::character varying,
    notification_status text
);


--
-- Name: health_emergency_vaccinations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.health_emergency_vaccinations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: health_emergency_vaccinations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.health_emergency_vaccinations_id_seq OWNED BY public.health_emergency_vaccinations.id;


--
-- Name: helps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.helps (
    id integer NOT NULL,
    controller_path character varying NOT NULL,
    action_name character varying NOT NULL,
    external_url character varying,
    title character varying NOT NULL,
    content text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    location character varying DEFAULT 'internal'::character varying NOT NULL
);


--
-- Name: helps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.helps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: helps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.helps_id_seq OWNED BY public.helps.id;


--
-- Name: hmis_2020_affiliations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_affiliations (
    id bigint NOT NULL,
    "AffiliationID" character varying,
    "ProjectID" character varying,
    "ResProjectID" character varying,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_affiliations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_affiliations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_affiliations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_affiliations_id_seq OWNED BY public.hmis_2020_affiliations.id;


--
-- Name: hmis_2020_aggregated_enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_aggregated_enrollments (
    id bigint NOT NULL,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "ProjectID" character varying,
    "EntryDate" date,
    "HouseholdID" character varying,
    "RelationshipToHoH" integer,
    "LivingSituation" integer,
    "LengthOfStay" integer,
    "LOSUnderThreshold" integer,
    "PreviousStreetESSH" integer,
    "DateToStreetESSH" date,
    "TimesHomelessPastThreeYears" integer,
    "MonthsHomelessPastThreeYears" integer,
    "DisablingCondition" integer,
    "DateOfEngagement" date,
    "MoveInDate" date,
    "DateOfPATHStatus" date,
    "ClientEnrolledInPATH" integer,
    "ReasonNotEnrolled" integer,
    "WorstHousingSituation" integer,
    "PercentAMI" integer,
    "LastPermanentStreet" character varying,
    "LastPermanentCity" character varying,
    "LastPermanentState" character varying,
    "LastPermanentZIP" character varying,
    "AddressDataQuality" integer,
    "DateOfBCPStatus" date,
    "EligibleForRHY" integer,
    "ReasonNoServices" integer,
    "RunawayYouth" integer,
    "SexualOrientation" integer,
    "SexualOrientationOther" character varying,
    "FormerWardChildWelfare" integer,
    "ChildWelfareYears" integer,
    "ChildWelfareMonths" integer,
    "FormerWardJuvenileJustice" integer,
    "JuvenileJusticeYears" integer,
    "JuvenileJusticeMonths" integer,
    "UnemploymentFam" integer,
    "MentalHealthIssuesFam" integer,
    "PhysicalDisabilityFam" integer,
    "AlcoholDrugAbuseFam" integer,
    "InsufficientIncome" integer,
    "IncarceratedParent" integer,
    "ReferralSource" integer,
    "CountOutreachReferralApproaches" integer,
    "UrgentReferral" integer,
    "TimeToHousingLoss" integer,
    "ZeroIncome" integer,
    "AnnualPercentAMI" integer,
    "FinancialChange" integer,
    "HouseholdChange" integer,
    "EvictionHistory" integer,
    "SubsidyAtRisk" integer,
    "LiteralHomelessHistory" integer,
    "DisabledHoH" integer,
    "CriminalRecord" integer,
    "SexOffender" integer,
    "DependentUnder6" integer,
    "SingleParent" integer,
    "HH5Plus" integer,
    "IraqAfghanistan" integer,
    "FemVet" integer,
    "HPScreeningScore" integer,
    "ThresholdScore" integer,
    "VAMCStation" character varying,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone
);


--
-- Name: hmis_2020_aggregated_enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_aggregated_enrollments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_aggregated_enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_aggregated_enrollments_id_seq OWNED BY public.hmis_2020_aggregated_enrollments.id;


--
-- Name: hmis_2020_aggregated_exits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_aggregated_exits (
    id bigint NOT NULL,
    "ExitID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "ExitDate" date,
    "Destination" integer,
    "OtherDestination" character varying,
    "HousingAssessment" integer,
    "SubsidyInformation" integer,
    "ProjectCompletionStatus" integer,
    "EarlyExitReason" integer,
    "ExchangeForSex" integer,
    "ExchangeForSexPastThreeMonths" integer,
    "CountOfExchangeForSex" integer,
    "AskedOrForcedToExchangeForSex" integer,
    "AskedOrForcedToExchangeForSexPastThreeMonths" integer,
    "WorkPlaceViolenceThreats" integer,
    "WorkplacePromiseDifference" integer,
    "CoercedToContinueWork" integer,
    "LaborExploitPastThreeMonths" integer,
    "CounselingReceived" integer,
    "IndividualCounseling" integer,
    "FamilyCounseling" integer,
    "GroupCounseling" integer,
    "SessionCountAtExit" integer,
    "PostExitCounselingPlan" integer,
    "SessionsInPlan" integer,
    "DestinationSafeClient" integer,
    "DestinationSafeWorker" integer,
    "PosAdultConnections" integer,
    "PosPeerConnections" integer,
    "PosCommunityConnections" integer,
    "AftercareDate" date,
    "AftercareProvided" integer,
    "EmailSocialMedia" integer,
    "Telephone" integer,
    "InPersonIndividual" integer,
    "InPersonGroup" integer,
    "CMExitReason" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone
);


--
-- Name: hmis_2020_aggregated_exits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_aggregated_exits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_aggregated_exits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_aggregated_exits_id_seq OWNED BY public.hmis_2020_aggregated_exits.id;


--
-- Name: hmis_2020_assessment_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_assessment_questions (
    id bigint NOT NULL,
    "AssessmentQuestionID" character varying,
    "AssessmentID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "AssessmentQuestionGroup" character varying,
    "AssessmentQuestionOrder" integer,
    "AssessmentQuestion" character varying,
    "AssessmentAnswer" character varying,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_assessment_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_assessment_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_assessment_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_assessment_questions_id_seq OWNED BY public.hmis_2020_assessment_questions.id;


--
-- Name: hmis_2020_assessment_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_assessment_results (
    id bigint NOT NULL,
    "AssessmentResultID" character varying,
    "AssessmentID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "AssessmentResultType" character varying,
    "AssessmentResult" character varying,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_assessment_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_assessment_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_assessment_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_assessment_results_id_seq OWNED BY public.hmis_2020_assessment_results.id;


--
-- Name: hmis_2020_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_assessments (
    id bigint NOT NULL,
    "AssessmentID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "AssessmentDate" date,
    "AssessmentLocation" character varying,
    "AssessmentType" integer,
    "AssessmentLevel" integer,
    "PrioritizationStatus" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_assessments_id_seq OWNED BY public.hmis_2020_assessments.id;


--
-- Name: hmis_2020_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_clients (
    id bigint NOT NULL,
    "PersonalID" character varying,
    "FirstName" character varying,
    "MiddleName" character varying,
    "LastName" character varying,
    "NameSuffix" character varying,
    "NameDataQuality" integer,
    "SSN" character varying,
    "SSNDataQuality" character varying,
    "DOB" date,
    "DOBDataQuality" character varying,
    "AmIndAKNative" integer,
    "Asian" integer,
    "BlackAfAmerican" integer,
    "NativeHIOtherPacific" integer,
    "White" integer,
    "RaceNone" integer,
    "Ethnicity" integer,
    "Gender" integer,
    "VeteranStatus" integer,
    "YearEnteredService" integer,
    "YearSeparated" integer,
    "WorldWarII" integer,
    "KoreanWar" integer,
    "VietnamWar" integer,
    "DesertStorm" integer,
    "AfghanistanOEF" integer,
    "IraqOIF" integer,
    "IraqOND" integer,
    "OtherTheater" integer,
    "MilitaryBranch" integer,
    "DischargeStatus" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_clients_id_seq OWNED BY public.hmis_2020_clients.id;


--
-- Name: hmis_2020_current_living_situations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_current_living_situations (
    id bigint NOT NULL,
    "CurrentLivingSitID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "InformationDate" date,
    "CurrentLivingSituation" integer,
    "VerifiedBy" character varying,
    "LeaveSituation14Days" integer,
    "SubsequentResidence" integer,
    "ResourcesToObtain" integer,
    "LeaseOwn60Day" integer,
    "MovedTwoOrMore" integer,
    "LocationDetails" character varying,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_current_living_situations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_current_living_situations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_current_living_situations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_current_living_situations_id_seq OWNED BY public.hmis_2020_current_living_situations.id;


--
-- Name: hmis_2020_disabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_disabilities (
    id bigint NOT NULL,
    "DisabilitiesID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "InformationDate" date,
    "DisabilityType" integer,
    "DisabilityResponse" integer,
    "IndefiniteAndImpairs" integer,
    "TCellCountAvailable" integer,
    "TCellCount" integer,
    "TCellSource" integer,
    "ViralLoadAvailable" integer,
    "ViralLoad" integer,
    "ViralLoadSource" integer,
    "DataCollectionStage" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_disabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_disabilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_disabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_disabilities_id_seq OWNED BY public.hmis_2020_disabilities.id;


--
-- Name: hmis_2020_employment_educations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_employment_educations (
    id bigint NOT NULL,
    "EmploymentEducationID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "InformationDate" date,
    "LastGradeCompleted" integer,
    "SchoolStatus" integer,
    "Employed" integer,
    "EmploymentType" integer,
    "NotEmployedReason" integer,
    "DataCollectionStage" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_employment_educations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_employment_educations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_employment_educations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_employment_educations_id_seq OWNED BY public.hmis_2020_employment_educations.id;


--
-- Name: hmis_2020_enrollment_cocs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_enrollment_cocs (
    id bigint NOT NULL,
    "EnrollmentCoCID" character varying,
    "EnrollmentID" character varying,
    "HouseholdID" character varying,
    "ProjectID" character varying,
    "PersonalID" character varying,
    "InformationDate" date,
    "CoCCode" character varying,
    "DataCollectionStage" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_enrollment_cocs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_enrollment_cocs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_enrollment_cocs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_enrollment_cocs_id_seq OWNED BY public.hmis_2020_enrollment_cocs.id;


--
-- Name: hmis_2020_enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_enrollments (
    id bigint NOT NULL,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "ProjectID" character varying,
    "EntryDate" date,
    "HouseholdID" character varying,
    "RelationshipToHoH" integer,
    "LivingSituation" integer,
    "LengthOfStay" integer,
    "LOSUnderThreshold" integer,
    "PreviousStreetESSH" integer,
    "DateToStreetESSH" date,
    "TimesHomelessPastThreeYears" integer,
    "MonthsHomelessPastThreeYears" integer,
    "DisablingCondition" integer,
    "DateOfEngagement" date,
    "MoveInDate" date,
    "DateOfPATHStatus" date,
    "ClientEnrolledInPATH" integer,
    "ReasonNotEnrolled" integer,
    "WorstHousingSituation" integer,
    "PercentAMI" integer,
    "LastPermanentStreet" character varying,
    "LastPermanentCity" character varying,
    "LastPermanentState" character varying,
    "LastPermanentZIP" character varying,
    "AddressDataQuality" integer,
    "DateOfBCPStatus" date,
    "EligibleForRHY" integer,
    "ReasonNoServices" integer,
    "RunawayYouth" integer,
    "SexualOrientation" integer,
    "SexualOrientationOther" character varying,
    "FormerWardChildWelfare" integer,
    "ChildWelfareYears" integer,
    "ChildWelfareMonths" integer,
    "FormerWardJuvenileJustice" integer,
    "JuvenileJusticeYears" integer,
    "JuvenileJusticeMonths" integer,
    "UnemploymentFam" integer,
    "MentalHealthIssuesFam" integer,
    "PhysicalDisabilityFam" integer,
    "AlcoholDrugAbuseFam" integer,
    "InsufficientIncome" integer,
    "IncarceratedParent" integer,
    "ReferralSource" integer,
    "CountOutreachReferralApproaches" integer,
    "UrgentReferral" integer,
    "TimeToHousingLoss" integer,
    "ZeroIncome" integer,
    "AnnualPercentAMI" integer,
    "FinancialChange" integer,
    "HouseholdChange" integer,
    "EvictionHistory" integer,
    "SubsidyAtRisk" integer,
    "LiteralHomelessHistory" integer,
    "DisabledHoH" integer,
    "CriminalRecord" integer,
    "SexOffender" integer,
    "DependentUnder6" integer,
    "SingleParent" integer,
    "HH5Plus" integer,
    "IraqAfghanistan" integer,
    "FemVet" integer,
    "HPScreeningScore" integer,
    "ThresholdScore" integer,
    "VAMCStation" character varying,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_enrollments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_enrollments_id_seq OWNED BY public.hmis_2020_enrollments.id;


--
-- Name: hmis_2020_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_events (
    id bigint NOT NULL,
    "EventID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "EventDate" date,
    "Event" integer,
    "ProbSolDivRRResult" integer,
    "ReferralCaseManageAfter" integer,
    "LocationCrisisorPHHousing" character varying,
    "ReferralResult" integer,
    "ResultDate" date,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_events_id_seq OWNED BY public.hmis_2020_events.id;


--
-- Name: hmis_2020_exits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_exits (
    id bigint NOT NULL,
    "ExitID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "ExitDate" date,
    "Destination" integer,
    "OtherDestination" character varying,
    "HousingAssessment" integer,
    "SubsidyInformation" integer,
    "ProjectCompletionStatus" integer,
    "EarlyExitReason" integer,
    "ExchangeForSex" integer,
    "ExchangeForSexPastThreeMonths" integer,
    "CountOfExchangeForSex" integer,
    "AskedOrForcedToExchangeForSex" integer,
    "AskedOrForcedToExchangeForSexPastThreeMonths" integer,
    "WorkPlaceViolenceThreats" integer,
    "WorkplacePromiseDifference" integer,
    "CoercedToContinueWork" integer,
    "LaborExploitPastThreeMonths" integer,
    "CounselingReceived" integer,
    "IndividualCounseling" integer,
    "FamilyCounseling" integer,
    "GroupCounseling" integer,
    "SessionCountAtExit" integer,
    "PostExitCounselingPlan" integer,
    "SessionsInPlan" integer,
    "DestinationSafeClient" integer,
    "DestinationSafeWorker" integer,
    "PosAdultConnections" integer,
    "PosPeerConnections" integer,
    "PosCommunityConnections" integer,
    "AftercareDate" date,
    "AftercareProvided" integer,
    "EmailSocialMedia" integer,
    "Telephone" integer,
    "InPersonIndividual" integer,
    "InPersonGroup" integer,
    "CMExitReason" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_exits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_exits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_exits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_exits_id_seq OWNED BY public.hmis_2020_exits.id;


--
-- Name: hmis_2020_exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_exports (
    id bigint NOT NULL,
    "ExportID" character varying,
    "SourceType" integer,
    "SourceID" character varying,
    "SourceName" character varying,
    "SourceContactFirst" character varying,
    "SourceContactLast" character varying,
    "SourceContactPhone" character varying,
    "SourceContactExtension" character varying,
    "SourceContactEmail" character varying,
    "ExportDate" timestamp without time zone,
    "ExportStartDate" date,
    "ExportEndDate" date,
    "SoftwareName" character varying,
    "SoftwareVersion" character varying,
    "ExportPeriodType" integer,
    "ExportDirective" integer,
    "HashStatus" integer,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_exports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_exports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_exports_id_seq OWNED BY public.hmis_2020_exports.id;


--
-- Name: hmis_2020_funders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_funders (
    id bigint NOT NULL,
    "FunderID" character varying,
    "ProjectID" character varying,
    "Funder" integer,
    "OtherFunder" character varying,
    "GrantID" character varying,
    "StartDate" date,
    "EndDate" date,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_funders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_funders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_funders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_funders_id_seq OWNED BY public.hmis_2020_funders.id;


--
-- Name: hmis_2020_health_and_dvs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_health_and_dvs (
    id bigint NOT NULL,
    "HealthAndDVID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "InformationDate" date,
    "DomesticViolenceVictim" integer,
    "WhenOccurred" integer,
    "CurrentlyFleeing" integer,
    "GeneralHealthStatus" integer,
    "DentalHealthStatus" integer,
    "MentalHealthStatus" integer,
    "PregnancyStatus" integer,
    "DueDate" date,
    "DataCollectionStage" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_health_and_dvs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_health_and_dvs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_health_and_dvs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_health_and_dvs_id_seq OWNED BY public.hmis_2020_health_and_dvs.id;


--
-- Name: hmis_2020_income_benefits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_income_benefits (
    id bigint NOT NULL,
    "IncomeBenefitsID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "InformationDate" date,
    "IncomeFromAnySource" integer,
    "TotalMonthlyIncome" character varying,
    "Earned" integer,
    "EarnedAmount" character varying,
    "Unemployment" integer,
    "UnemploymentAmount" character varying,
    "SSI" integer,
    "SSIAmount" character varying,
    "SSDI" integer,
    "SSDIAmount" character varying,
    "VADisabilityService" integer,
    "VADisabilityServiceAmount" character varying,
    "VADisabilityNonService" integer,
    "VADisabilityNonServiceAmount" character varying,
    "PrivateDisability" integer,
    "PrivateDisabilityAmount" character varying,
    "WorkersComp" integer,
    "WorkersCompAmount" character varying,
    "TANF" integer,
    "TANFAmount" character varying,
    "GA" integer,
    "GAAmount" character varying,
    "SocSecRetirement" integer,
    "SocSecRetirementAmount" character varying,
    "Pension" integer,
    "PensionAmount" character varying,
    "ChildSupport" integer,
    "ChildSupportAmount" character varying,
    "Alimony" integer,
    "AlimonyAmount" character varying,
    "OtherIncomeSource" integer,
    "OtherIncomeAmount" character varying,
    "OtherIncomeSourceIdentify" character varying,
    "BenefitsFromAnySource" integer,
    "SNAP" integer,
    "WIC" integer,
    "TANFChildCare" integer,
    "TANFTransportation" integer,
    "OtherTANF" integer,
    "OtherBenefitsSource" integer,
    "OtherBenefitsSourceIdentify" character varying,
    "InsuranceFromAnySource" integer,
    "Medicaid" integer,
    "NoMedicaidReason" integer,
    "Medicare" integer,
    "NoMedicareReason" integer,
    "SCHIP" integer,
    "NoSCHIPReason" integer,
    "VAMedicalServices" integer,
    "NoVAMedReason" integer,
    "EmployerProvided" integer,
    "NoEmployerProvidedReason" integer,
    "COBRA" integer,
    "NoCOBRAReason" integer,
    "PrivatePay" integer,
    "NoPrivatePayReason" integer,
    "StateHealthIns" integer,
    "NoStateHealthInsReason" integer,
    "IndianHealthServices" integer,
    "NoIndianHealthServicesReason" integer,
    "OtherInsurance" integer,
    "OtherInsuranceIdentify" character varying,
    "HIVAIDSAssistance" integer,
    "NoHIVAIDSAssistanceReason" integer,
    "ADAP" integer,
    "NoADAPReason" integer,
    "ConnectionWithSOAR" integer,
    "DataCollectionStage" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_income_benefits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_income_benefits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_income_benefits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_income_benefits_id_seq OWNED BY public.hmis_2020_income_benefits.id;


--
-- Name: hmis_2020_inventories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_inventories (
    id bigint NOT NULL,
    "InventoryID" character varying,
    "ProjectID" character varying,
    "CoCCode" character varying,
    "HouseholdType" integer,
    "Availability" integer,
    "UnitInventory" integer,
    "BedInventory" integer,
    "CHVetBedInventory" integer,
    "YouthVetBedInventory" integer,
    "VetBedInventory" integer,
    "CHYouthBedInventory" integer,
    "YouthBedInventory" integer,
    "CHBedInventory" integer,
    "OtherBedInventory" integer,
    "ESBedType" integer,
    "InventoryStartDate" date,
    "InventoryEndDate" date,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_inventories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_inventories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_inventories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_inventories_id_seq OWNED BY public.hmis_2020_inventories.id;


--
-- Name: hmis_2020_organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_organizations (
    id bigint NOT NULL,
    "OrganizationID" character varying,
    "OrganizationName" character varying,
    "VictimServicesProvider" integer,
    "OrganizationCommonName" character varying,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_organizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_organizations_id_seq OWNED BY public.hmis_2020_organizations.id;


--
-- Name: hmis_2020_project_cocs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_project_cocs (
    id bigint NOT NULL,
    "ProjectCoCID" character varying,
    "ProjectID" character varying,
    "CoCCode" character varying,
    "Geocode" character varying,
    "Address1" character varying,
    "Address2" character varying,
    "City" character varying,
    "State" character varying,
    "Zip" character varying,
    "GeographyType" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_project_cocs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_project_cocs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_project_cocs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_project_cocs_id_seq OWNED BY public.hmis_2020_project_cocs.id;


--
-- Name: hmis_2020_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_projects (
    id bigint NOT NULL,
    "ProjectID" character varying,
    "OrganizationID" character varying,
    "ProjectName" character varying,
    "ProjectCommonName" character varying,
    "OperatingStartDate" date,
    "OperatingEndDate" date,
    "ContinuumProject" integer,
    "ProjectType" integer,
    "HousingType" integer,
    "ResidentialAffiliation" integer,
    "TrackingMethod" integer,
    "HMISParticipatingProject" integer,
    "TargetPopulation" integer,
    "PITCount" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_projects_id_seq OWNED BY public.hmis_2020_projects.id;


--
-- Name: hmis_2020_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_services (
    id bigint NOT NULL,
    "ServicesID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "DateProvided" date,
    "RecordType" integer,
    "TypeProvided" integer,
    "OtherTypeProvided" character varying,
    "SubTypeProvided" integer,
    "FAAmount" character varying,
    "ReferralOutcome" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_services_id_seq OWNED BY public.hmis_2020_services.id;


--
-- Name: hmis_2020_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_2020_users (
    id bigint NOT NULL,
    "UserID" character varying,
    "UserFirstName" character varying,
    "UserLastName" character varying,
    "UserPhone" character varying,
    "UserExtension" character varying,
    "UserEmail" character varying,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    importer_log_id integer NOT NULL,
    pre_processed_at timestamp without time zone NOT NULL,
    source_hash character varying,
    source_id integer NOT NULL,
    source_type character varying NOT NULL,
    dirty_at timestamp without time zone,
    clean_at timestamp without time zone,
    should_import boolean DEFAULT true
);


--
-- Name: hmis_2020_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_2020_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_2020_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_2020_users_id_seq OWNED BY public.hmis_2020_users.id;


--
-- Name: hmis_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_assessments (
    id integer NOT NULL,
    assessment_id integer NOT NULL,
    site_id integer NOT NULL,
    site_name character varying,
    name character varying NOT NULL,
    "fetch" boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    last_fetched_at timestamp without time zone,
    data_source_id integer NOT NULL,
    confidential boolean DEFAULT false NOT NULL,
    exclude_from_window boolean DEFAULT false NOT NULL,
    details_in_window_with_release boolean DEFAULT false NOT NULL,
    health boolean DEFAULT false NOT NULL,
    vispdat boolean DEFAULT false,
    pathways boolean DEFAULT false,
    ssm boolean DEFAULT false,
    health_case_note boolean DEFAULT false,
    health_has_qualifying_activities boolean DEFAULT false,
    hud_assessment boolean DEFAULT false,
    triage_assessment boolean DEFAULT false,
    rrh_assessment boolean DEFAULT false,
    covid_19_impact_assessment boolean DEFAULT false,
    with_location_data boolean DEFAULT false NOT NULL
);


--
-- Name: hmis_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_assessments_id_seq OWNED BY public.hmis_assessments.id;


--
-- Name: hmis_client_attributes_defined_text; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_client_attributes_defined_text (
    id integer NOT NULL,
    client_id integer,
    data_source_id integer,
    consent_form_status character varying,
    consent_form_updated_at timestamp without time zone,
    source_id character varying,
    source_class character varying
);


--
-- Name: hmis_client_attributes_defined_text_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_client_attributes_defined_text_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_client_attributes_defined_text_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_client_attributes_defined_text_id_seq OWNED BY public.hmis_client_attributes_defined_text.id;


--
-- Name: hmis_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_clients (
    id integer NOT NULL,
    client_id integer,
    response text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    consent_form_status character varying,
    case_manager_name character varying,
    case_manager_attributes text,
    assigned_staff_name character varying,
    assigned_staff_attributes text,
    counselor_name character varying,
    counselor_attributes text,
    outreach_counselor_name character varying,
    subject_id integer,
    processed_fields jsonb,
    consent_confirmed_on date,
    consent_expires_on date,
    eto_last_updated timestamp without time zone,
    sexual_orientation character varying
);


--
-- Name: hmis_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_clients_id_seq OWNED BY public.hmis_clients.id;


--
-- Name: hmis_csv_2020_affiliations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_affiliations (
    id bigint NOT NULL,
    "AffiliationID" character varying,
    "ProjectID" character varying,
    "ResProjectID" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_affiliations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_affiliations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_affiliations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_affiliations_id_seq OWNED BY public.hmis_csv_2020_affiliations.id;


--
-- Name: hmis_csv_2020_assessment_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_assessment_questions (
    id bigint NOT NULL,
    "AssessmentQuestionID" character varying,
    "AssessmentID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "AssessmentQuestionGroup" character varying,
    "AssessmentQuestionOrder" character varying,
    "AssessmentQuestion" character varying,
    "AssessmentAnswer" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_assessment_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_assessment_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_assessment_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_assessment_questions_id_seq OWNED BY public.hmis_csv_2020_assessment_questions.id;


--
-- Name: hmis_csv_2020_assessment_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_assessment_results (
    id bigint NOT NULL,
    "AssessmentResultID" character varying,
    "AssessmentID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "AssessmentResultType" character varying,
    "AssessmentResult" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_assessment_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_assessment_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_assessment_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_assessment_results_id_seq OWNED BY public.hmis_csv_2020_assessment_results.id;


--
-- Name: hmis_csv_2020_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_assessments (
    id bigint NOT NULL,
    "AssessmentID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "AssessmentDate" character varying,
    "AssessmentLocation" character varying,
    "AssessmentType" character varying,
    "AssessmentLevel" character varying,
    "PrioritizationStatus" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_assessments_id_seq OWNED BY public.hmis_csv_2020_assessments.id;


--
-- Name: hmis_csv_2020_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_clients (
    id bigint NOT NULL,
    "PersonalID" character varying,
    "FirstName" character varying,
    "MiddleName" character varying,
    "LastName" character varying,
    "NameSuffix" character varying,
    "NameDataQuality" character varying,
    "SSN" character varying,
    "SSNDataQuality" character varying,
    "DOB" character varying,
    "DOBDataQuality" character varying,
    "AmIndAKNative" character varying,
    "Asian" character varying,
    "BlackAfAmerican" character varying,
    "NativeHIOtherPacific" character varying,
    "White" character varying,
    "RaceNone" character varying,
    "Ethnicity" character varying,
    "Gender" character varying,
    "VeteranStatus" character varying,
    "YearEnteredService" character varying,
    "YearSeparated" character varying,
    "WorldWarII" character varying,
    "KoreanWar" character varying,
    "VietnamWar" character varying,
    "DesertStorm" character varying,
    "AfghanistanOEF" character varying,
    "IraqOIF" character varying,
    "IraqOND" character varying,
    "OtherTheater" character varying,
    "MilitaryBranch" character varying,
    "DischargeStatus" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_clients_id_seq OWNED BY public.hmis_csv_2020_clients.id;


--
-- Name: hmis_csv_2020_current_living_situations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_current_living_situations (
    id bigint NOT NULL,
    "CurrentLivingSitID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "InformationDate" character varying,
    "CurrentLivingSituation" character varying,
    "VerifiedBy" character varying,
    "LeaveSituation14Days" character varying,
    "SubsequentResidence" character varying,
    "ResourcesToObtain" character varying,
    "LeaseOwn60Day" character varying,
    "MovedTwoOrMore" character varying,
    "LocationDetails" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_current_living_situations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_current_living_situations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_current_living_situations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_current_living_situations_id_seq OWNED BY public.hmis_csv_2020_current_living_situations.id;


--
-- Name: hmis_csv_2020_disabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_disabilities (
    id bigint NOT NULL,
    "DisabilitiesID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "InformationDate" character varying,
    "DisabilityType" character varying,
    "DisabilityResponse" character varying,
    "IndefiniteAndImpairs" character varying,
    "TCellCountAvailable" character varying,
    "TCellCount" character varying,
    "TCellSource" character varying,
    "ViralLoadAvailable" character varying,
    "ViralLoad" character varying,
    "ViralLoadSource" character varying,
    "DataCollectionStage" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_disabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_disabilities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_disabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_disabilities_id_seq OWNED BY public.hmis_csv_2020_disabilities.id;


--
-- Name: hmis_csv_2020_employment_educations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_employment_educations (
    id bigint NOT NULL,
    "EmploymentEducationID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "InformationDate" character varying,
    "LastGradeCompleted" character varying,
    "SchoolStatus" character varying,
    "Employed" character varying,
    "EmploymentType" character varying,
    "NotEmployedReason" character varying,
    "DataCollectionStage" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_employment_educations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_employment_educations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_employment_educations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_employment_educations_id_seq OWNED BY public.hmis_csv_2020_employment_educations.id;


--
-- Name: hmis_csv_2020_enrollment_cocs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_enrollment_cocs (
    id bigint NOT NULL,
    "EnrollmentCoCID" character varying,
    "EnrollmentID" character varying,
    "HouseholdID" character varying,
    "ProjectID" character varying,
    "PersonalID" character varying,
    "InformationDate" character varying,
    "CoCCode" character varying,
    "DataCollectionStage" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_enrollment_cocs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_enrollment_cocs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_enrollment_cocs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_enrollment_cocs_id_seq OWNED BY public.hmis_csv_2020_enrollment_cocs.id;


--
-- Name: hmis_csv_2020_enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_enrollments (
    id bigint NOT NULL,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "ProjectID" character varying,
    "EntryDate" character varying,
    "HouseholdID" character varying,
    "RelationshipToHoH" character varying,
    "LivingSituation" character varying,
    "LengthOfStay" character varying,
    "LOSUnderThreshold" character varying,
    "PreviousStreetESSH" character varying,
    "DateToStreetESSH" character varying,
    "TimesHomelessPastThreeYears" character varying,
    "MonthsHomelessPastThreeYears" character varying,
    "DisablingCondition" character varying,
    "DateOfEngagement" character varying,
    "MoveInDate" character varying,
    "DateOfPATHStatus" character varying,
    "ClientEnrolledInPATH" character varying,
    "ReasonNotEnrolled" character varying,
    "WorstHousingSituation" character varying,
    "PercentAMI" character varying,
    "LastPermanentStreet" character varying,
    "LastPermanentCity" character varying,
    "LastPermanentState" character varying,
    "LastPermanentZIP" character varying,
    "AddressDataQuality" character varying,
    "DateOfBCPStatus" character varying,
    "EligibleForRHY" character varying,
    "ReasonNoServices" character varying,
    "RunawayYouth" character varying,
    "SexualOrientation" character varying,
    "SexualOrientationOther" character varying,
    "FormerWardChildWelfare" character varying,
    "ChildWelfareYears" character varying,
    "ChildWelfareMonths" character varying,
    "FormerWardJuvenileJustice" character varying,
    "JuvenileJusticeYears" character varying,
    "JuvenileJusticeMonths" character varying,
    "UnemploymentFam" character varying,
    "MentalHealthIssuesFam" character varying,
    "PhysicalDisabilityFam" character varying,
    "AlcoholDrugAbuseFam" character varying,
    "InsufficientIncome" character varying,
    "IncarceratedParent" character varying,
    "ReferralSource" character varying,
    "CountOutreachReferralApproaches" character varying,
    "UrgentReferral" character varying,
    "TimeToHousingLoss" character varying,
    "ZeroIncome" character varying,
    "AnnualPercentAMI" character varying,
    "FinancialChange" character varying,
    "HouseholdChange" character varying,
    "EvictionHistory" character varying,
    "SubsidyAtRisk" character varying,
    "LiteralHomelessHistory" character varying,
    "DisabledHoH" character varying,
    "CriminalRecord" character varying,
    "SexOffender" character varying,
    "DependentUnder6" character varying,
    "SingleParent" character varying,
    "HH5Plus" character varying,
    "IraqAfghanistan" character varying,
    "FemVet" character varying,
    "HPScreeningScore" character varying,
    "ThresholdScore" character varying,
    "VAMCStation" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_enrollments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_enrollments_id_seq OWNED BY public.hmis_csv_2020_enrollments.id;


--
-- Name: hmis_csv_2020_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_events (
    id bigint NOT NULL,
    "EventID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "EventDate" character varying,
    "Event" character varying,
    "ProbSolDivRRResult" character varying,
    "ReferralCaseManageAfter" character varying,
    "LocationCrisisorPHHousing" character varying,
    "ReferralResult" character varying,
    "ResultDate" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_events_id_seq OWNED BY public.hmis_csv_2020_events.id;


--
-- Name: hmis_csv_2020_exits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_exits (
    id bigint NOT NULL,
    "ExitID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "ExitDate" character varying,
    "Destination" character varying,
    "OtherDestination" character varying,
    "HousingAssessment" character varying,
    "SubsidyInformation" character varying,
    "ProjectCompletionStatus" character varying,
    "EarlyExitReason" character varying,
    "ExchangeForSex" character varying,
    "ExchangeForSexPastThreeMonths" character varying,
    "CountOfExchangeForSex" character varying,
    "AskedOrForcedToExchangeForSex" character varying,
    "AskedOrForcedToExchangeForSexPastThreeMonths" character varying,
    "WorkPlaceViolenceThreats" character varying,
    "WorkplacePromiseDifference" character varying,
    "CoercedToContinueWork" character varying,
    "LaborExploitPastThreeMonths" character varying,
    "CounselingReceived" character varying,
    "IndividualCounseling" character varying,
    "FamilyCounseling" character varying,
    "GroupCounseling" character varying,
    "SessionCountAtExit" character varying,
    "PostExitCounselingPlan" character varying,
    "SessionsInPlan" character varying,
    "DestinationSafeClient" character varying,
    "DestinationSafeWorker" character varying,
    "PosAdultConnections" character varying,
    "PosPeerConnections" character varying,
    "PosCommunityConnections" character varying,
    "AftercareDate" character varying,
    "AftercareProvided" character varying,
    "EmailSocialMedia" character varying,
    "Telephone" character varying,
    "InPersonIndividual" character varying,
    "InPersonGroup" character varying,
    "CMExitReason" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_exits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_exits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_exits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_exits_id_seq OWNED BY public.hmis_csv_2020_exits.id;


--
-- Name: hmis_csv_2020_exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_exports (
    id bigint NOT NULL,
    "ExportID" character varying,
    "SourceType" character varying,
    "SourceID" character varying,
    "SourceName" character varying,
    "SourceContactFirst" character varying,
    "SourceContactLast" character varying,
    "SourceContactPhone" character varying,
    "SourceContactExtension" character varying,
    "SourceContactEmail" character varying,
    "ExportDate" character varying,
    "ExportStartDate" character varying,
    "ExportEndDate" character varying,
    "SoftwareName" character varying,
    "SoftwareVersion" character varying,
    "ExportPeriodType" character varying,
    "ExportDirective" character varying,
    "HashStatus" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_exports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_exports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_exports_id_seq OWNED BY public.hmis_csv_2020_exports.id;


--
-- Name: hmis_csv_2020_funders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_funders (
    id bigint NOT NULL,
    "FunderID" character varying,
    "ProjectID" character varying,
    "Funder" character varying,
    "OtherFunder" character varying,
    "GrantID" character varying,
    "StartDate" character varying,
    "EndDate" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_funders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_funders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_funders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_funders_id_seq OWNED BY public.hmis_csv_2020_funders.id;


--
-- Name: hmis_csv_2020_health_and_dvs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_health_and_dvs (
    id bigint NOT NULL,
    "HealthAndDVID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "InformationDate" character varying,
    "DomesticViolenceVictim" character varying,
    "WhenOccurred" character varying,
    "CurrentlyFleeing" character varying,
    "GeneralHealthStatus" character varying,
    "DentalHealthStatus" character varying,
    "MentalHealthStatus" character varying,
    "PregnancyStatus" character varying,
    "DueDate" character varying,
    "DataCollectionStage" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_health_and_dvs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_health_and_dvs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_health_and_dvs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_health_and_dvs_id_seq OWNED BY public.hmis_csv_2020_health_and_dvs.id;


--
-- Name: hmis_csv_2020_income_benefits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_income_benefits (
    id bigint NOT NULL,
    "IncomeBenefitsID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "InformationDate" character varying,
    "IncomeFromAnySource" character varying,
    "TotalMonthlyIncome" character varying,
    "Earned" character varying,
    "EarnedAmount" character varying,
    "Unemployment" character varying,
    "UnemploymentAmount" character varying,
    "SSI" character varying,
    "SSIAmount" character varying,
    "SSDI" character varying,
    "SSDIAmount" character varying,
    "VADisabilityService" character varying,
    "VADisabilityServiceAmount" character varying,
    "VADisabilityNonService" character varying,
    "VADisabilityNonServiceAmount" character varying,
    "PrivateDisability" character varying,
    "PrivateDisabilityAmount" character varying,
    "WorkersComp" character varying,
    "WorkersCompAmount" character varying,
    "TANF" character varying,
    "TANFAmount" character varying,
    "GA" character varying,
    "GAAmount" character varying,
    "SocSecRetirement" character varying,
    "SocSecRetirementAmount" character varying,
    "Pension" character varying,
    "PensionAmount" character varying,
    "ChildSupport" character varying,
    "ChildSupportAmount" character varying,
    "Alimony" character varying,
    "AlimonyAmount" character varying,
    "OtherIncomeSource" character varying,
    "OtherIncomeAmount" character varying,
    "OtherIncomeSourceIdentify" character varying,
    "BenefitsFromAnySource" character varying,
    "SNAP" character varying,
    "WIC" character varying,
    "TANFChildCare" character varying,
    "TANFTransportation" character varying,
    "OtherTANF" character varying,
    "OtherBenefitsSource" character varying,
    "OtherBenefitsSourceIdentify" character varying,
    "InsuranceFromAnySource" character varying,
    "Medicaid" character varying,
    "NoMedicaidReason" character varying,
    "Medicare" character varying,
    "NoMedicareReason" character varying,
    "SCHIP" character varying,
    "NoSCHIPReason" character varying,
    "VAMedicalServices" character varying,
    "NoVAMedReason" character varying,
    "EmployerProvided" character varying,
    "NoEmployerProvidedReason" character varying,
    "COBRA" character varying,
    "NoCOBRAReason" character varying,
    "PrivatePay" character varying,
    "NoPrivatePayReason" character varying,
    "StateHealthIns" character varying,
    "NoStateHealthInsReason" character varying,
    "IndianHealthServices" character varying,
    "NoIndianHealthServicesReason" character varying,
    "OtherInsurance" character varying,
    "OtherInsuranceIdentify" character varying,
    "HIVAIDSAssistance" character varying,
    "NoHIVAIDSAssistanceReason" character varying,
    "ADAP" character varying,
    "NoADAPReason" character varying,
    "ConnectionWithSOAR" character varying,
    "DataCollectionStage" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_income_benefits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_income_benefits_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_income_benefits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_income_benefits_id_seq OWNED BY public.hmis_csv_2020_income_benefits.id;


--
-- Name: hmis_csv_2020_inventories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_inventories (
    id bigint NOT NULL,
    "InventoryID" character varying,
    "ProjectID" character varying,
    "CoCCode" character varying,
    "HouseholdType" character varying,
    "Availability" character varying,
    "UnitInventory" character varying,
    "BedInventory" character varying,
    "CHVetBedInventory" character varying,
    "YouthVetBedInventory" character varying,
    "VetBedInventory" character varying,
    "CHYouthBedInventory" character varying,
    "YouthBedInventory" character varying,
    "CHBedInventory" character varying,
    "OtherBedInventory" character varying,
    "ESBedType" character varying,
    "InventoryStartDate" character varying,
    "InventoryEndDate" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_inventories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_inventories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_inventories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_inventories_id_seq OWNED BY public.hmis_csv_2020_inventories.id;


--
-- Name: hmis_csv_2020_organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_organizations (
    id bigint NOT NULL,
    "OrganizationID" character varying,
    "OrganizationName" character varying,
    "VictimServicesProvider" character varying,
    "OrganizationCommonName" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_organizations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_organizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_organizations_id_seq OWNED BY public.hmis_csv_2020_organizations.id;


--
-- Name: hmis_csv_2020_project_cocs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_project_cocs (
    id bigint NOT NULL,
    "ProjectCoCID" character varying,
    "ProjectID" character varying,
    "CoCCode" character varying,
    "Geocode" character varying,
    "Address1" character varying,
    "Address2" character varying,
    "City" character varying,
    "State" character varying,
    "Zip" character varying,
    "GeographyType" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_project_cocs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_project_cocs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_project_cocs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_project_cocs_id_seq OWNED BY public.hmis_csv_2020_project_cocs.id;


--
-- Name: hmis_csv_2020_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_projects (
    id bigint NOT NULL,
    "ProjectID" character varying,
    "OrganizationID" character varying,
    "ProjectName" character varying,
    "ProjectCommonName" character varying,
    "OperatingStartDate" character varying,
    "OperatingEndDate" character varying,
    "ContinuumProject" character varying,
    "ProjectType" character varying,
    "HousingType" character varying,
    "ResidentialAffiliation" character varying,
    "TrackingMethod" character varying,
    "HMISParticipatingProject" character varying,
    "TargetPopulation" character varying,
    "PITCount" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_projects_id_seq OWNED BY public.hmis_csv_2020_projects.id;


--
-- Name: hmis_csv_2020_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_services (
    id bigint NOT NULL,
    "ServicesID" character varying,
    "EnrollmentID" character varying,
    "PersonalID" character varying,
    "DateProvided" character varying,
    "RecordType" character varying,
    "TypeProvided" character varying,
    "OtherTypeProvided" character varying,
    "SubTypeProvided" character varying,
    "FAAmount" character varying,
    "ReferralOutcome" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "UserID" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_services_id_seq OWNED BY public.hmis_csv_2020_services.id;


--
-- Name: hmis_csv_2020_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_2020_users (
    id bigint NOT NULL,
    "UserID" character varying,
    "UserFirstName" character varying,
    "UserLastName" character varying,
    "UserPhone" character varying,
    "UserExtension" character varying,
    "UserEmail" character varying,
    "DateCreated" character varying,
    "DateUpdated" character varying,
    "DateDeleted" character varying,
    "ExportID" character varying,
    data_source_id integer NOT NULL,
    loaded_at timestamp without time zone NOT NULL,
    loader_id integer NOT NULL
);


--
-- Name: hmis_csv_2020_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_2020_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_2020_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_2020_users_id_seq OWNED BY public.hmis_csv_2020_users.id;


--
-- Name: hmis_csv_import_errors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_import_errors (
    id bigint NOT NULL,
    importer_log_id integer NOT NULL,
    message character varying,
    details character varying,
    source_type character varying NOT NULL,
    source_id character varying NOT NULL
);


--
-- Name: hmis_csv_import_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_import_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_import_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_import_errors_id_seq OWNED BY public.hmis_csv_import_errors.id;


--
-- Name: hmis_csv_import_validations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_import_validations (
    id bigint NOT NULL,
    importer_log_id integer NOT NULL,
    type character varying NOT NULL,
    source_id character varying NOT NULL,
    source_type character varying NOT NULL,
    status character varying,
    validated_column character varying
);


--
-- Name: hmis_csv_import_validations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_import_validations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_import_validations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_import_validations_id_seq OWNED BY public.hmis_csv_import_validations.id;


--
-- Name: hmis_csv_importer_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_importer_logs (
    id bigint NOT NULL,
    data_source_id integer NOT NULL,
    summary jsonb,
    status character varying,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    upload_id integer
);


--
-- Name: hmis_csv_importer_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_importer_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_importer_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_importer_logs_id_seq OWNED BY public.hmis_csv_importer_logs.id;


--
-- Name: hmis_csv_load_errors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_load_errors (
    id bigint NOT NULL,
    loader_log_id integer NOT NULL,
    file_name character varying NOT NULL,
    message character varying,
    details character varying,
    source character varying
);


--
-- Name: hmis_csv_load_errors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_load_errors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_load_errors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_load_errors_id_seq OWNED BY public.hmis_csv_load_errors.id;


--
-- Name: hmis_csv_loader_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_csv_loader_logs (
    id bigint NOT NULL,
    data_source_id integer NOT NULL,
    importer_log_id integer,
    summary jsonb,
    status character varying,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    upload_id integer
);


--
-- Name: hmis_csv_loader_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_csv_loader_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_csv_loader_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_csv_loader_logs_id_seq OWNED BY public.hmis_csv_loader_logs.id;


--
-- Name: hmis_forms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_forms (
    id integer NOT NULL,
    client_id integer,
    api_response text,
    name character varying,
    answers text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    response_id integer,
    subject_id integer,
    collected_at timestamp without time zone,
    staff character varying,
    assessment_type character varying,
    collection_location character varying,
    assessment_id integer,
    data_source_id integer NOT NULL,
    site_id integer,
    vispdat_score_updated_at timestamp without time zone,
    vispdat_total_score double precision,
    vispdat_youth_score double precision,
    vispdat_family_score double precision,
    vispdat_months_homeless double precision,
    vispdat_times_homeless double precision,
    staff_email character varying,
    eto_last_updated timestamp without time zone,
    housing_status character varying,
    vispdat_pregnant character varying,
    vispdat_pregnant_updated_at date,
    housing_status_updated_at timestamp without time zone,
    pathways_updated_at timestamp without time zone,
    assessment_completed_on date,
    assessment_score integer,
    rrh_desired boolean DEFAULT false NOT NULL,
    youth_rrh_desired boolean DEFAULT false NOT NULL,
    rrh_assessment_contact_info character varying,
    adult_rrh_desired boolean DEFAULT false NOT NULL,
    rrh_th_desired boolean DEFAULT false NOT NULL,
    income_maximization_assistance_requested boolean DEFAULT false NOT NULL,
    income_total_annual integer,
    pending_subsidized_housing_placement boolean DEFAULT false NOT NULL,
    domestic_violence boolean DEFAULT false NOT NULL,
    interested_in_set_asides boolean DEFAULT false NOT NULL,
    required_number_of_bedrooms integer,
    required_minimum_occupancy integer,
    requires_wheelchair_accessibility boolean DEFAULT false NOT NULL,
    requires_elevator_access boolean DEFAULT false NOT NULL,
    youth_rrh_aggregate character varying,
    dv_rrh_aggregate character varying,
    veteran_rrh_desired boolean DEFAULT false NOT NULL,
    sro_ok boolean DEFAULT false NOT NULL,
    other_accessibility boolean DEFAULT false NOT NULL,
    disabled_housing boolean DEFAULT false NOT NULL,
    evicted boolean DEFAULT false NOT NULL,
    neighborhood_interests jsonb DEFAULT '[]'::jsonb,
    client_phones character varying,
    client_emails character varying,
    client_shelters character varying,
    client_case_managers character varying,
    client_day_shelters character varying,
    client_night_shelters character varying,
    ssvf_eligible boolean DEFAULT false,
    vispdat_physical_disability_answer character varying,
    vispdat_physical_disability_updated_at timestamp without time zone,
    covid_impact_updated_at timestamp without time zone,
    number_of_bedrooms integer,
    subsidy_months integer,
    total_subsidy integer,
    monthly_rent_total integer,
    percent_ami integer,
    household_type character varying,
    household_size integer,
    location_processed_at timestamp without time zone
);


--
-- Name: hmis_forms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_forms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_forms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_forms_id_seq OWNED BY public.hmis_forms.id;


--
-- Name: hmis_import_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_import_configs (
    id bigint NOT NULL,
    data_source_id bigint NOT NULL,
    active boolean DEFAULT false,
    s3_access_key_id character varying NOT NULL,
    encrypted_s3_secret_access_key character varying NOT NULL,
    encrypted_s3_secret_access_key_iv character varying,
    s3_region character varying,
    s3_bucket_name character varying,
    s3_path character varying,
    encrypted_zip_file_password character varying,
    encrypted_zip_file_password_iv character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: hmis_import_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_import_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_import_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_import_configs_id_seq OWNED BY public.hmis_import_configs.id;


--
-- Name: hmis_staff; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_staff (
    id integer NOT NULL,
    site_id integer,
    first_name character varying,
    last_name character varying,
    middle_initial character varying,
    work_phone character varying,
    cell_phone character varying,
    email character varying,
    ssn character varying,
    source_class character varying,
    source_id character varying,
    data_source_id integer
);


--
-- Name: hmis_staff_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_staff_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_staff_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_staff_id_seq OWNED BY public.hmis_staff.id;


--
-- Name: hmis_staff_x_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hmis_staff_x_clients (
    id integer NOT NULL,
    staff_id integer,
    client_id integer,
    relationship_id integer,
    source_class character varying,
    source_id character varying
);


--
-- Name: hmis_staff_x_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_staff_x_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_staff_x_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hmis_staff_x_clients_id_seq OWNED BY public.hmis_staff_x_clients.id;


--
-- Name: homeless_summary_report_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.homeless_summary_report_clients (
    id bigint NOT NULL,
    client_id bigint,
    report_id bigint,
    first_name character varying,
    last_name character varying,
    spm_m1a_es_sh_days integer,
    spm_m1a_es_sh_th_days integer,
    spm_m1b_es_sh_ph_days integer,
    spm_m1b_es_sh_th_ph_days integer,
    spm_m2_reentry_days integer,
    spm_m7a1_destination integer,
    spm_m7b1_destination integer,
    spm_m7b2_destination integer,
    spm_m7a1_c2 boolean DEFAULT false,
    spm_m7a1_c3 boolean DEFAULT false,
    spm_m7a1_c4 boolean DEFAULT false,
    spm_m7b1_c2 boolean DEFAULT false,
    spm_m7b1_c3 boolean DEFAULT false,
    spm_m7b2_c2 boolean DEFAULT false,
    spm_m7b2_c3 boolean DEFAULT false,
    spm_all_persons integer,
    spm_without_children integer,
    spm_with_children integer,
    spm_only_children integer,
    spm_without_children_and_fifty_five_plus integer,
    spm_adults_with_children_where_parenting_adult_18_to_24 integer,
    spm_white_non_hispanic_latino integer,
    spm_hispanic_latino integer,
    spm_black_african_american integer,
    spm_asian integer,
    spm_american_indian_alaskan_native integer,
    spm_native_hawaiian_other_pacific_islander integer,
    spm_multi_racial integer,
    spm_fleeing_dv integer,
    spm_veteran integer,
    spm_has_disability integer,
    spm_has_rrh_move_in_date integer,
    spm_has_psh_move_in_date integer,
    spm_first_time_homeless integer,
    spm_returned_to_homelessness_from_permanent_destination integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    spm_exited_from_homeless_system boolean DEFAULT false
);


--
-- Name: homeless_summary_report_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.homeless_summary_report_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: homeless_summary_report_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.homeless_summary_report_clients_id_seq OWNED BY public.homeless_summary_report_clients.id;


--
-- Name: housing_resolution_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.housing_resolution_plans (
    id bigint NOT NULL,
    client_id bigint,
    user_id bigint,
    pronouns character varying,
    planned_on date,
    staff_name character varying,
    location character varying,
    chosen_resolution character varying,
    temporary_resolution character varying,
    plan_description character varying,
    action_steps character varying,
    backup_plan character varying,
    next_checkin date,
    how_to_contact character varying,
    psc_attempted character varying,
    psc_why_not character varying,
    resolution_achieved character varying,
    resolution_why_not character varying,
    problem_solving_point character varying,
    housing_crisis_causes jsonb,
    housing_crisis_cause_other character varying,
    factor_employment_income character varying,
    factor_family_supports character varying,
    factor_social_supports character varying,
    factor_life_skills character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: housing_resolution_plans_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.housing_resolution_plans_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: housing_resolution_plans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.housing_resolution_plans_id_seq OWNED BY public.housing_resolution_plans.id;


--
-- Name: hud_chronics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hud_chronics (
    id integer NOT NULL,
    date date,
    client_id integer,
    months_in_last_three_years integer,
    individual boolean,
    age integer,
    homeless_since date,
    dmh boolean,
    trigger character varying,
    project_names character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    days_in_last_three_years integer
);


--
-- Name: hud_chronics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hud_chronics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hud_chronics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hud_chronics_id_seq OWNED BY public.hud_chronics.id;


--
-- Name: hud_create_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hud_create_logs (
    id integer NOT NULL,
    hud_key character varying NOT NULL,
    personal_id character varying NOT NULL,
    type character varying NOT NULL,
    imported_at timestamp without time zone NOT NULL,
    effective_date date NOT NULL,
    data_source_id integer NOT NULL
);


--
-- Name: hud_create_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hud_create_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hud_create_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hud_create_logs_id_seq OWNED BY public.hud_create_logs.id;


--
-- Name: hud_report_apr_ce_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hud_report_apr_ce_assessments (
    id bigint NOT NULL,
    hud_report_apr_client_id bigint,
    project_id bigint,
    assessment_date date,
    assessment_level integer,
    deleted_at timestamp without time zone
);


--
-- Name: hud_report_apr_ce_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hud_report_apr_ce_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hud_report_apr_ce_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hud_report_apr_ce_assessments_id_seq OWNED BY public.hud_report_apr_ce_assessments.id;


--
-- Name: hud_report_apr_ce_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hud_report_apr_ce_events (
    id bigint NOT NULL,
    hud_report_apr_client_id bigint,
    project_id bigint,
    event_date date,
    event integer,
    problem_sol_div_rr_result integer,
    referral_case_manage_after integer,
    referral_result integer,
    deleted_at timestamp without time zone
);


--
-- Name: hud_report_apr_ce_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hud_report_apr_ce_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hud_report_apr_ce_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hud_report_apr_ce_events_id_seq OWNED BY public.hud_report_apr_ce_events.id;


--
-- Name: hud_report_apr_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hud_report_apr_clients (
    id bigint NOT NULL,
    age integer,
    head_of_household boolean,
    head_of_household_id character varying,
    parenting_youth boolean,
    first_date_in_program date,
    last_date_in_program date,
    veteran_status integer,
    length_of_stay integer,
    chronically_homeless boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    first_name character varying,
    last_name character varying,
    name_quality integer,
    ssn character varying,
    ssn_quality integer,
    dob date,
    dob_quality integer,
    enrollment_created date,
    ethnicity integer,
    gender integer,
    overlapping_enrollments jsonb,
    relationship_to_hoh integer,
    household_id character varying,
    enrollment_coc character varying,
    disabling_condition integer,
    developmental_disability boolean,
    hiv_aids boolean,
    physical_disability boolean,
    chronic_disability boolean,
    mental_health_problem boolean,
    substance_abuse boolean,
    indefinite_and_impairs boolean,
    client_id integer,
    data_source_id integer,
    report_instance_id integer,
    destination integer,
    income_date_at_start date,
    income_from_any_source_at_start integer,
    income_sources_at_start jsonb,
    annual_assessment_expected boolean,
    income_date_at_annual_assessment date,
    income_from_any_source_at_annual_assessment integer,
    income_sources_at_annual_assessment jsonb,
    income_date_at_exit date,
    income_from_any_source_at_exit integer,
    income_sources_at_exit jsonb,
    project_type integer,
    prior_living_situation integer,
    prior_length_of_stay integer,
    date_homeless date,
    times_homeless integer,
    months_homeless integer,
    came_from_street_last_night integer,
    exit_created date,
    project_tracking_method integer,
    date_of_last_bed_night date,
    other_clients_over_25 boolean,
    move_in_date date,
    household_type character varying,
    race integer,
    developmental_disability_entry integer,
    hiv_aids_entry integer,
    physical_disability_entry integer,
    chronic_disability_entry integer,
    mental_health_problem_entry integer,
    substance_abuse_entry integer,
    alcohol_abuse_entry boolean,
    drug_abuse_entry boolean,
    developmental_disability_exit integer,
    hiv_aids_exit integer,
    physical_disability_exit integer,
    chronic_disability_exit integer,
    mental_health_problem_exit integer,
    substance_abuse_exit integer,
    alcohol_abuse_exit boolean,
    drug_abuse_exit boolean,
    developmental_disability_latest integer,
    hiv_aids_latest integer,
    physical_disability_latest integer,
    chronic_disability_latest integer,
    mental_health_problem_latest integer,
    substance_abuse_latest integer,
    alcohol_abuse_latest boolean,
    drug_abuse_latest boolean,
    domestic_violence integer,
    currently_fleeing integer,
    income_total_at_start integer,
    income_total_at_annual_assessment integer,
    income_total_at_exit integer,
    non_cash_benefits_from_any_source_at_start integer,
    non_cash_benefits_from_any_source_at_annual_assessment integer,
    non_cash_benefits_from_any_source_at_exit integer,
    insurance_from_any_source_at_start integer,
    insurance_from_any_source_at_annual_assessment integer,
    insurance_from_any_source_at_exit integer,
    time_to_move_in integer,
    approximate_length_of_stay integer,
    approximate_time_to_move_in integer,
    date_to_street date,
    housing_assessment integer,
    subsidy_information integer,
    date_of_engagement date,
    household_members jsonb,
    parenting_juvenile boolean,
    deleted_at timestamp without time zone,
    destination_client_id integer,
    annual_assessment_in_window boolean,
    chronically_homeless_detail character varying,
    ce_assessment_date date,
    ce_assessment_type integer,
    ce_assessment_prioritization_status integer,
    ce_event_date date,
    ce_event_event integer,
    ce_event_problem_sol_div_rr_result integer,
    ce_event_referral_case_manage_after integer,
    ce_event_referral_result integer,
    gender_multi character varying
);


--
-- Name: hud_report_apr_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hud_report_apr_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hud_report_apr_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hud_report_apr_clients_id_seq OWNED BY public.hud_report_apr_clients.id;


--
-- Name: hud_report_apr_living_situations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hud_report_apr_living_situations (
    id bigint NOT NULL,
    hud_report_apr_client_id bigint,
    information_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    living_situation integer,
    deleted_at timestamp without time zone
);


--
-- Name: hud_report_apr_living_situations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hud_report_apr_living_situations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hud_report_apr_living_situations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hud_report_apr_living_situations_id_seq OWNED BY public.hud_report_apr_living_situations.id;


--
-- Name: hud_report_cells; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hud_report_cells (
    id bigint NOT NULL,
    report_instance_id bigint,
    question character varying NOT NULL,
    cell_name character varying,
    universe boolean DEFAULT false,
    metadata json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    summary json,
    status character varying,
    error_messages text,
    deleted_at timestamp without time zone
);


--
-- Name: hud_report_cells_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hud_report_cells_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hud_report_cells_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hud_report_cells_id_seq OWNED BY public.hud_report_cells.id;


--
-- Name: hud_report_dq_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hud_report_dq_clients (
    id bigint NOT NULL,
    client_id integer,
    data_source_id integer,
    report_instance_id integer,
    destination_client_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    age integer,
    alcohol_abuse_entry boolean,
    alcohol_abuse_exit boolean,
    alcohol_abuse_latest boolean,
    annual_assessment_expected boolean,
    approximate_length_of_stay integer,
    approximate_time_to_move_in integer,
    came_from_street_last_night integer,
    chronic_disability boolean,
    chronic_disability_entry integer,
    chronic_disability_exit integer,
    chronic_disability_latest integer,
    chronically_homeless boolean,
    currently_fleeing integer,
    date_homeless date,
    date_of_engagement date,
    date_of_last_bed_night date,
    date_to_street date,
    destination integer,
    developmental_disability boolean,
    developmental_disability_entry integer,
    developmental_disability_exit integer,
    developmental_disability_latest integer,
    disabling_condition integer,
    dob date,
    dob_quality integer,
    domestic_violence integer,
    drug_abuse_entry boolean,
    drug_abuse_exit boolean,
    drug_abuse_latest boolean,
    enrollment_coc character varying,
    enrollment_created date,
    ethnicity integer,
    exit_created date,
    first_date_in_program date,
    first_name character varying,
    gender integer,
    head_of_household boolean,
    head_of_household_id character varying,
    hiv_aids boolean,
    hiv_aids_entry integer,
    hiv_aids_exit integer,
    hiv_aids_latest integer,
    household_id character varying,
    household_members jsonb,
    household_type character varying,
    housing_assessment integer,
    income_date_at_annual_assessment date,
    income_date_at_exit date,
    income_date_at_start date,
    income_from_any_source_at_annual_assessment integer,
    income_from_any_source_at_exit integer,
    income_from_any_source_at_start integer,
    income_sources_at_annual_assessment jsonb,
    income_sources_at_exit jsonb,
    income_sources_at_start jsonb,
    income_total_at_annual_assessment integer,
    income_total_at_exit integer,
    income_total_at_start integer,
    indefinite_and_impairs boolean,
    insurance_from_any_source_at_annual_assessment integer,
    insurance_from_any_source_at_exit integer,
    insurance_from_any_source_at_start integer,
    last_date_in_program date,
    last_name character varying,
    length_of_stay integer,
    mental_health_problem boolean,
    mental_health_problem_entry integer,
    mental_health_problem_exit integer,
    mental_health_problem_latest integer,
    months_homeless integer,
    move_in_date date,
    name_quality integer,
    non_cash_benefits_from_any_source_at_annual_assessment integer,
    non_cash_benefits_from_any_source_at_exit integer,
    non_cash_benefits_from_any_source_at_start integer,
    other_clients_over_25 boolean,
    overlapping_enrollments jsonb,
    parenting_juvenil boolean,
    parenting_youth boolean,
    physical_disability boolean,
    physical_disability_entry integer,
    physical_disability_exit integer,
    physical_disability_latest integer,
    prior_length_of_stay integer,
    prior_living_situation integer,
    project_tracking_method integer,
    project_type integer,
    race integer,
    relationship_to_hoh integer,
    ssn character varying,
    ssn_quality integer,
    subsidy_information integer,
    substance_abuse boolean,
    substance_abuse_entry integer,
    substance_abuse_exit integer,
    substance_abuse_latest integer,
    time_to_move_in integer,
    times_homeless integer,
    veteran_status integer,
    annual_assessment_in_window boolean,
    gender_multi character varying
);


--
-- Name: hud_report_dq_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hud_report_dq_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hud_report_dq_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hud_report_dq_clients_id_seq OWNED BY public.hud_report_dq_clients.id;


--
-- Name: hud_report_dq_living_situations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hud_report_dq_living_situations (
    id bigint NOT NULL,
    hud_report_dq_client_id bigint,
    living_situation integer,
    information_date date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: hud_report_dq_living_situations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hud_report_dq_living_situations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hud_report_dq_living_situations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hud_report_dq_living_situations_id_seq OWNED BY public.hud_report_dq_living_situations.id;


--
-- Name: hud_report_instances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hud_report_instances (
    id bigint NOT NULL,
    user_id bigint,
    coc_code character varying,
    report_name character varying,
    start_date date,
    end_date date,
    options json,
    state character varying,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    project_ids json,
    question_names json NOT NULL,
    zip_file bytea,
    deleted_at timestamp without time zone,
    build_for_questions jsonb,
    remaining_questions jsonb,
    coc_codes jsonb
);


--
-- Name: hud_report_instances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hud_report_instances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hud_report_instances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hud_report_instances_id_seq OWNED BY public.hud_report_instances.id;


--
-- Name: hud_report_path_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hud_report_path_clients (
    id bigint NOT NULL,
    client_id bigint,
    data_source_id bigint,
    report_instance_id bigint,
    first_name character varying,
    last_name character varying,
    age integer,
    dob date,
    dob_quality integer,
    gender integer,
    am_ind_ak_native integer,
    asian integer,
    black_af_american integer,
    native_hi_other_pacific integer,
    white integer,
    race_none integer,
    ethnicity integer,
    veteran integer,
    substance_use_disorder integer,
    soar integer,
    prior_living_situation integer,
    length_of_stay integer,
    chronically_homeless character varying,
    domestic_violence integer,
    active_client boolean,
    new_client boolean,
    enrolled_client boolean,
    date_of_determination date,
    reason_not_enrolled integer,
    project_type integer,
    first_date_in_program date,
    last_date_in_program date,
    contacts date[],
    services jsonb,
    referrals jsonb,
    income_from_any_source_entry integer,
    incomes_at_entry jsonb,
    income_from_any_source_exit integer,
    incomes_at_exit jsonb,
    income_from_any_source_report_end integer,
    incomes_at_report_end jsonb,
    benefits_from_any_source_entry integer,
    benefits_from_any_source_exit integer,
    benefits_from_any_source_report_end integer,
    insurance_from_any_source_entry integer,
    insurance_from_any_source_exit integer,
    insurance_from_any_source_report_end integer,
    destination integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    gender_multi character varying
);


--
-- Name: hud_report_path_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hud_report_path_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hud_report_path_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hud_report_path_clients_id_seq OWNED BY public.hud_report_path_clients.id;


--
-- Name: hud_report_spm_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hud_report_spm_clients (
    id bigint NOT NULL,
    client_id integer NOT NULL,
    data_source_id integer NOT NULL,
    report_instance_id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    dob date,
    first_name character varying,
    last_name character varying,
    m1a_es_sh_days integer,
    m1a_es_sh_th_days integer,
    m1b_es_sh_ph_days integer,
    m1b_es_sh_th_ph_days integer,
    m1_history jsonb,
    m2_exit_from_project_type integer,
    m2_exit_to_destination integer,
    m2_reentry_days integer,
    m2_history jsonb,
    m3_active_project_types integer[],
    m4_stayer boolean,
    m4_latest_income numeric,
    m4_latest_earned_income numeric,
    m4_latest_non_earned_income numeric,
    m4_earliest_income numeric,
    m4_earliest_earned_income numeric,
    m4_earliest_non_earned_income numeric,
    m4_history jsonb,
    m5_active_project_types integer[],
    m5_recent_project_types integer[],
    m5_history jsonb,
    m6_exit_from_project_type integer,
    m6_exit_to_destination integer,
    m6_reentry_days integer,
    m6c1_destination integer,
    m6c2_destination integer,
    m6_history jsonb,
    m7a1_destination integer,
    m7b1_destination integer,
    m7b2_destination integer,
    m7_history jsonb
);


--
-- Name: hud_report_spm_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hud_report_spm_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hud_report_spm_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hud_report_spm_clients_id_seq OWNED BY public.hud_report_spm_clients.id;


--
-- Name: hud_report_universe_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.hud_report_universe_members (
    id bigint NOT NULL,
    report_cell_id bigint,
    universe_membership_type character varying,
    universe_membership_id bigint,
    client_id bigint,
    first_name character varying,
    last_name character varying,
    deleted_at timestamp without time zone
);


--
-- Name: hud_report_universe_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hud_report_universe_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hud_report_universe_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.hud_report_universe_members_id_seq OWNED BY public.hud_report_universe_members.id;


--
-- Name: identify_duplicates_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.identify_duplicates_log (
    id integer NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    to_match integer,
    matched integer,
    new_created integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: identify_duplicates_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.identify_duplicates_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identify_duplicates_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.identify_duplicates_log_id_seq OWNED BY public.identify_duplicates_log.id;


--
-- Name: import_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.import_logs (
    id integer NOT NULL,
    data_source_id integer,
    files character varying,
    import_errors text,
    summary character varying,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    zip character varying,
    upload_id integer,
    encrypted_import_errors text,
    encrypted_import_errors_iv character varying,
    type character varying DEFAULT 'GrdaWarehouse::ImportLog'::character varying,
    loader_log_id bigint,
    importer_log_id bigint
);


--
-- Name: import_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.import_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: import_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.import_logs_id_seq OWNED BY public.import_logs.id;


--
-- Name: income_benefits_report_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.income_benefits_report_clients (
    id bigint NOT NULL,
    report_id bigint NOT NULL,
    client_id bigint NOT NULL,
    date_range character varying NOT NULL,
    first_name character varying,
    middle_name character varying,
    last_name character varying,
    ethnicity integer,
    race character varying,
    dob date,
    age integer,
    gender integer,
    household_id character varying,
    head_of_household boolean,
    enrollment_id bigint NOT NULL,
    entry_date date,
    exit_date date,
    move_in_date date,
    project_name character varying,
    project_id bigint,
    earlier_income_record_id bigint,
    later_income_record_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: income_benefits_report_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.income_benefits_report_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: income_benefits_report_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.income_benefits_report_clients_id_seq OWNED BY public.income_benefits_report_clients.id;


--
-- Name: income_benefits_report_incomes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.income_benefits_report_incomes (
    id bigint NOT NULL,
    report_id bigint NOT NULL,
    client_id bigint NOT NULL,
    income_benefits_id bigint NOT NULL,
    stage character varying NOT NULL,
    date_range character varying NOT NULL,
    "InformationDate" date NOT NULL,
    "IncomeFromAnySource" integer,
    "TotalMonthlyIncome" numeric,
    "Earned" integer,
    "EarnedAmount" numeric,
    "Unemployment" integer,
    "UnemploymentAmount" numeric,
    "SSI" integer,
    "SSIAmount" numeric,
    "SSDI" integer,
    "SSDIAmount" numeric,
    "VADisabilityService" integer,
    "VADisabilityServiceAmount" numeric,
    "VADisabilityNonService" integer,
    "VADisabilityNonServiceAmount" numeric,
    "PrivateDisability" integer,
    "PrivateDisabilityAmount" numeric,
    "WorkersComp" integer,
    "WorkersCompAmount" numeric,
    "TANF" integer,
    "TANFAmount" numeric,
    "GA" integer,
    "GAAmount" numeric,
    "SocSecRetirement" integer,
    "SocSecRetirementAmount" numeric,
    "Pension" integer,
    "PensionAmount" numeric,
    "ChildSupport" integer,
    "ChildSupportAmount" numeric,
    "Alimony" integer,
    "AlimonyAmount" numeric,
    "OtherIncomeSource" integer,
    "OtherIncomeAmount" numeric,
    "OtherIncomeSourceIdentify" character varying,
    "BenefitsFromAnySource" integer,
    "SNAP" integer,
    "WIC" integer,
    "TANFChildCare" integer,
    "TANFTransportation" integer,
    "OtherTANF" integer,
    "OtherBenefitsSource" integer,
    "OtherBenefitsSourceIdentify" character varying,
    "InsuranceFromAnySource" integer,
    "Medicaid" integer,
    "NoMedicaidReason" integer,
    "Medicare" integer,
    "NoMedicareReason" integer,
    "SCHIP" integer,
    "NoSCHIPReason" integer,
    "VAMedicalServices" integer,
    "NoVAMedReason" integer,
    "EmployerProvided" integer,
    "NoEmployerProvidedReason" integer,
    "COBRA" integer,
    "NoCOBRAReason" integer,
    "PrivatePay" integer,
    "NoPrivatePayReason" integer,
    "StateHealthIns" integer,
    "NoStateHealthInsReason" integer,
    "IndianHealthServices" integer,
    "NoIndianHealthServicesReason" integer,
    "OtherInsurance" integer,
    "OtherInsuranceIdentify" character varying,
    "HIVAIDSAssistance" integer,
    "NoHIVAIDSAssistanceReason" integer,
    "ADAP" integer,
    "NoADAPReason" integer,
    "ConnectionWithSOAR" integer,
    "DataCollectionStage" integer
);


--
-- Name: income_benefits_report_incomes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.income_benefits_report_incomes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: income_benefits_report_incomes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.income_benefits_report_incomes_id_seq OWNED BY public.income_benefits_report_incomes.id;


--
-- Name: income_benefits_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.income_benefits_reports (
    id bigint NOT NULL,
    user_id bigint,
    options jsonb,
    report_date_range character varying NOT NULL,
    comparison_date_range character varying NOT NULL,
    processing_errors character varying,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    failed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: income_benefits_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.income_benefits_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: income_benefits_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.income_benefits_reports_id_seq OWNED BY public.income_benefits_reports.id;


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
-- Name: involved_in_imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.involved_in_imports (
    id bigint NOT NULL,
    importer_log_id bigint,
    record_type character varying NOT NULL,
    record_id bigint NOT NULL,
    hud_key character varying NOT NULL,
    record_action public.record_action
);


--
-- Name: involved_in_imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.involved_in_imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: involved_in_imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.involved_in_imports_id_seq OWNED BY public.involved_in_imports.id;


--
-- Name: lftp_s3_syncs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lftp_s3_syncs (
    id bigint NOT NULL,
    data_source_id bigint NOT NULL,
    ftp_host character varying NOT NULL,
    ftp_user character varying NOT NULL,
    encrypted_ftp_pass character varying NOT NULL,
    encrypted_ftp_pass_iv character varying NOT NULL,
    ftp_path character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: lftp_s3_syncs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lftp_s3_syncs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lftp_s3_syncs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lftp_s3_syncs_id_seq OWNED BY public.lftp_s3_syncs.id;


--
-- Name: lookups_ethnicities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lookups_ethnicities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lookups_ethnicities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lookups_ethnicities_id_seq OWNED BY public.lookups_ethnicities.id;


--
-- Name: lookups_funding_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lookups_funding_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lookups_funding_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lookups_funding_sources_id_seq OWNED BY public.lookups_funding_sources.id;


--
-- Name: lookups_genders_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lookups_genders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lookups_genders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lookups_genders_id_seq OWNED BY public.lookups_genders.id;


--
-- Name: lookups_living_situations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lookups_living_situations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lookups_living_situations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lookups_living_situations_id_seq OWNED BY public.lookups_living_situations.id;


--
-- Name: lookups_project_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lookups_project_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lookups_project_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lookups_project_types_id_seq OWNED BY public.lookups_project_types.id;


--
-- Name: lookups_relationships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lookups_relationships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lookups_relationships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lookups_relationships_id_seq OWNED BY public.lookups_relationships.id;


--
-- Name: lookups_tracking_methods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lookups_tracking_methods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lookups_tracking_methods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lookups_tracking_methods_id_seq OWNED BY public.lookups_tracking_methods.id;


--
-- Name: lookups_yes_no_etcs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lookups_yes_no_etcs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lookups_yes_no_etcs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lookups_yes_no_etcs_id_seq OWNED BY public.lookups_yes_no_etcs.id;


--
-- Name: lsa_rds_state_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lsa_rds_state_logs (
    id bigint NOT NULL,
    state character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: lsa_rds_state_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lsa_rds_state_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lsa_rds_state_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lsa_rds_state_logs_id_seq OWNED BY public.lsa_rds_state_logs.id;


--
-- Name: new_service_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.new_service_history (
    id integer NOT NULL,
    client_id integer NOT NULL,
    data_source_id integer,
    date date NOT NULL,
    first_date_in_program date NOT NULL,
    last_date_in_program date,
    enrollment_group_id character varying(50),
    age smallint,
    destination integer,
    head_of_household_id character varying(50),
    household_id character varying(50),
    project_id character varying(50),
    project_name character varying(150),
    project_type smallint,
    project_tracking_method integer,
    organization_id character varying(50),
    record_type character varying(50) NOT NULL,
    housing_status_at_entry integer,
    housing_status_at_exit integer,
    service_type smallint,
    computed_project_type smallint,
    presented_as_individual boolean,
    other_clients_over_25 smallint DEFAULT 0 NOT NULL,
    other_clients_under_18 smallint DEFAULT 0 NOT NULL,
    other_clients_between_18_and_25 smallint DEFAULT 0 NOT NULL,
    unaccompanied_youth boolean DEFAULT false NOT NULL,
    parenting_youth boolean DEFAULT false NOT NULL,
    parenting_juvenile boolean DEFAULT false NOT NULL,
    children_only boolean DEFAULT false NOT NULL,
    individual_adult boolean DEFAULT false NOT NULL,
    individual_elder boolean DEFAULT false NOT NULL,
    head_of_household boolean DEFAULT false NOT NULL
);


--
-- Name: new_service_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.new_service_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: new_service_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.new_service_history_id_seq OWNED BY public.new_service_history.id;


--
-- Name: nightly_census_by_project_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nightly_census_by_project_clients (
    id integer NOT NULL,
    date date NOT NULL,
    project_id integer NOT NULL,
    veterans jsonb DEFAULT '[]'::jsonb,
    non_veterans jsonb DEFAULT '[]'::jsonb,
    children jsonb DEFAULT '[]'::jsonb,
    adults jsonb DEFAULT '[]'::jsonb,
    youth jsonb DEFAULT '[]'::jsonb,
    families jsonb DEFAULT '[]'::jsonb,
    individuals jsonb DEFAULT '[]'::jsonb,
    parenting_youth jsonb DEFAULT '[]'::jsonb,
    parenting_juveniles jsonb DEFAULT '[]'::jsonb,
    all_clients jsonb DEFAULT '[]'::jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    juveniles jsonb DEFAULT '[]'::jsonb,
    unaccompanied_minors jsonb DEFAULT '[]'::jsonb,
    youth_families jsonb DEFAULT '[]'::jsonb,
    family_parents jsonb DEFAULT '[]'::jsonb
);


--
-- Name: nightly_census_by_project_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nightly_census_by_project_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nightly_census_by_project_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nightly_census_by_project_clients_id_seq OWNED BY public.nightly_census_by_project_clients.id;


--
-- Name: nightly_census_by_project_type_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nightly_census_by_project_type_clients (
    id integer NOT NULL,
    date date NOT NULL,
    literally_homeless_veterans jsonb DEFAULT '[]'::jsonb,
    literally_homeless_non_veterans jsonb DEFAULT '[]'::jsonb,
    literally_homeless_children jsonb DEFAULT '[]'::jsonb,
    literally_homeless_adults jsonb DEFAULT '[]'::jsonb,
    literally_homeless_youth jsonb DEFAULT '[]'::jsonb,
    literally_homeless_families jsonb DEFAULT '[]'::jsonb,
    literally_homeless_individuals jsonb DEFAULT '[]'::jsonb,
    literally_homeless_parenting_youth jsonb DEFAULT '[]'::jsonb,
    literally_homeless_parenting_juveniles jsonb DEFAULT '[]'::jsonb,
    literally_homeless_all_clients jsonb DEFAULT '[]'::jsonb,
    system_veterans jsonb DEFAULT '[]'::jsonb,
    system_non_veterans jsonb DEFAULT '[]'::jsonb,
    system_children jsonb DEFAULT '[]'::jsonb,
    system_adults jsonb DEFAULT '[]'::jsonb,
    system_youth jsonb DEFAULT '[]'::jsonb,
    system_families jsonb DEFAULT '[]'::jsonb,
    system_individuals jsonb DEFAULT '[]'::jsonb,
    system_parenting_youth jsonb DEFAULT '[]'::jsonb,
    system_parenting_juveniles jsonb DEFAULT '[]'::jsonb,
    system_all_clients jsonb DEFAULT '[]'::jsonb,
    homeless_veterans jsonb DEFAULT '[]'::jsonb,
    homeless_non_veterans jsonb DEFAULT '[]'::jsonb,
    homeless_children jsonb DEFAULT '[]'::jsonb,
    homeless_adults jsonb DEFAULT '[]'::jsonb,
    homeless_youth jsonb DEFAULT '[]'::jsonb,
    homeless_families jsonb DEFAULT '[]'::jsonb,
    homeless_individuals jsonb DEFAULT '[]'::jsonb,
    homeless_parenting_youth jsonb DEFAULT '[]'::jsonb,
    homeless_parenting_juveniles jsonb DEFAULT '[]'::jsonb,
    homeless_all_clients jsonb DEFAULT '[]'::jsonb,
    ph_veterans jsonb DEFAULT '[]'::jsonb,
    ph_non_veterans jsonb DEFAULT '[]'::jsonb,
    ph_children jsonb DEFAULT '[]'::jsonb,
    ph_adults jsonb DEFAULT '[]'::jsonb,
    ph_youth jsonb DEFAULT '[]'::jsonb,
    ph_families jsonb DEFAULT '[]'::jsonb,
    ph_individuals jsonb DEFAULT '[]'::jsonb,
    ph_parenting_youth jsonb DEFAULT '[]'::jsonb,
    ph_parenting_juveniles jsonb DEFAULT '[]'::jsonb,
    ph_all_clients jsonb DEFAULT '[]'::jsonb,
    es_veterans jsonb DEFAULT '[]'::jsonb,
    es_non_veterans jsonb DEFAULT '[]'::jsonb,
    es_children jsonb DEFAULT '[]'::jsonb,
    es_adults jsonb DEFAULT '[]'::jsonb,
    es_youth jsonb DEFAULT '[]'::jsonb,
    es_families jsonb DEFAULT '[]'::jsonb,
    es_individuals jsonb DEFAULT '[]'::jsonb,
    es_parenting_youth jsonb DEFAULT '[]'::jsonb,
    es_parenting_juveniles jsonb DEFAULT '[]'::jsonb,
    es_all_clients jsonb DEFAULT '[]'::jsonb,
    th_veterans jsonb DEFAULT '[]'::jsonb,
    th_non_veterans jsonb DEFAULT '[]'::jsonb,
    th_children jsonb DEFAULT '[]'::jsonb,
    th_adults jsonb DEFAULT '[]'::jsonb,
    th_youth jsonb DEFAULT '[]'::jsonb,
    th_families jsonb DEFAULT '[]'::jsonb,
    th_individuals jsonb DEFAULT '[]'::jsonb,
    th_parenting_youth jsonb DEFAULT '[]'::jsonb,
    th_parenting_juveniles jsonb DEFAULT '[]'::jsonb,
    th_all_clients jsonb DEFAULT '[]'::jsonb,
    so_veterans jsonb DEFAULT '[]'::jsonb,
    so_non_veterans jsonb DEFAULT '[]'::jsonb,
    so_children jsonb DEFAULT '[]'::jsonb,
    so_adults jsonb DEFAULT '[]'::jsonb,
    so_youth jsonb DEFAULT '[]'::jsonb,
    so_families jsonb DEFAULT '[]'::jsonb,
    so_individuals jsonb DEFAULT '[]'::jsonb,
    so_parenting_youth jsonb DEFAULT '[]'::jsonb,
    so_parenting_juveniles jsonb DEFAULT '[]'::jsonb,
    so_all_clients jsonb DEFAULT '[]'::jsonb,
    sh_veterans jsonb DEFAULT '[]'::jsonb,
    sh_non_veterans jsonb DEFAULT '[]'::jsonb,
    sh_children jsonb DEFAULT '[]'::jsonb,
    sh_adults jsonb DEFAULT '[]'::jsonb,
    sh_youth jsonb DEFAULT '[]'::jsonb,
    sh_families jsonb DEFAULT '[]'::jsonb,
    sh_individuals jsonb DEFAULT '[]'::jsonb,
    sh_parenting_youth jsonb DEFAULT '[]'::jsonb,
    sh_parenting_juveniles jsonb DEFAULT '[]'::jsonb,
    sh_all_clients jsonb DEFAULT '[]'::jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    literally_homeless_juveniles jsonb DEFAULT '[]'::jsonb,
    system_juveniles jsonb DEFAULT '[]'::jsonb,
    homeless_juveniles jsonb DEFAULT '[]'::jsonb,
    ph_juveniles jsonb DEFAULT '[]'::jsonb,
    es_juveniles jsonb DEFAULT '[]'::jsonb,
    th__juveniles jsonb DEFAULT '[]'::jsonb,
    so_juveniles jsonb DEFAULT '[]'::jsonb,
    sh_juveniles jsonb DEFAULT '[]'::jsonb,
    literally_homeless_unaccompanied_minors jsonb DEFAULT '[]'::jsonb,
    system_unaccompanied_minors jsonb DEFAULT '[]'::jsonb,
    homeless_unaccompanied_minors jsonb DEFAULT '[]'::jsonb,
    ph_unaccompanied_minors jsonb DEFAULT '[]'::jsonb,
    es_unaccompanied_minors jsonb DEFAULT '[]'::jsonb,
    th_unaccompanied_minors jsonb DEFAULT '[]'::jsonb,
    so_unaccompanied_minors jsonb DEFAULT '[]'::jsonb,
    sh_unaccompanied_minors jsonb DEFAULT '[]'::jsonb,
    literally_homeless_youth_families jsonb DEFAULT '[]'::jsonb,
    system_youth_families jsonb DEFAULT '[]'::jsonb,
    homeless_youth_families jsonb DEFAULT '[]'::jsonb,
    ph_youth_families jsonb DEFAULT '[]'::jsonb,
    es_youth_families jsonb DEFAULT '[]'::jsonb,
    th_youth_families jsonb DEFAULT '[]'::jsonb,
    so_youth_families jsonb DEFAULT '[]'::jsonb,
    sh_youth_families jsonb DEFAULT '[]'::jsonb,
    literally_homeless_family_parents jsonb DEFAULT '[]'::jsonb,
    system_family_parents jsonb DEFAULT '[]'::jsonb,
    homeless_family_parents jsonb DEFAULT '[]'::jsonb,
    ph_family_parents jsonb DEFAULT '[]'::jsonb,
    es_family_parents jsonb DEFAULT '[]'::jsonb,
    th_family_parents jsonb DEFAULT '[]'::jsonb,
    so_family_parents jsonb DEFAULT '[]'::jsonb,
    sh_family_parents jsonb DEFAULT '[]'::jsonb
);


--
-- Name: nightly_census_by_project_type_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nightly_census_by_project_type_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nightly_census_by_project_type_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nightly_census_by_project_type_clients_id_seq OWNED BY public.nightly_census_by_project_type_clients.id;


--
-- Name: nightly_census_by_project_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nightly_census_by_project_types (
    id integer NOT NULL,
    date date NOT NULL,
    literally_homeless_veterans integer DEFAULT 0,
    literally_homeless_non_veterans integer DEFAULT 0,
    literally_homeless_children integer DEFAULT 0,
    literally_homeless_adults integer DEFAULT 0,
    literally_homeless_youth integer DEFAULT 0,
    literally_homeless_families integer DEFAULT 0,
    literally_homeless_individuals integer DEFAULT 0,
    literally_homeless_parenting_youth integer DEFAULT 0,
    literally_homeless_parenting_juveniles integer DEFAULT 0,
    literally_homeless_all_clients integer DEFAULT 0,
    system_veterans integer DEFAULT 0,
    system_non_veterans integer DEFAULT 0,
    system_children integer DEFAULT 0,
    system_adults integer DEFAULT 0,
    system_youth integer DEFAULT 0,
    system_families integer DEFAULT 0,
    system_individuals integer DEFAULT 0,
    system_parenting_youth integer DEFAULT 0,
    system_parenting_juveniles integer DEFAULT 0,
    system_all_clients integer DEFAULT 0,
    homeless_veterans integer DEFAULT 0,
    homeless_non_veterans integer DEFAULT 0,
    homeless_children integer DEFAULT 0,
    homeless_adults integer DEFAULT 0,
    homeless_youth integer DEFAULT 0,
    homeless_families integer DEFAULT 0,
    homeless_individuals integer DEFAULT 0,
    homeless_parenting_youth integer DEFAULT 0,
    homeless_parenting_juveniles integer DEFAULT 0,
    homeless_all_clients integer DEFAULT 0,
    ph_veterans integer DEFAULT 0,
    ph_non_veterans integer DEFAULT 0,
    ph_children integer DEFAULT 0,
    ph_adults integer DEFAULT 0,
    ph_youth integer DEFAULT 0,
    ph_families integer DEFAULT 0,
    ph_individuals integer DEFAULT 0,
    ph_parenting_youth integer DEFAULT 0,
    ph_parenting_juveniles integer DEFAULT 0,
    ph_all_clients integer DEFAULT 0,
    es_veterans integer DEFAULT 0,
    es_non_veterans integer DEFAULT 0,
    es_children integer DEFAULT 0,
    es_adults integer DEFAULT 0,
    es_youth integer DEFAULT 0,
    es_families integer DEFAULT 0,
    es_individuals integer DEFAULT 0,
    es_parenting_youth integer DEFAULT 0,
    es_parenting_juveniles integer DEFAULT 0,
    es_all_clients integer DEFAULT 0,
    th_veterans integer DEFAULT 0,
    th_non_veterans integer DEFAULT 0,
    th_children integer DEFAULT 0,
    th_adults integer DEFAULT 0,
    th_youth integer DEFAULT 0,
    th_families integer DEFAULT 0,
    th_individuals integer DEFAULT 0,
    th_parenting_youth integer DEFAULT 0,
    th_parenting_juveniles integer DEFAULT 0,
    th_all_clients integer DEFAULT 0,
    so_veterans integer DEFAULT 0,
    so_non_veterans integer DEFAULT 0,
    so_children integer DEFAULT 0,
    so_adults integer DEFAULT 0,
    so_youth integer DEFAULT 0,
    so_families integer DEFAULT 0,
    so_individuals integer DEFAULT 0,
    so_parenting_youth integer DEFAULT 0,
    so_parenting_juveniles integer DEFAULT 0,
    so_all_clients integer DEFAULT 0,
    sh_veterans integer DEFAULT 0,
    sh_non_veterans integer DEFAULT 0,
    sh_children integer DEFAULT 0,
    sh_adults integer DEFAULT 0,
    sh_youth integer DEFAULT 0,
    sh_families integer DEFAULT 0,
    sh_individuals integer DEFAULT 0,
    sh_parenting_youth integer DEFAULT 0,
    sh_parenting_juveniles integer DEFAULT 0,
    sh_all_clients integer DEFAULT 0,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    ph_beds integer DEFAULT 0,
    es_beds integer DEFAULT 0,
    th_beds integer DEFAULT 0,
    so_beds integer DEFAULT 0,
    sh_beds integer DEFAULT 0,
    literally_homeless_juveniles integer DEFAULT 0,
    system_juveniles integer DEFAULT 0,
    homeless_juveniles integer DEFAULT 0,
    ph_juveniles integer DEFAULT 0,
    es_juveniles integer DEFAULT 0,
    th_juveniles integer DEFAULT 0,
    so_juveniles integer DEFAULT 0,
    sh_juveniles integer DEFAULT 0,
    literally_homeless_unaccompanied_minors integer DEFAULT 0,
    system_unaccompanied_minors integer DEFAULT 0,
    homeless_unaccompanied_minors integer DEFAULT 0,
    ph_unaccompanied_minors integer DEFAULT 0,
    es_unaccompanied_minors integer DEFAULT 0,
    th_unaccompanied_minors integer DEFAULT 0,
    so_unaccompanied_minors integer DEFAULT 0,
    sh_unaccompanied_minors integer DEFAULT 0,
    literally_homeless_youth_families integer DEFAULT 0,
    system_youth_families integer DEFAULT 0,
    homeless_youth_families integer DEFAULT 0,
    ph_youth_families integer DEFAULT 0,
    es_youth_families integer DEFAULT 0,
    th_youth_families integer DEFAULT 0,
    so_youth_families integer DEFAULT 0,
    sh_youth_families integer DEFAULT 0,
    literally_homeless_family_parents integer DEFAULT 0,
    system_family_parents integer DEFAULT 0,
    homeless_family_parents integer DEFAULT 0,
    ph_family_parents integer DEFAULT 0,
    es_family_parents integer DEFAULT 0,
    th_family_parents integer DEFAULT 0,
    so_family_parents integer DEFAULT 0,
    sh_family_parents integer DEFAULT 0
);


--
-- Name: nightly_census_by_project_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nightly_census_by_project_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nightly_census_by_project_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nightly_census_by_project_types_id_seq OWNED BY public.nightly_census_by_project_types.id;


--
-- Name: nightly_census_by_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nightly_census_by_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nightly_census_by_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nightly_census_by_projects_id_seq OWNED BY public.nightly_census_by_projects.id;


--
-- Name: non_hmis_uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.non_hmis_uploads (
    id integer NOT NULL,
    data_source_id integer,
    user_id integer,
    delayed_job_id integer,
    file character varying NOT NULL,
    percent_complete double precision,
    import_errors json,
    content_type character varying,
    content bytea,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    deleted_at timestamp without time zone
);


--
-- Name: non_hmis_uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.non_hmis_uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: non_hmis_uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.non_hmis_uploads_id_seq OWNED BY public.non_hmis_uploads.id;


--
-- Name: performance_metrics_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.performance_metrics_clients (
    id bigint NOT NULL,
    client_id bigint,
    report_id bigint,
    include_in_current_period boolean,
    current_period_age integer,
    current_period_earned_income_at_start integer,
    current_period_earned_income_at_exit integer,
    current_period_other_income_at_start integer,
    current_period_other_income_at_exit integer,
    current_caper_leaver boolean,
    current_period_days_in_es integer,
    current_period_days_in_rrh integer,
    current_period_days_in_psh integer,
    current_period_days_to_return integer,
    current_period_spm_leaver boolean,
    current_period_first_time boolean,
    current_period_reentering boolean,
    current_period_in_outflow boolean,
    current_period_entering_housing boolean,
    current_period_inactive boolean,
    current_period_caper_id bigint,
    current_period_spm_id bigint,
    include_in_prior_period boolean,
    prior_period_age integer,
    prior_period_earned_income_at_start integer,
    prior_period_earned_income_at_exit integer,
    prior_period_other_income_at_start integer,
    prior_period_other_income_at_exit integer,
    prior_caper_leaver boolean,
    prior_period_days_in_es integer,
    prior_period_days_in_rrh integer,
    prior_period_days_in_psh integer,
    prior_period_days_to_return integer,
    prior_period_spm_leaver boolean,
    prior_period_first_time boolean,
    prior_period_reentering boolean,
    prior_period_in_outflow boolean,
    prior_period_entering_housing boolean,
    prior_period_inactive boolean,
    prior_period_caper_id bigint,
    prior_period_spm_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    first_name character varying,
    last_name character varying
);


--
-- Name: performance_metrics_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.performance_metrics_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: performance_metrics_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.performance_metrics_clients_id_seq OWNED BY public.performance_metrics_clients.id;


--
-- Name: project_data_quality; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_data_quality (
    id integer NOT NULL,
    project_id integer,
    type character varying,
    start date,
    "end" date,
    report json,
    sent_at timestamp without time zone,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    processing_errors text,
    project_group_id integer,
    support json,
    requestor_id integer
);


--
-- Name: project_data_quality_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_data_quality_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_data_quality_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_data_quality_id_seq OWNED BY public.project_data_quality.id;


--
-- Name: project_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_groups (
    id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


--
-- Name: project_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_groups_id_seq OWNED BY public.project_groups.id;


--
-- Name: project_pass_fails; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_pass_fails (
    id bigint NOT NULL,
    user_id bigint,
    options jsonb DEFAULT '{}'::jsonb,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    failed_at timestamp without time zone,
    processing_errors text,
    utilization_rate double precision,
    projects_failing_universal_data_elements integer,
    average_days_to_enter_entry_date double precision,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    thresholds jsonb DEFAULT '{}'::jsonb
);


--
-- Name: project_pass_fails_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_pass_fails_clients (
    id bigint NOT NULL,
    project_pass_fail_id bigint,
    project_id bigint,
    client_id bigint,
    first_name character varying,
    last_name character varying,
    first_date_in_program date,
    last_date_in_program date,
    disabling_condition integer,
    dob_quality integer,
    dob date,
    ethnicity integer,
    gender integer,
    name_quality integer,
    race integer,
    ssn_quality integer,
    ssn character varying,
    veteran_status integer,
    relationship_to_hoh integer,
    enrollment_created date,
    enrollment_coc character varying,
    days_to_enter_entry_date integer,
    days_served integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    income_at_entry integer
);


--
-- Name: project_pass_fails_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_pass_fails_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_pass_fails_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_pass_fails_clients_id_seq OWNED BY public.project_pass_fails_clients.id;


--
-- Name: project_pass_fails_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_pass_fails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_pass_fails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_pass_fails_id_seq OWNED BY public.project_pass_fails.id;


--
-- Name: project_pass_fails_projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_pass_fails_projects (
    id bigint NOT NULL,
    project_pass_fail_id bigint,
    project_id bigint,
    apr_id bigint,
    available_beds double precision,
    utilization_rate double precision,
    name_error_rate double precision,
    ssn_error_rate double precision,
    race_error_rate double precision,
    ethnicity_error_rate double precision,
    gender_error_rate double precision,
    dob_error_rate double precision,
    veteran_status_error_rate double precision,
    start_date_error_rate double precision,
    relationship_to_hoh_error_rate double precision,
    location_error_rate double precision,
    disabling_condition_error_rate double precision,
    utilization_count double precision,
    name_error_count double precision,
    ssn_error_count double precision,
    race_error_count double precision,
    ethnicity_error_count double precision,
    gender_error_count double precision,
    dob_error_count double precision,
    veteran_status_error_count double precision,
    start_date_error_count double precision,
    relationship_to_hoh_error_count double precision,
    location_error_count double precision,
    disabling_condition_error_count double precision,
    average_days_to_enter_entry_date double precision,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    income_at_entry_error_rate double precision,
    income_at_entry_error_count integer
);


--
-- Name: project_pass_fails_projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_pass_fails_projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_pass_fails_projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_pass_fails_projects_id_seq OWNED BY public.project_pass_fails_projects.id;


--
-- Name: project_project_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_project_groups (
    id integer NOT NULL,
    project_group_id integer,
    project_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


--
-- Name: project_project_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_project_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_project_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_project_groups_id_seq OWNED BY public.project_project_groups.id;


--
-- Name: project_scorecard_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_scorecard_reports (
    id bigint NOT NULL,
    project_id bigint,
    project_group_id bigint,
    status character varying DEFAULT 'pending'::character varying,
    user_id bigint,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    sent_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    recipient character varying,
    subrecipient character varying,
    start_date date,
    end_date date,
    funding_year character varying,
    grant_term character varying,
    utilization_jan integer,
    utilization_apr integer,
    utilization_jul integer,
    utilization_oct integer,
    utilization_proposed integer,
    chronic_households_served integer,
    total_households_served integer,
    total_persons_served integer,
    total_persons_with_positive_exit integer,
    total_persons_exited integer,
    excluded_exits integer,
    average_los_leavers integer,
    percent_increased_employment_income_at_exit integer,
    percent_increased_other_cash_income_at_exit integer,
    percent_returns_to_homelessness integer,
    percent_pii_errors integer,
    percent_ude_errors integer,
    percent_income_and_housing_errors integer,
    days_to_lease_up integer,
    number_referrals integer,
    accepted_referrals integer,
    funds_expended integer,
    amount_awarded integer,
    months_since_start integer,
    pit_participation boolean,
    coc_meetings integer,
    coc_meetings_attended integer,
    improvement_plan character varying,
    financial_plan character varying,
    site_monitoring character varying,
    total_ces_referrals integer,
    accepted_ces_referrals integer,
    clients_with_vispdats integer,
    average_vispdat_score integer,
    budget_plus_match integer,
    prior_amount_awarded integer,
    prior_funds_expended integer,
    archive character varying,
    expansion_year boolean,
    special_population_only character varying,
    project_less_than_two boolean,
    geographic_location character varying,
    apr_id bigint
);


--
-- Name: project_scorecard_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_scorecard_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_scorecard_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_scorecard_reports_id_seq OWNED BY public.project_scorecard_reports.id;


--
-- Name: psc_feedback_surveys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.psc_feedback_surveys (
    id bigint NOT NULL,
    client_id bigint,
    user_id bigint,
    conversation_on date,
    location character varying,
    listened_to_me character varying,
    cared_about_me character varying,
    knowledgeable character varying,
    i_was_included character varying,
    i_decided character varying,
    supporting_my_needs character varying,
    sensitive_to_culture character varying,
    would_return character varying,
    more_calm_and_control character varying,
    satisfied character varying,
    comments character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: psc_feedback_surveys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.psc_feedback_surveys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: psc_feedback_surveys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.psc_feedback_surveys_id_seq OWNED BY public.psc_feedback_surveys.id;


--
-- Name: public_report_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.public_report_reports (
    id bigint NOT NULL,
    user_id bigint,
    type character varying,
    start_date date,
    end_date date,
    filter jsonb,
    state character varying,
    html text,
    published_url character varying,
    embed_code character varying,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    precalculated_data text,
    version_slug character varying
);


--
-- Name: public_report_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.public_report_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: public_report_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.public_report_reports_id_seq OWNED BY public.public_report_reports.id;


--
-- Name: public_report_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.public_report_settings (
    id bigint NOT NULL,
    s3_region character varying,
    s3_bucket character varying,
    s3_prefix character varying,
    encrypted_s3_access_key_id character varying,
    encrypted_s3_access_key_id_iv character varying,
    encrypted_s3_secret character varying,
    encrypted_s3_secret_iv character varying,
    color_0 character varying,
    color_1 character varying,
    color_2 character varying,
    color_3 character varying,
    color_4 character varying,
    color_5 character varying,
    color_6 character varying,
    color_7 character varying,
    color_8 character varying,
    color_9 character varying,
    color_10 character varying,
    color_11 character varying,
    color_12 character varying,
    color_13 character varying,
    color_14 character varying,
    color_15 character varying,
    color_16 character varying,
    font_url character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    font_family_0 character varying,
    font_family_1 character varying,
    font_family_2 character varying,
    font_family_3 character varying,
    font_size_0 character varying,
    font_size_1 character varying,
    font_size_2 character varying,
    font_size_3 character varying,
    font_weight_0 character varying,
    font_weight_1 character varying,
    font_weight_2 character varying,
    font_weight_3 character varying,
    gender_color_0 character varying,
    gender_color_1 character varying,
    gender_color_2 character varying,
    gender_color_3 character varying,
    gender_color_4 character varying,
    gender_color_5 character varying,
    gender_color_6 character varying,
    gender_color_7 character varying,
    gender_color_8 character varying,
    age_color_0 character varying,
    age_color_1 character varying,
    age_color_2 character varying,
    age_color_3 character varying,
    age_color_4 character varying,
    age_color_5 character varying,
    age_color_6 character varying,
    age_color_7 character varying,
    age_color_8 character varying,
    household_composition_color_0 character varying,
    household_composition_color_1 character varying,
    household_composition_color_2 character varying,
    household_composition_color_3 character varying,
    household_composition_color_4 character varying,
    household_composition_color_5 character varying,
    household_composition_color_6 character varying,
    household_composition_color_7 character varying,
    household_composition_color_8 character varying,
    race_color_0 character varying,
    race_color_1 character varying,
    race_color_2 character varying,
    race_color_3 character varying,
    race_color_4 character varying,
    race_color_5 character varying,
    race_color_6 character varying,
    race_color_7 character varying,
    race_color_8 character varying,
    time_color_0 character varying,
    time_color_1 character varying,
    time_color_2 character varying,
    time_color_3 character varying,
    time_color_4 character varying,
    time_color_5 character varying,
    time_color_6 character varying,
    time_color_7 character varying,
    time_color_8 character varying,
    housing_type_color_0 character varying,
    housing_type_color_1 character varying,
    housing_type_color_2 character varying,
    housing_type_color_3 character varying,
    housing_type_color_4 character varying,
    housing_type_color_5 character varying,
    housing_type_color_6 character varying,
    housing_type_color_7 character varying,
    housing_type_color_8 character varying,
    population_color_0 character varying,
    population_color_1 character varying,
    population_color_2 character varying,
    population_color_3 character varying,
    population_color_4 character varying,
    population_color_5 character varying,
    population_color_6 character varying,
    population_color_7 character varying,
    population_color_8 character varying,
    location_type_color_0 character varying,
    location_type_color_1 character varying,
    location_type_color_2 character varying,
    location_type_color_3 character varying,
    location_type_color_4 character varying,
    location_type_color_5 character varying,
    location_type_color_6 character varying,
    location_type_color_7 character varying,
    location_type_color_8 character varying,
    summary_color character varying,
    homeless_primary_color character varying,
    youth_primary_color character varying,
    adults_only_primary_color character varying,
    adults_with_children_primary_color character varying,
    children_only_primary_color character varying,
    veterans_primary_color character varying
);


--
-- Name: public_report_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.public_report_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: public_report_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.public_report_settings_id_seq OWNED BY public.public_report_settings.id;


--
-- Name: recent_report_enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recent_report_enrollments (
    "EnrollmentID" character varying(50),
    "PersonalID" character varying,
    "ProjectID" character varying(50),
    "EntryDate" date,
    "HouseholdID" character varying,
    "RelationshipToHoH" integer,
    "LivingSituation" integer,
    "OtherResidencePrior" character varying,
    "LengthOfStay" integer,
    "DisablingCondition" integer,
    "EntryFromStreetESSH" integer,
    "DateToStreetESSH" date,
    "ContinuouslyHomelessOneYear" integer,
    "TimesHomelessPastThreeYears" integer,
    "MonthsHomelessPastThreeYears" integer,
    "MonthsHomelessThisTime" integer,
    "StatusDocumented" integer,
    "HousingStatus" integer,
    "DateOfEngagement" date,
    "InPermanentHousing" integer,
    "MoveInDate" date,
    "DateOfPATHStatus" date,
    "ClientEnrolledInPATH" integer,
    "ReasonNotEnrolled" integer,
    "WorstHousingSituation" integer,
    "PercentAMI" integer,
    "LastPermanentStreet" character varying,
    "LastPermanentCity" character varying(50),
    "LastPermanentState" character varying(2),
    "LastPermanentZIP" character varying(10),
    "AddressDataQuality" integer,
    "DateOfBCPStatus" date,
    "EligibleForRHY" integer,
    "ReasonNoServices" integer,
    "SexualOrientation" integer,
    "FormerWardChildWelfare" integer,
    "ChildWelfareYears" integer,
    "ChildWelfareMonths" integer,
    "FormerWardJuvenileJustice" integer,
    "JuvenileJusticeYears" integer,
    "JuvenileJusticeMonths" integer,
    "HouseholdDynamics" integer,
    "SexualOrientationGenderIDYouth" integer,
    "SexualOrientationGenderIDFam" integer,
    "HousingIssuesYouth" integer,
    "HousingIssuesFam" integer,
    "SchoolEducationalIssuesYouth" integer,
    "SchoolEducationalIssuesFam" integer,
    "UnemploymentYouth" integer,
    "UnemploymentFam" integer,
    "MentalHealthIssuesYouth" integer,
    "MentalHealthIssuesFam" integer,
    "HealthIssuesYouth" integer,
    "HealthIssuesFam" integer,
    "PhysicalDisabilityYouth" integer,
    "PhysicalDisabilityFam" integer,
    "MentalDisabilityYouth" integer,
    "MentalDisabilityFam" integer,
    "AbuseAndNeglectYouth" integer,
    "AbuseAndNeglectFam" integer,
    "AlcoholDrugAbuseYouth" integer,
    "AlcoholDrugAbuseFam" integer,
    "InsufficientIncome" integer,
    "ActiveMilitaryParent" integer,
    "IncarceratedParent" integer,
    "IncarceratedParentStatus" integer,
    "ReferralSource" integer,
    "CountOutreachReferralApproaches" integer,
    "ExchangeForSex" integer,
    "ExchangeForSexPastThreeMonths" integer,
    "CountOfExchangeForSex" integer,
    "AskedOrForcedToExchangeForSex" integer,
    "AskedOrForcedToExchangeForSexPastThreeMonths" integer,
    "WorkPlaceViolenceThreats" integer,
    "WorkplacePromiseDifference" integer,
    "CoercedToContinueWork" integer,
    "LaborExploitPastThreeMonths" integer,
    "HPScreeningScore" integer,
    "VAMCStation" integer,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer,
    "LOSUnderThreshold" integer,
    "PreviousStreetESSH" integer,
    "UrgentReferral" integer,
    "TimeToHousingLoss" integer,
    "ZeroIncome" integer,
    "AnnualPercentAMI" integer,
    "FinancialChange" integer,
    "HouseholdChange" integer,
    "EvictionHistory" integer,
    "SubsidyAtRisk" integer,
    "LiteralHomelessHistory" integer,
    "DisabledHoH" integer,
    "CriminalRecord" integer,
    "SexOffender" integer,
    "DependentUnder6" integer,
    "SingleParent" integer,
    "HH5Plus" integer,
    "IraqAfghanistan" integer,
    "FemVet" integer,
    "ThresholdScore" integer,
    "ERVisits" integer,
    "JailNights" integer,
    "HospitalNights" integer,
    "RunawayYouth" integer,
    processed_hash character varying,
    processed_as character varying,
    roi_permission boolean,
    last_locality character varying,
    last_zipcode character varying,
    source_hash character varying,
    pending_date_deleted timestamp without time zone,
    "SexualOrientationOther" character varying(100),
    history_generated_on date,
    original_household_id character varying,
    service_history_processing_job_id bigint,
    demographic_id integer,
    client_id integer
);


--
-- Name: recent_service_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recent_service_history (
    id bigint,
    client_id integer,
    data_source_id integer,
    date date,
    first_date_in_program date,
    last_date_in_program date,
    enrollment_group_id character varying(50),
    age smallint,
    destination integer,
    head_of_household_id character varying(50),
    household_id character varying(50),
    project_id integer,
    project_type smallint,
    project_tracking_method integer,
    organization_id integer,
    housing_status_at_entry integer,
    housing_status_at_exit integer,
    service_type smallint,
    computed_project_type smallint,
    presented_as_individual boolean
);


--
-- Name: recurring_hmis_export_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recurring_hmis_export_links (
    id integer NOT NULL,
    hmis_export_id integer,
    recurring_hmis_export_id integer,
    exported_at date
);


--
-- Name: recurring_hmis_export_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recurring_hmis_export_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recurring_hmis_export_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recurring_hmis_export_links_id_seq OWNED BY public.recurring_hmis_export_links.id;


--
-- Name: recurring_hmis_exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recurring_hmis_exports (
    id integer NOT NULL,
    every_n_days integer,
    reporting_range character varying,
    reporting_range_days integer,
    start_date date,
    end_date date,
    hash_status integer,
    period_type integer,
    directive integer,
    include_deleted boolean,
    user_id integer,
    faked_pii boolean,
    project_ids character varying,
    project_group_ids character varying,
    organization_ids character varying,
    data_source_ids character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    s3_region character varying,
    s3_bucket character varying,
    s3_prefix character varying,
    encrypted_s3_access_key_id character varying,
    encrypted_s3_access_key_id_iv character varying,
    encrypted_s3_secret character varying,
    encrypted_s3_secret_iv character varying,
    deleted_at timestamp without time zone,
    version character varying
);


--
-- Name: recurring_hmis_exports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recurring_hmis_exports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recurring_hmis_exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recurring_hmis_exports_id_seq OWNED BY public.recurring_hmis_exports.id;


--
-- Name: report_definitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_definitions (
    id integer NOT NULL,
    report_group character varying,
    url text,
    name text,
    description text,
    weight integer DEFAULT 0 NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    limitable boolean DEFAULT true NOT NULL,
    health boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: report_definitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.report_definitions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_definitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.report_definitions_id_seq OWNED BY public.report_definitions.id;


--
-- Name: report_disabilities; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.report_disabilities AS
 SELECT "Disabilities"."DisabilitiesID",
    "Disabilities"."EnrollmentID" AS "ProjectEntryID",
    "Disabilities"."PersonalID",
    "Disabilities"."InformationDate",
    "Disabilities"."DisabilityType",
    "Disabilities"."DisabilityResponse",
    "Disabilities"."IndefiniteAndImpairs",
    "Disabilities"."DocumentationOnFile",
    "Disabilities"."ReceivingServices",
    "Disabilities"."PATHHowConfirmed",
    "Disabilities"."PATHSMIInformation",
    "Disabilities"."TCellCountAvailable",
    "Disabilities"."TCellCount",
    "Disabilities"."TCellSource",
    "Disabilities"."ViralLoadAvailable",
    "Disabilities"."ViralLoad",
    "Disabilities"."ViralLoadSource",
    "Disabilities"."DataCollectionStage",
    "Disabilities"."DateCreated",
    "Disabilities"."DateUpdated",
    "Disabilities"."UserID",
    "Disabilities"."DateDeleted",
    "Disabilities"."ExportID",
    "Disabilities".data_source_id,
    "Disabilities".id,
    "Enrollment".id AS enrollment_id,
    source_clients.id AS demographic_id,
    destination_clients.id AS client_id
   FROM ((((public."Disabilities"
     JOIN public."Client" source_clients ON ((("Disabilities".data_source_id = source_clients.data_source_id) AND (("Disabilities"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
     JOIN public."Enrollment" ON ((("Disabilities".data_source_id = "Enrollment".data_source_id) AND (("Disabilities"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("Disabilities"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
  WHERE ("Disabilities"."DateDeleted" IS NULL);


--
-- Name: report_employment_educations; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.report_employment_educations AS
 SELECT "EmploymentEducation"."EmploymentEducationID",
    "EmploymentEducation"."EnrollmentID" AS "ProjectEntryID",
    "EmploymentEducation"."PersonalID",
    "EmploymentEducation"."InformationDate",
    "EmploymentEducation"."LastGradeCompleted",
    "EmploymentEducation"."SchoolStatus",
    "EmploymentEducation"."Employed",
    "EmploymentEducation"."EmploymentType",
    "EmploymentEducation"."NotEmployedReason",
    "EmploymentEducation"."DataCollectionStage",
    "EmploymentEducation"."DateCreated",
    "EmploymentEducation"."DateUpdated",
    "EmploymentEducation"."UserID",
    "EmploymentEducation"."DateDeleted",
    "EmploymentEducation"."ExportID",
    "EmploymentEducation".data_source_id,
    "EmploymentEducation".id,
    "Enrollment".id AS enrollment_id,
    source_clients.id AS demographic_id,
    destination_clients.id AS client_id
   FROM ((((public."EmploymentEducation"
     JOIN public."Client" source_clients ON ((("EmploymentEducation".data_source_id = source_clients.data_source_id) AND (("EmploymentEducation"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
     JOIN public."Enrollment" ON ((("EmploymentEducation".data_source_id = "Enrollment".data_source_id) AND (("EmploymentEducation"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("EmploymentEducation"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
  WHERE ("EmploymentEducation"."DateDeleted" IS NULL);


--
-- Name: report_enrollments; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.report_enrollments AS
 SELECT "Enrollment"."EnrollmentID" AS "ProjectEntryID",
    "Enrollment"."PersonalID",
    "Enrollment"."ProjectID",
    "Enrollment"."EntryDate",
    "Enrollment"."HouseholdID",
    "Enrollment"."RelationshipToHoH",
    "Enrollment"."LivingSituation" AS "ResidencePrior",
    "Enrollment"."OtherResidencePrior",
    "Enrollment"."LengthOfStay" AS "ResidencePriorLengthOfStay",
    "Enrollment"."DisablingCondition",
    "Enrollment"."EntryFromStreetESSH",
    "Enrollment"."DateToStreetESSH",
    "Enrollment"."ContinuouslyHomelessOneYear",
    "Enrollment"."TimesHomelessPastThreeYears",
    "Enrollment"."MonthsHomelessPastThreeYears",
    "Enrollment"."MonthsHomelessThisTime",
    "Enrollment"."StatusDocumented",
    "Enrollment"."HousingStatus",
    "Enrollment"."DateOfEngagement",
    "Enrollment"."InPermanentHousing",
    "Enrollment"."MoveInDate" AS "ResidentialMoveInDate",
    "Enrollment"."DateOfPATHStatus",
    "Enrollment"."ClientEnrolledInPATH",
    "Enrollment"."ReasonNotEnrolled",
    "Enrollment"."WorstHousingSituation",
    "Enrollment"."PercentAMI",
    "Enrollment"."LastPermanentStreet",
    "Enrollment"."LastPermanentCity",
    "Enrollment"."LastPermanentState",
    "Enrollment"."LastPermanentZIP",
    "Enrollment"."AddressDataQuality",
    "Enrollment"."DateOfBCPStatus",
    "Enrollment"."EligibleForRHY" AS "FYSBYouth",
    "Enrollment"."ReasonNoServices",
    "Enrollment"."SexualOrientation",
    "Enrollment"."FormerWardChildWelfare",
    "Enrollment"."ChildWelfareYears",
    "Enrollment"."ChildWelfareMonths",
    "Enrollment"."FormerWardJuvenileJustice",
    "Enrollment"."JuvenileJusticeYears",
    "Enrollment"."JuvenileJusticeMonths",
    "Enrollment"."HouseholdDynamics",
    "Enrollment"."SexualOrientationGenderIDYouth",
    "Enrollment"."SexualOrientationGenderIDFam",
    "Enrollment"."HousingIssuesYouth",
    "Enrollment"."HousingIssuesFam",
    "Enrollment"."SchoolEducationalIssuesYouth",
    "Enrollment"."SchoolEducationalIssuesFam",
    "Enrollment"."UnemploymentYouth",
    "Enrollment"."UnemploymentFam",
    "Enrollment"."MentalHealthIssuesYouth",
    "Enrollment"."MentalHealthIssuesFam",
    "Enrollment"."HealthIssuesYouth",
    "Enrollment"."HealthIssuesFam",
    "Enrollment"."PhysicalDisabilityYouth",
    "Enrollment"."PhysicalDisabilityFam",
    "Enrollment"."MentalDisabilityYouth",
    "Enrollment"."MentalDisabilityFam",
    "Enrollment"."AbuseAndNeglectYouth",
    "Enrollment"."AbuseAndNeglectFam",
    "Enrollment"."AlcoholDrugAbuseYouth",
    "Enrollment"."AlcoholDrugAbuseFam",
    "Enrollment"."InsufficientIncome",
    "Enrollment"."ActiveMilitaryParent",
    "Enrollment"."IncarceratedParent",
    "Enrollment"."IncarceratedParentStatus",
    "Enrollment"."ReferralSource",
    "Enrollment"."CountOutreachReferralApproaches",
    "Enrollment"."ExchangeForSex",
    "Enrollment"."ExchangeForSexPastThreeMonths",
    "Enrollment"."CountOfExchangeForSex",
    "Enrollment"."AskedOrForcedToExchangeForSex",
    "Enrollment"."AskedOrForcedToExchangeForSexPastThreeMonths",
    "Enrollment"."WorkPlaceViolenceThreats",
    "Enrollment"."WorkplacePromiseDifference",
    "Enrollment"."CoercedToContinueWork",
    "Enrollment"."LaborExploitPastThreeMonths",
    "Enrollment"."HPScreeningScore",
    "Enrollment"."VAMCStation",
    "Enrollment"."DateCreated",
    "Enrollment"."DateUpdated",
    "Enrollment"."UserID",
    "Enrollment"."DateDeleted",
    "Enrollment"."ExportID",
    "Enrollment".data_source_id,
    "Enrollment".id,
    "Enrollment"."LOSUnderThreshold",
    "Enrollment"."PreviousStreetESSH",
    "Enrollment"."UrgentReferral",
    "Enrollment"."TimeToHousingLoss",
    "Enrollment"."ZeroIncome",
    "Enrollment"."AnnualPercentAMI",
    "Enrollment"."FinancialChange",
    "Enrollment"."HouseholdChange",
    "Enrollment"."EvictionHistory",
    "Enrollment"."SubsidyAtRisk",
    "Enrollment"."LiteralHomelessHistory",
    "Enrollment"."DisabledHoH",
    "Enrollment"."CriminalRecord",
    "Enrollment"."SexOffender",
    "Enrollment"."DependentUnder6",
    "Enrollment"."SingleParent",
    "Enrollment"."HH5Plus",
    "Enrollment"."IraqAfghanistan",
    "Enrollment"."FemVet",
    "Enrollment"."ThresholdScore",
    "Enrollment"."ERVisits",
    "Enrollment"."JailNights",
    "Enrollment"."HospitalNights",
    "Enrollment"."RunawayYouth",
    "Enrollment".processed_hash,
    source_clients.id AS demographic_id,
    destination_clients.id AS client_id
   FROM (((public."Enrollment"
     JOIN public."Client" source_clients ON ((("Enrollment".data_source_id = source_clients.data_source_id) AND (("Enrollment"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
  WHERE ("Enrollment"."DateDeleted" IS NULL);


--
-- Name: report_exits; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.report_exits AS
 SELECT "Exit"."ExitID",
    "Exit"."EnrollmentID" AS "ProjectEntryID",
    "Exit"."PersonalID",
    "Exit"."ExitDate",
    "Exit"."Destination",
    "Exit"."OtherDestination",
    "Exit"."AssessmentDisposition",
    "Exit"."OtherDisposition",
    "Exit"."HousingAssessment",
    "Exit"."SubsidyInformation",
    "Exit"."ConnectionWithSOAR",
    "Exit"."WrittenAftercarePlan",
    "Exit"."AssistanceMainstreamBenefits",
    "Exit"."PermanentHousingPlacement",
    "Exit"."TemporaryShelterPlacement",
    "Exit"."ExitCounseling",
    "Exit"."FurtherFollowUpServices",
    "Exit"."ScheduledFollowUpContacts",
    "Exit"."ResourcePackage",
    "Exit"."OtherAftercarePlanOrAction",
    "Exit"."ProjectCompletionStatus",
    "Exit"."EarlyExitReason",
    "Exit"."FamilyReunificationAchieved",
    "Exit"."DateCreated",
    "Exit"."DateUpdated",
    "Exit"."UserID",
    "Exit"."DateDeleted",
    "Exit"."ExportID",
    "Exit".data_source_id,
    "Exit".id,
    "Exit"."ExchangeForSex",
    "Exit"."ExchangeForSexPastThreeMonths",
    "Exit"."CountOfExchangeForSex",
    "Exit"."AskedOrForcedToExchangeForSex",
    "Exit"."AskedOrForcedToExchangeForSexPastThreeMonths",
    "Exit"."WorkPlaceViolenceThreats",
    "Exit"."WorkplacePromiseDifference",
    "Exit"."CoercedToContinueWork",
    "Exit"."LaborExploitPastThreeMonths",
    "Exit"."CounselingReceived",
    "Exit"."IndividualCounseling",
    "Exit"."FamilyCounseling",
    "Exit"."GroupCounseling",
    "Exit"."SessionCountAtExit",
    "Exit"."PostExitCounselingPlan",
    "Exit"."SessionsInPlan",
    "Exit"."DestinationSafeClient",
    "Exit"."DestinationSafeWorker",
    "Exit"."PosAdultConnections",
    "Exit"."PosPeerConnections",
    "Exit"."PosCommunityConnections",
    "Exit"."AftercareDate",
    "Exit"."AftercareProvided",
    "Exit"."EmailSocialMedia",
    "Exit"."Telephone",
    "Exit"."InPersonIndividual",
    "Exit"."InPersonGroup",
    "Exit"."CMExitReason",
    "Enrollment".id AS enrollment_id,
    source_clients.id AS demographic_id,
    destination_clients.id AS client_id
   FROM ((((public."Exit"
     JOIN public."Client" source_clients ON ((("Exit".data_source_id = source_clients.data_source_id) AND (("Exit"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
     JOIN public."Enrollment" ON ((("Exit".data_source_id = "Enrollment".data_source_id) AND (("Exit"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("Exit"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
  WHERE ("Exit"."DateDeleted" IS NULL);


--
-- Name: report_health_and_dvs; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.report_health_and_dvs AS
 SELECT "HealthAndDV"."HealthAndDVID",
    "HealthAndDV"."EnrollmentID" AS "ProjectEntryID",
    "HealthAndDV"."PersonalID",
    "HealthAndDV"."InformationDate",
    "HealthAndDV"."DomesticViolenceVictim",
    "HealthAndDV"."WhenOccurred",
    "HealthAndDV"."CurrentlyFleeing",
    "HealthAndDV"."GeneralHealthStatus",
    "HealthAndDV"."DentalHealthStatus",
    "HealthAndDV"."MentalHealthStatus",
    "HealthAndDV"."PregnancyStatus",
    "HealthAndDV"."DueDate",
    "HealthAndDV"."DataCollectionStage",
    "HealthAndDV"."DateCreated",
    "HealthAndDV"."DateUpdated",
    "HealthAndDV"."UserID",
    "HealthAndDV"."DateDeleted",
    "HealthAndDV"."ExportID",
    "HealthAndDV".data_source_id,
    "HealthAndDV".id,
    "Enrollment".id AS enrollment_id,
    source_clients.id AS demographic_id,
    destination_clients.id AS client_id
   FROM ((((public."HealthAndDV"
     JOIN public."Client" source_clients ON ((("HealthAndDV".data_source_id = source_clients.data_source_id) AND (("HealthAndDV"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
     JOIN public."Enrollment" ON ((("HealthAndDV".data_source_id = "Enrollment".data_source_id) AND (("HealthAndDV"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("HealthAndDV"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
  WHERE ("HealthAndDV"."DateDeleted" IS NULL);


--
-- Name: report_income_benefits; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.report_income_benefits AS
 SELECT "IncomeBenefits"."IncomeBenefitsID",
    "IncomeBenefits"."EnrollmentID" AS "ProjectEntryID",
    "IncomeBenefits"."PersonalID",
    "IncomeBenefits"."InformationDate",
    "IncomeBenefits"."IncomeFromAnySource",
    "IncomeBenefits"."TotalMonthlyIncome",
    "IncomeBenefits"."Earned",
    "IncomeBenefits"."EarnedAmount",
    "IncomeBenefits"."Unemployment",
    "IncomeBenefits"."UnemploymentAmount",
    "IncomeBenefits"."SSI",
    "IncomeBenefits"."SSIAmount",
    "IncomeBenefits"."SSDI",
    "IncomeBenefits"."SSDIAmount",
    "IncomeBenefits"."VADisabilityService",
    "IncomeBenefits"."VADisabilityServiceAmount",
    "IncomeBenefits"."VADisabilityNonService",
    "IncomeBenefits"."VADisabilityNonServiceAmount",
    "IncomeBenefits"."PrivateDisability",
    "IncomeBenefits"."PrivateDisabilityAmount",
    "IncomeBenefits"."WorkersComp",
    "IncomeBenefits"."WorkersCompAmount",
    "IncomeBenefits"."TANF",
    "IncomeBenefits"."TANFAmount",
    "IncomeBenefits"."GA",
    "IncomeBenefits"."GAAmount",
    "IncomeBenefits"."SocSecRetirement",
    "IncomeBenefits"."SocSecRetirementAmount",
    "IncomeBenefits"."Pension",
    "IncomeBenefits"."PensionAmount",
    "IncomeBenefits"."ChildSupport",
    "IncomeBenefits"."ChildSupportAmount",
    "IncomeBenefits"."Alimony",
    "IncomeBenefits"."AlimonyAmount",
    "IncomeBenefits"."OtherIncomeSource",
    "IncomeBenefits"."OtherIncomeAmount",
    "IncomeBenefits"."OtherIncomeSourceIdentify",
    "IncomeBenefits"."BenefitsFromAnySource",
    "IncomeBenefits"."SNAP",
    "IncomeBenefits"."WIC",
    "IncomeBenefits"."TANFChildCare",
    "IncomeBenefits"."TANFTransportation",
    "IncomeBenefits"."OtherTANF",
    "IncomeBenefits"."RentalAssistanceOngoing",
    "IncomeBenefits"."RentalAssistanceTemp",
    "IncomeBenefits"."OtherBenefitsSource",
    "IncomeBenefits"."OtherBenefitsSourceIdentify",
    "IncomeBenefits"."InsuranceFromAnySource",
    "IncomeBenefits"."Medicaid",
    "IncomeBenefits"."NoMedicaidReason",
    "IncomeBenefits"."Medicare",
    "IncomeBenefits"."NoMedicareReason",
    "IncomeBenefits"."SCHIP",
    "IncomeBenefits"."NoSCHIPReason",
    "IncomeBenefits"."VAMedicalServices",
    "IncomeBenefits"."NoVAMedReason",
    "IncomeBenefits"."EmployerProvided",
    "IncomeBenefits"."NoEmployerProvidedReason",
    "IncomeBenefits"."COBRA",
    "IncomeBenefits"."NoCOBRAReason",
    "IncomeBenefits"."PrivatePay",
    "IncomeBenefits"."NoPrivatePayReason",
    "IncomeBenefits"."StateHealthIns",
    "IncomeBenefits"."NoStateHealthInsReason",
    "IncomeBenefits"."HIVAIDSAssistance",
    "IncomeBenefits"."NoHIVAIDSAssistanceReason",
    "IncomeBenefits"."ADAP",
    "IncomeBenefits"."NoADAPReason",
    "IncomeBenefits"."DataCollectionStage",
    "IncomeBenefits"."DateCreated",
    "IncomeBenefits"."DateUpdated",
    "IncomeBenefits"."UserID",
    "IncomeBenefits"."DateDeleted",
    "IncomeBenefits"."ExportID",
    "IncomeBenefits".data_source_id,
    "IncomeBenefits".id,
    "IncomeBenefits"."IndianHealthServices",
    "IncomeBenefits"."NoIndianHealthServicesReason",
    "IncomeBenefits"."OtherInsurance",
    "IncomeBenefits"."OtherInsuranceIdentify",
    "IncomeBenefits"."ConnectionWithSOAR",
    "Enrollment".id AS enrollment_id,
    source_clients.id AS demographic_id,
    destination_clients.id AS client_id
   FROM ((((public."IncomeBenefits"
     JOIN public."Client" source_clients ON ((("IncomeBenefits".data_source_id = source_clients.data_source_id) AND (("IncomeBenefits"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
     JOIN public."Enrollment" ON ((("IncomeBenefits".data_source_id = "Enrollment".data_source_id) AND (("IncomeBenefits"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("IncomeBenefits"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
  WHERE ("IncomeBenefits"."DateDeleted" IS NULL);


--
-- Name: report_services; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.report_services AS
 SELECT "Services"."ServicesID",
    "Services"."EnrollmentID" AS "ProjectEntryID",
    "Services"."PersonalID",
    "Services"."DateProvided",
    "Services"."RecordType",
    "Services"."TypeProvided",
    "Services"."OtherTypeProvided",
    "Services"."SubTypeProvided",
    "Services"."FAAmount",
    "Services"."ReferralOutcome",
    "Services"."DateCreated",
    "Services"."DateUpdated",
    "Services"."UserID",
    "Services"."DateDeleted",
    "Services"."ExportID",
    "Services".data_source_id,
    "Services".id,
    "Enrollment".id AS enrollment_id,
    source_clients.id AS demographic_id,
    destination_clients.id AS client_id
   FROM ((((public."Services"
     JOIN public."Client" source_clients ON ((("Services".data_source_id = source_clients.data_source_id) AND (("Services"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
     JOIN public.warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
     JOIN public."Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
     JOIN public."Enrollment" ON ((("Services".data_source_id = "Enrollment".data_source_id) AND (("Services"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("Services"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
  WHERE ("Services"."DateDeleted" IS NULL);


--
-- Name: report_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_tokens (
    id integer NOT NULL,
    report_id integer NOT NULL,
    contact_id integer NOT NULL,
    token character varying NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    accessed_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: report_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.report_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.report_tokens_id_seq OWNED BY public.report_tokens.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: secure_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.secure_files (
    id integer NOT NULL,
    name character varying,
    file character varying,
    content_type character varying,
    content bytea,
    size integer,
    sender_id integer,
    recipient_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


--
-- Name: secure_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.secure_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: secure_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.secure_files_id_seq OWNED BY public.secure_files.id;


--
-- Name: service_history; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.service_history AS
 SELECT service_history_services.id,
    service_history_services.client_id,
    service_history_enrollments.data_source_id,
    service_history_services.date,
    service_history_enrollments.first_date_in_program,
    service_history_enrollments.last_date_in_program,
    service_history_enrollments.enrollment_group_id,
    service_history_enrollments.project_id,
    service_history_services.age,
    service_history_enrollments.destination,
    service_history_enrollments.head_of_household_id,
    service_history_enrollments.household_id,
    service_history_enrollments.project_name,
    service_history_services.project_type,
    service_history_enrollments.project_tracking_method,
    service_history_enrollments.organization_id,
    service_history_services.record_type,
    service_history_enrollments.housing_status_at_entry,
    service_history_enrollments.housing_status_at_exit,
    service_history_services.service_type,
    service_history_enrollments.computed_project_type,
    service_history_enrollments.presented_as_individual,
    service_history_enrollments.other_clients_over_25,
    service_history_enrollments.other_clients_under_18,
    service_history_enrollments.other_clients_between_18_and_25,
    service_history_enrollments.unaccompanied_youth,
    service_history_enrollments.parenting_youth,
    service_history_enrollments.parenting_juvenile,
    service_history_enrollments.children_only,
    service_history_enrollments.individual_adult,
    service_history_enrollments.individual_elder,
    service_history_enrollments.head_of_household
   FROM (public.service_history_services
     JOIN public.service_history_enrollments ON ((service_history_services.service_history_enrollment_id = service_history_enrollments.id)))
UNION
 SELECT service_history_enrollments.id,
    service_history_enrollments.client_id,
    service_history_enrollments.data_source_id,
    service_history_enrollments.date,
    service_history_enrollments.first_date_in_program,
    service_history_enrollments.last_date_in_program,
    service_history_enrollments.enrollment_group_id,
    service_history_enrollments.project_id,
    service_history_enrollments.age,
    service_history_enrollments.destination,
    service_history_enrollments.head_of_household_id,
    service_history_enrollments.household_id,
    service_history_enrollments.project_name,
    service_history_enrollments.project_type,
    service_history_enrollments.project_tracking_method,
    service_history_enrollments.organization_id,
    service_history_enrollments.record_type,
    service_history_enrollments.housing_status_at_entry,
    service_history_enrollments.housing_status_at_exit,
    service_history_enrollments.service_type,
    service_history_enrollments.computed_project_type,
    service_history_enrollments.presented_as_individual,
    service_history_enrollments.other_clients_over_25,
    service_history_enrollments.other_clients_under_18,
    service_history_enrollments.other_clients_between_18_and_25,
    service_history_enrollments.unaccompanied_youth,
    service_history_enrollments.parenting_youth,
    service_history_enrollments.parenting_juvenile,
    service_history_enrollments.children_only,
    service_history_enrollments.individual_adult,
    service_history_enrollments.individual_elder,
    service_history_enrollments.head_of_household
   FROM public.service_history_enrollments;


--
-- Name: service_history_enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.service_history_enrollments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: service_history_enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_history_enrollments_id_seq OWNED BY public.service_history_enrollments.id;


--
-- Name: service_history_services_2000; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2000 (
    CONSTRAINT service_history_services_2000_date_check CHECK (((date >= '2000-01-01'::date) AND (date <= '2000-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2001; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2001 (
    CONSTRAINT service_history_services_2001_date_check CHECK (((date >= '2001-01-01'::date) AND (date <= '2001-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2002; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2002 (
    CONSTRAINT service_history_services_2002_date_check CHECK (((date >= '2002-01-01'::date) AND (date <= '2002-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2003; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2003 (
    CONSTRAINT service_history_services_2003_date_check CHECK (((date >= '2003-01-01'::date) AND (date <= '2003-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2004; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2004 (
    CONSTRAINT service_history_services_2004_date_check CHECK (((date >= '2004-01-01'::date) AND (date <= '2004-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2005; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2005 (
    CONSTRAINT service_history_services_2005_date_check CHECK (((date >= '2005-01-01'::date) AND (date <= '2005-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2006; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2006 (
    CONSTRAINT service_history_services_2006_date_check CHECK (((date >= '2006-01-01'::date) AND (date <= '2006-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2007; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2007 (
    CONSTRAINT service_history_services_2007_date_check CHECK (((date >= '2007-01-01'::date) AND (date <= '2007-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2008; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2008 (
    CONSTRAINT service_history_services_2008_date_check CHECK (((date >= '2008-01-01'::date) AND (date <= '2008-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2009; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2009 (
    CONSTRAINT service_history_services_2009_date_check CHECK (((date >= '2009-01-01'::date) AND (date <= '2009-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2010; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2010 (
    CONSTRAINT service_history_services_2010_date_check CHECK (((date >= '2010-01-01'::date) AND (date <= '2010-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2011; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2011 (
    CONSTRAINT service_history_services_2011_date_check CHECK (((date >= '2011-01-01'::date) AND (date <= '2011-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2012; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2012 (
    CONSTRAINT service_history_services_2012_date_check CHECK (((date >= '2012-01-01'::date) AND (date <= '2012-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2013; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2013 (
    CONSTRAINT service_history_services_2013_date_check CHECK (((date >= '2013-01-01'::date) AND (date <= '2013-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2014; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2014 (
    CONSTRAINT service_history_services_2014_date_check CHECK (((date >= '2014-01-01'::date) AND (date <= '2014-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2015; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2015 (
    CONSTRAINT service_history_services_2015_date_check CHECK (((date >= '2015-01-01'::date) AND (date <= '2015-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2016; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2016 (
    CONSTRAINT service_history_services_2016_date_check CHECK (((date >= '2016-01-01'::date) AND (date <= '2016-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2017; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2017 (
    CONSTRAINT service_history_services_2017_date_check CHECK (((date >= '2017-01-01'::date) AND (date <= '2017-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2018; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2018 (
    CONSTRAINT service_history_services_2018_date_check CHECK (((date >= '2018-01-01'::date) AND (date <= '2018-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2019; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2019 (
    CONSTRAINT service_history_services_2019_date_check CHECK (((date >= '2019-01-01'::date) AND (date <= '2019-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.service_history_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: service_history_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_history_services_id_seq OWNED BY public.service_history_services.id;


--
-- Name: service_history_services_2020; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2020 (
    id bigint DEFAULT nextval('public.service_history_services_id_seq'::regclass),
    service_history_enrollment_id integer,
    record_type character varying(50),
    date date,
    age smallint,
    service_type smallint,
    client_id integer,
    project_type smallint,
    homeless boolean,
    literally_homeless boolean,
    CONSTRAINT service_history_services_2020_date_check CHECK (((date >= '2020-01-01'::date) AND (date <= '2020-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2021; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2021 (
    CONSTRAINT service_history_services_2021_date_check CHECK (((date >= '2021-01-01'::date) AND (date <= '2021-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2022; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2022 (
    CONSTRAINT service_history_services_2022_date_check CHECK (((date >= '2022-01-01'::date) AND (date <= '2022-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2023; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2023 (
    CONSTRAINT service_history_services_2023_date_check CHECK (((date >= '2023-01-01'::date) AND (date <= '2023-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2024; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2024 (
    CONSTRAINT service_history_services_2024_date_check CHECK (((date >= '2024-01-01'::date) AND (date <= '2024-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2025; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2025 (
    CONSTRAINT service_history_services_2025_date_check CHECK (((date >= '2025-01-01'::date) AND (date <= '2025-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2026; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2026 (
    CONSTRAINT service_history_services_2026_date_check CHECK (((date >= '2026-01-01'::date) AND (date <= '2026-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2027; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2027 (
    CONSTRAINT service_history_services_2027_date_check CHECK (((date >= '2027-01-01'::date) AND (date <= '2027-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2028; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2028 (
    CONSTRAINT service_history_services_2028_date_check CHECK (((date >= '2028-01-01'::date) AND (date <= '2028-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2029; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2029 (
    CONSTRAINT service_history_services_2029_date_check CHECK (((date >= '2029-01-01'::date) AND (date <= '2029-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2030; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2030 (
    CONSTRAINT service_history_services_2030_date_check CHECK (((date >= '2030-01-01'::date) AND (date <= '2030-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2031; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2031 (
    CONSTRAINT service_history_services_2031_date_check CHECK (((date >= '2031-01-01'::date) AND (date <= '2031-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2032; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2032 (
    CONSTRAINT service_history_services_2032_date_check CHECK (((date >= '2032-01-01'::date) AND (date <= '2032-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2033; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2033 (
    CONSTRAINT service_history_services_2033_date_check CHECK (((date >= '2033-01-01'::date) AND (date <= '2033-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2034; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2034 (
    CONSTRAINT service_history_services_2034_date_check CHECK (((date >= '2034-01-01'::date) AND (date <= '2034-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2035; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2035 (
    CONSTRAINT service_history_services_2035_date_check CHECK (((date >= '2035-01-01'::date) AND (date <= '2035-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2036; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2036 (
    CONSTRAINT service_history_services_2036_date_check CHECK (((date >= '2036-01-01'::date) AND (date <= '2036-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2037; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2037 (
    CONSTRAINT service_history_services_2037_date_check CHECK (((date >= '2037-01-01'::date) AND (date <= '2037-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2038; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2038 (
    CONSTRAINT service_history_services_2038_date_check CHECK (((date >= '2038-01-01'::date) AND (date <= '2038-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2039; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2039 (
    CONSTRAINT service_history_services_2039_date_check CHECK (((date >= '2039-01-01'::date) AND (date <= '2039-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2040; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2040 (
    CONSTRAINT service_history_services_2040_date_check CHECK (((date >= '2040-01-01'::date) AND (date <= '2040-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2041; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2041 (
    CONSTRAINT service_history_services_2041_date_check CHECK (((date >= '2041-01-01'::date) AND (date <= '2041-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2042; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2042 (
    CONSTRAINT service_history_services_2042_date_check CHECK (((date >= '2042-01-01'::date) AND (date <= '2042-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2043; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2043 (
    CONSTRAINT service_history_services_2043_date_check CHECK (((date >= '2043-01-01'::date) AND (date <= '2043-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2044; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2044 (
    CONSTRAINT service_history_services_2044_date_check CHECK (((date >= '2044-01-01'::date) AND (date <= '2044-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2045; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2045 (
    CONSTRAINT service_history_services_2045_date_check CHECK (((date >= '2045-01-01'::date) AND (date <= '2045-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2046; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2046 (
    CONSTRAINT service_history_services_2046_date_check CHECK (((date >= '2046-01-01'::date) AND (date <= '2046-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2047; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2047 (
    CONSTRAINT service_history_services_2047_date_check CHECK (((date >= '2047-01-01'::date) AND (date <= '2047-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2048; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2048 (
    CONSTRAINT service_history_services_2048_date_check CHECK (((date >= '2048-01-01'::date) AND (date <= '2048-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2049; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2049 (
    CONSTRAINT service_history_services_2049_date_check CHECK (((date >= '2049-01-01'::date) AND (date <= '2049-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_2050; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2050 (
    CONSTRAINT service_history_services_2050_date_check CHECK (((date >= '2050-01-01'::date) AND (date <= '2050-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_history_services_materialized; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.service_history_services_materialized AS
 SELECT service_history_services.id,
    service_history_services.service_history_enrollment_id,
    service_history_services.record_type,
    service_history_services.date,
    service_history_services.age,
    service_history_services.service_type,
    service_history_services.client_id,
    service_history_services.project_type,
    service_history_services.homeless,
    service_history_services.literally_homeless
   FROM public.service_history_services
  WITH NO DATA;


--
-- Name: service_history_services_remainder; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_remainder (
    CONSTRAINT service_history_services_remainder_date_check CHECK (((date < '2000-01-01'::date) OR (date > '2050-12-31'::date)))
)
INHERITS (public.service_history_services);


--
-- Name: service_scanning_scanner_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_scanning_scanner_ids (
    id bigint NOT NULL,
    client_id bigint NOT NULL,
    source_type character varying NOT NULL,
    scanned_id character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: service_scanning_scanner_ids_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.service_scanning_scanner_ids_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: service_scanning_scanner_ids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_scanning_scanner_ids_id_seq OWNED BY public.service_scanning_scanner_ids.id;


--
-- Name: service_scanning_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_scanning_services (
    id bigint NOT NULL,
    client_id bigint NOT NULL,
    project_id bigint NOT NULL,
    user_id bigint NOT NULL,
    type character varying NOT NULL,
    other_type character varying,
    provided_at timestamp without time zone,
    note character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


--
-- Name: service_scanning_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.service_scanning_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: service_scanning_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.service_scanning_services_id_seq OWNED BY public.service_scanning_services.id;


--
-- Name: shape_block_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shape_block_groups (
    id bigint NOT NULL,
    statefp character varying,
    countyfp character varying,
    tractce character varying,
    blkgrpce character varying,
    geoid character varying,
    namelsad character varying,
    mtfcc character varying,
    funcstat character varying,
    aland double precision,
    awater double precision,
    intptlat character varying,
    intptlon character varying,
    full_geoid character varying,
    simplified_geom public.geometry(MultiPolygon,4326),
    geom public.geometry(MultiPolygon,4326)
);


--
-- Name: shape_block_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shape_block_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shape_block_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shape_block_groups_id_seq OWNED BY public.shape_block_groups.id;


--
-- Name: shape_cocs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shape_cocs (
    id bigint NOT NULL,
    st character varying,
    state_name character varying,
    cocnum character varying,
    cocname character varying,
    ard numeric,
    pprn numeric,
    fprn numeric,
    fprn_statu character varying,
    es_c_hwac numeric,
    es_c_hwoa_ numeric,
    es_c_hwoc numeric,
    es_vso_tot numeric,
    th_c_hwac_ numeric,
    th_c_hwoa numeric,
    th_c_hwoc numeric,
    th_c_vet numeric,
    rrh_c_hwac numeric,
    rrh_c_hwoa numeric,
    rrh_c_hwoc numeric,
    rrh_c_vet numeric,
    psh_c_hwac numeric,
    psh_c_hwoa numeric,
    psh_c_hwoc numeric,
    psh_c_vet numeric,
    psh_c_ch numeric,
    psh_u_hwac character varying,
    psh_u_hwoa character varying,
    psh_u_hwoc character varying,
    psh_u_vet character varying,
    psh_u_ch character varying,
    sh_c_hwoa numeric,
    sh_c_vet numeric,
    sh_pers_hw numeric,
    unsh_pers_ numeric,
    sh_pers__1 numeric,
    unsh_pers1 numeric,
    sh_pers__2 numeric,
    unsh_per_1 numeric,
    sh_ch numeric,
    unsh_ch numeric,
    sh_youth_u numeric,
    unsh_youth numeric,
    sh_vets numeric,
    unsh_vets numeric,
    shape_leng numeric,
    shape_area numeric,
    geom public.geometry(MultiPolygon,4326),
    simplified_geom public.geometry(MultiPolygon,4326),
    full_geoid character varying
);


--
-- Name: shape_cocs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shape_cocs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shape_cocs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shape_cocs_id_seq OWNED BY public.shape_cocs.id;


--
-- Name: shape_counties; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shape_counties (
    id bigint NOT NULL,
    statefp character varying,
    countyfp character varying,
    countyns character varying,
    full_geoid character varying,
    geoid character varying,
    name character varying,
    namelsad character varying,
    lsad character varying,
    classfp character varying,
    mtfcc character varying,
    csafp character varying,
    cbsafp character varying,
    metdivfp character varying,
    funcstat character varying,
    aland double precision,
    awater double precision,
    intptlat character varying,
    intptlon character varying,
    simplified_geom public.geometry(MultiPolygon,4326),
    geom public.geometry(MultiPolygon,4326)
);


--
-- Name: shape_counties_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shape_counties_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shape_counties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shape_counties_id_seq OWNED BY public.shape_counties.id;


--
-- Name: shape_places; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shape_places (
    id bigint NOT NULL,
    statefp character varying,
    placefp character varying,
    placens character varying,
    full_geoid character varying,
    geoid character varying,
    name character varying,
    namelsad character varying,
    lsad character varying,
    classfp character varying,
    pcicbsa character varying,
    pcinecta character varying,
    mtfcc character varying,
    funcstat character varying,
    aland double precision,
    awater double precision,
    intptlat character varying,
    intptlon character varying,
    simplified_geom public.geometry(MultiPolygon,4326),
    geom public.geometry(MultiPolygon,4326)
);


--
-- Name: shape_places_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shape_places_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shape_places_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shape_places_id_seq OWNED BY public.shape_places.id;


--
-- Name: shape_states; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shape_states (
    id bigint NOT NULL,
    region character varying,
    division character varying,
    statefp character varying,
    statens character varying,
    full_geoid character varying,
    geoid character varying,
    stusps character varying,
    name character varying,
    lsad character varying,
    mtfcc character varying,
    funcstat character varying,
    aland double precision,
    awater double precision,
    intptlat character varying,
    intptlon character varying,
    simplified_geom public.geometry(MultiPolygon,4326),
    geom public.geometry(MultiPolygon,4326)
);


--
-- Name: shape_states_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shape_states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shape_states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shape_states_id_seq OWNED BY public.shape_states.id;


--
-- Name: shape_towns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shape_towns (
    id bigint NOT NULL,
    statefp character varying,
    fy integer,
    town_id integer,
    town character varying,
    shape_area numeric,
    shape_len numeric,
    full_geoid character varying,
    geoid character varying,
    simplified_geom public.geometry(MultiPolygon,4326),
    geom public.geometry(MultiPolygon,4326)
);


--
-- Name: shape_towns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shape_towns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shape_towns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shape_towns_id_seq OWNED BY public.shape_towns.id;


--
-- Name: shape_zip_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shape_zip_codes (
    id bigint NOT NULL,
    zcta5ce10 character varying(5),
    geoid10 character varying(5),
    classfp10 character varying(2),
    mtfcc10 character varying(5),
    funcstat10 character varying(1),
    aland10 double precision,
    awater10 double precision,
    intptlat10 character varying(11),
    intptlon10 character varying(12),
    geom public.geometry(MultiPolygon,4326),
    simplified_geom public.geometry(MultiPolygon,4326),
    full_geoid character varying
);


--
-- Name: shape_zip_codes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shape_zip_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shape_zip_codes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shape_zip_codes_id_seq OWNED BY public.shape_zip_codes.id;


--
-- Name: simple_report_cells; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.simple_report_cells (
    id bigint NOT NULL,
    report_instance_id bigint,
    name character varying,
    universe boolean DEFAULT false,
    summary integer,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: simple_report_cells_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.simple_report_cells_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: simple_report_cells_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.simple_report_cells_id_seq OWNED BY public.simple_report_cells.id;


--
-- Name: simple_report_instances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.simple_report_instances (
    id bigint NOT NULL,
    type character varying,
    options json,
    user_id bigint,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    failed_at timestamp without time zone
);


--
-- Name: simple_report_instances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.simple_report_instances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: simple_report_instances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.simple_report_instances_id_seq OWNED BY public.simple_report_instances.id;


--
-- Name: simple_report_universe_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.simple_report_universe_members (
    id bigint NOT NULL,
    report_cell_id bigint,
    universe_membership_type character varying,
    universe_membership_id bigint,
    client_id bigint,
    first_name character varying,
    last_name character varying,
    deleted_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: simple_report_universe_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.simple_report_universe_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: simple_report_universe_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.simple_report_universe_members_id_seq OWNED BY public.simple_report_universe_members.id;


--
-- Name: synthetic_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.synthetic_assessments (
    id bigint NOT NULL,
    enrollment_id bigint,
    client_id bigint,
    type character varying,
    source_type character varying,
    source_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    hud_assessment_id bigint
);


--
-- Name: synthetic_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.synthetic_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: synthetic_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.synthetic_assessments_id_seq OWNED BY public.synthetic_assessments.id;


--
-- Name: synthetic_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.synthetic_events (
    id bigint NOT NULL,
    enrollment_id bigint,
    client_id bigint,
    type character varying,
    source_type character varying,
    source_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    hud_event_id bigint
);


--
-- Name: synthetic_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.synthetic_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: synthetic_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.synthetic_events_id_seq OWNED BY public.synthetic_events.id;


--
-- Name: taggings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.taggings (
    id integer NOT NULL,
    tag_id integer,
    taggable_id integer,
    taggable_type character varying,
    tagger_id integer,
    tagger_type character varying,
    context character varying(128),
    created_at timestamp without time zone
);


--
-- Name: taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.taggings_id_seq
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
-- Name: talentlms_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.talentlms_configs (
    id bigint NOT NULL,
    subdomain character varying,
    encrypted_api_key character varying,
    encrypted_api_key_iv character varying,
    courseid integer
);


--
-- Name: talentlms_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.talentlms_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: talentlms_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.talentlms_configs_id_seq OWNED BY public.talentlms_configs.id;


--
-- Name: talentlms_logins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.talentlms_logins (
    id bigint NOT NULL,
    user_id bigint,
    login character varying,
    encrypted_password character varying,
    encrypted_password_iv character varying,
    lms_user_id integer
);


--
-- Name: talentlms_logins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.talentlms_logins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: talentlms_logins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.talentlms_logins_id_seq OWNED BY public.talentlms_logins.id;


--
-- Name: text_message_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.text_message_messages (
    id bigint NOT NULL,
    topic_id bigint,
    subscriber_id bigint,
    send_on_or_after date,
    sent_at timestamp without time zone,
    sent_to character varying,
    content character varying,
    source_id integer,
    source_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    delivery_status character varying
);


--
-- Name: text_message_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.text_message_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: text_message_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.text_message_messages_id_seq OWNED BY public.text_message_messages.id;


--
-- Name: text_message_topic_subscribers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.text_message_topic_subscribers (
    id bigint NOT NULL,
    topic_id bigint,
    subscribed_at timestamp without time zone,
    unsubscribed_at timestamp without time zone,
    first_name character varying,
    last_name character varying,
    phone_number character varying,
    preferred_language character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    client_id integer
);


--
-- Name: text_message_topic_subscribers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.text_message_topic_subscribers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: text_message_topic_subscribers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.text_message_topic_subscribers_id_seq OWNED BY public.text_message_topic_subscribers.id;


--
-- Name: text_message_topics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.text_message_topics (
    id bigint NOT NULL,
    arn character varying,
    title character varying,
    active_topic boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    send_hour integer
);


--
-- Name: text_message_topics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.text_message_topics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: text_message_topics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.text_message_topics_id_seq OWNED BY public.text_message_topics.id;


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
-- Name: uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.uploads (
    id integer NOT NULL,
    data_source_id integer,
    user_id integer,
    file character varying NOT NULL,
    percent_complete double precision,
    unzipped_path character varying,
    unzipped_files json,
    summary json,
    import_errors json,
    content_type character varying,
    content bytea,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    deleted_at timestamp without time zone,
    delayed_job_id integer,
    deidentified boolean DEFAULT false,
    project_whitelist boolean DEFAULT false,
    encrypted_content text,
    encrypted_content_iv character varying
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
-- Name: user_client_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_client_permissions (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    client_id integer NOT NULL,
    viewable boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_client_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_client_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_client_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_client_permissions_id_seq OWNED BY public.user_client_permissions.id;


--
-- Name: user_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_clients (
    id integer NOT NULL,
    user_id integer NOT NULL,
    client_id integer NOT NULL,
    confidential boolean DEFAULT false NOT NULL,
    relationship character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    start_date date,
    end_date date,
    client_notifications boolean DEFAULT false
);


--
-- Name: user_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_clients_id_seq OWNED BY public.user_clients.id;


--
-- Name: user_viewable_entities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_viewable_entities (
    id integer NOT NULL,
    user_id integer NOT NULL,
    entity_id integer NOT NULL,
    entity_type character varying NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: user_viewable_entities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_viewable_entities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_viewable_entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_viewable_entities_id_seq OWNED BY public.user_viewable_entities.id;


--
-- Name: verification_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.verification_sources (
    id integer NOT NULL,
    client_id integer,
    location character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    verified_at timestamp without time zone,
    type character varying
);


--
-- Name: verification_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.verification_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: verification_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.verification_sources_id_seq OWNED BY public.verification_sources.id;


--
-- Name: vispdats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vispdats (
    id integer NOT NULL,
    client_id integer,
    nickname character varying,
    language_answer integer,
    hiv_release boolean,
    sleep_answer integer,
    sleep_answer_other character varying,
    homeless integer,
    homeless_refused boolean,
    episodes_homeless integer,
    episodes_homeless_refused boolean,
    emergency_healthcare integer,
    emergency_healthcare_refused boolean,
    ambulance integer,
    ambulance_refused boolean,
    inpatient integer,
    inpatient_refused boolean,
    crisis_service integer,
    crisis_service_refused boolean,
    talked_to_police integer,
    talked_to_police_refused boolean,
    jail integer,
    jail_refused boolean,
    attacked_answer integer,
    threatened_answer integer,
    legal_answer integer,
    tricked_answer integer,
    risky_answer integer,
    owe_money_answer integer,
    get_money_answer integer,
    activities_answer integer,
    basic_needs_answer integer,
    abusive_answer integer,
    leave_answer integer,
    chronic_answer integer,
    hiv_answer integer,
    disability_answer integer,
    avoid_help_answer integer,
    pregnant_answer integer,
    eviction_answer integer,
    drinking_answer integer,
    mental_answer integer,
    head_answer integer,
    learning_answer integer,
    brain_answer integer,
    medication_answer integer,
    sell_answer integer,
    trauma_answer integer,
    find_location character varying,
    find_time character varying,
    when_answer integer,
    phone character varying,
    email character varying,
    picture_answer integer,
    score integer,
    recommendation character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    submitted_at timestamp without time zone,
    homeless_period integer,
    release_signed_on date,
    drug_release boolean,
    migrated_case_manager character varying,
    migrated_interviewer_name character varying,
    migrated_interviewer_email character varying,
    migrated_filed_by character varying,
    migrated boolean DEFAULT false NOT NULL,
    housing_release_confirmed boolean DEFAULT false,
    user_id integer,
    priority_score integer,
    active boolean DEFAULT false,
    type character varying DEFAULT 'GrdaWarehouse::Vispdat::Individual'::character varying,
    marijuana_answer integer,
    incarcerated_before_18_answer integer,
    homeless_due_to_ran_away_answer integer,
    homeless_due_to_religions_beliefs_answer integer,
    homeless_due_to_family_answer integer,
    homeless_due_to_gender_identity_answer integer,
    violence_between_family_members_answer integer,
    parent2_none boolean DEFAULT false,
    parent2_first_name character varying,
    parent2_nickname character varying,
    parent2_last_name character varying,
    parent2_language_answer character varying,
    parent2_dob date,
    parent2_ssn character varying,
    parent2_release_signed_on date,
    parent2_drug_release boolean DEFAULT false,
    parent2_hiv_release boolean DEFAULT false,
    number_of_children_under_18_with_family integer,
    number_of_children_under_18_with_family_refused boolean DEFAULT false,
    number_of_children_under_18_not_with_family integer,
    number_of_children_under_18_not_with_family_refused boolean DEFAULT false,
    any_member_pregnant_answer integer,
    family_member_tri_morbidity_answer integer,
    any_children_removed_answer integer,
    any_family_legal_issues_answer integer,
    any_children_lived_with_family_answer integer,
    any_child_abuse_answer integer,
    children_attend_school_answer integer,
    family_members_changed_answer integer,
    other_family_members_answer integer,
    planned_family_activities_answer integer,
    time_spent_alone_13_answer integer,
    time_spent_alone_12_answer integer,
    time_spent_helping_siblings_answer integer,
    number_of_bedrooms integer DEFAULT 0,
    contact_method character varying
);


--
-- Name: vispdats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vispdats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vispdats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vispdats_id_seq OWNED BY public.vispdats.id;


--
-- Name: warehouse_client_service_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_client_service_history (
    id integer NOT NULL,
    client_id integer NOT NULL,
    data_source_id integer,
    date date NOT NULL,
    first_date_in_program date NOT NULL,
    last_date_in_program date,
    enrollment_group_id character varying(50),
    age integer,
    destination integer,
    head_of_household_id character varying(50),
    household_id character varying(50),
    project_id character varying(50),
    project_name character varying(150),
    project_type integer,
    project_tracking_method integer,
    organization_id character varying(50),
    record_type character varying(50) NOT NULL,
    housing_status_at_entry integer,
    housing_status_at_exit integer,
    service_type integer,
    computed_project_type integer,
    presented_as_individual boolean,
    other_clients_over_25 integer DEFAULT 0 NOT NULL,
    other_clients_under_18 integer DEFAULT 0 NOT NULL,
    other_clients_between_18_and_25 integer DEFAULT 0 NOT NULL,
    unaccompanied_youth boolean DEFAULT false NOT NULL,
    parenting_youth boolean DEFAULT false NOT NULL,
    parenting_juvenile boolean DEFAULT false NOT NULL,
    children_only boolean DEFAULT false NOT NULL,
    individual_adult boolean DEFAULT false NOT NULL,
    individual_elder boolean DEFAULT false NOT NULL,
    head_of_household boolean DEFAULT false NOT NULL
);


--
-- Name: warehouse_client_service_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_client_service_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_client_service_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse_client_service_history_id_seq OWNED BY public.warehouse_client_service_history.id;


--
-- Name: warehouse_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse_clients_id_seq OWNED BY public.warehouse_clients.id;


--
-- Name: warehouse_clients_processed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_clients_processed (
    id integer NOT NULL,
    client_id integer,
    routine character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_service_updated_at timestamp without time zone,
    days_served integer,
    first_date_served date,
    last_date_served date,
    first_homeless_date date,
    last_homeless_date date,
    homeless_days integer,
    first_chronic_date date,
    last_chronic_date date,
    chronic_days integer,
    days_homeless_last_three_years integer,
    literally_homeless_last_three_years integer,
    enrolled_homeless_shelter boolean,
    enrolled_homeless_unsheltered boolean,
    enrolled_permanent_housing boolean,
    eto_coordinated_entry_assessment_score integer,
    household_members character varying,
    last_homeless_visit character varying,
    open_enrollments jsonb,
    rrh_desired boolean,
    vispdat_priority_score integer,
    vispdat_score integer,
    active_in_cas_match boolean DEFAULT false,
    last_exit_destination character varying,
    last_cas_match_date timestamp without time zone,
    lgbtq_from_hmis character varying,
    days_homeless_plus_overrides integer,
    cohorts_ongoing_enrollments_es jsonb,
    cohorts_ongoing_enrollments_sh jsonb,
    cohorts_ongoing_enrollments_th jsonb,
    cohorts_ongoing_enrollments_so jsonb,
    cohorts_ongoing_enrollments_psh jsonb,
    cohorts_ongoing_enrollments_rrh jsonb
);


--
-- Name: warehouse_clients_processed_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_clients_processed_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_clients_processed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse_clients_processed_id_seq OWNED BY public.warehouse_clients_processed.id;


--
-- Name: warehouse_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.warehouse_reports (
    id integer NOT NULL,
    parameters json,
    data json,
    type character varying,
    started_at timestamp without time zone,
    finished_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    client_count integer,
    support json,
    token character varying,
    user_id integer,
    deleted_at timestamp without time zone
);


--
-- Name: warehouse_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.warehouse_reports_id_seq OWNED BY public.warehouse_reports.id;


--
-- Name: weather; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.weather (
    id integer NOT NULL,
    url character varying NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: weather_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.weather_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: weather_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.weather_id_seq OWNED BY public.weather.id;


--
-- Name: whitelisted_projects_for_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.whitelisted_projects_for_clients (
    id integer NOT NULL,
    data_source_id integer NOT NULL,
    "ProjectID" character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: whitelisted_projects_for_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.whitelisted_projects_for_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: whitelisted_projects_for_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.whitelisted_projects_for_clients_id_seq OWNED BY public.whitelisted_projects_for_clients.id;


--
-- Name: youth_case_managements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.youth_case_managements (
    id integer NOT NULL,
    client_id integer,
    user_id integer,
    engaged_on date,
    activity text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    housing_status character varying,
    other_housing_status character varying,
    imported boolean DEFAULT false,
    zip_code character varying
);


--
-- Name: youth_case_managements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.youth_case_managements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: youth_case_managements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.youth_case_managements_id_seq OWNED BY public.youth_case_managements.id;


--
-- Name: youth_exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.youth_exports (
    id integer NOT NULL,
    user_id integer NOT NULL,
    options jsonb,
    headers jsonb,
    rows jsonb,
    client_count integer,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone
);


--
-- Name: youth_exports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.youth_exports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: youth_exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.youth_exports_id_seq OWNED BY public.youth_exports.id;


--
-- Name: youth_follow_ups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.youth_follow_ups (
    id integer NOT NULL,
    client_id integer,
    user_id integer,
    contacted_on date,
    housing_status character varying,
    zip_code character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    action character varying,
    action_on date,
    required_on date,
    case_management_id integer
);


--
-- Name: youth_follow_ups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.youth_follow_ups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: youth_follow_ups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.youth_follow_ups_id_seq OWNED BY public.youth_follow_ups.id;


--
-- Name: youth_intakes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.youth_intakes (
    id integer NOT NULL,
    client_id integer,
    user_id integer,
    type character varying,
    other_staff_completed_intake boolean DEFAULT false NOT NULL,
    client_dob date,
    staff_name character varying,
    staff_email character varying,
    engagement_date date NOT NULL,
    exit_date date,
    unaccompanied character varying NOT NULL,
    street_outreach_contact character varying NOT NULL,
    housing_status character varying NOT NULL,
    other_agency_involvement character varying,
    owns_cell_phone character varying,
    secondary_education character varying NOT NULL,
    attending_college character varying NOT NULL,
    health_insurance character varying NOT NULL,
    requesting_financial_assistance character varying NOT NULL,
    staff_believes_youth_under_24 character varying NOT NULL,
    client_gender integer NOT NULL,
    client_lgbtq character varying NOT NULL,
    client_race jsonb NOT NULL,
    client_ethnicity integer NOT NULL,
    client_primary_language character varying NOT NULL,
    pregnant_or_parenting character varying NOT NULL,
    disabilities jsonb NOT NULL,
    how_hear character varying,
    needs_shelter character varying NOT NULL,
    referred_to_shelter character varying DEFAULT 'f'::character varying NOT NULL,
    in_stable_housing character varying NOT NULL,
    stable_housing_zipcode character varying,
    youth_experiencing_homelessness_at_start character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    turned_away boolean DEFAULT false NOT NULL,
    college_pilot character varying DEFAULT 'No'::character varying NOT NULL,
    graduating_college character varying DEFAULT 'No'::character varying NOT NULL,
    imported boolean DEFAULT false,
    first_name character varying,
    last_name character varying,
    ssn character varying,
    other_agency_involvements json DEFAULT '[]'::json
);


--
-- Name: youth_intakes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.youth_intakes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: youth_intakes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.youth_intakes_id_seq OWNED BY public.youth_intakes.id;


--
-- Name: youth_referrals; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.youth_referrals (
    id integer NOT NULL,
    client_id integer,
    user_id integer,
    referred_on date,
    referred_to character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    imported boolean DEFAULT false,
    notes character varying
);


--
-- Name: youth_referrals_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.youth_referrals_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: youth_referrals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.youth_referrals_id_seq OWNED BY public.youth_referrals.id;


--
-- Name: Affiliation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Affiliation" ALTER COLUMN id SET DEFAULT nextval('public."Affiliation_id_seq"'::regclass);


--
-- Name: Assessment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Assessment" ALTER COLUMN id SET DEFAULT nextval('public."Assessment_id_seq"'::regclass);


--
-- Name: AssessmentQuestions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AssessmentQuestions" ALTER COLUMN id SET DEFAULT nextval('public."AssessmentQuestions_id_seq"'::regclass);


--
-- Name: AssessmentResults id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AssessmentResults" ALTER COLUMN id SET DEFAULT nextval('public."AssessmentResults_id_seq"'::regclass);


--
-- Name: Client id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Client" ALTER COLUMN id SET DEFAULT nextval('public."Client_id_seq"'::regclass);


--
-- Name: CurrentLivingSituation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CurrentLivingSituation" ALTER COLUMN id SET DEFAULT nextval('public."CurrentLivingSituation_id_seq"'::regclass);


--
-- Name: Disabilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Disabilities" ALTER COLUMN id SET DEFAULT nextval('public."Disabilities_id_seq"'::regclass);


--
-- Name: EmploymentEducation id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmploymentEducation" ALTER COLUMN id SET DEFAULT nextval('public."EmploymentEducation_id_seq"'::regclass);


--
-- Name: Enrollment id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Enrollment" ALTER COLUMN id SET DEFAULT nextval('public."Enrollment_id_seq"'::regclass);


--
-- Name: EnrollmentCoC id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EnrollmentCoC" ALTER COLUMN id SET DEFAULT nextval('public."EnrollmentCoC_id_seq"'::regclass);


--
-- Name: Event id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Event" ALTER COLUMN id SET DEFAULT nextval('public."Event_id_seq"'::regclass);


--
-- Name: Exit id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Exit" ALTER COLUMN id SET DEFAULT nextval('public."Exit_id_seq"'::regclass);


--
-- Name: Export id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Export" ALTER COLUMN id SET DEFAULT nextval('public."Export_id_seq"'::regclass);


--
-- Name: Funder id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Funder" ALTER COLUMN id SET DEFAULT nextval('public."Funder_id_seq"'::regclass);


--
-- Name: Geography id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Geography" ALTER COLUMN id SET DEFAULT nextval('public."Geography_id_seq"'::regclass);


--
-- Name: HealthAndDV id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."HealthAndDV" ALTER COLUMN id SET DEFAULT nextval('public."HealthAndDV_id_seq"'::regclass);


--
-- Name: IncomeBenefits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."IncomeBenefits" ALTER COLUMN id SET DEFAULT nextval('public."IncomeBenefits_id_seq"'::regclass);


--
-- Name: Inventory id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Inventory" ALTER COLUMN id SET DEFAULT nextval('public."Inventory_id_seq"'::regclass);


--
-- Name: Organization id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Organization" ALTER COLUMN id SET DEFAULT nextval('public."Organization_id_seq"'::regclass);


--
-- Name: Project id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Project" ALTER COLUMN id SET DEFAULT nextval('public."Project_id_seq"'::regclass);


--
-- Name: ProjectCoC id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProjectCoC" ALTER COLUMN id SET DEFAULT nextval('public."ProjectCoC_id_seq"'::regclass);


--
-- Name: Services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Services" ALTER COLUMN id SET DEFAULT nextval('public."Services_id_seq"'::regclass);


--
-- Name: User id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User" ALTER COLUMN id SET DEFAULT nextval('public."User_id_seq"'::regclass);


--
-- Name: YouthEducationStatus id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."YouthEducationStatus" ALTER COLUMN id SET DEFAULT nextval('public."YouthEducationStatus_id_seq"'::regclass);


--
-- Name: ad_hoc_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ad_hoc_batches ALTER COLUMN id SET DEFAULT nextval('public.ad_hoc_batches_id_seq'::regclass);


--
-- Name: ad_hoc_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ad_hoc_clients ALTER COLUMN id SET DEFAULT nextval('public.ad_hoc_clients_id_seq'::regclass);


--
-- Name: ad_hoc_data_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ad_hoc_data_sources ALTER COLUMN id SET DEFAULT nextval('public.ad_hoc_data_sources_id_seq'::regclass);


--
-- Name: administrative_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.administrative_events ALTER COLUMN id SET DEFAULT nextval('public.administrative_events_id_seq'::regclass);


--
-- Name: anomalies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anomalies ALTER COLUMN id SET DEFAULT nextval('public.anomalies_id_seq'::regclass);


--
-- Name: api_client_data_source_ids id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_client_data_source_ids ALTER COLUMN id SET DEFAULT nextval('public.api_client_data_source_ids_id_seq'::regclass);


--
-- Name: available_file_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.available_file_tags ALTER COLUMN id SET DEFAULT nextval('public.available_file_tags_id_seq'::regclass);


--
-- Name: bo_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bo_configs ALTER COLUMN id SET DEFAULT nextval('public.bo_configs_id_seq'::regclass);


--
-- Name: cas_availabilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_availabilities ALTER COLUMN id SET DEFAULT nextval('public.cas_availabilities_id_seq'::regclass);


--
-- Name: cas_ce_assessments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_ce_assessments ALTER COLUMN id SET DEFAULT nextval('public.cas_ce_assessments_id_seq'::regclass);


--
-- Name: cas_enrollments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_enrollments ALTER COLUMN id SET DEFAULT nextval('public.cas_enrollments_id_seq'::regclass);


--
-- Name: cas_houseds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_houseds ALTER COLUMN id SET DEFAULT nextval('public.cas_houseds_id_seq'::regclass);


--
-- Name: cas_non_hmis_client_histories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_non_hmis_client_histories ALTER COLUMN id SET DEFAULT nextval('public.cas_non_hmis_client_histories_id_seq'::regclass);


--
-- Name: cas_programs_to_projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_programs_to_projects ALTER COLUMN id SET DEFAULT nextval('public.cas_programs_to_projects_id_seq'::regclass);


--
-- Name: cas_referral_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_referral_events ALTER COLUMN id SET DEFAULT nextval('public.cas_referral_events_id_seq'::regclass);


--
-- Name: cas_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_reports ALTER COLUMN id SET DEFAULT nextval('public.cas_reports_id_seq'::regclass);


--
-- Name: cas_vacancies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_vacancies ALTER COLUMN id SET DEFAULT nextval('public.cas_vacancies_id_seq'::regclass);


--
-- Name: ce_assessments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ce_assessments ALTER COLUMN id SET DEFAULT nextval('public.ce_assessments_id_seq'::regclass);


--
-- Name: census_by_project_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.census_by_project_types ALTER COLUMN id SET DEFAULT nextval('public.census_by_project_types_id_seq'::regclass);


--
-- Name: census_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.census_groups ALTER COLUMN id SET DEFAULT nextval('public.census_groups_id_seq'::regclass);


--
-- Name: census_values id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.census_values ALTER COLUMN id SET DEFAULT nextval('public.census_values_id_seq'::regclass);


--
-- Name: census_variables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.census_variables ALTER COLUMN id SET DEFAULT nextval('public.census_variables_id_seq'::regclass);


--
-- Name: censuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.censuses ALTER COLUMN id SET DEFAULT nextval('public.censuses_id_seq'::regclass);


--
-- Name: censuses_averaged_by_year id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.censuses_averaged_by_year ALTER COLUMN id SET DEFAULT nextval('public.censuses_averaged_by_year_id_seq'::regclass);


--
-- Name: children id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.children ALTER COLUMN id SET DEFAULT nextval('public.children_id_seq'::regclass);


--
-- Name: chronics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chronics ALTER COLUMN id SET DEFAULT nextval('public.chronics_id_seq'::regclass);


--
-- Name: clh_locations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clh_locations ALTER COLUMN id SET DEFAULT nextval('public.clh_locations_id_seq'::regclass);


--
-- Name: client_matches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_matches ALTER COLUMN id SET DEFAULT nextval('public.client_matches_id_seq'::regclass);


--
-- Name: client_merge_histories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_merge_histories ALTER COLUMN id SET DEFAULT nextval('public.client_merge_histories_id_seq'::regclass);


--
-- Name: client_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_notes ALTER COLUMN id SET DEFAULT nextval('public.client_notes_id_seq'::regclass);


--
-- Name: client_split_histories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_split_histories ALTER COLUMN id SET DEFAULT nextval('public.client_split_histories_id_seq'::regclass);


--
-- Name: coc_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coc_codes ALTER COLUMN id SET DEFAULT nextval('public.coc_codes_id_seq'::regclass);


--
-- Name: cohort_client_changes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cohort_client_changes ALTER COLUMN id SET DEFAULT nextval('public.cohort_client_changes_id_seq'::regclass);


--
-- Name: cohort_client_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cohort_client_notes ALTER COLUMN id SET DEFAULT nextval('public.cohort_client_notes_id_seq'::regclass);


--
-- Name: cohort_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cohort_clients ALTER COLUMN id SET DEFAULT nextval('public.cohort_clients_id_seq'::regclass);


--
-- Name: cohort_column_options id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cohort_column_options ALTER COLUMN id SET DEFAULT nextval('public.cohort_column_options_id_seq'::regclass);


--
-- Name: cohorts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cohorts ALTER COLUMN id SET DEFAULT nextval('public.cohorts_id_seq'::regclass);


--
-- Name: configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configs ALTER COLUMN id SET DEFAULT nextval('public.configs_id_seq'::regclass);


--
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- Name: dashboard_export_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dashboard_export_reports ALTER COLUMN id SET DEFAULT nextval('public.dashboard_export_reports_id_seq'::regclass);


--
-- Name: data_monitorings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_monitorings ALTER COLUMN id SET DEFAULT nextval('public.data_monitorings_id_seq'::regclass);


--
-- Name: data_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sources ALTER COLUMN id SET DEFAULT nextval('public.data_sources_id_seq'::regclass);


--
-- Name: direct_financial_assistances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direct_financial_assistances ALTER COLUMN id SET DEFAULT nextval('public.direct_financial_assistances_id_seq'::regclass);


--
-- Name: document_exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_exports ALTER COLUMN id SET DEFAULT nextval('public.document_exports_id_seq'::regclass);


--
-- Name: enrollment_change_histories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_change_histories ALTER COLUMN id SET DEFAULT nextval('public.enrollment_change_histories_id_seq'::regclass);


--
-- Name: enrollment_extras id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_extras ALTER COLUMN id SET DEFAULT nextval('public.enrollment_extras_id_seq'::regclass);


--
-- Name: eto_api_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eto_api_configs ALTER COLUMN id SET DEFAULT nextval('public.eto_api_configs_id_seq'::regclass);


--
-- Name: eto_client_lookups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eto_client_lookups ALTER COLUMN id SET DEFAULT nextval('public.eto_client_lookups_id_seq'::regclass);


--
-- Name: eto_subject_response_lookups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eto_subject_response_lookups ALTER COLUMN id SET DEFAULT nextval('public.eto_subject_response_lookups_id_seq'::regclass);


--
-- Name: eto_touch_point_lookups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eto_touch_point_lookups ALTER COLUMN id SET DEFAULT nextval('public.eto_touch_point_lookups_id_seq'::regclass);


--
-- Name: eto_touch_point_response_times id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eto_touch_point_response_times ALTER COLUMN id SET DEFAULT nextval('public.eto_touch_point_response_times_id_seq'::regclass);


--
-- Name: exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports ALTER COLUMN id SET DEFAULT nextval('public.exports_id_seq'::regclass);


--
-- Name: exports_ad_hoc_anons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports_ad_hoc_anons ALTER COLUMN id SET DEFAULT nextval('public.exports_ad_hoc_anons_id_seq'::regclass);


--
-- Name: exports_ad_hocs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports_ad_hocs ALTER COLUMN id SET DEFAULT nextval('public.exports_ad_hocs_id_seq'::regclass);


--
-- Name: fake_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fake_data ALTER COLUMN id SET DEFAULT nextval('public.fake_data_id_seq'::regclass);


--
-- Name: federal_census_breakdowns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.federal_census_breakdowns ALTER COLUMN id SET DEFAULT nextval('public.federal_census_breakdowns_id_seq'::regclass);


--
-- Name: files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.files ALTER COLUMN id SET DEFAULT nextval('public.files_id_seq'::regclass);


--
-- Name: generate_service_history_batch_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generate_service_history_batch_logs ALTER COLUMN id SET DEFAULT nextval('public.generate_service_history_batch_logs_id_seq'::regclass);


--
-- Name: generate_service_history_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generate_service_history_log ALTER COLUMN id SET DEFAULT nextval('public.generate_service_history_log_id_seq'::regclass);


--
-- Name: grades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grades ALTER COLUMN id SET DEFAULT nextval('public.grades_id_seq'::regclass);


--
-- Name: group_viewable_entities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_viewable_entities ALTER COLUMN id SET DEFAULT nextval('public.group_viewable_entities_id_seq'::regclass);


--
-- Name: hap_report_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hap_report_clients ALTER COLUMN id SET DEFAULT nextval('public.hap_report_clients_id_seq'::regclass);


--
-- Name: health_emergency_ama_restrictions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_ama_restrictions ALTER COLUMN id SET DEFAULT nextval('public.health_emergency_ama_restrictions_id_seq'::regclass);


--
-- Name: health_emergency_clinical_triages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_clinical_triages ALTER COLUMN id SET DEFAULT nextval('public.health_emergency_clinical_triages_id_seq'::regclass);


--
-- Name: health_emergency_isolations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_isolations ALTER COLUMN id SET DEFAULT nextval('public.health_emergency_isolations_id_seq'::regclass);


--
-- Name: health_emergency_test_batches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_test_batches ALTER COLUMN id SET DEFAULT nextval('public.health_emergency_test_batches_id_seq'::regclass);


--
-- Name: health_emergency_tests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_tests ALTER COLUMN id SET DEFAULT nextval('public.health_emergency_tests_id_seq'::regclass);


--
-- Name: health_emergency_triages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_triages ALTER COLUMN id SET DEFAULT nextval('public.health_emergency_triages_id_seq'::regclass);


--
-- Name: health_emergency_uploaded_tests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_uploaded_tests ALTER COLUMN id SET DEFAULT nextval('public.health_emergency_uploaded_tests_id_seq'::regclass);


--
-- Name: health_emergency_vaccinations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_vaccinations ALTER COLUMN id SET DEFAULT nextval('public.health_emergency_vaccinations_id_seq'::regclass);


--
-- Name: helps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.helps ALTER COLUMN id SET DEFAULT nextval('public.helps_id_seq'::regclass);


--
-- Name: hmis_2020_affiliations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_affiliations ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_affiliations_id_seq'::regclass);


--
-- Name: hmis_2020_aggregated_enrollments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_aggregated_enrollments ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_aggregated_enrollments_id_seq'::regclass);


--
-- Name: hmis_2020_aggregated_exits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_aggregated_exits ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_aggregated_exits_id_seq'::regclass);


--
-- Name: hmis_2020_assessment_questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_assessment_questions ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_assessment_questions_id_seq'::regclass);


--
-- Name: hmis_2020_assessment_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_assessment_results ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_assessment_results_id_seq'::regclass);


--
-- Name: hmis_2020_assessments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_assessments ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_assessments_id_seq'::regclass);


--
-- Name: hmis_2020_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_clients ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_clients_id_seq'::regclass);


--
-- Name: hmis_2020_current_living_situations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_current_living_situations ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_current_living_situations_id_seq'::regclass);


--
-- Name: hmis_2020_disabilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_disabilities ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_disabilities_id_seq'::regclass);


--
-- Name: hmis_2020_employment_educations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_employment_educations ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_employment_educations_id_seq'::regclass);


--
-- Name: hmis_2020_enrollment_cocs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_enrollment_cocs ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_enrollment_cocs_id_seq'::regclass);


--
-- Name: hmis_2020_enrollments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_enrollments ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_enrollments_id_seq'::regclass);


--
-- Name: hmis_2020_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_events ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_events_id_seq'::regclass);


--
-- Name: hmis_2020_exits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_exits ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_exits_id_seq'::regclass);


--
-- Name: hmis_2020_exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_exports ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_exports_id_seq'::regclass);


--
-- Name: hmis_2020_funders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_funders ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_funders_id_seq'::regclass);


--
-- Name: hmis_2020_health_and_dvs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_health_and_dvs ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_health_and_dvs_id_seq'::regclass);


--
-- Name: hmis_2020_income_benefits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_income_benefits ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_income_benefits_id_seq'::regclass);


--
-- Name: hmis_2020_inventories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_inventories ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_inventories_id_seq'::regclass);


--
-- Name: hmis_2020_organizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_organizations ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_organizations_id_seq'::regclass);


--
-- Name: hmis_2020_project_cocs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_project_cocs ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_project_cocs_id_seq'::regclass);


--
-- Name: hmis_2020_projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_projects ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_projects_id_seq'::regclass);


--
-- Name: hmis_2020_services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_services ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_services_id_seq'::regclass);


--
-- Name: hmis_2020_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_users ALTER COLUMN id SET DEFAULT nextval('public.hmis_2020_users_id_seq'::regclass);


--
-- Name: hmis_assessments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_assessments ALTER COLUMN id SET DEFAULT nextval('public.hmis_assessments_id_seq'::regclass);


--
-- Name: hmis_client_attributes_defined_text id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_client_attributes_defined_text ALTER COLUMN id SET DEFAULT nextval('public.hmis_client_attributes_defined_text_id_seq'::regclass);


--
-- Name: hmis_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_clients ALTER COLUMN id SET DEFAULT nextval('public.hmis_clients_id_seq'::regclass);


--
-- Name: hmis_csv_2020_affiliations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_affiliations ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_affiliations_id_seq'::regclass);


--
-- Name: hmis_csv_2020_assessment_questions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_assessment_questions ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_assessment_questions_id_seq'::regclass);


--
-- Name: hmis_csv_2020_assessment_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_assessment_results ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_assessment_results_id_seq'::regclass);


--
-- Name: hmis_csv_2020_assessments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_assessments ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_assessments_id_seq'::regclass);


--
-- Name: hmis_csv_2020_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_clients ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_clients_id_seq'::regclass);


--
-- Name: hmis_csv_2020_current_living_situations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_current_living_situations ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_current_living_situations_id_seq'::regclass);


--
-- Name: hmis_csv_2020_disabilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_disabilities ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_disabilities_id_seq'::regclass);


--
-- Name: hmis_csv_2020_employment_educations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_employment_educations ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_employment_educations_id_seq'::regclass);


--
-- Name: hmis_csv_2020_enrollment_cocs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_enrollment_cocs ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_enrollment_cocs_id_seq'::regclass);


--
-- Name: hmis_csv_2020_enrollments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_enrollments ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_enrollments_id_seq'::regclass);


--
-- Name: hmis_csv_2020_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_events ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_events_id_seq'::regclass);


--
-- Name: hmis_csv_2020_exits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_exits ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_exits_id_seq'::regclass);


--
-- Name: hmis_csv_2020_exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_exports ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_exports_id_seq'::regclass);


--
-- Name: hmis_csv_2020_funders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_funders ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_funders_id_seq'::regclass);


--
-- Name: hmis_csv_2020_health_and_dvs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_health_and_dvs ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_health_and_dvs_id_seq'::regclass);


--
-- Name: hmis_csv_2020_income_benefits id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_income_benefits ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_income_benefits_id_seq'::regclass);


--
-- Name: hmis_csv_2020_inventories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_inventories ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_inventories_id_seq'::regclass);


--
-- Name: hmis_csv_2020_organizations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_organizations ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_organizations_id_seq'::regclass);


--
-- Name: hmis_csv_2020_project_cocs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_project_cocs ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_project_cocs_id_seq'::regclass);


--
-- Name: hmis_csv_2020_projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_projects ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_projects_id_seq'::regclass);


--
-- Name: hmis_csv_2020_services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_services ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_services_id_seq'::regclass);


--
-- Name: hmis_csv_2020_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_users ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_2020_users_id_seq'::regclass);


--
-- Name: hmis_csv_import_errors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_import_errors ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_import_errors_id_seq'::regclass);


--
-- Name: hmis_csv_import_validations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_import_validations ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_import_validations_id_seq'::regclass);


--
-- Name: hmis_csv_importer_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_importer_logs ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_importer_logs_id_seq'::regclass);


--
-- Name: hmis_csv_load_errors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_load_errors ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_load_errors_id_seq'::regclass);


--
-- Name: hmis_csv_loader_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_loader_logs ALTER COLUMN id SET DEFAULT nextval('public.hmis_csv_loader_logs_id_seq'::regclass);


--
-- Name: hmis_forms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_forms ALTER COLUMN id SET DEFAULT nextval('public.hmis_forms_id_seq'::regclass);


--
-- Name: hmis_import_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_import_configs ALTER COLUMN id SET DEFAULT nextval('public.hmis_import_configs_id_seq'::regclass);


--
-- Name: hmis_staff id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_staff ALTER COLUMN id SET DEFAULT nextval('public.hmis_staff_id_seq'::regclass);


--
-- Name: hmis_staff_x_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_staff_x_clients ALTER COLUMN id SET DEFAULT nextval('public.hmis_staff_x_clients_id_seq'::regclass);


--
-- Name: homeless_summary_report_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homeless_summary_report_clients ALTER COLUMN id SET DEFAULT nextval('public.homeless_summary_report_clients_id_seq'::regclass);


--
-- Name: housing_resolution_plans id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.housing_resolution_plans ALTER COLUMN id SET DEFAULT nextval('public.housing_resolution_plans_id_seq'::regclass);


--
-- Name: hud_chronics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_chronics ALTER COLUMN id SET DEFAULT nextval('public.hud_chronics_id_seq'::regclass);


--
-- Name: hud_create_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_create_logs ALTER COLUMN id SET DEFAULT nextval('public.hud_create_logs_id_seq'::regclass);


--
-- Name: hud_report_apr_ce_assessments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_apr_ce_assessments ALTER COLUMN id SET DEFAULT nextval('public.hud_report_apr_ce_assessments_id_seq'::regclass);


--
-- Name: hud_report_apr_ce_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_apr_ce_events ALTER COLUMN id SET DEFAULT nextval('public.hud_report_apr_ce_events_id_seq'::regclass);


--
-- Name: hud_report_apr_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_apr_clients ALTER COLUMN id SET DEFAULT nextval('public.hud_report_apr_clients_id_seq'::regclass);


--
-- Name: hud_report_apr_living_situations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_apr_living_situations ALTER COLUMN id SET DEFAULT nextval('public.hud_report_apr_living_situations_id_seq'::regclass);


--
-- Name: hud_report_cells id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_cells ALTER COLUMN id SET DEFAULT nextval('public.hud_report_cells_id_seq'::regclass);


--
-- Name: hud_report_dq_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_dq_clients ALTER COLUMN id SET DEFAULT nextval('public.hud_report_dq_clients_id_seq'::regclass);


--
-- Name: hud_report_dq_living_situations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_dq_living_situations ALTER COLUMN id SET DEFAULT nextval('public.hud_report_dq_living_situations_id_seq'::regclass);


--
-- Name: hud_report_instances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_instances ALTER COLUMN id SET DEFAULT nextval('public.hud_report_instances_id_seq'::regclass);


--
-- Name: hud_report_path_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_path_clients ALTER COLUMN id SET DEFAULT nextval('public.hud_report_path_clients_id_seq'::regclass);


--
-- Name: hud_report_spm_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_spm_clients ALTER COLUMN id SET DEFAULT nextval('public.hud_report_spm_clients_id_seq'::regclass);


--
-- Name: hud_report_universe_members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_universe_members ALTER COLUMN id SET DEFAULT nextval('public.hud_report_universe_members_id_seq'::regclass);


--
-- Name: identify_duplicates_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identify_duplicates_log ALTER COLUMN id SET DEFAULT nextval('public.identify_duplicates_log_id_seq'::regclass);


--
-- Name: import_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_logs ALTER COLUMN id SET DEFAULT nextval('public.import_logs_id_seq'::regclass);


--
-- Name: income_benefits_report_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.income_benefits_report_clients ALTER COLUMN id SET DEFAULT nextval('public.income_benefits_report_clients_id_seq'::regclass);


--
-- Name: income_benefits_report_incomes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.income_benefits_report_incomes ALTER COLUMN id SET DEFAULT nextval('public.income_benefits_report_incomes_id_seq'::regclass);


--
-- Name: income_benefits_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.income_benefits_reports ALTER COLUMN id SET DEFAULT nextval('public.income_benefits_reports_id_seq'::regclass);


--
-- Name: involved_in_imports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.involved_in_imports ALTER COLUMN id SET DEFAULT nextval('public.involved_in_imports_id_seq'::regclass);


--
-- Name: lftp_s3_syncs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lftp_s3_syncs ALTER COLUMN id SET DEFAULT nextval('public.lftp_s3_syncs_id_seq'::regclass);


--
-- Name: lookups_ethnicities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_ethnicities ALTER COLUMN id SET DEFAULT nextval('public.lookups_ethnicities_id_seq'::regclass);


--
-- Name: lookups_funding_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_funding_sources ALTER COLUMN id SET DEFAULT nextval('public.lookups_funding_sources_id_seq'::regclass);


--
-- Name: lookups_genders id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_genders ALTER COLUMN id SET DEFAULT nextval('public.lookups_genders_id_seq'::regclass);


--
-- Name: lookups_living_situations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_living_situations ALTER COLUMN id SET DEFAULT nextval('public.lookups_living_situations_id_seq'::regclass);


--
-- Name: lookups_project_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_project_types ALTER COLUMN id SET DEFAULT nextval('public.lookups_project_types_id_seq'::regclass);


--
-- Name: lookups_relationships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_relationships ALTER COLUMN id SET DEFAULT nextval('public.lookups_relationships_id_seq'::regclass);


--
-- Name: lookups_tracking_methods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_tracking_methods ALTER COLUMN id SET DEFAULT nextval('public.lookups_tracking_methods_id_seq'::regclass);


--
-- Name: lookups_yes_no_etcs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_yes_no_etcs ALTER COLUMN id SET DEFAULT nextval('public.lookups_yes_no_etcs_id_seq'::regclass);


--
-- Name: lsa_rds_state_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_rds_state_logs ALTER COLUMN id SET DEFAULT nextval('public.lsa_rds_state_logs_id_seq'::regclass);


--
-- Name: new_service_history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.new_service_history ALTER COLUMN id SET DEFAULT nextval('public.new_service_history_id_seq'::regclass);


--
-- Name: nightly_census_by_project_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nightly_census_by_project_clients ALTER COLUMN id SET DEFAULT nextval('public.nightly_census_by_project_clients_id_seq'::regclass);


--
-- Name: nightly_census_by_project_type_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nightly_census_by_project_type_clients ALTER COLUMN id SET DEFAULT nextval('public.nightly_census_by_project_type_clients_id_seq'::regclass);


--
-- Name: nightly_census_by_project_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nightly_census_by_project_types ALTER COLUMN id SET DEFAULT nextval('public.nightly_census_by_project_types_id_seq'::regclass);


--
-- Name: nightly_census_by_projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nightly_census_by_projects ALTER COLUMN id SET DEFAULT nextval('public.nightly_census_by_projects_id_seq'::regclass);


--
-- Name: non_hmis_uploads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.non_hmis_uploads ALTER COLUMN id SET DEFAULT nextval('public.non_hmis_uploads_id_seq'::regclass);


--
-- Name: performance_metrics_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_metrics_clients ALTER COLUMN id SET DEFAULT nextval('public.performance_metrics_clients_id_seq'::regclass);


--
-- Name: project_data_quality id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_data_quality ALTER COLUMN id SET DEFAULT nextval('public.project_data_quality_id_seq'::regclass);


--
-- Name: project_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_groups ALTER COLUMN id SET DEFAULT nextval('public.project_groups_id_seq'::regclass);


--
-- Name: project_pass_fails id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_pass_fails ALTER COLUMN id SET DEFAULT nextval('public.project_pass_fails_id_seq'::regclass);


--
-- Name: project_pass_fails_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_pass_fails_clients ALTER COLUMN id SET DEFAULT nextval('public.project_pass_fails_clients_id_seq'::regclass);


--
-- Name: project_pass_fails_projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_pass_fails_projects ALTER COLUMN id SET DEFAULT nextval('public.project_pass_fails_projects_id_seq'::regclass);


--
-- Name: project_project_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_project_groups ALTER COLUMN id SET DEFAULT nextval('public.project_project_groups_id_seq'::regclass);


--
-- Name: project_scorecard_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_scorecard_reports ALTER COLUMN id SET DEFAULT nextval('public.project_scorecard_reports_id_seq'::regclass);


--
-- Name: psc_feedback_surveys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.psc_feedback_surveys ALTER COLUMN id SET DEFAULT nextval('public.psc_feedback_surveys_id_seq'::regclass);


--
-- Name: public_report_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.public_report_reports ALTER COLUMN id SET DEFAULT nextval('public.public_report_reports_id_seq'::regclass);


--
-- Name: public_report_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.public_report_settings ALTER COLUMN id SET DEFAULT nextval('public.public_report_settings_id_seq'::regclass);


--
-- Name: recurring_hmis_export_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurring_hmis_export_links ALTER COLUMN id SET DEFAULT nextval('public.recurring_hmis_export_links_id_seq'::regclass);


--
-- Name: recurring_hmis_exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurring_hmis_exports ALTER COLUMN id SET DEFAULT nextval('public.recurring_hmis_exports_id_seq'::regclass);


--
-- Name: report_definitions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_definitions ALTER COLUMN id SET DEFAULT nextval('public.report_definitions_id_seq'::regclass);


--
-- Name: report_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_tokens ALTER COLUMN id SET DEFAULT nextval('public.report_tokens_id_seq'::regclass);


--
-- Name: secure_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.secure_files ALTER COLUMN id SET DEFAULT nextval('public.secure_files_id_seq'::regclass);


--
-- Name: service_history_enrollments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_enrollments ALTER COLUMN id SET DEFAULT nextval('public.service_history_enrollments_id_seq'::regclass);


--
-- Name: service_history_services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2000 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2000 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2001 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2001 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2002 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2002 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2003 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2003 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2004 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2004 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2005 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2005 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2006 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2006 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2007 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2007 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2008 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2008 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2009 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2009 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2010 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2010 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2011 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2011 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2012 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2012 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2013 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2013 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2014 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2014 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2015 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2015 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2016 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2016 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2017 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2017 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2018 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2018 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2019 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2019 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2021 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2021 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2022 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2022 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2023 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2023 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2024 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2024 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2025 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2025 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2026 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2026 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2027 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2027 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2028 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2028 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2029 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2029 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2030 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2030 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2031 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2031 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2032 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2032 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2033 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2033 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2034 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2034 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2035 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2035 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2036 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2036 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2037 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2037 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2038 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2038 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2039 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2039 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2040 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2040 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2041 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2041 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2042 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2042 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2043 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2043 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2044 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2044 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2045 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2045 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2046 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2046 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2047 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2047 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2048 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2048 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2049 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2049 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_2050 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2050 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_history_services_remainder id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_remainder ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


--
-- Name: service_scanning_scanner_ids id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_scanning_scanner_ids ALTER COLUMN id SET DEFAULT nextval('public.service_scanning_scanner_ids_id_seq'::regclass);


--
-- Name: service_scanning_services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_scanning_services ALTER COLUMN id SET DEFAULT nextval('public.service_scanning_services_id_seq'::regclass);


--
-- Name: shape_block_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shape_block_groups ALTER COLUMN id SET DEFAULT nextval('public.shape_block_groups_id_seq'::regclass);


--
-- Name: shape_cocs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shape_cocs ALTER COLUMN id SET DEFAULT nextval('public.shape_cocs_id_seq'::regclass);


--
-- Name: shape_counties id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shape_counties ALTER COLUMN id SET DEFAULT nextval('public.shape_counties_id_seq'::regclass);


--
-- Name: shape_places id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shape_places ALTER COLUMN id SET DEFAULT nextval('public.shape_places_id_seq'::regclass);


--
-- Name: shape_states id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shape_states ALTER COLUMN id SET DEFAULT nextval('public.shape_states_id_seq'::regclass);


--
-- Name: shape_towns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shape_towns ALTER COLUMN id SET DEFAULT nextval('public.shape_towns_id_seq'::regclass);


--
-- Name: shape_zip_codes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shape_zip_codes ALTER COLUMN id SET DEFAULT nextval('public.shape_zip_codes_id_seq'::regclass);


--
-- Name: simple_report_cells id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.simple_report_cells ALTER COLUMN id SET DEFAULT nextval('public.simple_report_cells_id_seq'::regclass);


--
-- Name: simple_report_instances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.simple_report_instances ALTER COLUMN id SET DEFAULT nextval('public.simple_report_instances_id_seq'::regclass);


--
-- Name: simple_report_universe_members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.simple_report_universe_members ALTER COLUMN id SET DEFAULT nextval('public.simple_report_universe_members_id_seq'::regclass);


--
-- Name: synthetic_assessments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.synthetic_assessments ALTER COLUMN id SET DEFAULT nextval('public.synthetic_assessments_id_seq'::regclass);


--
-- Name: synthetic_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.synthetic_events ALTER COLUMN id SET DEFAULT nextval('public.synthetic_events_id_seq'::regclass);


--
-- Name: taggings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings ALTER COLUMN id SET DEFAULT nextval('public.taggings_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: talentlms_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.talentlms_configs ALTER COLUMN id SET DEFAULT nextval('public.talentlms_configs_id_seq'::regclass);


--
-- Name: talentlms_logins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.talentlms_logins ALTER COLUMN id SET DEFAULT nextval('public.talentlms_logins_id_seq'::regclass);


--
-- Name: text_message_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.text_message_messages ALTER COLUMN id SET DEFAULT nextval('public.text_message_messages_id_seq'::regclass);


--
-- Name: text_message_topic_subscribers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.text_message_topic_subscribers ALTER COLUMN id SET DEFAULT nextval('public.text_message_topic_subscribers_id_seq'::regclass);


--
-- Name: text_message_topics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.text_message_topics ALTER COLUMN id SET DEFAULT nextval('public.text_message_topics_id_seq'::regclass);


--
-- Name: uploads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uploads ALTER COLUMN id SET DEFAULT nextval('public.uploads_id_seq'::regclass);


--
-- Name: user_client_permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_client_permissions ALTER COLUMN id SET DEFAULT nextval('public.user_client_permissions_id_seq'::regclass);


--
-- Name: user_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_clients ALTER COLUMN id SET DEFAULT nextval('public.user_clients_id_seq'::regclass);


--
-- Name: user_viewable_entities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_viewable_entities ALTER COLUMN id SET DEFAULT nextval('public.user_viewable_entities_id_seq'::regclass);


--
-- Name: verification_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verification_sources ALTER COLUMN id SET DEFAULT nextval('public.verification_sources_id_seq'::regclass);


--
-- Name: vispdats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vispdats ALTER COLUMN id SET DEFAULT nextval('public.vispdats_id_seq'::regclass);


--
-- Name: warehouse_client_service_history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_client_service_history ALTER COLUMN id SET DEFAULT nextval('public.warehouse_client_service_history_id_seq'::regclass);


--
-- Name: warehouse_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_clients ALTER COLUMN id SET DEFAULT nextval('public.warehouse_clients_id_seq'::regclass);


--
-- Name: warehouse_clients_processed id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_clients_processed ALTER COLUMN id SET DEFAULT nextval('public.warehouse_clients_processed_id_seq'::regclass);


--
-- Name: warehouse_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_reports ALTER COLUMN id SET DEFAULT nextval('public.warehouse_reports_id_seq'::regclass);


--
-- Name: weather id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weather ALTER COLUMN id SET DEFAULT nextval('public.weather_id_seq'::regclass);


--
-- Name: whitelisted_projects_for_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.whitelisted_projects_for_clients ALTER COLUMN id SET DEFAULT nextval('public.whitelisted_projects_for_clients_id_seq'::regclass);


--
-- Name: youth_case_managements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.youth_case_managements ALTER COLUMN id SET DEFAULT nextval('public.youth_case_managements_id_seq'::regclass);


--
-- Name: youth_exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.youth_exports ALTER COLUMN id SET DEFAULT nextval('public.youth_exports_id_seq'::regclass);


--
-- Name: youth_follow_ups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.youth_follow_ups ALTER COLUMN id SET DEFAULT nextval('public.youth_follow_ups_id_seq'::regclass);


--
-- Name: youth_intakes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.youth_intakes ALTER COLUMN id SET DEFAULT nextval('public.youth_intakes_id_seq'::regclass);


--
-- Name: youth_referrals id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.youth_referrals ALTER COLUMN id SET DEFAULT nextval('public.youth_referrals_id_seq'::regclass);


--
-- Name: Affiliation Affiliation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Affiliation"
    ADD CONSTRAINT "Affiliation_pkey" PRIMARY KEY (id);


--
-- Name: AssessmentQuestions AssessmentQuestions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AssessmentQuestions"
    ADD CONSTRAINT "AssessmentQuestions_pkey" PRIMARY KEY (id);


--
-- Name: AssessmentResults AssessmentResults_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."AssessmentResults"
    ADD CONSTRAINT "AssessmentResults_pkey" PRIMARY KEY (id);


--
-- Name: Assessment Assessment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Assessment"
    ADD CONSTRAINT "Assessment_pkey" PRIMARY KEY (id);


--
-- Name: ClientUnencrypted ClientUnencrypted_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ClientUnencrypted"
    ADD CONSTRAINT "ClientUnencrypted_pkey" PRIMARY KEY (id);


--
-- Name: Client Client_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Client"
    ADD CONSTRAINT "Client_pkey" PRIMARY KEY (id);


--
-- Name: CurrentLivingSituation CurrentLivingSituation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."CurrentLivingSituation"
    ADD CONSTRAINT "CurrentLivingSituation_pkey" PRIMARY KEY (id);


--
-- Name: Disabilities Disabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Disabilities"
    ADD CONSTRAINT "Disabilities_pkey" PRIMARY KEY (id);


--
-- Name: EmploymentEducation EmploymentEducation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmploymentEducation"
    ADD CONSTRAINT "EmploymentEducation_pkey" PRIMARY KEY (id);


--
-- Name: EnrollmentCoC EnrollmentCoC_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EnrollmentCoC"
    ADD CONSTRAINT "EnrollmentCoC_pkey" PRIMARY KEY (id);


--
-- Name: Enrollment Enrollment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Enrollment"
    ADD CONSTRAINT "Enrollment_pkey" PRIMARY KEY (id);


--
-- Name: Event Event_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Event"
    ADD CONSTRAINT "Event_pkey" PRIMARY KEY (id);


--
-- Name: Exit Exit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Exit"
    ADD CONSTRAINT "Exit_pkey" PRIMARY KEY (id);


--
-- Name: Export Export_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Export"
    ADD CONSTRAINT "Export_pkey" PRIMARY KEY (id);


--
-- Name: Funder Funder_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Funder"
    ADD CONSTRAINT "Funder_pkey" PRIMARY KEY (id);


--
-- Name: Geography Geography_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Geography"
    ADD CONSTRAINT "Geography_pkey" PRIMARY KEY (id);


--
-- Name: HealthAndDV HealthAndDV_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."HealthAndDV"
    ADD CONSTRAINT "HealthAndDV_pkey" PRIMARY KEY (id);


--
-- Name: IncomeBenefits IncomeBenefits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."IncomeBenefits"
    ADD CONSTRAINT "IncomeBenefits_pkey" PRIMARY KEY (id);


--
-- Name: Inventory Inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Inventory"
    ADD CONSTRAINT "Inventory_pkey" PRIMARY KEY (id);


--
-- Name: Organization Organization_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Organization"
    ADD CONSTRAINT "Organization_pkey" PRIMARY KEY (id);


--
-- Name: ProjectCoC ProjectCoC_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProjectCoC"
    ADD CONSTRAINT "ProjectCoC_pkey" PRIMARY KEY (id);


--
-- Name: Project Project_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Project"
    ADD CONSTRAINT "Project_pkey" PRIMARY KEY (id);


--
-- Name: Services Services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Services"
    ADD CONSTRAINT "Services_pkey" PRIMARY KEY (id);


--
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (id);


--
-- Name: YouthEducationStatus YouthEducationStatus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."YouthEducationStatus"
    ADD CONSTRAINT "YouthEducationStatus_pkey" PRIMARY KEY (id);


--
-- Name: ad_hoc_batches ad_hoc_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ad_hoc_batches
    ADD CONSTRAINT ad_hoc_batches_pkey PRIMARY KEY (id);


--
-- Name: ad_hoc_clients ad_hoc_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ad_hoc_clients
    ADD CONSTRAINT ad_hoc_clients_pkey PRIMARY KEY (id);


--
-- Name: ad_hoc_data_sources ad_hoc_data_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ad_hoc_data_sources
    ADD CONSTRAINT ad_hoc_data_sources_pkey PRIMARY KEY (id);


--
-- Name: administrative_events administrative_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.administrative_events
    ADD CONSTRAINT administrative_events_pkey PRIMARY KEY (id);


--
-- Name: anomalies anomalies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anomalies
    ADD CONSTRAINT anomalies_pkey PRIMARY KEY (id);


--
-- Name: api_client_data_source_ids api_client_data_source_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_client_data_source_ids
    ADD CONSTRAINT api_client_data_source_ids_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: available_file_tags available_file_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.available_file_tags
    ADD CONSTRAINT available_file_tags_pkey PRIMARY KEY (id);


--
-- Name: bo_configs bo_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bo_configs
    ADD CONSTRAINT bo_configs_pkey PRIMARY KEY (id);


--
-- Name: cas_availabilities cas_availabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_availabilities
    ADD CONSTRAINT cas_availabilities_pkey PRIMARY KEY (id);


--
-- Name: cas_ce_assessments cas_ce_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_ce_assessments
    ADD CONSTRAINT cas_ce_assessments_pkey PRIMARY KEY (id);


--
-- Name: cas_enrollments cas_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_enrollments
    ADD CONSTRAINT cas_enrollments_pkey PRIMARY KEY (id);


--
-- Name: cas_houseds cas_houseds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_houseds
    ADD CONSTRAINT cas_houseds_pkey PRIMARY KEY (id);


--
-- Name: cas_non_hmis_client_histories cas_non_hmis_client_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_non_hmis_client_histories
    ADD CONSTRAINT cas_non_hmis_client_histories_pkey PRIMARY KEY (id);


--
-- Name: cas_programs_to_projects cas_programs_to_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_programs_to_projects
    ADD CONSTRAINT cas_programs_to_projects_pkey PRIMARY KEY (id);


--
-- Name: cas_referral_events cas_referral_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_referral_events
    ADD CONSTRAINT cas_referral_events_pkey PRIMARY KEY (id);


--
-- Name: cas_reports cas_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_reports
    ADD CONSTRAINT cas_reports_pkey PRIMARY KEY (id);


--
-- Name: cas_vacancies cas_vacancies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_vacancies
    ADD CONSTRAINT cas_vacancies_pkey PRIMARY KEY (id);


--
-- Name: ce_assessments ce_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ce_assessments
    ADD CONSTRAINT ce_assessments_pkey PRIMARY KEY (id);


--
-- Name: census_by_project_types census_by_project_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.census_by_project_types
    ADD CONSTRAINT census_by_project_types_pkey PRIMARY KEY (id);


--
-- Name: census_groups census_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.census_groups
    ADD CONSTRAINT census_groups_pkey PRIMARY KEY (id);


--
-- Name: census_values census_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.census_values
    ADD CONSTRAINT census_values_pkey PRIMARY KEY (id);


--
-- Name: census_variables census_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.census_variables
    ADD CONSTRAINT census_variables_pkey PRIMARY KEY (id);


--
-- Name: censuses_averaged_by_year censuses_averaged_by_year_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.censuses_averaged_by_year
    ADD CONSTRAINT censuses_averaged_by_year_pkey PRIMARY KEY (id);


--
-- Name: censuses censuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.censuses
    ADD CONSTRAINT censuses_pkey PRIMARY KEY (id);


--
-- Name: children children_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.children
    ADD CONSTRAINT children_pkey PRIMARY KEY (id);


--
-- Name: chronics chronics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chronics
    ADD CONSTRAINT chronics_pkey PRIMARY KEY (id);


--
-- Name: clh_locations clh_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clh_locations
    ADD CONSTRAINT clh_locations_pkey PRIMARY KEY (id);


--
-- Name: client_matches client_matches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_matches
    ADD CONSTRAINT client_matches_pkey PRIMARY KEY (id);


--
-- Name: client_merge_histories client_merge_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_merge_histories
    ADD CONSTRAINT client_merge_histories_pkey PRIMARY KEY (id);


--
-- Name: client_notes client_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_notes
    ADD CONSTRAINT client_notes_pkey PRIMARY KEY (id);


--
-- Name: client_split_histories client_split_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_split_histories
    ADD CONSTRAINT client_split_histories_pkey PRIMARY KEY (id);


--
-- Name: coc_codes coc_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.coc_codes
    ADD CONSTRAINT coc_codes_pkey PRIMARY KEY (id);


--
-- Name: cohort_client_changes cohort_client_changes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cohort_client_changes
    ADD CONSTRAINT cohort_client_changes_pkey PRIMARY KEY (id);


--
-- Name: cohort_client_notes cohort_client_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cohort_client_notes
    ADD CONSTRAINT cohort_client_notes_pkey PRIMARY KEY (id);


--
-- Name: cohort_clients cohort_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cohort_clients
    ADD CONSTRAINT cohort_clients_pkey PRIMARY KEY (id);


--
-- Name: cohort_column_options cohort_column_options_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cohort_column_options
    ADD CONSTRAINT cohort_column_options_pkey PRIMARY KEY (id);


--
-- Name: cohorts cohorts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cohorts
    ADD CONSTRAINT cohorts_pkey PRIMARY KEY (id);


--
-- Name: configs configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configs
    ADD CONSTRAINT configs_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: dashboard_export_reports dashboard_export_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dashboard_export_reports
    ADD CONSTRAINT dashboard_export_reports_pkey PRIMARY KEY (id);


--
-- Name: data_monitorings data_monitorings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_monitorings
    ADD CONSTRAINT data_monitorings_pkey PRIMARY KEY (id);


--
-- Name: data_sources data_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sources
    ADD CONSTRAINT data_sources_pkey PRIMARY KEY (id);


--
-- Name: direct_financial_assistances direct_financial_assistances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.direct_financial_assistances
    ADD CONSTRAINT direct_financial_assistances_pkey PRIMARY KEY (id);


--
-- Name: document_exports document_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.document_exports
    ADD CONSTRAINT document_exports_pkey PRIMARY KEY (id);


--
-- Name: enrollment_change_histories enrollment_change_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_change_histories
    ADD CONSTRAINT enrollment_change_histories_pkey PRIMARY KEY (id);


--
-- Name: enrollment_extras enrollment_extras_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollment_extras
    ADD CONSTRAINT enrollment_extras_pkey PRIMARY KEY (id);


--
-- Name: eto_api_configs eto_api_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eto_api_configs
    ADD CONSTRAINT eto_api_configs_pkey PRIMARY KEY (id);


--
-- Name: eto_client_lookups eto_client_lookups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eto_client_lookups
    ADD CONSTRAINT eto_client_lookups_pkey PRIMARY KEY (id);


--
-- Name: eto_subject_response_lookups eto_subject_response_lookups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eto_subject_response_lookups
    ADD CONSTRAINT eto_subject_response_lookups_pkey PRIMARY KEY (id);


--
-- Name: eto_touch_point_lookups eto_touch_point_lookups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eto_touch_point_lookups
    ADD CONSTRAINT eto_touch_point_lookups_pkey PRIMARY KEY (id);


--
-- Name: eto_touch_point_response_times eto_touch_point_response_times_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.eto_touch_point_response_times
    ADD CONSTRAINT eto_touch_point_response_times_pkey PRIMARY KEY (id);


--
-- Name: exports_ad_hoc_anons exports_ad_hoc_anons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports_ad_hoc_anons
    ADD CONSTRAINT exports_ad_hoc_anons_pkey PRIMARY KEY (id);


--
-- Name: exports_ad_hocs exports_ad_hocs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports_ad_hocs
    ADD CONSTRAINT exports_ad_hocs_pkey PRIMARY KEY (id);


--
-- Name: exports exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports
    ADD CONSTRAINT exports_pkey PRIMARY KEY (id);


--
-- Name: fake_data fake_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fake_data
    ADD CONSTRAINT fake_data_pkey PRIMARY KEY (id);


--
-- Name: federal_census_breakdowns federal_census_breakdowns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.federal_census_breakdowns
    ADD CONSTRAINT federal_census_breakdowns_pkey PRIMARY KEY (id);


--
-- Name: files files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);


--
-- Name: generate_service_history_batch_logs generate_service_history_batch_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generate_service_history_batch_logs
    ADD CONSTRAINT generate_service_history_batch_logs_pkey PRIMARY KEY (id);


--
-- Name: generate_service_history_log generate_service_history_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generate_service_history_log
    ADD CONSTRAINT generate_service_history_log_pkey PRIMARY KEY (id);


--
-- Name: grades grades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grades
    ADD CONSTRAINT grades_pkey PRIMARY KEY (id);


--
-- Name: group_viewable_entities group_viewable_entities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_viewable_entities
    ADD CONSTRAINT group_viewable_entities_pkey PRIMARY KEY (id);


--
-- Name: hap_report_clients hap_report_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hap_report_clients
    ADD CONSTRAINT hap_report_clients_pkey PRIMARY KEY (id);


--
-- Name: health_emergency_ama_restrictions health_emergency_ama_restrictions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_ama_restrictions
    ADD CONSTRAINT health_emergency_ama_restrictions_pkey PRIMARY KEY (id);


--
-- Name: health_emergency_clinical_triages health_emergency_clinical_triages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_clinical_triages
    ADD CONSTRAINT health_emergency_clinical_triages_pkey PRIMARY KEY (id);


--
-- Name: health_emergency_isolations health_emergency_isolations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_isolations
    ADD CONSTRAINT health_emergency_isolations_pkey PRIMARY KEY (id);


--
-- Name: health_emergency_test_batches health_emergency_test_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_test_batches
    ADD CONSTRAINT health_emergency_test_batches_pkey PRIMARY KEY (id);


--
-- Name: health_emergency_tests health_emergency_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_tests
    ADD CONSTRAINT health_emergency_tests_pkey PRIMARY KEY (id);


--
-- Name: health_emergency_triages health_emergency_triages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_triages
    ADD CONSTRAINT health_emergency_triages_pkey PRIMARY KEY (id);


--
-- Name: health_emergency_uploaded_tests health_emergency_uploaded_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_uploaded_tests
    ADD CONSTRAINT health_emergency_uploaded_tests_pkey PRIMARY KEY (id);


--
-- Name: health_emergency_vaccinations health_emergency_vaccinations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.health_emergency_vaccinations
    ADD CONSTRAINT health_emergency_vaccinations_pkey PRIMARY KEY (id);


--
-- Name: helps helps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.helps
    ADD CONSTRAINT helps_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_affiliations hmis_2020_affiliations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_affiliations
    ADD CONSTRAINT hmis_2020_affiliations_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_aggregated_enrollments hmis_2020_aggregated_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_aggregated_enrollments
    ADD CONSTRAINT hmis_2020_aggregated_enrollments_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_aggregated_exits hmis_2020_aggregated_exits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_aggregated_exits
    ADD CONSTRAINT hmis_2020_aggregated_exits_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_assessment_questions hmis_2020_assessment_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_assessment_questions
    ADD CONSTRAINT hmis_2020_assessment_questions_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_assessment_results hmis_2020_assessment_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_assessment_results
    ADD CONSTRAINT hmis_2020_assessment_results_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_assessments hmis_2020_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_assessments
    ADD CONSTRAINT hmis_2020_assessments_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_clients hmis_2020_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_clients
    ADD CONSTRAINT hmis_2020_clients_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_current_living_situations hmis_2020_current_living_situations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_current_living_situations
    ADD CONSTRAINT hmis_2020_current_living_situations_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_disabilities hmis_2020_disabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_disabilities
    ADD CONSTRAINT hmis_2020_disabilities_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_employment_educations hmis_2020_employment_educations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_employment_educations
    ADD CONSTRAINT hmis_2020_employment_educations_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_enrollment_cocs hmis_2020_enrollment_cocs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_enrollment_cocs
    ADD CONSTRAINT hmis_2020_enrollment_cocs_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_enrollments hmis_2020_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_enrollments
    ADD CONSTRAINT hmis_2020_enrollments_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_events hmis_2020_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_events
    ADD CONSTRAINT hmis_2020_events_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_exits hmis_2020_exits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_exits
    ADD CONSTRAINT hmis_2020_exits_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_exports hmis_2020_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_exports
    ADD CONSTRAINT hmis_2020_exports_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_funders hmis_2020_funders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_funders
    ADD CONSTRAINT hmis_2020_funders_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_health_and_dvs hmis_2020_health_and_dvs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_health_and_dvs
    ADD CONSTRAINT hmis_2020_health_and_dvs_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_income_benefits hmis_2020_income_benefits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_income_benefits
    ADD CONSTRAINT hmis_2020_income_benefits_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_inventories hmis_2020_inventories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_inventories
    ADD CONSTRAINT hmis_2020_inventories_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_organizations hmis_2020_organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_organizations
    ADD CONSTRAINT hmis_2020_organizations_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_project_cocs hmis_2020_project_cocs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_project_cocs
    ADD CONSTRAINT hmis_2020_project_cocs_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_projects hmis_2020_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_projects
    ADD CONSTRAINT hmis_2020_projects_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_services hmis_2020_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_services
    ADD CONSTRAINT hmis_2020_services_pkey PRIMARY KEY (id);


--
-- Name: hmis_2020_users hmis_2020_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_2020_users
    ADD CONSTRAINT hmis_2020_users_pkey PRIMARY KEY (id);


--
-- Name: hmis_assessments hmis_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_assessments
    ADD CONSTRAINT hmis_assessments_pkey PRIMARY KEY (id);


--
-- Name: hmis_client_attributes_defined_text hmis_client_attributes_defined_text_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_client_attributes_defined_text
    ADD CONSTRAINT hmis_client_attributes_defined_text_pkey PRIMARY KEY (id);


--
-- Name: hmis_clients hmis_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_clients
    ADD CONSTRAINT hmis_clients_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_affiliations hmis_csv_2020_affiliations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_affiliations
    ADD CONSTRAINT hmis_csv_2020_affiliations_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_assessment_questions hmis_csv_2020_assessment_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_assessment_questions
    ADD CONSTRAINT hmis_csv_2020_assessment_questions_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_assessment_results hmis_csv_2020_assessment_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_assessment_results
    ADD CONSTRAINT hmis_csv_2020_assessment_results_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_assessments hmis_csv_2020_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_assessments
    ADD CONSTRAINT hmis_csv_2020_assessments_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_clients hmis_csv_2020_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_clients
    ADD CONSTRAINT hmis_csv_2020_clients_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_current_living_situations hmis_csv_2020_current_living_situations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_current_living_situations
    ADD CONSTRAINT hmis_csv_2020_current_living_situations_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_disabilities hmis_csv_2020_disabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_disabilities
    ADD CONSTRAINT hmis_csv_2020_disabilities_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_employment_educations hmis_csv_2020_employment_educations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_employment_educations
    ADD CONSTRAINT hmis_csv_2020_employment_educations_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_enrollment_cocs hmis_csv_2020_enrollment_cocs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_enrollment_cocs
    ADD CONSTRAINT hmis_csv_2020_enrollment_cocs_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_enrollments hmis_csv_2020_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_enrollments
    ADD CONSTRAINT hmis_csv_2020_enrollments_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_events hmis_csv_2020_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_events
    ADD CONSTRAINT hmis_csv_2020_events_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_exits hmis_csv_2020_exits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_exits
    ADD CONSTRAINT hmis_csv_2020_exits_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_exports hmis_csv_2020_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_exports
    ADD CONSTRAINT hmis_csv_2020_exports_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_funders hmis_csv_2020_funders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_funders
    ADD CONSTRAINT hmis_csv_2020_funders_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_health_and_dvs hmis_csv_2020_health_and_dvs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_health_and_dvs
    ADD CONSTRAINT hmis_csv_2020_health_and_dvs_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_income_benefits hmis_csv_2020_income_benefits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_income_benefits
    ADD CONSTRAINT hmis_csv_2020_income_benefits_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_inventories hmis_csv_2020_inventories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_inventories
    ADD CONSTRAINT hmis_csv_2020_inventories_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_organizations hmis_csv_2020_organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_organizations
    ADD CONSTRAINT hmis_csv_2020_organizations_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_project_cocs hmis_csv_2020_project_cocs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_project_cocs
    ADD CONSTRAINT hmis_csv_2020_project_cocs_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_projects hmis_csv_2020_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_projects
    ADD CONSTRAINT hmis_csv_2020_projects_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_services hmis_csv_2020_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_services
    ADD CONSTRAINT hmis_csv_2020_services_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_2020_users hmis_csv_2020_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_2020_users
    ADD CONSTRAINT hmis_csv_2020_users_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_import_errors hmis_csv_import_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_import_errors
    ADD CONSTRAINT hmis_csv_import_errors_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_import_validations hmis_csv_import_validations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_import_validations
    ADD CONSTRAINT hmis_csv_import_validations_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_importer_logs hmis_csv_importer_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_importer_logs
    ADD CONSTRAINT hmis_csv_importer_logs_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_load_errors hmis_csv_load_errors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_load_errors
    ADD CONSTRAINT hmis_csv_load_errors_pkey PRIMARY KEY (id);


--
-- Name: hmis_csv_loader_logs hmis_csv_loader_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_csv_loader_logs
    ADD CONSTRAINT hmis_csv_loader_logs_pkey PRIMARY KEY (id);


--
-- Name: hmis_forms hmis_forms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_forms
    ADD CONSTRAINT hmis_forms_pkey PRIMARY KEY (id);


--
-- Name: hmis_import_configs hmis_import_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_import_configs
    ADD CONSTRAINT hmis_import_configs_pkey PRIMARY KEY (id);


--
-- Name: hmis_staff hmis_staff_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_staff
    ADD CONSTRAINT hmis_staff_pkey PRIMARY KEY (id);


--
-- Name: hmis_staff_x_clients hmis_staff_x_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_staff_x_clients
    ADD CONSTRAINT hmis_staff_x_clients_pkey PRIMARY KEY (id);


--
-- Name: homeless_summary_report_clients homeless_summary_report_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.homeless_summary_report_clients
    ADD CONSTRAINT homeless_summary_report_clients_pkey PRIMARY KEY (id);


--
-- Name: housing_resolution_plans housing_resolution_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.housing_resolution_plans
    ADD CONSTRAINT housing_resolution_plans_pkey PRIMARY KEY (id);


--
-- Name: hud_chronics hud_chronics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_chronics
    ADD CONSTRAINT hud_chronics_pkey PRIMARY KEY (id);


--
-- Name: hud_create_logs hud_create_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_create_logs
    ADD CONSTRAINT hud_create_logs_pkey PRIMARY KEY (id);


--
-- Name: hud_report_apr_ce_assessments hud_report_apr_ce_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_apr_ce_assessments
    ADD CONSTRAINT hud_report_apr_ce_assessments_pkey PRIMARY KEY (id);


--
-- Name: hud_report_apr_ce_events hud_report_apr_ce_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_apr_ce_events
    ADD CONSTRAINT hud_report_apr_ce_events_pkey PRIMARY KEY (id);


--
-- Name: hud_report_apr_clients hud_report_apr_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_apr_clients
    ADD CONSTRAINT hud_report_apr_clients_pkey PRIMARY KEY (id);


--
-- Name: hud_report_apr_living_situations hud_report_apr_living_situations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_apr_living_situations
    ADD CONSTRAINT hud_report_apr_living_situations_pkey PRIMARY KEY (id);


--
-- Name: hud_report_cells hud_report_cells_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_cells
    ADD CONSTRAINT hud_report_cells_pkey PRIMARY KEY (id);


--
-- Name: hud_report_dq_clients hud_report_dq_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_dq_clients
    ADD CONSTRAINT hud_report_dq_clients_pkey PRIMARY KEY (id);


--
-- Name: hud_report_dq_living_situations hud_report_dq_living_situations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_dq_living_situations
    ADD CONSTRAINT hud_report_dq_living_situations_pkey PRIMARY KEY (id);


--
-- Name: hud_report_instances hud_report_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_instances
    ADD CONSTRAINT hud_report_instances_pkey PRIMARY KEY (id);


--
-- Name: hud_report_path_clients hud_report_path_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_path_clients
    ADD CONSTRAINT hud_report_path_clients_pkey PRIMARY KEY (id);


--
-- Name: hud_report_spm_clients hud_report_spm_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_spm_clients
    ADD CONSTRAINT hud_report_spm_clients_pkey PRIMARY KEY (id);


--
-- Name: hud_report_universe_members hud_report_universe_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_report_universe_members
    ADD CONSTRAINT hud_report_universe_members_pkey PRIMARY KEY (id);


--
-- Name: identify_duplicates_log identify_duplicates_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identify_duplicates_log
    ADD CONSTRAINT identify_duplicates_log_pkey PRIMARY KEY (id);


--
-- Name: import_logs import_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_logs
    ADD CONSTRAINT import_logs_pkey PRIMARY KEY (id);


--
-- Name: income_benefits_report_clients income_benefits_report_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.income_benefits_report_clients
    ADD CONSTRAINT income_benefits_report_clients_pkey PRIMARY KEY (id);


--
-- Name: income_benefits_report_incomes income_benefits_report_incomes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.income_benefits_report_incomes
    ADD CONSTRAINT income_benefits_report_incomes_pkey PRIMARY KEY (id);


--
-- Name: income_benefits_reports income_benefits_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.income_benefits_reports
    ADD CONSTRAINT income_benefits_reports_pkey PRIMARY KEY (id);


--
-- Name: involved_in_imports involved_in_imports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.involved_in_imports
    ADD CONSTRAINT involved_in_imports_pkey PRIMARY KEY (id);


--
-- Name: lftp_s3_syncs lftp_s3_syncs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lftp_s3_syncs
    ADD CONSTRAINT lftp_s3_syncs_pkey PRIMARY KEY (id);


--
-- Name: lookups_ethnicities lookups_ethnicities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_ethnicities
    ADD CONSTRAINT lookups_ethnicities_pkey PRIMARY KEY (id);


--
-- Name: lookups_funding_sources lookups_funding_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_funding_sources
    ADD CONSTRAINT lookups_funding_sources_pkey PRIMARY KEY (id);


--
-- Name: lookups_genders lookups_genders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_genders
    ADD CONSTRAINT lookups_genders_pkey PRIMARY KEY (id);


--
-- Name: lookups_living_situations lookups_living_situations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_living_situations
    ADD CONSTRAINT lookups_living_situations_pkey PRIMARY KEY (id);


--
-- Name: lookups_project_types lookups_project_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_project_types
    ADD CONSTRAINT lookups_project_types_pkey PRIMARY KEY (id);


--
-- Name: lookups_relationships lookups_relationships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_relationships
    ADD CONSTRAINT lookups_relationships_pkey PRIMARY KEY (id);


--
-- Name: lookups_tracking_methods lookups_tracking_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_tracking_methods
    ADD CONSTRAINT lookups_tracking_methods_pkey PRIMARY KEY (id);


--
-- Name: lookups_yes_no_etcs lookups_yes_no_etcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lookups_yes_no_etcs
    ADD CONSTRAINT lookups_yes_no_etcs_pkey PRIMARY KEY (id);


--
-- Name: lsa_rds_state_logs lsa_rds_state_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lsa_rds_state_logs
    ADD CONSTRAINT lsa_rds_state_logs_pkey PRIMARY KEY (id);


--
-- Name: new_service_history new_service_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.new_service_history
    ADD CONSTRAINT new_service_history_pkey PRIMARY KEY (id);


--
-- Name: nightly_census_by_project_clients nightly_census_by_project_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nightly_census_by_project_clients
    ADD CONSTRAINT nightly_census_by_project_clients_pkey PRIMARY KEY (id);


--
-- Name: nightly_census_by_project_type_clients nightly_census_by_project_type_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nightly_census_by_project_type_clients
    ADD CONSTRAINT nightly_census_by_project_type_clients_pkey PRIMARY KEY (id);


--
-- Name: nightly_census_by_project_types nightly_census_by_project_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nightly_census_by_project_types
    ADD CONSTRAINT nightly_census_by_project_types_pkey PRIMARY KEY (id);


--
-- Name: nightly_census_by_projects nightly_census_by_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nightly_census_by_projects
    ADD CONSTRAINT nightly_census_by_projects_pkey PRIMARY KEY (id);


--
-- Name: non_hmis_uploads non_hmis_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.non_hmis_uploads
    ADD CONSTRAINT non_hmis_uploads_pkey PRIMARY KEY (id);


--
-- Name: performance_metrics_clients performance_metrics_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_metrics_clients
    ADD CONSTRAINT performance_metrics_clients_pkey PRIMARY KEY (id);


--
-- Name: project_data_quality project_data_quality_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_data_quality
    ADD CONSTRAINT project_data_quality_pkey PRIMARY KEY (id);


--
-- Name: project_groups project_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_groups
    ADD CONSTRAINT project_groups_pkey PRIMARY KEY (id);


--
-- Name: project_pass_fails_clients project_pass_fails_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_pass_fails_clients
    ADD CONSTRAINT project_pass_fails_clients_pkey PRIMARY KEY (id);


--
-- Name: project_pass_fails project_pass_fails_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_pass_fails
    ADD CONSTRAINT project_pass_fails_pkey PRIMARY KEY (id);


--
-- Name: project_pass_fails_projects project_pass_fails_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_pass_fails_projects
    ADD CONSTRAINT project_pass_fails_projects_pkey PRIMARY KEY (id);


--
-- Name: project_project_groups project_project_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_project_groups
    ADD CONSTRAINT project_project_groups_pkey PRIMARY KEY (id);


--
-- Name: project_scorecard_reports project_scorecard_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_scorecard_reports
    ADD CONSTRAINT project_scorecard_reports_pkey PRIMARY KEY (id);


--
-- Name: psc_feedback_surveys psc_feedback_surveys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.psc_feedback_surveys
    ADD CONSTRAINT psc_feedback_surveys_pkey PRIMARY KEY (id);


--
-- Name: public_report_reports public_report_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.public_report_reports
    ADD CONSTRAINT public_report_reports_pkey PRIMARY KEY (id);


--
-- Name: public_report_settings public_report_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.public_report_settings
    ADD CONSTRAINT public_report_settings_pkey PRIMARY KEY (id);


--
-- Name: recurring_hmis_export_links recurring_hmis_export_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurring_hmis_export_links
    ADD CONSTRAINT recurring_hmis_export_links_pkey PRIMARY KEY (id);


--
-- Name: recurring_hmis_exports recurring_hmis_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurring_hmis_exports
    ADD CONSTRAINT recurring_hmis_exports_pkey PRIMARY KEY (id);


--
-- Name: report_definitions report_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_definitions
    ADD CONSTRAINT report_definitions_pkey PRIMARY KEY (id);


--
-- Name: report_tokens report_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_tokens
    ADD CONSTRAINT report_tokens_pkey PRIMARY KEY (id);


--
-- Name: secure_files secure_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.secure_files
    ADD CONSTRAINT secure_files_pkey PRIMARY KEY (id);


--
-- Name: service_history_enrollments service_history_enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_enrollments
    ADD CONSTRAINT service_history_enrollments_pkey PRIMARY KEY (id);


--
-- Name: service_history_services service_history_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services
    ADD CONSTRAINT service_history_services_pkey PRIMARY KEY (id);


--
-- Name: service_scanning_scanner_ids service_scanning_scanner_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_scanning_scanner_ids
    ADD CONSTRAINT service_scanning_scanner_ids_pkey PRIMARY KEY (id);


--
-- Name: service_scanning_services service_scanning_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_scanning_services
    ADD CONSTRAINT service_scanning_services_pkey PRIMARY KEY (id);


--
-- Name: shape_block_groups shape_block_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shape_block_groups
    ADD CONSTRAINT shape_block_groups_pkey PRIMARY KEY (id);


--
-- Name: shape_cocs shape_cocs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shape_cocs
    ADD CONSTRAINT shape_cocs_pkey PRIMARY KEY (id);


--
-- Name: shape_counties shape_counties_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shape_counties
    ADD CONSTRAINT shape_counties_pkey PRIMARY KEY (id);


--
-- Name: shape_places shape_places_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shape_places
    ADD CONSTRAINT shape_places_pkey PRIMARY KEY (id);


--
-- Name: shape_states shape_states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shape_states
    ADD CONSTRAINT shape_states_pkey PRIMARY KEY (id);


--
-- Name: shape_towns shape_towns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shape_towns
    ADD CONSTRAINT shape_towns_pkey PRIMARY KEY (id);


--
-- Name: shape_zip_codes shape_zip_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shape_zip_codes
    ADD CONSTRAINT shape_zip_codes_pkey PRIMARY KEY (id);


--
-- Name: simple_report_cells simple_report_cells_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.simple_report_cells
    ADD CONSTRAINT simple_report_cells_pkey PRIMARY KEY (id);


--
-- Name: simple_report_instances simple_report_instances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.simple_report_instances
    ADD CONSTRAINT simple_report_instances_pkey PRIMARY KEY (id);


--
-- Name: simple_report_universe_members simple_report_universe_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.simple_report_universe_members
    ADD CONSTRAINT simple_report_universe_members_pkey PRIMARY KEY (id);


--
-- Name: synthetic_assessments synthetic_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.synthetic_assessments
    ADD CONSTRAINT synthetic_assessments_pkey PRIMARY KEY (id);


--
-- Name: synthetic_events synthetic_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.synthetic_events
    ADD CONSTRAINT synthetic_events_pkey PRIMARY KEY (id);


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
-- Name: talentlms_configs talentlms_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.talentlms_configs
    ADD CONSTRAINT talentlms_configs_pkey PRIMARY KEY (id);


--
-- Name: talentlms_logins talentlms_logins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.talentlms_logins
    ADD CONSTRAINT talentlms_logins_pkey PRIMARY KEY (id);


--
-- Name: text_message_messages text_message_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.text_message_messages
    ADD CONSTRAINT text_message_messages_pkey PRIMARY KEY (id);


--
-- Name: text_message_topic_subscribers text_message_topic_subscribers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.text_message_topic_subscribers
    ADD CONSTRAINT text_message_topic_subscribers_pkey PRIMARY KEY (id);


--
-- Name: text_message_topics text_message_topics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.text_message_topics
    ADD CONSTRAINT text_message_topics_pkey PRIMARY KEY (id);


--
-- Name: uploads uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uploads
    ADD CONSTRAINT uploads_pkey PRIMARY KEY (id);


--
-- Name: user_client_permissions user_client_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_client_permissions
    ADD CONSTRAINT user_client_permissions_pkey PRIMARY KEY (id);


--
-- Name: user_clients user_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_clients
    ADD CONSTRAINT user_clients_pkey PRIMARY KEY (id);


--
-- Name: user_viewable_entities user_viewable_entities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_viewable_entities
    ADD CONSTRAINT user_viewable_entities_pkey PRIMARY KEY (id);


--
-- Name: verification_sources verification_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verification_sources
    ADD CONSTRAINT verification_sources_pkey PRIMARY KEY (id);


--
-- Name: vispdats vispdats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vispdats
    ADD CONSTRAINT vispdats_pkey PRIMARY KEY (id);


--
-- Name: warehouse_client_service_history warehouse_client_service_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_client_service_history
    ADD CONSTRAINT warehouse_client_service_history_pkey PRIMARY KEY (id);


--
-- Name: warehouse_clients warehouse_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_clients
    ADD CONSTRAINT warehouse_clients_pkey PRIMARY KEY (id);


--
-- Name: warehouse_clients_processed warehouse_clients_processed_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_clients_processed
    ADD CONSTRAINT warehouse_clients_processed_pkey PRIMARY KEY (id);


--
-- Name: warehouse_reports warehouse_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_reports
    ADD CONSTRAINT warehouse_reports_pkey PRIMARY KEY (id);


--
-- Name: weather weather_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.weather
    ADD CONSTRAINT weather_pkey PRIMARY KEY (id);


--
-- Name: whitelisted_projects_for_clients whitelisted_projects_for_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.whitelisted_projects_for_clients
    ADD CONSTRAINT whitelisted_projects_for_clients_pkey PRIMARY KEY (id);


--
-- Name: youth_case_managements youth_case_managements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.youth_case_managements
    ADD CONSTRAINT youth_case_managements_pkey PRIMARY KEY (id);


--
-- Name: youth_exports youth_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.youth_exports
    ADD CONSTRAINT youth_exports_pkey PRIMARY KEY (id);


--
-- Name: youth_follow_ups youth_follow_ups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.youth_follow_ups
    ADD CONSTRAINT youth_follow_ups_pkey PRIMARY KEY (id);


--
-- Name: youth_intakes youth_intakes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.youth_intakes
    ADD CONSTRAINT youth_intakes_pkey PRIMARY KEY (id);


--
-- Name: youth_referrals youth_referrals_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.youth_referrals
    ADD CONSTRAINT youth_referrals_pkey PRIMARY KEY (id);


--
-- Name: ClientUnencrypted_DateCreated_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ClientUnencrypted_DateCreated_idx" ON public."ClientUnencrypted" USING btree ("DateCreated");


--
-- Name: ClientUnencrypted_DateDeleted_data_source_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ClientUnencrypted_DateDeleted_data_source_id_idx" ON public."ClientUnencrypted" USING btree ("DateDeleted", data_source_id);


--
-- Name: ClientUnencrypted_DateUpdated_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ClientUnencrypted_DateUpdated_idx" ON public."ClientUnencrypted" USING btree ("DateUpdated");


--
-- Name: ClientUnencrypted_ExportID_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ClientUnencrypted_ExportID_idx" ON public."ClientUnencrypted" USING btree ("ExportID");


--
-- Name: ClientUnencrypted_FirstName_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ClientUnencrypted_FirstName_idx" ON public."ClientUnencrypted" USING btree ("FirstName");


--
-- Name: ClientUnencrypted_LastName_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ClientUnencrypted_LastName_idx" ON public."ClientUnencrypted" USING btree ("LastName");


--
-- Name: ClientUnencrypted_PersonalID_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ClientUnencrypted_PersonalID_idx" ON public."ClientUnencrypted" USING btree ("PersonalID");


--
-- Name: ClientUnencrypted_creator_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ClientUnencrypted_creator_id_idx" ON public."ClientUnencrypted" USING btree (creator_id);


--
-- Name: ClientUnencrypted_data_source_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ClientUnencrypted_data_source_id_idx" ON public."ClientUnencrypted" USING btree (data_source_id);


--
-- Name: ClientUnencrypted_pending_date_deleted_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ClientUnencrypted_pending_date_deleted_idx" ON public."ClientUnencrypted" USING btree (pending_date_deleted);


--
-- Name: Disabilities_DateDeleted_data_source_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Disabilities_DateDeleted_data_source_id_idx" ON public."Disabilities" USING btree ("DateDeleted", data_source_id) WHERE ("DateDeleted" IS NULL);


--
-- Name: Disabilities_DateDeleted_data_source_id_idx1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Disabilities_DateDeleted_data_source_id_idx1" ON public."Disabilities" USING btree ("DateDeleted", data_source_id) WHERE ("DateDeleted" IS NULL);


--
-- Name: Disabilities_DateDeleted_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "Disabilities_DateDeleted_idx" ON public."Disabilities" USING btree ("DateDeleted") WHERE ("DateDeleted" IS NULL);


--
-- Name: IncomeBenefits_DateDeleted_data_source_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IncomeBenefits_DateDeleted_data_source_id_idx" ON public."IncomeBenefits" USING btree ("DateDeleted", data_source_id) WHERE ("DateDeleted" IS NULL);


--
-- Name: IncomeBenefits_DateDeleted_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IncomeBenefits_DateDeleted_idx" ON public."IncomeBenefits" USING btree ("DateDeleted") WHERE ("DateDeleted" IS NULL);


--
-- Name: IncomeBenefits_data_source_id_DateDeleted_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "IncomeBenefits_data_source_id_DateDeleted_idx" ON public."IncomeBenefits" USING btree (data_source_id, "DateDeleted") WHERE ("DateDeleted" IS NULL);


--
-- Name: affiliation_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX affiliation_date_created ON public."Affiliation" USING btree ("DateCreated");


--
-- Name: affiliation_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX affiliation_date_updated ON public."Affiliation" USING btree ("DateUpdated");


--
-- Name: affiliation_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX affiliation_export_id ON public."Affiliation" USING btree ("ExportID");


--
-- Name: apr_client_conflict_columns; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX apr_client_conflict_columns ON public.hud_report_apr_clients USING btree (client_id, data_source_id, report_instance_id);


--
-- Name: aq_aq_id_ds_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX aq_aq_id_ds_id ON public."AssessmentQuestions" USING btree ("AssessmentQuestionID", data_source_id);


--
-- Name: ar_ar_id_ds_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ar_ar_id_ds_id ON public."AssessmentResults" USING btree ("AssessmentResultID", data_source_id);


--
-- Name: assessment_p_id_en_id_ds_id_a_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assessment_p_id_en_id_ds_id_a_id ON public."Assessment" USING btree ("PersonalID", "EnrollmentID", data_source_id, "AssessmentID");


--
-- Name: assessment_q_a_id_ds_id_p_id_en_id_aq_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assessment_q_a_id_ds_id_p_id_en_id_aq_id ON public."AssessmentQuestions" USING btree ("AssessmentID", data_source_id, "PersonalID", "EnrollmentID", "AssessmentQuestionID");


--
-- Name: assessment_r_a_id_ds_id_p_id_en_id_ar_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assessment_r_a_id_ds_id_p_id_en_id_ar_id ON public."AssessmentResults" USING btree ("AssessmentID", data_source_id, "PersonalID", "EnrollmentID", "AssessmentResultID");


--
-- Name: client_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_date_created ON public."Client" USING btree ("DateCreated");


--
-- Name: client_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_date_updated ON public."Client" USING btree ("DateUpdated");


--
-- Name: client_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_export_id ON public."Client" USING btree ("ExportID");


--
-- Name: client_first_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_first_name ON public."Client" USING btree ("FirstName");


--
-- Name: client_id_rsh_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_id_rsh_index ON public.recent_service_history USING btree (client_id);


--
-- Name: client_last_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_last_name ON public."Client" USING btree ("LastName");


--
-- Name: client_personal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_personal_id ON public."Client" USING btree ("PersonalID");


--
-- Name: computed_project_type_rsh_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX computed_project_type_rsh_index ON public.recent_service_history USING btree (computed_project_type);


--
-- Name: cur_liv_sit_cur_id_ds_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cur_liv_sit_cur_id_ds_id ON public."CurrentLivingSituation" USING btree ("CurrentLivingSitID", data_source_id);


--
-- Name: cur_liv_sit_p_id_en_id_ds_id_cur_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX cur_liv_sit_p_id_en_id_ds_id_cur_id ON public."CurrentLivingSituation" USING btree ("PersonalID", "EnrollmentID", data_source_id, "CurrentLivingSitID");


--
-- Name: cur_liv_sit_sit_id_ds_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX cur_liv_sit_sit_id_ds_id ON public."CurrentLivingSituation" USING btree ("CurrentLivingSitID", data_source_id);


--
-- Name: date_rsh_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX date_rsh_index ON public.recent_service_history USING btree (date);


--
-- Name: disabilities_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX disabilities_date_created ON public."Disabilities" USING btree ("DateCreated");


--
-- Name: disabilities_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX disabilities_date_updated ON public."Disabilities" USING btree ("DateUpdated");


--
-- Name: disabilities_disability_type_response_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX disabilities_disability_type_response_idx ON public."Disabilities" USING btree ("DisabilityType", "DisabilityResponse", "InformationDate", "PersonalID", "EnrollmentID", "DateDeleted");


--
-- Name: disabilities_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX disabilities_export_id ON public."Disabilities" USING btree ("ExportID");


--
-- Name: dq_client_conflict_columns; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX dq_client_conflict_columns ON public.hud_report_dq_clients USING btree (client_id, data_source_id, report_instance_id);


--
-- Name: ee_ee_id_ds_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ee_ee_id_ds_id ON public."EmploymentEducation" USING btree ("EmploymentEducationID", data_source_id);


--
-- Name: employment_education_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX employment_education_date_created ON public."EmploymentEducation" USING btree ("DateCreated");


--
-- Name: employment_education_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX employment_education_date_updated ON public."EmploymentEducation" USING btree ("DateUpdated");


--
-- Name: employment_education_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX employment_education_export_id ON public."EmploymentEducation" USING btree ("ExportID");


--
-- Name: en_en_id_p_id_ds_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX en_en_id_p_id_ds_id ON public."Enrollment" USING btree ("EnrollmentID", "PersonalID", data_source_id);


--
-- Name: enrollment_coc_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enrollment_coc_date_created ON public."EnrollmentCoC" USING btree ("DateCreated");


--
-- Name: enrollment_coc_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enrollment_coc_date_updated ON public."EnrollmentCoC" USING btree ("DateUpdated");


--
-- Name: enrollment_coc_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enrollment_coc_export_id ON public."EnrollmentCoC" USING btree ("ExportID");


--
-- Name: enrollment_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enrollment_date_created ON public."Enrollment" USING btree ("DateCreated");


--
-- Name: enrollment_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enrollment_date_updated ON public."Enrollment" USING btree ("DateUpdated");


--
-- Name: enrollment_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enrollment_export_id ON public."Enrollment" USING btree ("ExportID");


--
-- Name: ev_ev_id_ds_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ev_ev_id_ds_id ON public."Event" USING btree ("EventID", data_source_id);


--
-- Name: event_ds_id_p_id_en_id_ev_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX event_ds_id_p_id_en_id_ev_id ON public."Event" USING btree (data_source_id, "PersonalID", "EnrollmentID", "EventID");


--
-- Name: exit_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX exit_date_created ON public."Exit" USING btree ("DateCreated");


--
-- Name: exit_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX exit_date_updated ON public."Exit" USING btree ("DateUpdated");


--
-- Name: exit_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX exit_export_id ON public."Exit" USING btree ("ExportID");


--
-- Name: export_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX export_export_id ON public."Export" USING btree ("ExportID");


--
-- Name: funder_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX funder_date_created ON public."Funder" USING btree ("DateCreated");


--
-- Name: funder_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX funder_date_updated ON public."Funder" USING btree ("DateUpdated");


--
-- Name: funder_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX funder_export_id ON public."Funder" USING btree ("ExportID");


--
-- Name: health_and_dv_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX health_and_dv_date_created ON public."HealthAndDV" USING btree ("DateCreated");


--
-- Name: health_and_dv_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX health_and_dv_date_updated ON public."HealthAndDV" USING btree ("DateUpdated");


--
-- Name: health_and_dv_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX health_and_dv_export_id ON public."HealthAndDV" USING btree ("ExportID");


--
-- Name: hmis_2020_affiliations-jXFa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_affiliations-jXFa" ON public.hmis_2020_affiliations USING btree (source_type, source_id);


--
-- Name: hmis_2020_affiliations-lZaj; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_affiliations-lZaj" ON public.hmis_2020_affiliations USING btree ("AffiliationID", data_source_id);


--
-- Name: hmis_2020_affiliations-qycr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_affiliations-qycr" ON public.hmis_2020_affiliations USING btree ("ExportID");


--
-- Name: hmis_2020_agg_enrollments_p_id_p_id_ds_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX hmis_2020_agg_enrollments_p_id_p_id_ds_id ON public.hmis_2020_aggregated_enrollments USING btree ("PersonalID", "ProjectID", data_source_id);


--
-- Name: hmis_2020_aggregated_enrollments-0cTv; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "hmis_2020_aggregated_enrollments-0cTv" ON public.hmis_2020_aggregated_enrollments USING btree ("EnrollmentID", "PersonalID", data_source_id);


--
-- Name: hmis_2020_aggregated_enrollments-4L8g; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-4L8g" ON public.hmis_2020_aggregated_enrollments USING btree ("DateUpdated");


--
-- Name: hmis_2020_aggregated_enrollments-6wqk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-6wqk" ON public.hmis_2020_aggregated_enrollments USING btree ("DateDeleted");


--
-- Name: hmis_2020_aggregated_enrollments-BMfj; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-BMfj" ON public.hmis_2020_aggregated_enrollments USING btree ("ProjectID", "HouseholdID");


--
-- Name: hmis_2020_aggregated_enrollments-CpSq; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-CpSq" ON public.hmis_2020_aggregated_enrollments USING btree ("ProjectID");


--
-- Name: hmis_2020_aggregated_enrollments-E6ih; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-E6ih" ON public.hmis_2020_aggregated_enrollments USING btree ("RelationshipToHoH");


--
-- Name: hmis_2020_aggregated_enrollments-G7U1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-G7U1" ON public.hmis_2020_aggregated_enrollments USING btree (source_type, source_id);


--
-- Name: hmis_2020_aggregated_enrollments-Jmkq; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-Jmkq" ON public.hmis_2020_aggregated_enrollments USING btree ("DateCreated");


--
-- Name: hmis_2020_aggregated_enrollments-QV2G; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-QV2G" ON public.hmis_2020_aggregated_enrollments USING btree ("HouseholdID");


--
-- Name: hmis_2020_aggregated_enrollments-RJNU; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-RJNU" ON public.hmis_2020_aggregated_enrollments USING btree ("ProjectID", "RelationshipToHoH");


--
-- Name: hmis_2020_aggregated_enrollments-RNSl; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-RNSl" ON public.hmis_2020_aggregated_enrollments USING btree ("EnrollmentID");


--
-- Name: hmis_2020_aggregated_enrollments-Xqsk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-Xqsk" ON public.hmis_2020_aggregated_enrollments USING btree ("PreviousStreetESSH", "LengthOfStay");


--
-- Name: hmis_2020_aggregated_enrollments-ZGm4; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-ZGm4" ON public.hmis_2020_aggregated_enrollments USING btree ("TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears");


--
-- Name: hmis_2020_aggregated_enrollments-fSDc; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "hmis_2020_aggregated_enrollments-fSDc" ON public.hmis_2020_aggregated_enrollments USING btree ("EnrollmentID", "PersonalID", importer_log_id, data_source_id);


--
-- Name: hmis_2020_aggregated_enrollments-fXAB; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-fXAB" ON public.hmis_2020_aggregated_enrollments USING btree ("ExportID");


--
-- Name: hmis_2020_aggregated_enrollments-ocKA; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-ocKA" ON public.hmis_2020_aggregated_enrollments USING btree ("EnrollmentID", "PersonalID");


--
-- Name: hmis_2020_aggregated_enrollments-oiEU; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-oiEU" ON public.hmis_2020_aggregated_enrollments USING btree ("EntryDate");


--
-- Name: hmis_2020_aggregated_enrollments-wnDD; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-wnDD" ON public.hmis_2020_aggregated_enrollments USING btree ("PersonalID");


--
-- Name: hmis_2020_aggregated_enrollments-ysoO; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-ysoO" ON public.hmis_2020_aggregated_enrollments USING btree ("LivingSituation");


--
-- Name: hmis_2020_aggregated_enrollments-zNVo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_enrollments-zNVo" ON public.hmis_2020_aggregated_enrollments USING btree ("EnrollmentID", "ProjectID", "EntryDate");


--
-- Name: hmis_2020_aggregated_exits-2lOR; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_exits-2lOR" ON public.hmis_2020_aggregated_exits USING btree ("DateCreated");


--
-- Name: hmis_2020_aggregated_exits-2mwI; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "hmis_2020_aggregated_exits-2mwI" ON public.hmis_2020_aggregated_exits USING btree ("ExitID", importer_log_id, data_source_id);


--
-- Name: hmis_2020_aggregated_exits-BwSf; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_exits-BwSf" ON public.hmis_2020_aggregated_exits USING btree ("EnrollmentID");


--
-- Name: hmis_2020_aggregated_exits-EPOP; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_exits-EPOP" ON public.hmis_2020_aggregated_exits USING btree ("PersonalID");


--
-- Name: hmis_2020_aggregated_exits-GBBG; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_exits-GBBG" ON public.hmis_2020_aggregated_exits USING btree ("ExitDate");


--
-- Name: hmis_2020_aggregated_exits-SgMf; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_exits-SgMf" ON public.hmis_2020_aggregated_exits USING btree (source_type, source_id);


--
-- Name: hmis_2020_aggregated_exits-UYdB; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "hmis_2020_aggregated_exits-UYdB" ON public.hmis_2020_aggregated_exits USING btree ("ExitID", data_source_id);


--
-- Name: hmis_2020_aggregated_exits-VRGa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_exits-VRGa" ON public.hmis_2020_aggregated_exits USING btree ("DateUpdated");


--
-- Name: hmis_2020_aggregated_exits-auds; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_exits-auds" ON public.hmis_2020_aggregated_exits USING btree ("ExportID");


--
-- Name: hmis_2020_aggregated_exits-cduB; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_exits-cduB" ON public.hmis_2020_aggregated_exits USING btree ("DateDeleted");


--
-- Name: hmis_2020_aggregated_exits-g6y1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_aggregated_exits-g6y1" ON public.hmis_2020_aggregated_exits USING btree ("ExitID");


--
-- Name: hmis_2020_assessment_questions-0oMf; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_assessment_questions-0oMf" ON public.hmis_2020_assessment_questions USING btree ("AssessmentQuestionID", data_source_id);


--
-- Name: hmis_2020_assessment_questions-fD1j; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_assessment_questions-fD1j" ON public.hmis_2020_assessment_questions USING btree ("AssessmentID");


--
-- Name: hmis_2020_assessment_questions-gVG2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_assessment_questions-gVG2" ON public.hmis_2020_assessment_questions USING btree (source_type, source_id);


--
-- Name: hmis_2020_assessment_questions-sDob; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_assessment_questions-sDob" ON public.hmis_2020_assessment_questions USING btree ("ExportID");


--
-- Name: hmis_2020_assessment_results-2kxY; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_assessment_results-2kxY" ON public.hmis_2020_assessment_results USING btree ("ExportID");


--
-- Name: hmis_2020_assessment_results-AnQd; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_assessment_results-AnQd" ON public.hmis_2020_assessment_results USING btree ("AssessmentID");


--
-- Name: hmis_2020_assessment_results-CKgC; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_assessment_results-CKgC" ON public.hmis_2020_assessment_results USING btree (source_type, source_id);


--
-- Name: hmis_2020_assessment_results-rawc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_assessment_results-rawc" ON public.hmis_2020_assessment_results USING btree ("AssessmentResultID", data_source_id);


--
-- Name: hmis_2020_assessments-3sM0; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_assessments-3sM0" ON public.hmis_2020_assessments USING btree ("AssessmentID", data_source_id);


--
-- Name: hmis_2020_assessments-B1tS; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_assessments-B1tS" ON public.hmis_2020_assessments USING btree (source_type, source_id);


--
-- Name: hmis_2020_assessments-YW8L; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_assessments-YW8L" ON public.hmis_2020_assessments USING btree ("AssessmentDate");


--
-- Name: hmis_2020_assessments-gMUw; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_assessments-gMUw" ON public.hmis_2020_assessments USING btree ("EnrollmentID");


--
-- Name: hmis_2020_assessments-kdgA; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_assessments-kdgA" ON public.hmis_2020_assessments USING btree ("PersonalID");


--
-- Name: hmis_2020_assessments-kqMe; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_assessments-kqMe" ON public.hmis_2020_assessments USING btree ("AssessmentID");


--
-- Name: hmis_2020_assessments-u0eq; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_assessments-u0eq" ON public.hmis_2020_assessments USING btree ("ExportID");


--
-- Name: hmis_2020_clients-3vTw; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_clients-3vTw" ON public.hmis_2020_clients USING btree ("LastName");


--
-- Name: hmis_2020_clients-48Qj; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_clients-48Qj" ON public.hmis_2020_clients USING btree ("FirstName");


--
-- Name: hmis_2020_clients-VRsB; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_clients-VRsB" ON public.hmis_2020_clients USING btree (source_type, source_id);


--
-- Name: hmis_2020_clients-gmgS; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_clients-gmgS" ON public.hmis_2020_clients USING btree ("ExportID");


--
-- Name: hmis_2020_clients-jdcP; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_clients-jdcP" ON public.hmis_2020_clients USING btree ("DateUpdated");


--
-- Name: hmis_2020_clients-qK9d; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_clients-qK9d" ON public.hmis_2020_clients USING btree ("PersonalID");


--
-- Name: hmis_2020_clients-qUjP; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_clients-qUjP" ON public.hmis_2020_clients USING btree ("DOB");


--
-- Name: hmis_2020_clients-rrgI; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_clients-rrgI" ON public.hmis_2020_clients USING btree ("DateCreated");


--
-- Name: hmis_2020_clients-t6qe; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_clients-t6qe" ON public.hmis_2020_clients USING btree ("PersonalID", data_source_id);


--
-- Name: hmis_2020_clients-z1iL; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_clients-z1iL" ON public.hmis_2020_clients USING btree ("VeteranStatus");


--
-- Name: hmis_2020_current_living_situations-4v4L; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_current_living_situations-4v4L" ON public.hmis_2020_current_living_situations USING btree ("InformationDate");


--
-- Name: hmis_2020_current_living_situations-DXZ0; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_current_living_situations-DXZ0" ON public.hmis_2020_current_living_situations USING btree ("CurrentLivingSitID");


--
-- Name: hmis_2020_current_living_situations-WmJZ; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_current_living_situations-WmJZ" ON public.hmis_2020_current_living_situations USING btree ("CurrentLivingSituation");


--
-- Name: hmis_2020_current_living_situations-cLpS; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_current_living_situations-cLpS" ON public.hmis_2020_current_living_situations USING btree ("CurrentLivingSitID", data_source_id);


--
-- Name: hmis_2020_current_living_situations-hGfj; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_current_living_situations-hGfj" ON public.hmis_2020_current_living_situations USING btree ("ExportID");


--
-- Name: hmis_2020_current_living_situations-jG8y; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_current_living_situations-jG8y" ON public.hmis_2020_current_living_situations USING btree ("EnrollmentID");


--
-- Name: hmis_2020_current_living_situations-qbbx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_current_living_situations-qbbx" ON public.hmis_2020_current_living_situations USING btree (source_type, source_id);


--
-- Name: hmis_2020_current_living_situations-vWt4; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_current_living_situations-vWt4" ON public.hmis_2020_current_living_situations USING btree ("PersonalID");


--
-- Name: hmis_2020_disabilities-1JPN; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_disabilities-1JPN" ON public.hmis_2020_disabilities USING btree ("EnrollmentID");


--
-- Name: hmis_2020_disabilities-2lYA; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_disabilities-2lYA" ON public.hmis_2020_disabilities USING btree ("PersonalID");


--
-- Name: hmis_2020_disabilities-8DFL; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_disabilities-8DFL" ON public.hmis_2020_disabilities USING btree ("DisabilitiesID");


--
-- Name: hmis_2020_disabilities-DA3C; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_disabilities-DA3C" ON public.hmis_2020_disabilities USING btree ("DisabilitiesID", data_source_id);


--
-- Name: hmis_2020_disabilities-G1Z0; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_disabilities-G1Z0" ON public.hmis_2020_disabilities USING btree ("ExportID");


--
-- Name: hmis_2020_disabilities-oxMH; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_disabilities-oxMH" ON public.hmis_2020_disabilities USING btree ("DateUpdated");


--
-- Name: hmis_2020_disabilities-p0j2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_disabilities-p0j2" ON public.hmis_2020_disabilities USING btree ("DateCreated");


--
-- Name: hmis_2020_disabilities-zFRZ; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_disabilities-zFRZ" ON public.hmis_2020_disabilities USING btree (source_type, source_id);


--
-- Name: hmis_2020_employment_educations-EPrc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_employment_educations-EPrc" ON public.hmis_2020_employment_educations USING btree ("PersonalID");


--
-- Name: hmis_2020_employment_educations-Hv6e; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_employment_educations-Hv6e" ON public.hmis_2020_employment_educations USING btree ("EmploymentEducationID");


--
-- Name: hmis_2020_employment_educations-mSvG; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_employment_educations-mSvG" ON public.hmis_2020_employment_educations USING btree ("EnrollmentID");


--
-- Name: hmis_2020_employment_educations-oPbl; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_employment_educations-oPbl" ON public.hmis_2020_employment_educations USING btree ("DateCreated");


--
-- Name: hmis_2020_employment_educations-rTDS; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_employment_educations-rTDS" ON public.hmis_2020_employment_educations USING btree ("DateUpdated");


--
-- Name: hmis_2020_employment_educations-rxeE; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_employment_educations-rxeE" ON public.hmis_2020_employment_educations USING btree (source_type, source_id);


--
-- Name: hmis_2020_employment_educations-uCTm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_employment_educations-uCTm" ON public.hmis_2020_employment_educations USING btree ("ExportID");


--
-- Name: hmis_2020_employment_educations-zM3A; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_employment_educations-zM3A" ON public.hmis_2020_employment_educations USING btree ("EmploymentEducationID", data_source_id);


--
-- Name: hmis_2020_enrollment_cocs-5FMZ; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollment_cocs-5FMZ" ON public.hmis_2020_enrollment_cocs USING btree ("PersonalID");


--
-- Name: hmis_2020_enrollment_cocs-5ROz; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollment_cocs-5ROz" ON public.hmis_2020_enrollment_cocs USING btree ("CoCCode");


--
-- Name: hmis_2020_enrollment_cocs-6ENr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollment_cocs-6ENr" ON public.hmis_2020_enrollment_cocs USING btree ("EnrollmentCoCID");


--
-- Name: hmis_2020_enrollment_cocs-6Mre; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollment_cocs-6Mre" ON public.hmis_2020_enrollment_cocs USING btree ("DateUpdated");


--
-- Name: hmis_2020_enrollment_cocs-GUQA; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollment_cocs-GUQA" ON public.hmis_2020_enrollment_cocs USING btree ("DateDeleted");


--
-- Name: hmis_2020_enrollment_cocs-LilW; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollment_cocs-LilW" ON public.hmis_2020_enrollment_cocs USING btree ("EnrollmentCoCID", data_source_id);


--
-- Name: hmis_2020_enrollment_cocs-Se2O; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollment_cocs-Se2O" ON public.hmis_2020_enrollment_cocs USING btree (source_type, source_id);


--
-- Name: hmis_2020_enrollment_cocs-gQJA; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollment_cocs-gQJA" ON public.hmis_2020_enrollment_cocs USING btree ("EnrollmentID");


--
-- Name: hmis_2020_enrollment_cocs-sVGW; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollment_cocs-sVGW" ON public.hmis_2020_enrollment_cocs USING btree ("ExportID");


--
-- Name: hmis_2020_enrollment_cocs-zikd; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollment_cocs-zikd" ON public.hmis_2020_enrollment_cocs USING btree ("DateCreated");


--
-- Name: hmis_2020_enrollments-3NkS; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-3NkS" ON public.hmis_2020_enrollments USING btree (source_type, source_id);


--
-- Name: hmis_2020_enrollments-6ZYF; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-6ZYF" ON public.hmis_2020_enrollments USING btree ("EntryDate");


--
-- Name: hmis_2020_enrollments-8tOj; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-8tOj" ON public.hmis_2020_enrollments USING btree ("ProjectID", "HouseholdID");


--
-- Name: hmis_2020_enrollments-9mEF; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-9mEF" ON public.hmis_2020_enrollments USING btree ("TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears");


--
-- Name: hmis_2020_enrollments-HNd8; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-HNd8" ON public.hmis_2020_enrollments USING btree ("ProjectID", "RelationshipToHoH");


--
-- Name: hmis_2020_enrollments-Io4W; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-Io4W" ON public.hmis_2020_enrollments USING btree ("LivingSituation");


--
-- Name: hmis_2020_enrollments-Qd6d; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-Qd6d" ON public.hmis_2020_enrollments USING btree ("EnrollmentID", "ProjectID", "EntryDate");


--
-- Name: hmis_2020_enrollments-UM6y; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-UM6y" ON public.hmis_2020_enrollments USING btree ("PersonalID");


--
-- Name: hmis_2020_enrollments-UrCS; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-UrCS" ON public.hmis_2020_enrollments USING btree ("EnrollmentID");


--
-- Name: hmis_2020_enrollments-WHri; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-WHri" ON public.hmis_2020_enrollments USING btree ("DateDeleted");


--
-- Name: hmis_2020_enrollments-ZK9t; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-ZK9t" ON public.hmis_2020_enrollments USING btree ("DateCreated");


--
-- Name: hmis_2020_enrollments-dRUc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-dRUc" ON public.hmis_2020_enrollments USING btree ("EnrollmentID", data_source_id);


--
-- Name: hmis_2020_enrollments-dn8l; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-dn8l" ON public.hmis_2020_enrollments USING btree ("ProjectID");


--
-- Name: hmis_2020_enrollments-hQVn; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-hQVn" ON public.hmis_2020_enrollments USING btree ("DateUpdated");


--
-- Name: hmis_2020_enrollments-kIRP; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-kIRP" ON public.hmis_2020_enrollments USING btree ("PreviousStreetESSH", "LengthOfStay");


--
-- Name: hmis_2020_enrollments-kzx7; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-kzx7" ON public.hmis_2020_enrollments USING btree ("ExportID");


--
-- Name: hmis_2020_enrollments-xB0L; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-xB0L" ON public.hmis_2020_enrollments USING btree ("EnrollmentID", "PersonalID");


--
-- Name: hmis_2020_enrollments-xiJ6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-xiJ6" ON public.hmis_2020_enrollments USING btree ("HouseholdID");


--
-- Name: hmis_2020_enrollments-y1wr; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_enrollments-y1wr" ON public.hmis_2020_enrollments USING btree ("RelationshipToHoH");


--
-- Name: hmis_2020_events-5Ulw; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_events-5Ulw" ON public.hmis_2020_events USING btree ("EventID", data_source_id);


--
-- Name: hmis_2020_events-SY9T; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_events-SY9T" ON public.hmis_2020_events USING btree ("EventDate");


--
-- Name: hmis_2020_events-chRs; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_events-chRs" ON public.hmis_2020_events USING btree ("ExportID");


--
-- Name: hmis_2020_events-ej4z; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_events-ej4z" ON public.hmis_2020_events USING btree ("EnrollmentID");


--
-- Name: hmis_2020_events-h86C; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_events-h86C" ON public.hmis_2020_events USING btree ("EventID");


--
-- Name: hmis_2020_events-sFna; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_events-sFna" ON public.hmis_2020_events USING btree ("PersonalID");


--
-- Name: hmis_2020_events-ztpH; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_events-ztpH" ON public.hmis_2020_events USING btree (source_type, source_id);


--
-- Name: hmis_2020_exits-4DnO; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_exits-4DnO" ON public.hmis_2020_exits USING btree ("ExitID");


--
-- Name: hmis_2020_exits-Crsu; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_exits-Crsu" ON public.hmis_2020_exits USING btree ("DateUpdated");


--
-- Name: hmis_2020_exits-F305; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_exits-F305" ON public.hmis_2020_exits USING btree ("DateCreated");


--
-- Name: hmis_2020_exits-QkLT; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_exits-QkLT" ON public.hmis_2020_exits USING btree ("PersonalID");


--
-- Name: hmis_2020_exits-S9yO; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_exits-S9yO" ON public.hmis_2020_exits USING btree ("ExitID", data_source_id);


--
-- Name: hmis_2020_exits-Z3F6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_exits-Z3F6" ON public.hmis_2020_exits USING btree ("EnrollmentID");


--
-- Name: hmis_2020_exits-c4Un; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_exits-c4Un" ON public.hmis_2020_exits USING btree ("ExportID");


--
-- Name: hmis_2020_exits-dozv; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_exits-dozv" ON public.hmis_2020_exits USING btree (source_type, source_id);


--
-- Name: hmis_2020_exits-nEjV; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_exits-nEjV" ON public.hmis_2020_exits USING btree ("ExitDate");


--
-- Name: hmis_2020_exits-s54g; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_exits-s54g" ON public.hmis_2020_exits USING btree ("DateDeleted");


--
-- Name: hmis_2020_exports-5gdY; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_exports-5gdY" ON public.hmis_2020_exports USING btree (source_type, source_id);


--
-- Name: hmis_2020_exports-YcvP; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_exports-YcvP" ON public.hmis_2020_exports USING btree ("ExportID", data_source_id);


--
-- Name: hmis_2020_exports-awLV; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_exports-awLV" ON public.hmis_2020_exports USING btree ("ExportID");


--
-- Name: hmis_2020_funders-CQE4; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_funders-CQE4" ON public.hmis_2020_funders USING btree ("DateCreated");


--
-- Name: hmis_2020_funders-P3hw; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_funders-P3hw" ON public.hmis_2020_funders USING btree ("FunderID");


--
-- Name: hmis_2020_funders-Srvd; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_funders-Srvd" ON public.hmis_2020_funders USING btree (source_type, source_id);


--
-- Name: hmis_2020_funders-XiWW; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_funders-XiWW" ON public.hmis_2020_funders USING btree ("FunderID", data_source_id);


--
-- Name: hmis_2020_funders-qRxb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_funders-qRxb" ON public.hmis_2020_funders USING btree ("ExportID");


--
-- Name: hmis_2020_funders-yKF3; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_funders-yKF3" ON public.hmis_2020_funders USING btree ("DateUpdated");


--
-- Name: hmis_2020_health_and_dvs-85bD; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_health_and_dvs-85bD" ON public.hmis_2020_health_and_dvs USING btree ("DateCreated");


--
-- Name: hmis_2020_health_and_dvs-Ha57; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_health_and_dvs-Ha57" ON public.hmis_2020_health_and_dvs USING btree (source_type, source_id);


--
-- Name: hmis_2020_health_and_dvs-Kqiz; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_health_and_dvs-Kqiz" ON public.hmis_2020_health_and_dvs USING btree ("PersonalID");


--
-- Name: hmis_2020_health_and_dvs-SbP4; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_health_and_dvs-SbP4" ON public.hmis_2020_health_and_dvs USING btree ("EnrollmentID");


--
-- Name: hmis_2020_health_and_dvs-TUTe; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_health_and_dvs-TUTe" ON public.hmis_2020_health_and_dvs USING btree ("DateUpdated");


--
-- Name: hmis_2020_health_and_dvs-w4jj; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_health_and_dvs-w4jj" ON public.hmis_2020_health_and_dvs USING btree ("ExportID");


--
-- Name: hmis_2020_health_and_dvs-zE81; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_health_and_dvs-zE81" ON public.hmis_2020_health_and_dvs USING btree ("HealthAndDVID");


--
-- Name: hmis_2020_health_and_dvs-zonF; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_health_and_dvs-zonF" ON public.hmis_2020_health_and_dvs USING btree ("HealthAndDVID", data_source_id);


--
-- Name: hmis_2020_income_benefits-AUwp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_income_benefits-AUwp" ON public.hmis_2020_income_benefits USING btree ("EnrollmentID");


--
-- Name: hmis_2020_income_benefits-BE9p; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_income_benefits-BE9p" ON public.hmis_2020_income_benefits USING btree ("ExportID");


--
-- Name: hmis_2020_income_benefits-JwPq; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_income_benefits-JwPq" ON public.hmis_2020_income_benefits USING btree ("DateCreated");


--
-- Name: hmis_2020_income_benefits-LCKi; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_income_benefits-LCKi" ON public.hmis_2020_income_benefits USING btree (source_type, source_id);


--
-- Name: hmis_2020_income_benefits-NcHX; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_income_benefits-NcHX" ON public.hmis_2020_income_benefits USING btree ("PersonalID");


--
-- Name: hmis_2020_income_benefits-aphJ; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_income_benefits-aphJ" ON public.hmis_2020_income_benefits USING btree ("DateUpdated");


--
-- Name: hmis_2020_income_benefits-pfYl; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_income_benefits-pfYl" ON public.hmis_2020_income_benefits USING btree ("IncomeBenefitsID");


--
-- Name: hmis_2020_income_benefits-tBcJ; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_income_benefits-tBcJ" ON public.hmis_2020_income_benefits USING btree ("IncomeBenefitsID", data_source_id);


--
-- Name: hmis_2020_inventories-0TGU; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_inventories-0TGU" ON public.hmis_2020_inventories USING btree ("DateUpdated");


--
-- Name: hmis_2020_inventories-DTHt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_inventories-DTHt" ON public.hmis_2020_inventories USING btree (source_type, source_id);


--
-- Name: hmis_2020_inventories-J6na; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_inventories-J6na" ON public.hmis_2020_inventories USING btree ("DateCreated");


--
-- Name: hmis_2020_inventories-LNwI; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_inventories-LNwI" ON public.hmis_2020_inventories USING btree ("InventoryID", data_source_id);


--
-- Name: hmis_2020_inventories-fun6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_inventories-fun6" ON public.hmis_2020_inventories USING btree ("InventoryID");


--
-- Name: hmis_2020_inventories-whCo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_inventories-whCo" ON public.hmis_2020_inventories USING btree ("ExportID");


--
-- Name: hmis_2020_inventories-yV3L; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_inventories-yV3L" ON public.hmis_2020_inventories USING btree ("ProjectID", "CoCCode");


--
-- Name: hmis_2020_organizations-MfSb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_organizations-MfSb" ON public.hmis_2020_organizations USING btree ("OrganizationID", data_source_id);


--
-- Name: hmis_2020_organizations-Prts; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_organizations-Prts" ON public.hmis_2020_organizations USING btree ("OrganizationID");


--
-- Name: hmis_2020_organizations-SWg3; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_organizations-SWg3" ON public.hmis_2020_organizations USING btree (source_type, source_id);


--
-- Name: hmis_2020_organizations-VQWo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_organizations-VQWo" ON public.hmis_2020_organizations USING btree ("ExportID");


--
-- Name: hmis_2020_project_cocs-GTs4; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_project_cocs-GTs4" ON public.hmis_2020_project_cocs USING btree ("ExportID");


--
-- Name: hmis_2020_project_cocs-JAwb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_project_cocs-JAwb" ON public.hmis_2020_project_cocs USING btree ("ProjectCoCID", data_source_id);


--
-- Name: hmis_2020_project_cocs-K8nw; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_project_cocs-K8nw" ON public.hmis_2020_project_cocs USING btree ("ProjectID", "CoCCode");


--
-- Name: hmis_2020_project_cocs-OI4Q; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_project_cocs-OI4Q" ON public.hmis_2020_project_cocs USING btree ("DateUpdated");


--
-- Name: hmis_2020_project_cocs-Tmf3; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_project_cocs-Tmf3" ON public.hmis_2020_project_cocs USING btree ("DateCreated");


--
-- Name: hmis_2020_project_cocs-icQq; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_project_cocs-icQq" ON public.hmis_2020_project_cocs USING btree (source_type, source_id);


--
-- Name: hmis_2020_project_cocs-iuZj; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_project_cocs-iuZj" ON public.hmis_2020_project_cocs USING btree ("ProjectCoCID");


--
-- Name: hmis_2020_projects-5SSM; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_projects-5SSM" ON public.hmis_2020_projects USING btree (source_type, source_id);


--
-- Name: hmis_2020_projects-ctk2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_projects-ctk2" ON public.hmis_2020_projects USING btree ("DateCreated");


--
-- Name: hmis_2020_projects-fqB3; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_projects-fqB3" ON public.hmis_2020_projects USING btree ("ExportID");


--
-- Name: hmis_2020_projects-nhkJ; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_projects-nhkJ" ON public.hmis_2020_projects USING btree ("ProjectID");


--
-- Name: hmis_2020_projects-oxQa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_projects-oxQa" ON public.hmis_2020_projects USING btree ("ProjectID", data_source_id);


--
-- Name: hmis_2020_projects-xkUs; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_projects-xkUs" ON public.hmis_2020_projects USING btree ("ProjectType");


--
-- Name: hmis_2020_projects-zcbu; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_projects-zcbu" ON public.hmis_2020_projects USING btree ("DateUpdated");


--
-- Name: hmis_2020_services-3lC5; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-3lC5" ON public.hmis_2020_services USING btree ("ServicesID", data_source_id);


--
-- Name: hmis_2020_services-4CG1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-4CG1" ON public.hmis_2020_services USING btree (source_type, source_id);


--
-- Name: hmis_2020_services-8nZj; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-8nZj" ON public.hmis_2020_services USING btree ("DateProvided");


--
-- Name: hmis_2020_services-ApuA; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-ApuA" ON public.hmis_2020_services USING btree ("RecordType", "DateProvided");


--
-- Name: hmis_2020_services-LqGx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-LqGx" ON public.hmis_2020_services USING btree ("EnrollmentID", "RecordType", "DateDeleted", "DateProvided");


--
-- Name: hmis_2020_services-QkXD; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-QkXD" ON public.hmis_2020_services USING btree ("ServicesID");


--
-- Name: hmis_2020_services-Rwkq; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-Rwkq" ON public.hmis_2020_services USING btree ("PersonalID");


--
-- Name: hmis_2020_services-VJ0s; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-VJ0s" ON public.hmis_2020_services USING btree ("DateUpdated");


--
-- Name: hmis_2020_services-WGtP; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-WGtP" ON public.hmis_2020_services USING btree ("DateDeleted");


--
-- Name: hmis_2020_services-WrTZ; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-WrTZ" ON public.hmis_2020_services USING btree ("RecordType", "DateDeleted");


--
-- Name: hmis_2020_services-Y8F7; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-Y8F7" ON public.hmis_2020_services USING btree ("ExportID");


--
-- Name: hmis_2020_services-eNab; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-eNab" ON public.hmis_2020_services USING btree ("DateCreated");


--
-- Name: hmis_2020_services-ggIO; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-ggIO" ON public.hmis_2020_services USING btree ("PersonalID", "RecordType", "EnrollmentID", "DateProvided");


--
-- Name: hmis_2020_services-m63x; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-m63x" ON public.hmis_2020_services USING btree ("EnrollmentID", "PersonalID");


--
-- Name: hmis_2020_services-mIRP; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-mIRP" ON public.hmis_2020_services USING btree ("RecordType");


--
-- Name: hmis_2020_services-wXdL; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_services-wXdL" ON public.hmis_2020_services USING btree ("EnrollmentID");


--
-- Name: hmis_2020_users-74tq; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_users-74tq" ON public.hmis_2020_users USING btree ("UserID");


--
-- Name: hmis_2020_users-DmeI; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_users-DmeI" ON public.hmis_2020_users USING btree ("UserID", data_source_id);


--
-- Name: hmis_2020_users-Ls1u; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_users-Ls1u" ON public.hmis_2020_users USING btree ("ExportID");


--
-- Name: hmis_2020_users-ZfY6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_2020_users-ZfY6" ON public.hmis_2020_users USING btree (source_type, source_id);


--
-- Name: hmis_csv_2020_affiliations-F2ar; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_affiliations-F2ar" ON public.hmis_csv_2020_affiliations USING btree ("AffiliationID", data_source_id);


--
-- Name: hmis_csv_2020_affiliations-ofln; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_affiliations-ofln" ON public.hmis_csv_2020_affiliations USING btree ("ExportID");


--
-- Name: hmis_csv_2020_assessment_questions-U6Dk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_assessment_questions-U6Dk" ON public.hmis_csv_2020_assessment_questions USING btree ("AssessmentID");


--
-- Name: hmis_csv_2020_assessment_questions-Xt6t; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_assessment_questions-Xt6t" ON public.hmis_csv_2020_assessment_questions USING btree ("ExportID");


--
-- Name: hmis_csv_2020_assessment_questions-ZGxE; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_assessment_questions-ZGxE" ON public.hmis_csv_2020_assessment_questions USING btree ("AssessmentQuestionID", data_source_id);


--
-- Name: hmis_csv_2020_assessment_results-NEN7; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_assessment_results-NEN7" ON public.hmis_csv_2020_assessment_results USING btree ("AssessmentID");


--
-- Name: hmis_csv_2020_assessment_results-NLC4; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_assessment_results-NLC4" ON public.hmis_csv_2020_assessment_results USING btree ("ExportID");


--
-- Name: hmis_csv_2020_assessment_results-Rkod; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_assessment_results-Rkod" ON public.hmis_csv_2020_assessment_results USING btree ("AssessmentResultID", data_source_id);


--
-- Name: hmis_csv_2020_assessments-EZd7; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_assessments-EZd7" ON public.hmis_csv_2020_assessments USING btree ("EnrollmentID");


--
-- Name: hmis_csv_2020_assessments-GRoC; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_assessments-GRoC" ON public.hmis_csv_2020_assessments USING btree ("AssessmentDate");


--
-- Name: hmis_csv_2020_assessments-MoqJ; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_assessments-MoqJ" ON public.hmis_csv_2020_assessments USING btree ("ExportID");


--
-- Name: hmis_csv_2020_assessments-W4vL; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_assessments-W4vL" ON public.hmis_csv_2020_assessments USING btree ("AssessmentID");


--
-- Name: hmis_csv_2020_assessments-nFH4; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_assessments-nFH4" ON public.hmis_csv_2020_assessments USING btree ("PersonalID");


--
-- Name: hmis_csv_2020_assessments-y7s0; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_assessments-y7s0" ON public.hmis_csv_2020_assessments USING btree ("AssessmentID", data_source_id);


--
-- Name: hmis_csv_2020_clients-20vV; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_clients-20vV" ON public.hmis_csv_2020_clients USING btree ("ExportID");


--
-- Name: hmis_csv_2020_clients-2cnC; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_clients-2cnC" ON public.hmis_csv_2020_clients USING btree ("DateCreated");


--
-- Name: hmis_csv_2020_clients-85Ap; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_clients-85Ap" ON public.hmis_csv_2020_clients USING btree ("LastName");


--
-- Name: hmis_csv_2020_clients-FQ7O; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_clients-FQ7O" ON public.hmis_csv_2020_clients USING btree ("DOB");


--
-- Name: hmis_csv_2020_clients-Q0u6; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_clients-Q0u6" ON public.hmis_csv_2020_clients USING btree ("FirstName");


--
-- Name: hmis_csv_2020_clients-kRKs; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_clients-kRKs" ON public.hmis_csv_2020_clients USING btree ("VeteranStatus");


--
-- Name: hmis_csv_2020_clients-moFz; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_clients-moFz" ON public.hmis_csv_2020_clients USING btree ("PersonalID");


--
-- Name: hmis_csv_2020_clients-qppE; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_clients-qppE" ON public.hmis_csv_2020_clients USING btree ("PersonalID", data_source_id);


--
-- Name: hmis_csv_2020_clients-wlPc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_clients-wlPc" ON public.hmis_csv_2020_clients USING btree ("DateUpdated");


--
-- Name: hmis_csv_2020_current_living_situations-3hVq; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_current_living_situations-3hVq" ON public.hmis_csv_2020_current_living_situations USING btree ("PersonalID");


--
-- Name: hmis_csv_2020_current_living_situations-EGfX; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_current_living_situations-EGfX" ON public.hmis_csv_2020_current_living_situations USING btree ("CurrentLivingSitID");


--
-- Name: hmis_csv_2020_current_living_situations-KGuH; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_current_living_situations-KGuH" ON public.hmis_csv_2020_current_living_situations USING btree ("ExportID");


--
-- Name: hmis_csv_2020_current_living_situations-ScsR; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_current_living_situations-ScsR" ON public.hmis_csv_2020_current_living_situations USING btree ("EnrollmentID");


--
-- Name: hmis_csv_2020_current_living_situations-VCsb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_current_living_situations-VCsb" ON public.hmis_csv_2020_current_living_situations USING btree ("InformationDate");


--
-- Name: hmis_csv_2020_current_living_situations-Vh4Y; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_current_living_situations-Vh4Y" ON public.hmis_csv_2020_current_living_situations USING btree ("CurrentLivingSituation");


--
-- Name: hmis_csv_2020_current_living_situations-jzq2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_current_living_situations-jzq2" ON public.hmis_csv_2020_current_living_situations USING btree ("CurrentLivingSitID", data_source_id);


--
-- Name: hmis_csv_2020_disabilities-4Nml; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_disabilities-4Nml" ON public.hmis_csv_2020_disabilities USING btree ("DateUpdated");


--
-- Name: hmis_csv_2020_disabilities-9jL3; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_disabilities-9jL3" ON public.hmis_csv_2020_disabilities USING btree ("EnrollmentID");


--
-- Name: hmis_csv_2020_disabilities-Sp4k; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_disabilities-Sp4k" ON public.hmis_csv_2020_disabilities USING btree ("ExportID");


--
-- Name: hmis_csv_2020_disabilities-anqe; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_disabilities-anqe" ON public.hmis_csv_2020_disabilities USING btree ("DisabilitiesID", data_source_id);


--
-- Name: hmis_csv_2020_disabilities-ohpt; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_disabilities-ohpt" ON public.hmis_csv_2020_disabilities USING btree ("DateCreated");


--
-- Name: hmis_csv_2020_disabilities-toFu; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_disabilities-toFu" ON public.hmis_csv_2020_disabilities USING btree ("DisabilitiesID");


--
-- Name: hmis_csv_2020_disabilities-xa8A; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_disabilities-xa8A" ON public.hmis_csv_2020_disabilities USING btree ("PersonalID");


--
-- Name: hmis_csv_2020_employment_educations-3UVX; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_employment_educations-3UVX" ON public.hmis_csv_2020_employment_educations USING btree ("EmploymentEducationID", data_source_id);


--
-- Name: hmis_csv_2020_employment_educations-4yxa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_employment_educations-4yxa" ON public.hmis_csv_2020_employment_educations USING btree ("DateUpdated");


--
-- Name: hmis_csv_2020_employment_educations-8u1c; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_employment_educations-8u1c" ON public.hmis_csv_2020_employment_educations USING btree ("ExportID");


--
-- Name: hmis_csv_2020_employment_educations-JTgH; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_employment_educations-JTgH" ON public.hmis_csv_2020_employment_educations USING btree ("EnrollmentID");


--
-- Name: hmis_csv_2020_employment_educations-U3yq; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_employment_educations-U3yq" ON public.hmis_csv_2020_employment_educations USING btree ("EmploymentEducationID");


--
-- Name: hmis_csv_2020_employment_educations-bTVG; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_employment_educations-bTVG" ON public.hmis_csv_2020_employment_educations USING btree ("DateCreated");


--
-- Name: hmis_csv_2020_employment_educations-ffjb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_employment_educations-ffjb" ON public.hmis_csv_2020_employment_educations USING btree ("PersonalID");


--
-- Name: hmis_csv_2020_enrollment_cocs-AFlL; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollment_cocs-AFlL" ON public.hmis_csv_2020_enrollment_cocs USING btree ("ExportID");


--
-- Name: hmis_csv_2020_enrollment_cocs-GYSJ; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollment_cocs-GYSJ" ON public.hmis_csv_2020_enrollment_cocs USING btree ("PersonalID");


--
-- Name: hmis_csv_2020_enrollment_cocs-ManB; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollment_cocs-ManB" ON public.hmis_csv_2020_enrollment_cocs USING btree ("DateDeleted");


--
-- Name: hmis_csv_2020_enrollment_cocs-MhSp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollment_cocs-MhSp" ON public.hmis_csv_2020_enrollment_cocs USING btree ("EnrollmentCoCID", data_source_id);


--
-- Name: hmis_csv_2020_enrollment_cocs-RyqL; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollment_cocs-RyqL" ON public.hmis_csv_2020_enrollment_cocs USING btree ("CoCCode");


--
-- Name: hmis_csv_2020_enrollment_cocs-dizj; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollment_cocs-dizj" ON public.hmis_csv_2020_enrollment_cocs USING btree ("DateCreated");


--
-- Name: hmis_csv_2020_enrollment_cocs-myvn; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollment_cocs-myvn" ON public.hmis_csv_2020_enrollment_cocs USING btree ("DateUpdated");


--
-- Name: hmis_csv_2020_enrollment_cocs-phxe; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollment_cocs-phxe" ON public.hmis_csv_2020_enrollment_cocs USING btree ("EnrollmentID");


--
-- Name: hmis_csv_2020_enrollment_cocs-zRK2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollment_cocs-zRK2" ON public.hmis_csv_2020_enrollment_cocs USING btree ("EnrollmentCoCID");


--
-- Name: hmis_csv_2020_enrollments-1CJ3; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-1CJ3" ON public.hmis_csv_2020_enrollments USING btree ("ExportID");


--
-- Name: hmis_csv_2020_enrollments-1ErZ; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-1ErZ" ON public.hmis_csv_2020_enrollments USING btree ("HouseholdID");


--
-- Name: hmis_csv_2020_enrollments-2DM8; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-2DM8" ON public.hmis_csv_2020_enrollments USING btree ("EnrollmentID", data_source_id);


--
-- Name: hmis_csv_2020_enrollments-7ZVi; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-7ZVi" ON public.hmis_csv_2020_enrollments USING btree ("PersonalID");


--
-- Name: hmis_csv_2020_enrollments-8UEw; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-8UEw" ON public.hmis_csv_2020_enrollments USING btree ("EnrollmentID", "PersonalID");


--
-- Name: hmis_csv_2020_enrollments-B4uX; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-B4uX" ON public.hmis_csv_2020_enrollments USING btree ("DateDeleted");


--
-- Name: hmis_csv_2020_enrollments-CKRZ; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-CKRZ" ON public.hmis_csv_2020_enrollments USING btree ("ProjectID");


--
-- Name: hmis_csv_2020_enrollments-CxJA; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-CxJA" ON public.hmis_csv_2020_enrollments USING btree ("PreviousStreetESSH", "LengthOfStay");


--
-- Name: hmis_csv_2020_enrollments-GH0S; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-GH0S" ON public.hmis_csv_2020_enrollments USING btree ("RelationshipToHoH");


--
-- Name: hmis_csv_2020_enrollments-KtXA; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-KtXA" ON public.hmis_csv_2020_enrollments USING btree ("ProjectID", "RelationshipToHoH");


--
-- Name: hmis_csv_2020_enrollments-LQ7R; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-LQ7R" ON public.hmis_csv_2020_enrollments USING btree ("EnrollmentID", "ProjectID", "EntryDate");


--
-- Name: hmis_csv_2020_enrollments-Leaw; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-Leaw" ON public.hmis_csv_2020_enrollments USING btree ("LivingSituation");


--
-- Name: hmis_csv_2020_enrollments-XI6S; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-XI6S" ON public.hmis_csv_2020_enrollments USING btree ("EnrollmentID");


--
-- Name: hmis_csv_2020_enrollments-bpsk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-bpsk" ON public.hmis_csv_2020_enrollments USING btree ("TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears");


--
-- Name: hmis_csv_2020_enrollments-djbw; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-djbw" ON public.hmis_csv_2020_enrollments USING btree ("DateCreated");


--
-- Name: hmis_csv_2020_enrollments-gF7Z; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-gF7Z" ON public.hmis_csv_2020_enrollments USING btree ("ProjectID", "HouseholdID");


--
-- Name: hmis_csv_2020_enrollments-l0fG; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-l0fG" ON public.hmis_csv_2020_enrollments USING btree ("EntryDate");


--
-- Name: hmis_csv_2020_enrollments-qD0O; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_enrollments-qD0O" ON public.hmis_csv_2020_enrollments USING btree ("DateUpdated");


--
-- Name: hmis_csv_2020_events-7ZMP; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_events-7ZMP" ON public.hmis_csv_2020_events USING btree ("PersonalID");


--
-- Name: hmis_csv_2020_events-BBvn; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_events-BBvn" ON public.hmis_csv_2020_events USING btree ("EventID", data_source_id);


--
-- Name: hmis_csv_2020_events-G60G; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_events-G60G" ON public.hmis_csv_2020_events USING btree ("EventDate");


--
-- Name: hmis_csv_2020_events-HCAc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_events-HCAc" ON public.hmis_csv_2020_events USING btree ("EventID");


--
-- Name: hmis_csv_2020_events-lkZq; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_events-lkZq" ON public.hmis_csv_2020_events USING btree ("ExportID");


--
-- Name: hmis_csv_2020_events-niJ9; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_events-niJ9" ON public.hmis_csv_2020_events USING btree ("EnrollmentID");


--
-- Name: hmis_csv_2020_exits-86BM; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_exits-86BM" ON public.hmis_csv_2020_exits USING btree ("PersonalID");


--
-- Name: hmis_csv_2020_exits-9oMc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_exits-9oMc" ON public.hmis_csv_2020_exits USING btree ("DateDeleted");


--
-- Name: hmis_csv_2020_exits-B03u; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_exits-B03u" ON public.hmis_csv_2020_exits USING btree ("DateCreated");


--
-- Name: hmis_csv_2020_exits-lfLn; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_exits-lfLn" ON public.hmis_csv_2020_exits USING btree ("EnrollmentID");


--
-- Name: hmis_csv_2020_exits-m68a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_exits-m68a" ON public.hmis_csv_2020_exits USING btree ("ExitID", data_source_id);


--
-- Name: hmis_csv_2020_exits-u5YR; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_exits-u5YR" ON public.hmis_csv_2020_exits USING btree ("DateUpdated");


--
-- Name: hmis_csv_2020_exits-wXSx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_exits-wXSx" ON public.hmis_csv_2020_exits USING btree ("ExitDate");


--
-- Name: hmis_csv_2020_exits-xc6a; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_exits-xc6a" ON public.hmis_csv_2020_exits USING btree ("ExportID");


--
-- Name: hmis_csv_2020_exits-yZ3j; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_exits-yZ3j" ON public.hmis_csv_2020_exits USING btree ("ExitID");


--
-- Name: hmis_csv_2020_exports-K9wp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_exports-K9wp" ON public.hmis_csv_2020_exports USING btree ("ExportID", data_source_id);


--
-- Name: hmis_csv_2020_exports-iweG; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_exports-iweG" ON public.hmis_csv_2020_exports USING btree ("ExportID");


--
-- Name: hmis_csv_2020_funders-1HLT; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_funders-1HLT" ON public.hmis_csv_2020_funders USING btree ("FunderID");


--
-- Name: hmis_csv_2020_funders-BLkd; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_funders-BLkd" ON public.hmis_csv_2020_funders USING btree ("FunderID", data_source_id);


--
-- Name: hmis_csv_2020_funders-IC4k; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_funders-IC4k" ON public.hmis_csv_2020_funders USING btree ("DateCreated");


--
-- Name: hmis_csv_2020_funders-Ix1m; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_funders-Ix1m" ON public.hmis_csv_2020_funders USING btree ("DateUpdated");


--
-- Name: hmis_csv_2020_funders-PEzG; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_funders-PEzG" ON public.hmis_csv_2020_funders USING btree ("ExportID");


--
-- Name: hmis_csv_2020_health_and_dvs-2NoM; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_health_and_dvs-2NoM" ON public.hmis_csv_2020_health_and_dvs USING btree ("HealthAndDVID");


--
-- Name: hmis_csv_2020_health_and_dvs-6zDo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_health_and_dvs-6zDo" ON public.hmis_csv_2020_health_and_dvs USING btree ("HealthAndDVID", data_source_id);


--
-- Name: hmis_csv_2020_health_and_dvs-TUWh; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_health_and_dvs-TUWh" ON public.hmis_csv_2020_health_and_dvs USING btree ("DateCreated");


--
-- Name: hmis_csv_2020_health_and_dvs-lO76; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_health_and_dvs-lO76" ON public.hmis_csv_2020_health_and_dvs USING btree ("ExportID");


--
-- Name: hmis_csv_2020_health_and_dvs-xYMb; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_health_and_dvs-xYMb" ON public.hmis_csv_2020_health_and_dvs USING btree ("PersonalID");


--
-- Name: hmis_csv_2020_health_and_dvs-y2fn; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_health_and_dvs-y2fn" ON public.hmis_csv_2020_health_and_dvs USING btree ("DateUpdated");


--
-- Name: hmis_csv_2020_health_and_dvs-zvlJ; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_health_and_dvs-zvlJ" ON public.hmis_csv_2020_health_and_dvs USING btree ("EnrollmentID");


--
-- Name: hmis_csv_2020_income_benefits-6HMy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_income_benefits-6HMy" ON public.hmis_csv_2020_income_benefits USING btree ("EnrollmentID");


--
-- Name: hmis_csv_2020_income_benefits-KXp0; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_income_benefits-KXp0" ON public.hmis_csv_2020_income_benefits USING btree ("IncomeBenefitsID");


--
-- Name: hmis_csv_2020_income_benefits-O58u; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_income_benefits-O58u" ON public.hmis_csv_2020_income_benefits USING btree ("IncomeBenefitsID", data_source_id);


--
-- Name: hmis_csv_2020_income_benefits-Qf5l; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_income_benefits-Qf5l" ON public.hmis_csv_2020_income_benefits USING btree ("PersonalID");


--
-- Name: hmis_csv_2020_income_benefits-SEnq; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_income_benefits-SEnq" ON public.hmis_csv_2020_income_benefits USING btree ("ExportID");


--
-- Name: hmis_csv_2020_income_benefits-YyfJ; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_income_benefits-YyfJ" ON public.hmis_csv_2020_income_benefits USING btree ("DateUpdated");


--
-- Name: hmis_csv_2020_income_benefits-lVjn; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_income_benefits-lVjn" ON public.hmis_csv_2020_income_benefits USING btree ("DateCreated");


--
-- Name: hmis_csv_2020_inventories-BTZq; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_inventories-BTZq" ON public.hmis_csv_2020_inventories USING btree ("ProjectID", "CoCCode");


--
-- Name: hmis_csv_2020_inventories-NeSc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_inventories-NeSc" ON public.hmis_csv_2020_inventories USING btree ("DateUpdated");


--
-- Name: hmis_csv_2020_inventories-RGrg; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_inventories-RGrg" ON public.hmis_csv_2020_inventories USING btree ("InventoryID");


--
-- Name: hmis_csv_2020_inventories-eYpq; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_inventories-eYpq" ON public.hmis_csv_2020_inventories USING btree ("DateCreated");


--
-- Name: hmis_csv_2020_inventories-sfWI; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_inventories-sfWI" ON public.hmis_csv_2020_inventories USING btree ("InventoryID", data_source_id);


--
-- Name: hmis_csv_2020_inventories-wdcK; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_inventories-wdcK" ON public.hmis_csv_2020_inventories USING btree ("ExportID");


--
-- Name: hmis_csv_2020_organizations-LqQF; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_organizations-LqQF" ON public.hmis_csv_2020_organizations USING btree ("ExportID");


--
-- Name: hmis_csv_2020_organizations-cRJF; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_organizations-cRJF" ON public.hmis_csv_2020_organizations USING btree ("OrganizationID", data_source_id);


--
-- Name: hmis_csv_2020_organizations-tyIy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_organizations-tyIy" ON public.hmis_csv_2020_organizations USING btree ("OrganizationID");


--
-- Name: hmis_csv_2020_project_cocs-336L; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_project_cocs-336L" ON public.hmis_csv_2020_project_cocs USING btree ("ExportID");


--
-- Name: hmis_csv_2020_project_cocs-5NHP; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_project_cocs-5NHP" ON public.hmis_csv_2020_project_cocs USING btree ("ProjectCoCID");


--
-- Name: hmis_csv_2020_project_cocs-G4ij; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_project_cocs-G4ij" ON public.hmis_csv_2020_project_cocs USING btree ("ProjectID", "CoCCode");


--
-- Name: hmis_csv_2020_project_cocs-K765; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_project_cocs-K765" ON public.hmis_csv_2020_project_cocs USING btree ("ProjectCoCID", data_source_id);


--
-- Name: hmis_csv_2020_project_cocs-fRQZ; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_project_cocs-fRQZ" ON public.hmis_csv_2020_project_cocs USING btree ("DateCreated");


--
-- Name: hmis_csv_2020_project_cocs-wP5S; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_project_cocs-wP5S" ON public.hmis_csv_2020_project_cocs USING btree ("DateUpdated");


--
-- Name: hmis_csv_2020_projects-I9LN; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_projects-I9LN" ON public.hmis_csv_2020_projects USING btree ("ProjectID");


--
-- Name: hmis_csv_2020_projects-MNAC; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_projects-MNAC" ON public.hmis_csv_2020_projects USING btree ("DateUpdated");


--
-- Name: hmis_csv_2020_projects-StS2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_projects-StS2" ON public.hmis_csv_2020_projects USING btree ("ProjectID", data_source_id);


--
-- Name: hmis_csv_2020_projects-f4DP; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_projects-f4DP" ON public.hmis_csv_2020_projects USING btree ("ExportID");


--
-- Name: hmis_csv_2020_projects-gAEK; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_projects-gAEK" ON public.hmis_csv_2020_projects USING btree ("ProjectType");


--
-- Name: hmis_csv_2020_projects-m4tQ; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_projects-m4tQ" ON public.hmis_csv_2020_projects USING btree ("DateCreated");


--
-- Name: hmis_csv_2020_services-1ggS; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_services-1ggS" ON public.hmis_csv_2020_services USING btree ("EnrollmentID", "RecordType", "DateDeleted", "DateProvided");


--
-- Name: hmis_csv_2020_services-4Q3B; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_services-4Q3B" ON public.hmis_csv_2020_services USING btree ("ServicesID");


--
-- Name: hmis_csv_2020_services-5b2P; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_services-5b2P" ON public.hmis_csv_2020_services USING btree ("DateDeleted");


--
-- Name: hmis_csv_2020_services-7Ekp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_services-7Ekp" ON public.hmis_csv_2020_services USING btree ("EnrollmentID", "PersonalID");


--
-- Name: hmis_csv_2020_services-8SnT; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_services-8SnT" ON public.hmis_csv_2020_services USING btree ("RecordType", "DateProvided");


--
-- Name: hmis_csv_2020_services-MSYV; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_services-MSYV" ON public.hmis_csv_2020_services USING btree ("DateUpdated");


--
-- Name: hmis_csv_2020_services-Nlyp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_services-Nlyp" ON public.hmis_csv_2020_services USING btree ("DateCreated");


--
-- Name: hmis_csv_2020_services-VRZ7; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_services-VRZ7" ON public.hmis_csv_2020_services USING btree ("RecordType", "DateDeleted");


--
-- Name: hmis_csv_2020_services-ZiEF; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_services-ZiEF" ON public.hmis_csv_2020_services USING btree ("PersonalID");


--
-- Name: hmis_csv_2020_services-b6iK; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_services-b6iK" ON public.hmis_csv_2020_services USING btree ("ExportID");


--
-- Name: hmis_csv_2020_services-dacu; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_services-dacu" ON public.hmis_csv_2020_services USING btree ("ServicesID", data_source_id);


--
-- Name: hmis_csv_2020_services-feYP; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_services-feYP" ON public.hmis_csv_2020_services USING btree ("RecordType");


--
-- Name: hmis_csv_2020_services-i7KB; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_services-i7KB" ON public.hmis_csv_2020_services USING btree ("DateProvided");


--
-- Name: hmis_csv_2020_services-lVDS; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_services-lVDS" ON public.hmis_csv_2020_services USING btree ("PersonalID", "RecordType", "EnrollmentID", "DateProvided");


--
-- Name: hmis_csv_2020_services-mvqR; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_services-mvqR" ON public.hmis_csv_2020_services USING btree ("EnrollmentID");


--
-- Name: hmis_csv_2020_users-3tXl; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_users-3tXl" ON public.hmis_csv_2020_users USING btree ("UserID");


--
-- Name: hmis_csv_2020_users-Vflk; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_users-Vflk" ON public.hmis_csv_2020_users USING btree ("ExportID");


--
-- Name: hmis_csv_2020_users-Y4OW; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_2020_users-Y4OW" ON public.hmis_csv_2020_users USING btree ("UserID", data_source_id);


--
-- Name: hmis_csv_import_errors-wgH3; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_import_errors-wgH3" ON public.hmis_csv_import_errors USING btree (source_type, source_id);


--
-- Name: hmis_csv_validations-ONiu; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "hmis_csv_validations-ONiu" ON public.hmis_csv_import_validations USING btree (source_type, source_id);


--
-- Name: household_id_rsh_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX household_id_rsh_index ON public.recent_service_history USING btree (household_id);


--
-- Name: hud_path_client_conflict_columns; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX hud_path_client_conflict_columns ON public.hud_report_path_clients USING btree (report_instance_id, data_source_id, client_id);


--
-- Name: id_rsh_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX id_rsh_index ON public.recent_service_history USING btree (id);


--
-- Name: idx_any_stage; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_any_stage ON public."IncomeBenefits" USING btree ("IncomeFromAnySource", "DataCollectionStage");


--
-- Name: idx_earned_stage; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_earned_stage ON public."IncomeBenefits" USING btree ("Earned", "DataCollectionStage");


--
-- Name: idx_enrollment_ds_id_hh_id_p_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_enrollment_ds_id_hh_id_p_id ON public."Enrollment" USING btree (data_source_id, "HouseholdID", "ProjectID");


--
-- Name: idx_fed_census_acc_on_geo_measure; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fed_census_acc_on_geo_measure ON public.federal_census_breakdowns USING btree (accurate_on, geography, geography_level, measure);


--
-- Name: idx_hmis_2020_affiliations_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_affiliations_imid_du ON public.hmis_2020_affiliations USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_assessment_questions_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_assessment_questions_imid_du ON public.hmis_2020_assessment_questions USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_assessment_results_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_assessment_results_imid_du ON public.hmis_2020_assessment_results USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_assessments_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_assessments_imid_du ON public.hmis_2020_assessments USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_clients_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_clients_imid_du ON public.hmis_2020_clients USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_current_living_situations_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_current_living_situations_imid_du ON public.hmis_2020_current_living_situations USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_disabilities_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_disabilities_imid_du ON public.hmis_2020_disabilities USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_employment_educations_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_employment_educations_imid_du ON public.hmis_2020_employment_educations USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_enrollment_cocs_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_enrollment_cocs_imid_du ON public.hmis_2020_enrollment_cocs USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_enrollments_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_enrollments_imid_du ON public.hmis_2020_enrollments USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_events_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_events_imid_du ON public.hmis_2020_events USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_exits_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_exits_imid_du ON public.hmis_2020_exits USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_funders_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_funders_imid_du ON public.hmis_2020_funders USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_health_and_dvs_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_health_and_dvs_imid_du ON public.hmis_2020_health_and_dvs USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_income_benefits_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_income_benefits_imid_du ON public.hmis_2020_income_benefits USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_inventories_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_inventories_imid_du ON public.hmis_2020_inventories USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_organizations_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_organizations_imid_du ON public.hmis_2020_organizations USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_project_cocs_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_project_cocs_imid_du ON public.hmis_2020_project_cocs USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_projects_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_projects_imid_du ON public.hmis_2020_projects USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_services_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_services_imid_du ON public.hmis_2020_services USING btree (importer_log_id, "DateUpdated");


--
-- Name: idx_hmis_2020_users_imid_du; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_hmis_2020_users_imid_du ON public.hmis_2020_users USING btree (importer_log_id, "DateUpdated");


--
-- Name: income_benefits_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX income_benefits_date_created ON public."IncomeBenefits" USING btree ("DateCreated");


--
-- Name: income_benefits_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX income_benefits_date_updated ON public."IncomeBenefits" USING btree ("DateUpdated");


--
-- Name: income_benefits_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX income_benefits_export_id ON public."IncomeBenefits" USING btree ("ExportID");


--
-- Name: index_Affiliation_on_AffiliationID_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "index_Affiliation_on_AffiliationID_and_data_source_id" ON public."Affiliation" USING btree ("AffiliationID", data_source_id);


--
-- Name: index_Affiliation_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Affiliation_on_DateDeleted_and_data_source_id" ON public."Affiliation" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_Affiliation_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Affiliation_on_data_source_id" ON public."Affiliation" USING btree (data_source_id);


--
-- Name: index_Affiliation_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Affiliation_on_pending_date_deleted" ON public."Affiliation" USING btree (pending_date_deleted);


--
-- Name: index_AssessmentQuestions_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_AssessmentQuestions_on_pending_date_deleted" ON public."AssessmentQuestions" USING btree (pending_date_deleted);


--
-- Name: index_AssessmentResults_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_AssessmentResults_on_pending_date_deleted" ON public."AssessmentResults" USING btree (pending_date_deleted);


--
-- Name: index_Assessment_on_AssessmentID_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "index_Assessment_on_AssessmentID_and_data_source_id" ON public."Assessment" USING btree ("AssessmentID", data_source_id);


--
-- Name: index_Assessment_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Assessment_on_pending_date_deleted" ON public."Assessment" USING btree (pending_date_deleted);


--
-- Name: index_Client_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Client_on_DateDeleted_and_data_source_id" ON public."Client" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_Client_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Client_on_creator_id" ON public."Client" USING btree (creator_id);


--
-- Name: index_Client_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Client_on_data_source_id" ON public."Client" USING btree (data_source_id);


--
-- Name: index_Client_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Client_on_pending_date_deleted" ON public."Client" USING btree (pending_date_deleted);


--
-- Name: index_CurrentLivingSituation_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_CurrentLivingSituation_on_pending_date_deleted" ON public."CurrentLivingSituation" USING btree (pending_date_deleted);


--
-- Name: index_Disabilities_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Disabilities_on_DateDeleted_and_data_source_id" ON public."Disabilities" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_Disabilities_on_DisabilitiesID_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "index_Disabilities_on_DisabilitiesID_and_data_source_id" ON public."Disabilities" USING btree ("DisabilitiesID", data_source_id);


--
-- Name: index_Disabilities_on_EnrollmentID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Disabilities_on_EnrollmentID" ON public."Disabilities" USING btree ("EnrollmentID");


--
-- Name: index_Disabilities_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Disabilities_on_PersonalID" ON public."Disabilities" USING btree ("PersonalID");


--
-- Name: index_Disabilities_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Disabilities_on_data_source_id" ON public."Disabilities" USING btree (data_source_id);


--
-- Name: index_Disabilities_on_data_source_id_and_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Disabilities_on_data_source_id_and_PersonalID" ON public."Disabilities" USING btree (data_source_id, "PersonalID");


--
-- Name: index_Disabilities_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Disabilities_on_pending_date_deleted" ON public."Disabilities" USING btree (pending_date_deleted);


--
-- Name: index_EmploymentEducation_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EmploymentEducation_on_DateDeleted_and_data_source_id" ON public."EmploymentEducation" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_EmploymentEducation_on_EnrollmentID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EmploymentEducation_on_EnrollmentID" ON public."EmploymentEducation" USING btree ("EnrollmentID");


--
-- Name: index_EmploymentEducation_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EmploymentEducation_on_PersonalID" ON public."EmploymentEducation" USING btree ("PersonalID");


--
-- Name: index_EmploymentEducation_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EmploymentEducation_on_data_source_id" ON public."EmploymentEducation" USING btree (data_source_id);


--
-- Name: index_EmploymentEducation_on_data_source_id_and_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EmploymentEducation_on_data_source_id_and_PersonalID" ON public."EmploymentEducation" USING btree (data_source_id, "PersonalID");


--
-- Name: index_EmploymentEducation_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EmploymentEducation_on_pending_date_deleted" ON public."EmploymentEducation" USING btree (pending_date_deleted);


--
-- Name: index_EnrollmentCoC_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EnrollmentCoC_on_DateDeleted_and_data_source_id" ON public."EnrollmentCoC" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_EnrollmentCoC_on_EnrollmentCoCID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EnrollmentCoC_on_EnrollmentCoCID" ON public."EnrollmentCoC" USING btree ("EnrollmentCoCID");


--
-- Name: index_EnrollmentCoC_on_EnrollmentCoCID_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "index_EnrollmentCoC_on_EnrollmentCoCID_and_data_source_id" ON public."EnrollmentCoC" USING btree ("EnrollmentCoCID", data_source_id);


--
-- Name: index_EnrollmentCoC_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EnrollmentCoC_on_data_source_id" ON public."EnrollmentCoC" USING btree (data_source_id);


--
-- Name: index_EnrollmentCoC_on_data_source_id_and_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EnrollmentCoC_on_data_source_id_and_PersonalID" ON public."EnrollmentCoC" USING btree (data_source_id, "PersonalID");


--
-- Name: index_EnrollmentCoC_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EnrollmentCoC_on_pending_date_deleted" ON public."EnrollmentCoC" USING btree (pending_date_deleted);


--
-- Name: index_Enrollment_on_DateDeleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_DateDeleted" ON public."Enrollment" USING btree ("DateDeleted");


--
-- Name: index_Enrollment_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_DateDeleted_and_data_source_id" ON public."Enrollment" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_Enrollment_on_EnrollmentID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_EnrollmentID" ON public."Enrollment" USING btree ("EnrollmentID");


--
-- Name: index_Enrollment_on_EntryDate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_EntryDate" ON public."Enrollment" USING btree ("EntryDate");


--
-- Name: index_Enrollment_on_MoveInDate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_MoveInDate" ON public."Enrollment" USING btree ("MoveInDate");


--
-- Name: index_Enrollment_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_PersonalID" ON public."Enrollment" USING btree ("PersonalID");


--
-- Name: index_Enrollment_on_ProjectID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_ProjectID" ON public."Enrollment" USING btree ("ProjectID");


--
-- Name: index_Enrollment_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_data_source_id" ON public."Enrollment" USING btree (data_source_id);


--
-- Name: index_Enrollment_on_data_source_id_and_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_data_source_id_and_PersonalID" ON public."Enrollment" USING btree (data_source_id, "PersonalID");


--
-- Name: index_Enrollment_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_pending_date_deleted" ON public."Enrollment" USING btree (pending_date_deleted);


--
-- Name: index_Enrollment_on_service_history_processing_job_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_service_history_processing_job_id" ON public."Enrollment" USING btree (service_history_processing_job_id);


--
-- Name: index_Event_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Event_on_pending_date_deleted" ON public."Event" USING btree (pending_date_deleted);


--
-- Name: index_Exit_on_DateDeleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_DateDeleted" ON public."Exit" USING btree ("DateDeleted");


--
-- Name: index_Exit_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_DateDeleted_and_data_source_id" ON public."Exit" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_Exit_on_EnrollmentID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_EnrollmentID" ON public."Exit" USING btree ("EnrollmentID");


--
-- Name: index_Exit_on_ExitDate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_ExitDate" ON public."Exit" USING btree ("ExitDate");


--
-- Name: index_Exit_on_ExitID_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "index_Exit_on_ExitID_and_data_source_id" ON public."Exit" USING btree ("ExitID", data_source_id);


--
-- Name: index_Exit_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_PersonalID" ON public."Exit" USING btree ("PersonalID");


--
-- Name: index_Exit_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_data_source_id" ON public."Exit" USING btree (data_source_id);


--
-- Name: index_Exit_on_data_source_id_and_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_data_source_id_and_PersonalID" ON public."Exit" USING btree (data_source_id, "PersonalID");


--
-- Name: index_Exit_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_pending_date_deleted" ON public."Exit" USING btree (pending_date_deleted);


--
-- Name: index_Export_on_ExportID_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "index_Export_on_ExportID_and_data_source_id" ON public."Export" USING btree ("ExportID", data_source_id);


--
-- Name: index_Export_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Export_on_data_source_id" ON public."Export" USING btree (data_source_id);


--
-- Name: index_Funder_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Funder_on_DateDeleted_and_data_source_id" ON public."Funder" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_Funder_on_FunderID_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "index_Funder_on_FunderID_and_data_source_id" ON public."Funder" USING btree ("FunderID", data_source_id);


--
-- Name: index_Funder_on_ProjectID_and_Funder; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Funder_on_ProjectID_and_Funder" ON public."Funder" USING btree ("ProjectID", "Funder");


--
-- Name: index_Funder_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Funder_on_data_source_id" ON public."Funder" USING btree (data_source_id);


--
-- Name: index_Funder_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Funder_on_pending_date_deleted" ON public."Funder" USING btree (pending_date_deleted);


--
-- Name: index_Geography_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Geography_on_DateDeleted_and_data_source_id" ON public."Geography" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_Geography_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Geography_on_data_source_id" ON public."Geography" USING btree (data_source_id);


--
-- Name: index_Geography_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Geography_on_pending_date_deleted" ON public."Geography" USING btree (pending_date_deleted);


--
-- Name: index_HealthAndDV_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_HealthAndDV_on_DateDeleted_and_data_source_id" ON public."HealthAndDV" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_HealthAndDV_on_EnrollmentID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_HealthAndDV_on_EnrollmentID" ON public."HealthAndDV" USING btree ("EnrollmentID");


--
-- Name: index_HealthAndDV_on_HealthAndDVID_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "index_HealthAndDV_on_HealthAndDVID_and_data_source_id" ON public."HealthAndDV" USING btree ("HealthAndDVID", data_source_id);


--
-- Name: index_HealthAndDV_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_HealthAndDV_on_PersonalID" ON public."HealthAndDV" USING btree ("PersonalID");


--
-- Name: index_HealthAndDV_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_HealthAndDV_on_data_source_id" ON public."HealthAndDV" USING btree (data_source_id);


--
-- Name: index_HealthAndDV_on_data_source_id_and_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_HealthAndDV_on_data_source_id_and_PersonalID" ON public."HealthAndDV" USING btree (data_source_id, "PersonalID");


--
-- Name: index_HealthAndDV_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_HealthAndDV_on_pending_date_deleted" ON public."HealthAndDV" USING btree (pending_date_deleted);


--
-- Name: index_IncomeBenefits_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_DateDeleted_and_data_source_id" ON public."IncomeBenefits" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_IncomeBenefits_on_EnrollmentID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_EnrollmentID" ON public."IncomeBenefits" USING btree ("EnrollmentID");


--
-- Name: index_IncomeBenefits_on_IncomeBenefitsID_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "index_IncomeBenefits_on_IncomeBenefitsID_and_data_source_id" ON public."IncomeBenefits" USING btree ("IncomeBenefitsID", data_source_id);


--
-- Name: index_IncomeBenefits_on_InformationDate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_InformationDate" ON public."IncomeBenefits" USING btree ("InformationDate");


--
-- Name: index_IncomeBenefits_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_PersonalID" ON public."IncomeBenefits" USING btree ("PersonalID");


--
-- Name: index_IncomeBenefits_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_data_source_id" ON public."IncomeBenefits" USING btree (data_source_id);


--
-- Name: index_IncomeBenefits_on_data_source_id_and_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_data_source_id_and_PersonalID" ON public."IncomeBenefits" USING btree (data_source_id, "PersonalID");


--
-- Name: index_IncomeBenefits_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_pending_date_deleted" ON public."IncomeBenefits" USING btree (pending_date_deleted);


--
-- Name: index_Inventory_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Inventory_on_DateDeleted_and_data_source_id" ON public."Inventory" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_Inventory_on_InventoryID_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "index_Inventory_on_InventoryID_and_data_source_id" ON public."Inventory" USING btree ("InventoryID", data_source_id);


--
-- Name: index_Inventory_on_ProjectID_and_CoCCode_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Inventory_on_ProjectID_and_CoCCode_and_data_source_id" ON public."Inventory" USING btree ("ProjectID", "CoCCode", data_source_id);


--
-- Name: index_Inventory_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Inventory_on_data_source_id" ON public."Inventory" USING btree (data_source_id);


--
-- Name: index_Inventory_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Inventory_on_pending_date_deleted" ON public."Inventory" USING btree (pending_date_deleted);


--
-- Name: index_Organization_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Organization_on_DateDeleted_and_data_source_id" ON public."Organization" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_Organization_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Organization_on_data_source_id" ON public."Organization" USING btree (data_source_id);


--
-- Name: index_Organization_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Organization_on_pending_date_deleted" ON public."Organization" USING btree (pending_date_deleted);


--
-- Name: index_ProjectCoC_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_ProjectCoC_on_DateDeleted_and_data_source_id" ON public."ProjectCoC" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_ProjectCoC_on_ProjectCoCID_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "index_ProjectCoC_on_ProjectCoCID_and_data_source_id" ON public."ProjectCoC" USING btree ("ProjectCoCID", data_source_id);


--
-- Name: index_ProjectCoC_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_ProjectCoC_on_data_source_id" ON public."ProjectCoC" USING btree (data_source_id);


--
-- Name: index_ProjectCoC_on_data_source_id_and_ProjectID_and_CoCCode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_ProjectCoC_on_data_source_id_and_ProjectID_and_CoCCode" ON public."ProjectCoC" USING btree (data_source_id, "ProjectID", "CoCCode");


--
-- Name: index_ProjectCoC_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_ProjectCoC_on_pending_date_deleted" ON public."ProjectCoC" USING btree (pending_date_deleted);


--
-- Name: index_Project_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Project_on_DateDeleted_and_data_source_id" ON public."Project" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_Project_on_ProjectType; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Project_on_ProjectType" ON public."Project" USING btree ("ProjectType");


--
-- Name: index_Project_on_computed_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Project_on_computed_project_type" ON public."Project" USING btree (computed_project_type);


--
-- Name: index_Project_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Project_on_data_source_id" ON public."Project" USING btree (data_source_id);


--
-- Name: index_Project_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Project_on_pending_date_deleted" ON public."Project" USING btree (pending_date_deleted);


--
-- Name: index_Services_on_DateDeleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Services_on_DateDeleted" ON public."Services" USING btree ("DateDeleted");


--
-- Name: index_Services_on_DateDeleted_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Services_on_DateDeleted_and_data_source_id" ON public."Services" USING btree ("DateDeleted", data_source_id);


--
-- Name: index_Services_on_DateProvided; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Services_on_DateProvided" ON public."Services" USING btree ("DateProvided");


--
-- Name: index_Services_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Services_on_PersonalID" ON public."Services" USING btree ("PersonalID");


--
-- Name: index_Services_on_ServicesID_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "index_Services_on_ServicesID_and_data_source_id" ON public."Services" USING btree ("ServicesID", data_source_id);


--
-- Name: index_Services_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Services_on_data_source_id" ON public."Services" USING btree (data_source_id);


--
-- Name: index_Services_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Services_on_pending_date_deleted" ON public."Services" USING btree (pending_date_deleted);


--
-- Name: index_User_on_UserID_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "index_User_on_UserID_and_data_source_id" ON public."User" USING btree ("UserID", data_source_id);


--
-- Name: index_User_on_pending_date_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_User_on_pending_date_deleted" ON public."User" USING btree (pending_date_deleted);


--
-- Name: index_ad_hoc_batches_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ad_hoc_batches_on_created_at ON public.ad_hoc_batches USING btree (created_at);


--
-- Name: index_ad_hoc_batches_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ad_hoc_batches_on_deleted_at ON public.ad_hoc_batches USING btree (deleted_at);


--
-- Name: index_ad_hoc_batches_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ad_hoc_batches_on_updated_at ON public.ad_hoc_batches USING btree (updated_at);


--
-- Name: index_ad_hoc_clients_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ad_hoc_clients_on_created_at ON public.ad_hoc_clients USING btree (created_at);


--
-- Name: index_ad_hoc_clients_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ad_hoc_clients_on_deleted_at ON public.ad_hoc_clients USING btree (deleted_at);


--
-- Name: index_ad_hoc_clients_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ad_hoc_clients_on_updated_at ON public.ad_hoc_clients USING btree (updated_at);


--
-- Name: index_ad_hoc_data_sources_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ad_hoc_data_sources_on_created_at ON public.ad_hoc_data_sources USING btree (created_at);


--
-- Name: index_ad_hoc_data_sources_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ad_hoc_data_sources_on_deleted_at ON public.ad_hoc_data_sources USING btree (deleted_at);


--
-- Name: index_ad_hoc_data_sources_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ad_hoc_data_sources_on_updated_at ON public.ad_hoc_data_sources USING btree (updated_at);


--
-- Name: index_ad_hoc_data_sources_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ad_hoc_data_sources_on_user_id ON public.ad_hoc_data_sources USING btree (user_id);


--
-- Name: index_administrative_events_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_administrative_events_on_deleted_at ON public.administrative_events USING btree (deleted_at);


--
-- Name: index_anomalies_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_anomalies_on_client_id ON public.anomalies USING btree (client_id);


--
-- Name: index_anomalies_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_anomalies_on_status ON public.anomalies USING btree (status);


--
-- Name: index_api_client_data_source_ids_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_api_client_data_source_ids_on_client_id ON public.api_client_data_source_ids USING btree (client_id);


--
-- Name: index_api_client_data_source_ids_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_api_client_data_source_ids_on_data_source_id ON public.api_client_data_source_ids USING btree (data_source_id);


--
-- Name: index_api_client_data_source_ids_on_warehouse_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_api_client_data_source_ids_on_warehouse_id ON public.api_client_data_source_ids USING btree (warehouse_id);


--
-- Name: index_cas_availabilities_on_available_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_availabilities_on_available_at ON public.cas_availabilities USING btree (available_at);


--
-- Name: index_cas_availabilities_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_availabilities_on_client_id ON public.cas_availabilities USING btree (client_id);


--
-- Name: index_cas_availabilities_on_unavailable_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_availabilities_on_unavailable_at ON public.cas_availabilities USING btree (unavailable_at);


--
-- Name: index_cas_ce_assessments_on_cas_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_ce_assessments_on_cas_client_id ON public.cas_ce_assessments USING btree (cas_client_id);


--
-- Name: index_cas_ce_assessments_on_cas_non_hmis_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cas_ce_assessments_on_cas_non_hmis_assessment_id ON public.cas_ce_assessments USING btree (cas_non_hmis_assessment_id);


--
-- Name: index_cas_ce_assessments_on_hmis_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_ce_assessments_on_hmis_client_id ON public.cas_ce_assessments USING btree (hmis_client_id);


--
-- Name: index_cas_ce_assessments_on_program_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_ce_assessments_on_program_id ON public.cas_ce_assessments USING btree (program_id);


--
-- Name: index_cas_enrollments_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_enrollments_on_client_id ON public.cas_enrollments USING btree (client_id);


--
-- Name: index_cas_enrollments_on_enrollment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_enrollments_on_enrollment_id ON public.cas_enrollments USING btree (enrollment_id);


--
-- Name: index_cas_houseds_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_houseds_on_client_id ON public.cas_houseds USING btree (client_id);


--
-- Name: index_cas_non_hmis_client_histories_on_cas_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_non_hmis_client_histories_on_cas_client_id ON public.cas_non_hmis_client_histories USING btree (cas_client_id);


--
-- Name: index_cas_programs_to_projects_on_program_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_programs_to_projects_on_program_id ON public.cas_programs_to_projects USING btree (program_id);


--
-- Name: index_cas_programs_to_projects_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_programs_to_projects_on_project_id ON public.cas_programs_to_projects USING btree (project_id);


--
-- Name: index_cas_referral_events_on_cas_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_referral_events_on_cas_client_id ON public.cas_referral_events USING btree (cas_client_id);


--
-- Name: index_cas_referral_events_on_client_opportunity_match_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_referral_events_on_client_opportunity_match_id ON public.cas_referral_events USING btree (client_opportunity_match_id);


--
-- Name: index_cas_referral_events_on_hmis_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_referral_events_on_hmis_client_id ON public.cas_referral_events USING btree (hmis_client_id);


--
-- Name: index_cas_referral_events_on_program_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_referral_events_on_program_id ON public.cas_referral_events USING btree (program_id);


--
-- Name: index_cas_reports_on_client_id_and_match_id_and_decision_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cas_reports_on_client_id_and_match_id_and_decision_id ON public.cas_reports USING btree (client_id, match_id, decision_id);


--
-- Name: index_cas_vacancies_on_program_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_vacancies_on_program_id ON public.cas_vacancies USING btree (program_id);


--
-- Name: index_cas_vacancies_on_sub_program_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_vacancies_on_sub_program_id ON public.cas_vacancies USING btree (sub_program_id);


--
-- Name: index_ce_assessments_on_assessor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ce_assessments_on_assessor_id ON public.ce_assessments USING btree (assessor_id);


--
-- Name: index_ce_assessments_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ce_assessments_on_client_id ON public.ce_assessments USING btree (client_id);


--
-- Name: index_ce_assessments_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ce_assessments_on_deleted_at ON public.ce_assessments USING btree (deleted_at);


--
-- Name: index_ce_assessments_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ce_assessments_on_type ON public.ce_assessments USING btree (type);


--
-- Name: index_ce_assessments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ce_assessments_on_user_id ON public.ce_assessments USING btree (user_id);


--
-- Name: index_census_groups_on_year_and_dataset_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_census_groups_on_year_and_dataset_and_name ON public.census_groups USING btree (year, dataset, name);


--
-- Name: index_census_values_on_census_level; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_census_values_on_census_level ON public.census_values USING btree (census_level);


--
-- Name: index_census_values_on_census_variable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_census_values_on_census_variable_id ON public.census_values USING btree (census_variable_id);


--
-- Name: index_census_values_on_full_geoid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_census_values_on_full_geoid ON public.census_values USING btree (full_geoid);


--
-- Name: index_census_values_on_full_geoid_and_census_variable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_census_values_on_full_geoid_and_census_variable_id ON public.census_values USING btree (full_geoid, census_variable_id);


--
-- Name: index_census_variables_on_dataset; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_census_variables_on_dataset ON public.census_variables USING btree (dataset);


--
-- Name: index_census_variables_on_internal_name_and_year_and_dataset; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_census_variables_on_internal_name_and_year_and_dataset ON public.census_variables USING btree (internal_name, year, dataset) WHERE (internal_name IS NOT NULL);


--
-- Name: index_census_variables_on_year_and_dataset_and_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_census_variables_on_year_and_dataset_and_name ON public.census_variables USING btree (year, dataset, name);


--
-- Name: index_censuses_ave_year_ds_id_proj_type_org_id_proj_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_censuses_ave_year_ds_id_proj_type_org_id_proj_id ON public.censuses_averaged_by_year USING btree (year, data_source_id, "ProjectType", "OrganizationID", "ProjectID");


--
-- Name: index_censuses_ds_id_proj_type_org_id_proj_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_censuses_ds_id_proj_type_org_id_proj_id ON public.censuses USING btree (data_source_id, "ProjectType", "OrganizationID", "ProjectID");


--
-- Name: index_censuses_on_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_censuses_on_date ON public.censuses USING btree (date);


--
-- Name: index_censuses_on_date_and_ProjectType; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_censuses_on_date_and_ProjectType" ON public.censuses USING btree (date, "ProjectType");


--
-- Name: index_children_on_family_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_children_on_family_id ON public.children USING btree (family_id);


--
-- Name: index_chronics_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chronics_on_client_id ON public.chronics USING btree (client_id);


--
-- Name: index_chronics_on_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chronics_on_date ON public.chronics USING btree (date);


--
-- Name: index_clh_locations_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_clh_locations_on_client_id ON public.clh_locations USING btree (client_id);


--
-- Name: index_clh_locations_on_source_type_and_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_clh_locations_on_source_type_and_source_id ON public.clh_locations USING btree (source_type, source_id);


--
-- Name: index_client_matches_on_destination_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_matches_on_destination_client_id ON public.client_matches USING btree (destination_client_id);


--
-- Name: index_client_matches_on_source_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_matches_on_source_client_id ON public.client_matches USING btree (source_client_id);


--
-- Name: index_client_matches_on_updated_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_matches_on_updated_by_id ON public.client_matches USING btree (updated_by_id);


--
-- Name: index_client_merge_histories_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_merge_histories_on_created_at ON public.client_merge_histories USING btree (created_at);


--
-- Name: index_client_merge_histories_on_merged_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_merge_histories_on_merged_from ON public.client_merge_histories USING btree (merged_from);


--
-- Name: index_client_merge_histories_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_merge_histories_on_updated_at ON public.client_merge_histories USING btree (updated_at);


--
-- Name: index_client_notes_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_notes_on_client_id ON public.client_notes USING btree (client_id);


--
-- Name: index_client_notes_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_notes_on_project_id ON public.client_notes USING btree (project_id);


--
-- Name: index_client_notes_on_service_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_notes_on_service_id ON public.client_notes USING btree (service_id);


--
-- Name: index_client_notes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_notes_on_user_id ON public.client_notes USING btree (user_id);


--
-- Name: index_client_split_histories_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_split_histories_on_created_at ON public.client_split_histories USING btree (created_at);


--
-- Name: index_client_split_histories_on_split_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_split_histories_on_split_from ON public.client_split_histories USING btree (split_from);


--
-- Name: index_client_split_histories_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_split_histories_on_updated_at ON public.client_split_histories USING btree (updated_at);


--
-- Name: index_coc_codes_on_coc_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_coc_codes_on_coc_code ON public.coc_codes USING btree (coc_code);


--
-- Name: index_cohort_client_changes_on_change; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cohort_client_changes_on_change ON public.cohort_client_changes USING btree (change);


--
-- Name: index_cohort_client_changes_on_changed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cohort_client_changes_on_changed_at ON public.cohort_client_changes USING btree (changed_at);


--
-- Name: index_cohort_client_notes_on_cohort_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cohort_client_notes_on_cohort_client_id ON public.cohort_client_notes USING btree (cohort_client_id);


--
-- Name: index_cohort_client_notes_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cohort_client_notes_on_deleted_at ON public.cohort_client_notes USING btree (deleted_at);


--
-- Name: index_cohort_clients_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cohort_clients_on_client_id ON public.cohort_clients USING btree (client_id);


--
-- Name: index_cohort_clients_on_cohort_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cohort_clients_on_cohort_id ON public.cohort_clients USING btree (cohort_id);


--
-- Name: index_cohort_clients_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cohort_clients_on_deleted_at ON public.cohort_clients USING btree (deleted_at);


--
-- Name: index_cohorts_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cohorts_on_deleted_at ON public.cohorts USING btree (deleted_at);


--
-- Name: index_contacts_on_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_entity_id ON public.contacts USING btree (entity_id);


--
-- Name: index_contacts_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_type ON public.contacts USING btree (type);


--
-- Name: index_data_monitorings_on_calculated_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_monitorings_on_calculated_on ON public.data_monitorings USING btree (calculated_on);


--
-- Name: index_data_monitorings_on_census; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_monitorings_on_census ON public.data_monitorings USING btree (census);


--
-- Name: index_data_monitorings_on_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_monitorings_on_resource_id ON public.data_monitorings USING btree (resource_id);


--
-- Name: index_data_monitorings_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_data_monitorings_on_type ON public.data_monitorings USING btree (type);


--
-- Name: index_direct_financial_assistances_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_direct_financial_assistances_on_deleted_at ON public.direct_financial_assistances USING btree (deleted_at);


--
-- Name: index_document_exports_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_document_exports_on_type ON public.document_exports USING btree (type);


--
-- Name: index_document_exports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_document_exports_on_user_id ON public.document_exports USING btree (user_id);


--
-- Name: index_enrollment_change_histories_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollment_change_histories_on_client_id ON public.enrollment_change_histories USING btree (client_id);


--
-- Name: index_eto_api_configs_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_eto_api_configs_on_data_source_id ON public.eto_api_configs USING btree (data_source_id);


--
-- Name: index_eto_client_lookups_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_eto_client_lookups_on_client_id ON public.eto_client_lookups USING btree (client_id);


--
-- Name: index_eto_client_lookups_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_eto_client_lookups_on_data_source_id ON public.eto_client_lookups USING btree (data_source_id);


--
-- Name: index_eto_subject_response_lookups_on_subject_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_eto_subject_response_lookups_on_subject_id ON public.eto_subject_response_lookups USING btree (subject_id);


--
-- Name: index_eto_touch_point_lookups_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_eto_touch_point_lookups_on_client_id ON public.eto_touch_point_lookups USING btree (client_id);


--
-- Name: index_eto_touch_point_lookups_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_eto_touch_point_lookups_on_data_source_id ON public.eto_touch_point_lookups USING btree (data_source_id);


--
-- Name: index_exports_ad_hoc_anons_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exports_ad_hoc_anons_on_created_at ON public.exports_ad_hoc_anons USING btree (created_at);


--
-- Name: index_exports_ad_hoc_anons_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exports_ad_hoc_anons_on_updated_at ON public.exports_ad_hoc_anons USING btree (updated_at);


--
-- Name: index_exports_ad_hoc_anons_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exports_ad_hoc_anons_on_user_id ON public.exports_ad_hoc_anons USING btree (user_id);


--
-- Name: index_exports_ad_hocs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exports_ad_hocs_on_created_at ON public.exports_ad_hocs USING btree (created_at);


--
-- Name: index_exports_ad_hocs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exports_ad_hocs_on_updated_at ON public.exports_ad_hocs USING btree (updated_at);


--
-- Name: index_exports_ad_hocs_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exports_ad_hocs_on_user_id ON public.exports_ad_hocs USING btree (user_id);


--
-- Name: index_exports_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exports_on_deleted_at ON public.exports USING btree (deleted_at);


--
-- Name: index_exports_on_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_exports_on_export_id ON public.exports USING btree (export_id);


--
-- Name: index_files_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_files_on_type ON public.files USING btree (type);


--
-- Name: index_files_on_vispdat_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_files_on_vispdat_id ON public.files USING btree (vispdat_id);


--
-- Name: index_grades_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_grades_on_type ON public.grades USING btree (type);


--
-- Name: index_hap_report_clients_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hap_report_clients_on_client_id ON public.hap_report_clients USING btree (client_id);


--
-- Name: index_health_emergency_ama_restrictions_on_agency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_ama_restrictions_on_agency_id ON public.health_emergency_ama_restrictions USING btree (agency_id);


--
-- Name: index_health_emergency_ama_restrictions_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_ama_restrictions_on_client_id ON public.health_emergency_ama_restrictions USING btree (client_id);


--
-- Name: index_health_emergency_ama_restrictions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_ama_restrictions_on_created_at ON public.health_emergency_ama_restrictions USING btree (created_at);


--
-- Name: index_health_emergency_ama_restrictions_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_ama_restrictions_on_updated_at ON public.health_emergency_ama_restrictions USING btree (updated_at);


--
-- Name: index_health_emergency_ama_restrictions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_ama_restrictions_on_user_id ON public.health_emergency_ama_restrictions USING btree (user_id);


--
-- Name: index_health_emergency_clinical_triages_on_agency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_clinical_triages_on_agency_id ON public.health_emergency_clinical_triages USING btree (agency_id);


--
-- Name: index_health_emergency_clinical_triages_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_clinical_triages_on_client_id ON public.health_emergency_clinical_triages USING btree (client_id);


--
-- Name: index_health_emergency_clinical_triages_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_clinical_triages_on_created_at ON public.health_emergency_clinical_triages USING btree (created_at);


--
-- Name: index_health_emergency_clinical_triages_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_clinical_triages_on_updated_at ON public.health_emergency_clinical_triages USING btree (updated_at);


--
-- Name: index_health_emergency_clinical_triages_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_clinical_triages_on_user_id ON public.health_emergency_clinical_triages USING btree (user_id);


--
-- Name: index_health_emergency_isolations_on_agency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_isolations_on_agency_id ON public.health_emergency_isolations USING btree (agency_id);


--
-- Name: index_health_emergency_isolations_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_isolations_on_client_id ON public.health_emergency_isolations USING btree (client_id);


--
-- Name: index_health_emergency_isolations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_isolations_on_created_at ON public.health_emergency_isolations USING btree (created_at);


--
-- Name: index_health_emergency_isolations_on_location; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_isolations_on_location ON public.health_emergency_isolations USING btree (location);


--
-- Name: index_health_emergency_isolations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_isolations_on_updated_at ON public.health_emergency_isolations USING btree (updated_at);


--
-- Name: index_health_emergency_isolations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_isolations_on_user_id ON public.health_emergency_isolations USING btree (user_id);


--
-- Name: index_health_emergency_test_batches_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_test_batches_on_created_at ON public.health_emergency_test_batches USING btree (created_at);


--
-- Name: index_health_emergency_test_batches_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_test_batches_on_deleted_at ON public.health_emergency_test_batches USING btree (deleted_at);


--
-- Name: index_health_emergency_test_batches_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_test_batches_on_updated_at ON public.health_emergency_test_batches USING btree (updated_at);


--
-- Name: index_health_emergency_test_batches_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_test_batches_on_user_id ON public.health_emergency_test_batches USING btree (user_id);


--
-- Name: index_health_emergency_tests_on_agency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_tests_on_agency_id ON public.health_emergency_tests USING btree (agency_id);


--
-- Name: index_health_emergency_tests_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_tests_on_client_id ON public.health_emergency_tests USING btree (client_id);


--
-- Name: index_health_emergency_tests_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_tests_on_created_at ON public.health_emergency_tests USING btree (created_at);


--
-- Name: index_health_emergency_tests_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_tests_on_updated_at ON public.health_emergency_tests USING btree (updated_at);


--
-- Name: index_health_emergency_tests_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_tests_on_user_id ON public.health_emergency_tests USING btree (user_id);


--
-- Name: index_health_emergency_triages_on_agency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_triages_on_agency_id ON public.health_emergency_triages USING btree (agency_id);


--
-- Name: index_health_emergency_triages_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_triages_on_client_id ON public.health_emergency_triages USING btree (client_id);


--
-- Name: index_health_emergency_triages_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_triages_on_created_at ON public.health_emergency_triages USING btree (created_at);


--
-- Name: index_health_emergency_triages_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_triages_on_updated_at ON public.health_emergency_triages USING btree (updated_at);


--
-- Name: index_health_emergency_triages_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_triages_on_user_id ON public.health_emergency_triages USING btree (user_id);


--
-- Name: index_health_emergency_uploaded_tests_on_ama_restriction_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_uploaded_tests_on_ama_restriction_id ON public.health_emergency_uploaded_tests USING btree (ama_restriction_id);


--
-- Name: index_health_emergency_uploaded_tests_on_batch_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_uploaded_tests_on_batch_id ON public.health_emergency_uploaded_tests USING btree (batch_id);


--
-- Name: index_health_emergency_uploaded_tests_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_uploaded_tests_on_created_at ON public.health_emergency_uploaded_tests USING btree (created_at);


--
-- Name: index_health_emergency_uploaded_tests_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_uploaded_tests_on_deleted_at ON public.health_emergency_uploaded_tests USING btree (deleted_at);


--
-- Name: index_health_emergency_uploaded_tests_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_uploaded_tests_on_updated_at ON public.health_emergency_uploaded_tests USING btree (updated_at);


--
-- Name: index_health_emergency_vaccinations_on_agency_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_vaccinations_on_agency_id ON public.health_emergency_vaccinations USING btree (agency_id);


--
-- Name: index_health_emergency_vaccinations_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_vaccinations_on_client_id ON public.health_emergency_vaccinations USING btree (client_id);


--
-- Name: index_health_emergency_vaccinations_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_vaccinations_on_created_at ON public.health_emergency_vaccinations USING btree (created_at);


--
-- Name: index_health_emergency_vaccinations_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_vaccinations_on_updated_at ON public.health_emergency_vaccinations USING btree (updated_at);


--
-- Name: index_health_emergency_vaccinations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_health_emergency_vaccinations_on_user_id ON public.health_emergency_vaccinations USING btree (user_id);


--
-- Name: index_helps_on_controller_path_and_action_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_helps_on_controller_path_and_action_name ON public.helps USING btree (controller_path, action_name);


--
-- Name: index_helps_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_helps_on_created_at ON public.helps USING btree (created_at);


--
-- Name: index_helps_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_helps_on_updated_at ON public.helps USING btree (updated_at);


--
-- Name: index_hmis_2020_exports_on_importer_log_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_2020_exports_on_importer_log_id ON public.hmis_2020_exports USING btree (importer_log_id);


--
-- Name: index_hmis_assessments_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_assessments_on_assessment_id ON public.hmis_assessments USING btree (assessment_id);


--
-- Name: index_hmis_assessments_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_assessments_on_data_source_id ON public.hmis_assessments USING btree (data_source_id);


--
-- Name: index_hmis_assessments_on_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_assessments_on_site_id ON public.hmis_assessments USING btree (site_id);


--
-- Name: index_hmis_client_attributes_defined_text_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_client_attributes_defined_text_on_client_id ON public.hmis_client_attributes_defined_text USING btree (client_id);


--
-- Name: index_hmis_client_attributes_defined_text_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_client_attributes_defined_text_on_data_source_id ON public.hmis_client_attributes_defined_text USING btree (data_source_id);


--
-- Name: index_hmis_clients_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_clients_on_client_id ON public.hmis_clients USING btree (client_id);


--
-- Name: index_hmis_csv_2020_affiliations_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_affiliations_on_loader_id ON public.hmis_csv_2020_affiliations USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_assessment_questions_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_assessment_questions_on_loader_id ON public.hmis_csv_2020_assessment_questions USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_assessment_results_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_assessment_results_on_loader_id ON public.hmis_csv_2020_assessment_results USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_assessments_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_assessments_on_loader_id ON public.hmis_csv_2020_assessments USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_clients_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_clients_on_loader_id ON public.hmis_csv_2020_clients USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_current_living_situations_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_current_living_situations_on_loader_id ON public.hmis_csv_2020_current_living_situations USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_disabilities_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_disabilities_on_loader_id ON public.hmis_csv_2020_disabilities USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_employment_educations_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_employment_educations_on_loader_id ON public.hmis_csv_2020_employment_educations USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_enrollment_cocs_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_enrollment_cocs_on_loader_id ON public.hmis_csv_2020_enrollment_cocs USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_enrollments_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_enrollments_on_loader_id ON public.hmis_csv_2020_enrollments USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_events_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_events_on_loader_id ON public.hmis_csv_2020_events USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_exits_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_exits_on_loader_id ON public.hmis_csv_2020_exits USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_exports_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_exports_on_loader_id ON public.hmis_csv_2020_exports USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_funders_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_funders_on_loader_id ON public.hmis_csv_2020_funders USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_health_and_dvs_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_health_and_dvs_on_loader_id ON public.hmis_csv_2020_health_and_dvs USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_income_benefits_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_income_benefits_on_loader_id ON public.hmis_csv_2020_income_benefits USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_inventories_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_inventories_on_loader_id ON public.hmis_csv_2020_inventories USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_organizations_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_organizations_on_loader_id ON public.hmis_csv_2020_organizations USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_project_cocs_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_project_cocs_on_loader_id ON public.hmis_csv_2020_project_cocs USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_projects_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_projects_on_loader_id ON public.hmis_csv_2020_projects USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_services_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_services_on_loader_id ON public.hmis_csv_2020_services USING btree (loader_id);


--
-- Name: index_hmis_csv_2020_users_on_loader_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_2020_users_on_loader_id ON public.hmis_csv_2020_users USING btree (loader_id);


--
-- Name: index_hmis_csv_import_errors_on_importer_log_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_import_errors_on_importer_log_id ON public.hmis_csv_import_errors USING btree (importer_log_id);


--
-- Name: index_hmis_csv_import_validations_on_importer_log_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_import_validations_on_importer_log_id ON public.hmis_csv_import_validations USING btree (importer_log_id);


--
-- Name: index_hmis_csv_import_validations_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_import_validations_on_type ON public.hmis_csv_import_validations USING btree (type);


--
-- Name: index_hmis_csv_importer_logs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_importer_logs_on_created_at ON public.hmis_csv_importer_logs USING btree (created_at);


--
-- Name: index_hmis_csv_importer_logs_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_importer_logs_on_data_source_id ON public.hmis_csv_importer_logs USING btree (data_source_id);


--
-- Name: index_hmis_csv_importer_logs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_importer_logs_on_updated_at ON public.hmis_csv_importer_logs USING btree (updated_at);


--
-- Name: index_hmis_csv_load_errors_on_loader_log_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_load_errors_on_loader_log_id ON public.hmis_csv_load_errors USING btree (loader_log_id);


--
-- Name: index_hmis_csv_loader_logs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_loader_logs_on_created_at ON public.hmis_csv_loader_logs USING btree (created_at);


--
-- Name: index_hmis_csv_loader_logs_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_loader_logs_on_data_source_id ON public.hmis_csv_loader_logs USING btree (data_source_id);


--
-- Name: index_hmis_csv_loader_logs_on_importer_log_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_loader_logs_on_importer_log_id ON public.hmis_csv_loader_logs USING btree (importer_log_id);


--
-- Name: index_hmis_csv_loader_logs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_csv_loader_logs_on_updated_at ON public.hmis_csv_loader_logs USING btree (updated_at);


--
-- Name: index_hmis_forms_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_forms_on_assessment_id ON public.hmis_forms USING btree (assessment_id);


--
-- Name: index_hmis_forms_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_forms_on_client_id ON public.hmis_forms USING btree (client_id);


--
-- Name: index_hmis_forms_on_collected_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_forms_on_collected_at ON public.hmis_forms USING btree (collected_at);


--
-- Name: index_hmis_forms_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_forms_on_name ON public.hmis_forms USING btree (name);


--
-- Name: index_hmis_import_configs_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_import_configs_on_data_source_id ON public.hmis_import_configs USING btree (data_source_id);


--
-- Name: index_homeless_summary_report_clients_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_homeless_summary_report_clients_on_client_id ON public.homeless_summary_report_clients USING btree (client_id);


--
-- Name: index_homeless_summary_report_clients_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_homeless_summary_report_clients_on_created_at ON public.homeless_summary_report_clients USING btree (created_at);


--
-- Name: index_homeless_summary_report_clients_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_homeless_summary_report_clients_on_deleted_at ON public.homeless_summary_report_clients USING btree (deleted_at);


--
-- Name: index_homeless_summary_report_clients_on_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_homeless_summary_report_clients_on_report_id ON public.homeless_summary_report_clients USING btree (report_id);


--
-- Name: index_homeless_summary_report_clients_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_homeless_summary_report_clients_on_updated_at ON public.homeless_summary_report_clients USING btree (updated_at);


--
-- Name: index_housing_resolution_plans_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_housing_resolution_plans_on_client_id ON public.housing_resolution_plans USING btree (client_id);


--
-- Name: index_housing_resolution_plans_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_housing_resolution_plans_on_user_id ON public.housing_resolution_plans USING btree (user_id);


--
-- Name: index_hud_apr_client_liv_sit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_apr_client_liv_sit ON public.hud_report_apr_living_situations USING btree (hud_report_apr_client_id);


--
-- Name: index_hud_chronics_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_chronics_on_client_id ON public.hud_chronics USING btree (client_id);


--
-- Name: index_hud_create_logs_on_effective_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_create_logs_on_effective_date ON public.hud_create_logs USING btree (effective_date);


--
-- Name: index_hud_create_logs_on_imported_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_create_logs_on_imported_at ON public.hud_create_logs USING btree (imported_at);


--
-- Name: index_hud_dq_client_liv_sit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_dq_client_liv_sit ON public.hud_report_dq_living_situations USING btree (hud_report_dq_client_id);


--
-- Name: index_hud_report_apr_ce_assessments_on_hud_report_apr_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_report_apr_ce_assessments_on_hud_report_apr_client_id ON public.hud_report_apr_ce_assessments USING btree (hud_report_apr_client_id);


--
-- Name: index_hud_report_apr_ce_assessments_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_report_apr_ce_assessments_on_project_id ON public.hud_report_apr_ce_assessments USING btree (project_id);


--
-- Name: index_hud_report_apr_ce_events_on_hud_report_apr_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_report_apr_ce_events_on_hud_report_apr_client_id ON public.hud_report_apr_ce_events USING btree (hud_report_apr_client_id);


--
-- Name: index_hud_report_apr_ce_events_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_report_apr_ce_events_on_project_id ON public.hud_report_apr_ce_events USING btree (project_id);


--
-- Name: index_hud_report_cells_on_report_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_report_cells_on_report_instance_id ON public.hud_report_cells USING btree (report_instance_id);


--
-- Name: index_hud_report_instances_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_report_instances_on_user_id ON public.hud_report_instances USING btree (user_id);


--
-- Name: index_hud_report_path_clients_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_report_path_clients_on_client_id ON public.hud_report_path_clients USING btree (client_id);


--
-- Name: index_hud_report_path_clients_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_report_path_clients_on_data_source_id ON public.hud_report_path_clients USING btree (data_source_id);


--
-- Name: index_hud_report_path_clients_on_incomes_at_entry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_report_path_clients_on_incomes_at_entry ON public.hud_report_path_clients USING gin (incomes_at_entry);


--
-- Name: index_hud_report_path_clients_on_incomes_at_exit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_report_path_clients_on_incomes_at_exit ON public.hud_report_path_clients USING gin (incomes_at_exit);


--
-- Name: index_hud_report_path_clients_on_incomes_at_report_end; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_report_path_clients_on_incomes_at_report_end ON public.hud_report_path_clients USING gin (incomes_at_report_end);


--
-- Name: index_hud_report_path_clients_on_referrals; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_report_path_clients_on_referrals ON public.hud_report_path_clients USING gin (referrals);


--
-- Name: index_hud_report_path_clients_on_report_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_report_path_clients_on_report_instance_id ON public.hud_report_path_clients USING btree (report_instance_id);


--
-- Name: index_hud_report_path_clients_on_services; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_report_path_clients_on_services ON public.hud_report_path_clients USING gin (services);


--
-- Name: index_hud_report_universe_members_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_report_universe_members_on_client_id ON public.hud_report_universe_members USING btree (client_id);


--
-- Name: index_import_logs_on_completed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_import_logs_on_completed_at ON public.import_logs USING btree (completed_at);


--
-- Name: index_import_logs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_import_logs_on_created_at ON public.import_logs USING btree (created_at);


--
-- Name: index_import_logs_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_import_logs_on_data_source_id ON public.import_logs USING btree (data_source_id);


--
-- Name: index_import_logs_on_importer_log_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_import_logs_on_importer_log_id ON public.import_logs USING btree (importer_log_id);


--
-- Name: index_import_logs_on_loader_log_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_import_logs_on_loader_log_id ON public.import_logs USING btree (loader_log_id);


--
-- Name: index_import_logs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_import_logs_on_updated_at ON public.import_logs USING btree (updated_at);


--
-- Name: index_income_benefits_report_clients_earlier; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_income_benefits_report_clients_earlier ON public.income_benefits_report_clients USING btree (earlier_income_record_id);


--
-- Name: index_income_benefits_report_clients_later; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_income_benefits_report_clients_later ON public.income_benefits_report_clients USING btree (later_income_record_id);


--
-- Name: index_income_benefits_report_clients_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_income_benefits_report_clients_on_client_id ON public.income_benefits_report_clients USING btree (client_id);


--
-- Name: index_income_benefits_report_clients_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_income_benefits_report_clients_on_created_at ON public.income_benefits_report_clients USING btree (created_at);


--
-- Name: index_income_benefits_report_clients_on_enrollment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_income_benefits_report_clients_on_enrollment_id ON public.income_benefits_report_clients USING btree (enrollment_id);


--
-- Name: index_income_benefits_report_clients_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_income_benefits_report_clients_on_project_id ON public.income_benefits_report_clients USING btree (project_id);


--
-- Name: index_income_benefits_report_clients_on_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_income_benefits_report_clients_on_report_id ON public.income_benefits_report_clients USING btree (report_id);


--
-- Name: index_income_benefits_report_clients_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_income_benefits_report_clients_on_updated_at ON public.income_benefits_report_clients USING btree (updated_at);


--
-- Name: index_income_benefits_report_incomes_on_Earned; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_income_benefits_report_incomes_on_Earned" ON public.income_benefits_report_incomes USING btree ("Earned");


--
-- Name: index_income_benefits_report_incomes_on_IncomeFromAnySource; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_income_benefits_report_incomes_on_IncomeFromAnySource" ON public.income_benefits_report_incomes USING btree ("IncomeFromAnySource");


--
-- Name: index_income_benefits_report_incomes_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_income_benefits_report_incomes_on_client_id ON public.income_benefits_report_incomes USING btree (client_id);


--
-- Name: index_income_benefits_report_incomes_on_income_benefits_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_income_benefits_report_incomes_on_income_benefits_id ON public.income_benefits_report_incomes USING btree (income_benefits_id);


--
-- Name: index_income_benefits_report_incomes_on_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_income_benefits_report_incomes_on_report_id ON public.income_benefits_report_incomes USING btree (report_id);


--
-- Name: index_income_benefits_reports_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_income_benefits_reports_on_created_at ON public.income_benefits_reports USING btree (created_at);


--
-- Name: index_income_benefits_reports_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_income_benefits_reports_on_deleted_at ON public.income_benefits_reports USING btree (deleted_at);


--
-- Name: index_income_benefits_reports_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_income_benefits_reports_on_updated_at ON public.income_benefits_reports USING btree (updated_at);


--
-- Name: index_income_benefits_reports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_income_benefits_reports_on_user_id ON public.income_benefits_reports USING btree (user_id);


--
-- Name: index_involved_in_imports_on_importer_log_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_involved_in_imports_on_importer_log_id ON public.involved_in_imports USING btree (importer_log_id);


--
-- Name: index_lftp_s3_syncs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lftp_s3_syncs_on_created_at ON public.lftp_s3_syncs USING btree (created_at);


--
-- Name: index_lftp_s3_syncs_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lftp_s3_syncs_on_data_source_id ON public.lftp_s3_syncs USING btree (data_source_id);


--
-- Name: index_lftp_s3_syncs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lftp_s3_syncs_on_updated_at ON public.lftp_s3_syncs USING btree (updated_at);


--
-- Name: index_lookups_ethnicities_on_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lookups_ethnicities_on_value ON public.lookups_ethnicities USING btree (value);


--
-- Name: index_lookups_funding_sources_on_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lookups_funding_sources_on_value ON public.lookups_funding_sources USING btree (value);


--
-- Name: index_lookups_genders_on_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lookups_genders_on_value ON public.lookups_genders USING btree (value);


--
-- Name: index_lookups_living_situations_on_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lookups_living_situations_on_value ON public.lookups_living_situations USING btree (value);


--
-- Name: index_lookups_project_types_on_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lookups_project_types_on_value ON public.lookups_project_types USING btree (value);


--
-- Name: index_lookups_relationships_on_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lookups_relationships_on_value ON public.lookups_relationships USING btree (value);


--
-- Name: index_lookups_tracking_methods_on_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lookups_tracking_methods_on_value ON public.lookups_tracking_methods USING btree (value);


--
-- Name: index_lookups_yes_no_etcs_on_value; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lookups_yes_no_etcs_on_value ON public.lookups_yes_no_etcs USING btree (value);


--
-- Name: index_new_service_history_on_first_date_in_program; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_new_service_history_on_first_date_in_program ON public.new_service_history USING brin (first_date_in_program);


--
-- Name: index_non_hmis_uploads_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_non_hmis_uploads_on_deleted_at ON public.non_hmis_uploads USING btree (deleted_at);


--
-- Name: index_performance_metrics_clients_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_performance_metrics_clients_on_client_id ON public.performance_metrics_clients USING btree (client_id);


--
-- Name: index_performance_metrics_clients_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_performance_metrics_clients_on_created_at ON public.performance_metrics_clients USING btree (created_at);


--
-- Name: index_performance_metrics_clients_on_current_period_caper_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_performance_metrics_clients_on_current_period_caper_id ON public.performance_metrics_clients USING btree (current_period_caper_id);


--
-- Name: index_performance_metrics_clients_on_current_period_spm_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_performance_metrics_clients_on_current_period_spm_id ON public.performance_metrics_clients USING btree (current_period_spm_id);


--
-- Name: index_performance_metrics_clients_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_performance_metrics_clients_on_deleted_at ON public.performance_metrics_clients USING btree (deleted_at);


--
-- Name: index_performance_metrics_clients_on_prior_period_caper_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_performance_metrics_clients_on_prior_period_caper_id ON public.performance_metrics_clients USING btree (prior_period_caper_id);


--
-- Name: index_performance_metrics_clients_on_prior_period_spm_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_performance_metrics_clients_on_prior_period_spm_id ON public.performance_metrics_clients USING btree (prior_period_spm_id);


--
-- Name: index_performance_metrics_clients_on_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_performance_metrics_clients_on_report_id ON public.performance_metrics_clients USING btree (report_id);


--
-- Name: index_performance_metrics_clients_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_performance_metrics_clients_on_updated_at ON public.performance_metrics_clients USING btree (updated_at);


--
-- Name: index_proj_proj_id_org_id_ds_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_proj_proj_id_org_id_ds_id ON public."Project" USING btree ("ProjectID", data_source_id, "OrganizationID");


--
-- Name: index_project_data_quality_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_data_quality_on_project_id ON public.project_data_quality USING btree (project_id);


--
-- Name: index_project_pass_fails_clients_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pass_fails_clients_on_client_id ON public.project_pass_fails_clients USING btree (client_id);


--
-- Name: index_project_pass_fails_clients_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pass_fails_clients_on_created_at ON public.project_pass_fails_clients USING btree (created_at);


--
-- Name: index_project_pass_fails_clients_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pass_fails_clients_on_deleted_at ON public.project_pass_fails_clients USING btree (deleted_at);


--
-- Name: index_project_pass_fails_clients_on_project_pass_fail_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pass_fails_clients_on_project_pass_fail_id ON public.project_pass_fails_clients USING btree (project_pass_fail_id);


--
-- Name: index_project_pass_fails_clients_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pass_fails_clients_on_updated_at ON public.project_pass_fails_clients USING btree (updated_at);


--
-- Name: index_project_pass_fails_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pass_fails_on_created_at ON public.project_pass_fails USING btree (created_at);


--
-- Name: index_project_pass_fails_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pass_fails_on_deleted_at ON public.project_pass_fails USING btree (deleted_at);


--
-- Name: index_project_pass_fails_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pass_fails_on_updated_at ON public.project_pass_fails USING btree (updated_at);


--
-- Name: index_project_pass_fails_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pass_fails_on_user_id ON public.project_pass_fails USING btree (user_id);


--
-- Name: index_project_pass_fails_projects_on_apr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pass_fails_projects_on_apr_id ON public.project_pass_fails_projects USING btree (apr_id);


--
-- Name: index_project_pass_fails_projects_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pass_fails_projects_on_created_at ON public.project_pass_fails_projects USING btree (created_at);


--
-- Name: index_project_pass_fails_projects_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pass_fails_projects_on_deleted_at ON public.project_pass_fails_projects USING btree (deleted_at);


--
-- Name: index_project_pass_fails_projects_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pass_fails_projects_on_project_id ON public.project_pass_fails_projects USING btree (project_id);


--
-- Name: index_project_pass_fails_projects_on_project_pass_fail_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pass_fails_projects_on_project_pass_fail_id ON public.project_pass_fails_projects USING btree (project_pass_fail_id);


--
-- Name: index_project_pass_fails_projects_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_pass_fails_projects_on_updated_at ON public.project_pass_fails_projects USING btree (updated_at);


--
-- Name: index_project_scorecard_reports_on_apr_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_scorecard_reports_on_apr_id ON public.project_scorecard_reports USING btree (apr_id);


--
-- Name: index_project_scorecard_reports_on_project_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_scorecard_reports_on_project_group_id ON public.project_scorecard_reports USING btree (project_group_id);


--
-- Name: index_project_scorecard_reports_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_scorecard_reports_on_project_id ON public.project_scorecard_reports USING btree (project_id);


--
-- Name: index_project_scorecard_reports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_scorecard_reports_on_user_id ON public.project_scorecard_reports USING btree (user_id);


--
-- Name: index_psc_feedback_surveys_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_psc_feedback_surveys_on_client_id ON public.psc_feedback_surveys USING btree (client_id);


--
-- Name: index_psc_feedback_surveys_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_psc_feedback_surveys_on_user_id ON public.psc_feedback_surveys USING btree (user_id);


--
-- Name: index_public_report_reports_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_public_report_reports_on_created_at ON public.public_report_reports USING btree (created_at);


--
-- Name: index_public_report_reports_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_public_report_reports_on_updated_at ON public.public_report_reports USING btree (updated_at);


--
-- Name: index_public_report_reports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_public_report_reports_on_user_id ON public.public_report_reports USING btree (user_id);


--
-- Name: index_recurring_hmis_exports_on_encrypted_s3_access_key_id_iv; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_recurring_hmis_exports_on_encrypted_s3_access_key_id_iv ON public.recurring_hmis_exports USING btree (encrypted_s3_access_key_id_iv);


--
-- Name: index_recurring_hmis_exports_on_encrypted_s3_secret_iv; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_recurring_hmis_exports_on_encrypted_s3_secret_iv ON public.recurring_hmis_exports USING btree (encrypted_s3_secret_iv);


--
-- Name: index_report_tokens_on_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_tokens_on_contact_id ON public.report_tokens USING btree (contact_id);


--
-- Name: index_report_tokens_on_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_tokens_on_report_id ON public.report_tokens USING btree (report_id);


--
-- Name: index_serv_on_proj_entry_per_id_ds_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_serv_on_proj_entry_per_id_ds_id ON public."Services" USING btree ("EnrollmentID", "PersonalID", data_source_id);


--
-- Name: index_service_history_enrollments_on_age; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_history_enrollments_on_age ON public.service_history_enrollments USING btree (age);


--
-- Name: index_service_history_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_history_on_client_id ON public.warehouse_client_service_history USING btree (client_id);


--
-- Name: index_service_history_services_2000_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2000_on_id ON public.service_history_services_2000 USING btree (id);


--
-- Name: index_service_history_services_2001_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2001_on_id ON public.service_history_services_2001 USING btree (id);


--
-- Name: index_service_history_services_2002_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2002_on_id ON public.service_history_services_2002 USING btree (id);


--
-- Name: index_service_history_services_2003_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2003_on_id ON public.service_history_services_2003 USING btree (id);


--
-- Name: index_service_history_services_2004_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2004_on_id ON public.service_history_services_2004 USING btree (id);


--
-- Name: index_service_history_services_2005_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2005_on_id ON public.service_history_services_2005 USING btree (id);


--
-- Name: index_service_history_services_2006_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2006_on_id ON public.service_history_services_2006 USING btree (id);


--
-- Name: index_service_history_services_2007_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2007_on_id ON public.service_history_services_2007 USING btree (id);


--
-- Name: index_service_history_services_2008_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2008_on_id ON public.service_history_services_2008 USING btree (id);


--
-- Name: index_service_history_services_2009_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2009_on_id ON public.service_history_services_2009 USING btree (id);


--
-- Name: index_service_history_services_2010_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2010_on_id ON public.service_history_services_2010 USING btree (id);


--
-- Name: index_service_history_services_2011_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2011_on_id ON public.service_history_services_2011 USING btree (id);


--
-- Name: index_service_history_services_2012_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2012_on_id ON public.service_history_services_2012 USING btree (id);


--
-- Name: index_service_history_services_2013_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2013_on_id ON public.service_history_services_2013 USING btree (id);


--
-- Name: index_service_history_services_2014_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2014_on_id ON public.service_history_services_2014 USING btree (id);


--
-- Name: index_service_history_services_2015_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2015_on_id ON public.service_history_services_2015 USING btree (id);


--
-- Name: index_service_history_services_2016_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2016_on_id ON public.service_history_services_2016 USING btree (id);


--
-- Name: index_service_history_services_2017_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2017_on_id ON public.service_history_services_2017 USING btree (id);


--
-- Name: index_service_history_services_2018_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2018_on_id ON public.service_history_services_2018 USING btree (id);


--
-- Name: index_service_history_services_2019_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2019_on_id ON public.service_history_services_2019 USING btree (id);


--
-- Name: index_service_history_services_2020_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2020_on_id ON public.service_history_services_2020 USING btree (id);


--
-- Name: index_service_history_services_2021_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2021_on_id ON public.service_history_services_2021 USING btree (id);


--
-- Name: index_service_history_services_2022_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2022_on_id ON public.service_history_services_2022 USING btree (id);


--
-- Name: index_service_history_services_2023_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2023_on_id ON public.service_history_services_2023 USING btree (id);


--
-- Name: index_service_history_services_2024_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2024_on_id ON public.service_history_services_2024 USING btree (id);


--
-- Name: index_service_history_services_2025_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2025_on_id ON public.service_history_services_2025 USING btree (id);


--
-- Name: index_service_history_services_2026_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2026_on_id ON public.service_history_services_2026 USING btree (id);


--
-- Name: index_service_history_services_2027_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2027_on_id ON public.service_history_services_2027 USING btree (id);


--
-- Name: index_service_history_services_2028_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2028_on_id ON public.service_history_services_2028 USING btree (id);


--
-- Name: index_service_history_services_2029_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2029_on_id ON public.service_history_services_2029 USING btree (id);


--
-- Name: index_service_history_services_2030_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2030_on_id ON public.service_history_services_2030 USING btree (id);


--
-- Name: index_service_history_services_2031_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2031_on_id ON public.service_history_services_2031 USING btree (id);


--
-- Name: index_service_history_services_2032_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2032_on_id ON public.service_history_services_2032 USING btree (id);


--
-- Name: index_service_history_services_2033_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2033_on_id ON public.service_history_services_2033 USING btree (id);


--
-- Name: index_service_history_services_2034_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2034_on_id ON public.service_history_services_2034 USING btree (id);


--
-- Name: index_service_history_services_2035_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2035_on_id ON public.service_history_services_2035 USING btree (id);


--
-- Name: index_service_history_services_2036_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2036_on_id ON public.service_history_services_2036 USING btree (id);


--
-- Name: index_service_history_services_2037_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2037_on_id ON public.service_history_services_2037 USING btree (id);


--
-- Name: index_service_history_services_2038_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2038_on_id ON public.service_history_services_2038 USING btree (id);


--
-- Name: index_service_history_services_2039_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2039_on_id ON public.service_history_services_2039 USING btree (id);


--
-- Name: index_service_history_services_2040_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2040_on_id ON public.service_history_services_2040 USING btree (id);


--
-- Name: index_service_history_services_2041_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2041_on_id ON public.service_history_services_2041 USING btree (id);


--
-- Name: index_service_history_services_2042_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2042_on_id ON public.service_history_services_2042 USING btree (id);


--
-- Name: index_service_history_services_2043_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2043_on_id ON public.service_history_services_2043 USING btree (id);


--
-- Name: index_service_history_services_2044_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2044_on_id ON public.service_history_services_2044 USING btree (id);


--
-- Name: index_service_history_services_2045_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2045_on_id ON public.service_history_services_2045 USING btree (id);


--
-- Name: index_service_history_services_2046_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2046_on_id ON public.service_history_services_2046 USING btree (id);


--
-- Name: index_service_history_services_2047_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2047_on_id ON public.service_history_services_2047 USING btree (id);


--
-- Name: index_service_history_services_2048_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2048_on_id ON public.service_history_services_2048 USING btree (id);


--
-- Name: index_service_history_services_2049_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2049_on_id ON public.service_history_services_2049 USING btree (id);


--
-- Name: index_service_history_services_2050_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_2050_on_id ON public.service_history_services_2050 USING btree (id);


--
-- Name: index_service_history_services_materialized_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_materialized_on_id ON public.service_history_services_materialized USING btree (id);


--
-- Name: index_service_history_services_remainder_on_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_service_history_services_remainder_on_id ON public.service_history_services_remainder USING btree (id);


--
-- Name: index_service_scanning_scanner_ids_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_scanning_scanner_ids_on_client_id ON public.service_scanning_scanner_ids USING btree (client_id);


--
-- Name: index_service_scanning_scanner_ids_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_scanning_scanner_ids_on_created_at ON public.service_scanning_scanner_ids USING btree (created_at);


--
-- Name: index_service_scanning_scanner_ids_on_scanned_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_scanning_scanner_ids_on_scanned_id ON public.service_scanning_scanner_ids USING btree (scanned_id);


--
-- Name: index_service_scanning_scanner_ids_on_source_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_scanning_scanner_ids_on_source_type ON public.service_scanning_scanner_ids USING btree (source_type);


--
-- Name: index_service_scanning_scanner_ids_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_scanning_scanner_ids_on_updated_at ON public.service_scanning_scanner_ids USING btree (updated_at);


--
-- Name: index_service_scanning_services_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_scanning_services_on_client_id ON public.service_scanning_services USING btree (client_id);


--
-- Name: index_service_scanning_services_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_scanning_services_on_created_at ON public.service_scanning_services USING btree (created_at);


--
-- Name: index_service_scanning_services_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_scanning_services_on_project_id ON public.service_scanning_services USING btree (project_id);


--
-- Name: index_service_scanning_services_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_scanning_services_on_type ON public.service_scanning_services USING btree (type);


--
-- Name: index_service_scanning_services_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_scanning_services_on_updated_at ON public.service_scanning_services USING btree (updated_at);


--
-- Name: index_service_scanning_services_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_scanning_services_on_user_id ON public.service_scanning_services USING btree (user_id);


--
-- Name: index_services_ds_id_p_id_type_entry_id_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_services_ds_id_p_id_type_entry_id_date ON public."Services" USING btree (data_source_id, "PersonalID", "RecordType", "EnrollmentID", "DateProvided");


--
-- Name: index_sh__enrollment_id_track_meth; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sh__enrollment_id_track_meth ON public.new_service_history USING btree (enrollment_group_id, project_tracking_method);


--
-- Name: index_sh_date_ds_org_proj_proj_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sh_date_ds_org_proj_proj_type ON public.new_service_history USING btree (record_type, date, data_source_id, organization_id, project_id, project_type, project_tracking_method);


--
-- Name: index_sh_date_r_type_indiv; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sh_date_r_type_indiv ON public.warehouse_client_service_history USING btree (date, record_type, presented_as_individual);


--
-- Name: index_sh_ds_id_org_id_proj_id_r_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sh_ds_id_org_id_proj_id_r_type ON public.warehouse_client_service_history USING btree (data_source_id, organization_id, project_id, record_type);


--
-- Name: index_sh_ds_proj_org_r_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sh_ds_proj_org_r_type ON public.new_service_history USING btree (data_source_id, project_id, organization_id, record_type);


--
-- Name: index_sh_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sh_on_client_id ON public.new_service_history USING btree (client_id, record_type);


--
-- Name: index_sh_on_computed_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sh_on_computed_project_type ON public.new_service_history USING btree (computed_project_type, record_type, client_id);


--
-- Name: index_sh_on_household_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sh_on_household_id ON public.new_service_history USING btree (date, household_id, record_type);


--
-- Name: index_sh_tracking_method; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sh_tracking_method ON public.warehouse_client_service_history USING btree (project_tracking_method);


--
-- Name: index_shape_block_groups_on_full_geoid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_block_groups_on_full_geoid ON public.shape_block_groups USING btree (full_geoid);


--
-- Name: index_shape_block_groups_on_geoid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shape_block_groups_on_geoid ON public.shape_block_groups USING btree (geoid);


--
-- Name: index_shape_block_groups_on_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_block_groups_on_geom ON public.shape_block_groups USING gist (geom);


--
-- Name: index_shape_block_groups_on_simplified_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_block_groups_on_simplified_geom ON public.shape_block_groups USING gist (simplified_geom);


--
-- Name: index_shape_cocs_on_cocname; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_cocs_on_cocname ON public.shape_cocs USING btree (cocname);


--
-- Name: index_shape_cocs_on_full_geoid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shape_cocs_on_full_geoid ON public.shape_cocs USING btree (full_geoid);


--
-- Name: index_shape_cocs_on_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_cocs_on_geom ON public.shape_cocs USING gist (geom);


--
-- Name: index_shape_cocs_on_simplified_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_cocs_on_simplified_geom ON public.shape_cocs USING gist (simplified_geom);


--
-- Name: index_shape_cocs_on_st; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_cocs_on_st ON public.shape_cocs USING btree (st);


--
-- Name: index_shape_counties_on_full_geoid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_counties_on_full_geoid ON public.shape_counties USING btree (full_geoid);


--
-- Name: index_shape_counties_on_geoid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shape_counties_on_geoid ON public.shape_counties USING btree (geoid);


--
-- Name: index_shape_counties_on_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_counties_on_geom ON public.shape_counties USING gist (geom);


--
-- Name: index_shape_counties_on_simplified_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_counties_on_simplified_geom ON public.shape_counties USING gist (simplified_geom);


--
-- Name: index_shape_counties_on_statefp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_counties_on_statefp ON public.shape_counties USING btree (statefp);


--
-- Name: index_shape_places_on_full_geoid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_places_on_full_geoid ON public.shape_places USING btree (full_geoid);


--
-- Name: index_shape_places_on_geoid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shape_places_on_geoid ON public.shape_places USING btree (geoid);


--
-- Name: index_shape_places_on_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_places_on_geom ON public.shape_places USING gist (geom);


--
-- Name: index_shape_places_on_simplified_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_places_on_simplified_geom ON public.shape_places USING gist (simplified_geom);


--
-- Name: index_shape_states_on_full_geoid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_states_on_full_geoid ON public.shape_states USING btree (full_geoid);


--
-- Name: index_shape_states_on_geoid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shape_states_on_geoid ON public.shape_states USING btree (geoid);


--
-- Name: index_shape_states_on_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_states_on_geom ON public.shape_states USING gist (geom);


--
-- Name: index_shape_states_on_simplified_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_states_on_simplified_geom ON public.shape_states USING gist (simplified_geom);


--
-- Name: index_shape_states_on_stusps; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_states_on_stusps ON public.shape_states USING btree (stusps);


--
-- Name: index_shape_towns_on_full_geoid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_towns_on_full_geoid ON public.shape_towns USING btree (full_geoid);


--
-- Name: index_shape_towns_on_geoid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shape_towns_on_geoid ON public.shape_towns USING btree (geoid);


--
-- Name: index_shape_towns_on_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_towns_on_geom ON public.shape_towns USING gist (geom);


--
-- Name: index_shape_towns_on_simplified_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_towns_on_simplified_geom ON public.shape_towns USING gist (simplified_geom);


--
-- Name: index_shape_zip_codes_on_full_geoid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_zip_codes_on_full_geoid ON public.shape_zip_codes USING btree (full_geoid);


--
-- Name: index_shape_zip_codes_on_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_zip_codes_on_geom ON public.shape_zip_codes USING gist (geom);


--
-- Name: index_shape_zip_codes_on_simplified_geom; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shape_zip_codes_on_simplified_geom ON public.shape_zip_codes USING gist (simplified_geom);


--
-- Name: index_shape_zip_codes_on_zcta5ce10; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shape_zip_codes_on_zcta5ce10 ON public.shape_zip_codes USING btree (zcta5ce10);


--
-- Name: index_she__enrollment_id_track_meth; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_she__enrollment_id_track_meth ON public.service_history_enrollments USING btree (enrollment_group_id, project_tracking_method);


--
-- Name: index_she_date_ds_org_proj_proj_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_she_date_ds_org_proj_proj_type ON public.service_history_enrollments USING btree (record_type, date, data_source_id, organization_id, project_id, project_type, project_tracking_method);


--
-- Name: index_she_date_r_type_indiv; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_she_date_r_type_indiv ON public.service_history_enrollments USING btree (date, record_type, presented_as_individual);


--
-- Name: index_she_ds_proj_org_r_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_she_ds_proj_org_r_type ON public.service_history_enrollments USING btree (data_source_id, project_id, organization_id, record_type);


--
-- Name: index_she_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_she_on_client_id ON public.service_history_enrollments USING btree (client_id, record_type);


--
-- Name: index_she_on_computed_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_she_on_computed_project_type ON public.service_history_enrollments USING btree (computed_project_type, record_type, client_id);


--
-- Name: index_she_on_first_date_in_program; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_she_on_first_date_in_program ON public.service_history_enrollments USING brin (first_date_in_program);


--
-- Name: index_she_on_household_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_she_on_household_id ON public.service_history_enrollments USING btree (date, household_id, record_type);


--
-- Name: index_she_on_last_date_in_program; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_she_on_last_date_in_program ON public.service_history_enrollments USING btree (first_date_in_program, last_date_in_program, record_type, date);


--
-- Name: index_shs_1900_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_1900_date_brin ON public.service_history_services_remainder USING brin (date);


--
-- Name: index_shs_1900_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_1900_date_client_id ON public.service_history_services_remainder USING btree (date, client_id);


--
-- Name: index_shs_1900_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_1900_date_en_id ON public.service_history_services_remainder USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_1900_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_1900_date_project_type ON public.service_history_services_remainder USING btree (date, project_type);


--
-- Name: index_shs_2000_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2000_c_id_en_id ON public.service_history_services_2000 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2000_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2000_client_id_only ON public.service_history_services_2000 USING btree (client_id);


--
-- Name: index_shs_2000_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2000_date_brin ON public.service_history_services_2000 USING brin (date);


--
-- Name: index_shs_2000_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2000_date_client_id ON public.service_history_services_2000 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2000_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2000_date_en_id ON public.service_history_services_2000 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2000_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2000_date_project_type ON public.service_history_services_2000 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2000_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2000_en_id_only ON public.service_history_services_2000 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2001_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2001_c_id_en_id ON public.service_history_services_2001 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2001_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2001_client_id_only ON public.service_history_services_2001 USING btree (client_id);


--
-- Name: index_shs_2001_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2001_date_brin ON public.service_history_services_2001 USING brin (date);


--
-- Name: index_shs_2001_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2001_date_client_id ON public.service_history_services_2001 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2001_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2001_date_en_id ON public.service_history_services_2001 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2001_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2001_date_project_type ON public.service_history_services_2001 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2001_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2001_en_id_only ON public.service_history_services_2001 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2002_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2002_c_id_en_id ON public.service_history_services_2002 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2002_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2002_client_id_only ON public.service_history_services_2002 USING btree (client_id);


--
-- Name: index_shs_2002_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2002_date_brin ON public.service_history_services_2002 USING brin (date);


--
-- Name: index_shs_2002_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2002_date_client_id ON public.service_history_services_2002 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2002_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2002_date_en_id ON public.service_history_services_2002 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2002_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2002_date_project_type ON public.service_history_services_2002 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2002_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2002_en_id_only ON public.service_history_services_2002 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2003_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2003_c_id_en_id ON public.service_history_services_2003 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2003_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2003_client_id_only ON public.service_history_services_2003 USING btree (client_id);


--
-- Name: index_shs_2003_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2003_date_brin ON public.service_history_services_2003 USING brin (date);


--
-- Name: index_shs_2003_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2003_date_client_id ON public.service_history_services_2003 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2003_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2003_date_en_id ON public.service_history_services_2003 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2003_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2003_date_project_type ON public.service_history_services_2003 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2003_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2003_en_id_only ON public.service_history_services_2003 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2004_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2004_c_id_en_id ON public.service_history_services_2004 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2004_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2004_client_id_only ON public.service_history_services_2004 USING btree (client_id);


--
-- Name: index_shs_2004_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2004_date_brin ON public.service_history_services_2004 USING brin (date);


--
-- Name: index_shs_2004_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2004_date_client_id ON public.service_history_services_2004 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2004_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2004_date_en_id ON public.service_history_services_2004 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2004_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2004_date_project_type ON public.service_history_services_2004 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2004_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2004_en_id_only ON public.service_history_services_2004 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2005_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2005_c_id_en_id ON public.service_history_services_2005 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2005_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2005_client_id_only ON public.service_history_services_2005 USING btree (client_id);


--
-- Name: index_shs_2005_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2005_date_brin ON public.service_history_services_2005 USING brin (date);


--
-- Name: index_shs_2005_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2005_date_client_id ON public.service_history_services_2005 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2005_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2005_date_en_id ON public.service_history_services_2005 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2005_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2005_date_project_type ON public.service_history_services_2005 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2005_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2005_en_id_only ON public.service_history_services_2005 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2006_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2006_c_id_en_id ON public.service_history_services_2006 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2006_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2006_client_id_only ON public.service_history_services_2006 USING btree (client_id);


--
-- Name: index_shs_2006_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2006_date_brin ON public.service_history_services_2006 USING brin (date);


--
-- Name: index_shs_2006_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2006_date_client_id ON public.service_history_services_2006 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2006_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2006_date_en_id ON public.service_history_services_2006 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2006_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2006_date_project_type ON public.service_history_services_2006 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2006_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2006_en_id_only ON public.service_history_services_2006 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2007_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2007_c_id_en_id ON public.service_history_services_2007 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2007_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2007_client_id_only ON public.service_history_services_2007 USING btree (client_id);


--
-- Name: index_shs_2007_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2007_date_brin ON public.service_history_services_2007 USING brin (date);


--
-- Name: index_shs_2007_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2007_date_client_id ON public.service_history_services_2007 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2007_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2007_date_en_id ON public.service_history_services_2007 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2007_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2007_date_project_type ON public.service_history_services_2007 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2007_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2007_en_id_only ON public.service_history_services_2007 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2008_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2008_c_id_en_id ON public.service_history_services_2008 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2008_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2008_client_id_only ON public.service_history_services_2008 USING btree (client_id);


--
-- Name: index_shs_2008_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2008_date_brin ON public.service_history_services_2008 USING brin (date);


--
-- Name: index_shs_2008_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2008_date_client_id ON public.service_history_services_2008 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2008_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2008_date_en_id ON public.service_history_services_2008 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2008_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2008_date_project_type ON public.service_history_services_2008 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2008_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2008_en_id_only ON public.service_history_services_2008 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2009_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2009_c_id_en_id ON public.service_history_services_2009 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2009_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2009_client_id_only ON public.service_history_services_2009 USING btree (client_id);


--
-- Name: index_shs_2009_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2009_date_brin ON public.service_history_services_2009 USING brin (date);


--
-- Name: index_shs_2009_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2009_date_client_id ON public.service_history_services_2009 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2009_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2009_date_en_id ON public.service_history_services_2009 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2009_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2009_date_project_type ON public.service_history_services_2009 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2009_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2009_en_id_only ON public.service_history_services_2009 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2010_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2010_c_id_en_id ON public.service_history_services_2010 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2010_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2010_client_id_only ON public.service_history_services_2010 USING btree (client_id);


--
-- Name: index_shs_2010_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2010_date_brin ON public.service_history_services_2010 USING brin (date);


--
-- Name: index_shs_2010_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2010_date_client_id ON public.service_history_services_2010 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2010_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2010_date_en_id ON public.service_history_services_2010 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2010_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2010_date_project_type ON public.service_history_services_2010 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2010_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2010_en_id_only ON public.service_history_services_2010 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2011_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2011_c_id_en_id ON public.service_history_services_2011 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2011_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2011_client_id_only ON public.service_history_services_2011 USING btree (client_id);


--
-- Name: index_shs_2011_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2011_date_brin ON public.service_history_services_2011 USING brin (date);


--
-- Name: index_shs_2011_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2011_date_client_id ON public.service_history_services_2011 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2011_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2011_date_en_id ON public.service_history_services_2011 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2011_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2011_date_project_type ON public.service_history_services_2011 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2011_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2011_en_id_only ON public.service_history_services_2011 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2012_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2012_c_id_en_id ON public.service_history_services_2012 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2012_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2012_client_id_only ON public.service_history_services_2012 USING btree (client_id);


--
-- Name: index_shs_2012_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2012_date_brin ON public.service_history_services_2012 USING brin (date);


--
-- Name: index_shs_2012_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2012_date_client_id ON public.service_history_services_2012 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2012_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2012_date_en_id ON public.service_history_services_2012 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2012_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2012_date_project_type ON public.service_history_services_2012 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2012_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2012_en_id_only ON public.service_history_services_2012 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2013_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2013_c_id_en_id ON public.service_history_services_2013 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2013_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2013_client_id_only ON public.service_history_services_2013 USING btree (client_id);


--
-- Name: index_shs_2013_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2013_date_brin ON public.service_history_services_2013 USING brin (date);


--
-- Name: index_shs_2013_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2013_date_client_id ON public.service_history_services_2013 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2013_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2013_date_en_id ON public.service_history_services_2013 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2013_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2013_date_project_type ON public.service_history_services_2013 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2013_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2013_en_id_only ON public.service_history_services_2013 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2014_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2014_c_id_en_id ON public.service_history_services_2014 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2014_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2014_client_id_only ON public.service_history_services_2014 USING btree (client_id);


--
-- Name: index_shs_2014_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2014_date_brin ON public.service_history_services_2014 USING brin (date);


--
-- Name: index_shs_2014_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2014_date_client_id ON public.service_history_services_2014 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2014_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2014_date_en_id ON public.service_history_services_2014 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2014_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2014_date_project_type ON public.service_history_services_2014 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2014_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2014_en_id_only ON public.service_history_services_2014 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2015_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2015_c_id_en_id ON public.service_history_services_2015 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2015_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2015_client_id_only ON public.service_history_services_2015 USING btree (client_id);


--
-- Name: index_shs_2015_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2015_date_brin ON public.service_history_services_2015 USING brin (date);


--
-- Name: index_shs_2015_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2015_date_client_id ON public.service_history_services_2015 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2015_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2015_date_en_id ON public.service_history_services_2015 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2015_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2015_date_project_type ON public.service_history_services_2015 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2015_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2015_en_id_only ON public.service_history_services_2015 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2016_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2016_c_id_en_id ON public.service_history_services_2016 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2016_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2016_client_id_only ON public.service_history_services_2016 USING btree (client_id);


--
-- Name: index_shs_2016_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2016_date_brin ON public.service_history_services_2016 USING brin (date);


--
-- Name: index_shs_2016_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2016_date_client_id ON public.service_history_services_2016 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2016_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2016_date_en_id ON public.service_history_services_2016 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2016_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2016_date_project_type ON public.service_history_services_2016 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2016_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2016_en_id_only ON public.service_history_services_2016 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2017_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2017_c_id_en_id ON public.service_history_services_2017 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2017_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2017_client_id_only ON public.service_history_services_2017 USING btree (client_id);


--
-- Name: index_shs_2017_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2017_date_brin ON public.service_history_services_2017 USING brin (date);


--
-- Name: index_shs_2017_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2017_date_client_id ON public.service_history_services_2017 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2017_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2017_date_en_id ON public.service_history_services_2017 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2017_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2017_date_project_type ON public.service_history_services_2017 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2017_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2017_en_id_only ON public.service_history_services_2017 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2018_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2018_c_id_en_id ON public.service_history_services_2018 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2018_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2018_client_id_only ON public.service_history_services_2018 USING btree (client_id);


--
-- Name: index_shs_2018_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2018_date_brin ON public.service_history_services_2018 USING brin (date);


--
-- Name: index_shs_2018_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2018_date_client_id ON public.service_history_services_2018 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2018_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2018_date_en_id ON public.service_history_services_2018 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2018_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2018_date_project_type ON public.service_history_services_2018 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2018_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2018_en_id_only ON public.service_history_services_2018 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2019_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2019_c_id_en_id ON public.service_history_services_2019 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2019_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2019_client_id_only ON public.service_history_services_2019 USING btree (client_id);


--
-- Name: index_shs_2019_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2019_date_brin ON public.service_history_services_2019 USING brin (date);


--
-- Name: index_shs_2019_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2019_date_client_id ON public.service_history_services_2019 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2019_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2019_date_en_id ON public.service_history_services_2019 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2019_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2019_date_project_type ON public.service_history_services_2019 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2019_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2019_en_id_only ON public.service_history_services_2019 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2020_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2020_c_id_en_id ON public.service_history_services_2020 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2020_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2020_client_id_only ON public.service_history_services_2020 USING btree (client_id);


--
-- Name: index_shs_2020_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2020_date_brin ON public.service_history_services_2020 USING brin (date);


--
-- Name: index_shs_2020_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2020_date_client_id ON public.service_history_services_2020 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2020_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2020_date_en_id ON public.service_history_services_2020 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2020_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2020_date_project_type ON public.service_history_services_2020 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2020_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2020_en_id_only ON public.service_history_services_2020 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2021_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2021_c_id_en_id ON public.service_history_services_2021 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2021_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2021_client_id_only ON public.service_history_services_2021 USING btree (client_id);


--
-- Name: index_shs_2021_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2021_date_brin ON public.service_history_services_2021 USING brin (date);


--
-- Name: index_shs_2021_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2021_date_client_id ON public.service_history_services_2021 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2021_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2021_date_en_id ON public.service_history_services_2021 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2021_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2021_date_project_type ON public.service_history_services_2021 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2021_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2021_en_id_only ON public.service_history_services_2021 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2022_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2022_c_id_en_id ON public.service_history_services_2022 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2022_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2022_client_id_only ON public.service_history_services_2022 USING btree (client_id);


--
-- Name: index_shs_2022_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2022_date_brin ON public.service_history_services_2022 USING brin (date);


--
-- Name: index_shs_2022_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2022_date_client_id ON public.service_history_services_2022 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2022_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2022_date_en_id ON public.service_history_services_2022 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2022_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2022_date_project_type ON public.service_history_services_2022 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2022_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2022_en_id_only ON public.service_history_services_2022 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2023_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2023_c_id_en_id ON public.service_history_services_2023 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2023_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2023_client_id_only ON public.service_history_services_2023 USING btree (client_id);


--
-- Name: index_shs_2023_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2023_date_brin ON public.service_history_services_2023 USING brin (date);


--
-- Name: index_shs_2023_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2023_date_client_id ON public.service_history_services_2023 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2023_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2023_date_en_id ON public.service_history_services_2023 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2023_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2023_date_project_type ON public.service_history_services_2023 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2023_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2023_en_id_only ON public.service_history_services_2023 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2024_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2024_c_id_en_id ON public.service_history_services_2024 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2024_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2024_client_id_only ON public.service_history_services_2024 USING btree (client_id);


--
-- Name: index_shs_2024_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2024_date_brin ON public.service_history_services_2024 USING brin (date);


--
-- Name: index_shs_2024_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2024_date_client_id ON public.service_history_services_2024 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2024_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2024_date_en_id ON public.service_history_services_2024 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2024_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2024_date_project_type ON public.service_history_services_2024 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2024_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2024_en_id_only ON public.service_history_services_2024 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2025_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2025_c_id_en_id ON public.service_history_services_2025 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2025_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2025_client_id_only ON public.service_history_services_2025 USING btree (client_id);


--
-- Name: index_shs_2025_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2025_date_brin ON public.service_history_services_2025 USING brin (date);


--
-- Name: index_shs_2025_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2025_date_client_id ON public.service_history_services_2025 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2025_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2025_date_en_id ON public.service_history_services_2025 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2025_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2025_date_project_type ON public.service_history_services_2025 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2025_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2025_en_id_only ON public.service_history_services_2025 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2026_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2026_c_id_en_id ON public.service_history_services_2026 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2026_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2026_client_id_only ON public.service_history_services_2026 USING btree (client_id);


--
-- Name: index_shs_2026_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2026_date_brin ON public.service_history_services_2026 USING brin (date);


--
-- Name: index_shs_2026_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2026_date_client_id ON public.service_history_services_2026 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2026_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2026_date_en_id ON public.service_history_services_2026 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2026_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2026_date_project_type ON public.service_history_services_2026 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2026_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2026_en_id_only ON public.service_history_services_2026 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2027_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2027_c_id_en_id ON public.service_history_services_2027 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2027_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2027_client_id_only ON public.service_history_services_2027 USING btree (client_id);


--
-- Name: index_shs_2027_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2027_date_brin ON public.service_history_services_2027 USING brin (date);


--
-- Name: index_shs_2027_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2027_date_client_id ON public.service_history_services_2027 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2027_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2027_date_en_id ON public.service_history_services_2027 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2027_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2027_date_project_type ON public.service_history_services_2027 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2027_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2027_en_id_only ON public.service_history_services_2027 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2028_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2028_c_id_en_id ON public.service_history_services_2028 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2028_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2028_client_id_only ON public.service_history_services_2028 USING btree (client_id);


--
-- Name: index_shs_2028_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2028_date_brin ON public.service_history_services_2028 USING brin (date);


--
-- Name: index_shs_2028_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2028_date_client_id ON public.service_history_services_2028 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2028_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2028_date_en_id ON public.service_history_services_2028 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2028_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2028_date_project_type ON public.service_history_services_2028 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2028_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2028_en_id_only ON public.service_history_services_2028 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2029_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2029_c_id_en_id ON public.service_history_services_2029 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2029_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2029_client_id_only ON public.service_history_services_2029 USING btree (client_id);


--
-- Name: index_shs_2029_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2029_date_brin ON public.service_history_services_2029 USING brin (date);


--
-- Name: index_shs_2029_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2029_date_client_id ON public.service_history_services_2029 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2029_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2029_date_en_id ON public.service_history_services_2029 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2029_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2029_date_project_type ON public.service_history_services_2029 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2029_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2029_en_id_only ON public.service_history_services_2029 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2030_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2030_c_id_en_id ON public.service_history_services_2030 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2030_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2030_client_id_only ON public.service_history_services_2030 USING btree (client_id);


--
-- Name: index_shs_2030_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2030_date_brin ON public.service_history_services_2030 USING brin (date);


--
-- Name: index_shs_2030_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2030_date_client_id ON public.service_history_services_2030 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2030_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2030_date_en_id ON public.service_history_services_2030 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2030_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2030_date_project_type ON public.service_history_services_2030 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2030_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2030_en_id_only ON public.service_history_services_2030 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2031_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2031_c_id_en_id ON public.service_history_services_2031 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2031_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2031_client_id_only ON public.service_history_services_2031 USING btree (client_id);


--
-- Name: index_shs_2031_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2031_date_brin ON public.service_history_services_2031 USING brin (date);


--
-- Name: index_shs_2031_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2031_date_client_id ON public.service_history_services_2031 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2031_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2031_date_en_id ON public.service_history_services_2031 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2031_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2031_date_project_type ON public.service_history_services_2031 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2031_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2031_en_id_only ON public.service_history_services_2031 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2032_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2032_c_id_en_id ON public.service_history_services_2032 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2032_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2032_client_id_only ON public.service_history_services_2032 USING btree (client_id);


--
-- Name: index_shs_2032_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2032_date_brin ON public.service_history_services_2032 USING brin (date);


--
-- Name: index_shs_2032_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2032_date_client_id ON public.service_history_services_2032 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2032_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2032_date_en_id ON public.service_history_services_2032 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2032_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2032_date_project_type ON public.service_history_services_2032 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2032_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2032_en_id_only ON public.service_history_services_2032 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2033_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2033_c_id_en_id ON public.service_history_services_2033 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2033_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2033_client_id_only ON public.service_history_services_2033 USING btree (client_id);


--
-- Name: index_shs_2033_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2033_date_brin ON public.service_history_services_2033 USING brin (date);


--
-- Name: index_shs_2033_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2033_date_client_id ON public.service_history_services_2033 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2033_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2033_date_en_id ON public.service_history_services_2033 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2033_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2033_date_project_type ON public.service_history_services_2033 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2033_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2033_en_id_only ON public.service_history_services_2033 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2034_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2034_c_id_en_id ON public.service_history_services_2034 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2034_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2034_client_id_only ON public.service_history_services_2034 USING btree (client_id);


--
-- Name: index_shs_2034_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2034_date_brin ON public.service_history_services_2034 USING brin (date);


--
-- Name: index_shs_2034_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2034_date_client_id ON public.service_history_services_2034 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2034_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2034_date_en_id ON public.service_history_services_2034 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2034_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2034_date_project_type ON public.service_history_services_2034 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2034_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2034_en_id_only ON public.service_history_services_2034 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2035_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2035_c_id_en_id ON public.service_history_services_2035 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2035_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2035_client_id_only ON public.service_history_services_2035 USING btree (client_id);


--
-- Name: index_shs_2035_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2035_date_brin ON public.service_history_services_2035 USING brin (date);


--
-- Name: index_shs_2035_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2035_date_client_id ON public.service_history_services_2035 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2035_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2035_date_en_id ON public.service_history_services_2035 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2035_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2035_date_project_type ON public.service_history_services_2035 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2035_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2035_en_id_only ON public.service_history_services_2035 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2036_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2036_c_id_en_id ON public.service_history_services_2036 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2036_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2036_client_id_only ON public.service_history_services_2036 USING btree (client_id);


--
-- Name: index_shs_2036_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2036_date_brin ON public.service_history_services_2036 USING brin (date);


--
-- Name: index_shs_2036_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2036_date_client_id ON public.service_history_services_2036 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2036_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2036_date_en_id ON public.service_history_services_2036 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2036_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2036_date_project_type ON public.service_history_services_2036 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2036_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2036_en_id_only ON public.service_history_services_2036 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2037_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2037_c_id_en_id ON public.service_history_services_2037 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2037_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2037_client_id_only ON public.service_history_services_2037 USING btree (client_id);


--
-- Name: index_shs_2037_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2037_date_brin ON public.service_history_services_2037 USING brin (date);


--
-- Name: index_shs_2037_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2037_date_client_id ON public.service_history_services_2037 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2037_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2037_date_en_id ON public.service_history_services_2037 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2037_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2037_date_project_type ON public.service_history_services_2037 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2037_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2037_en_id_only ON public.service_history_services_2037 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2038_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2038_c_id_en_id ON public.service_history_services_2038 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2038_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2038_client_id_only ON public.service_history_services_2038 USING btree (client_id);


--
-- Name: index_shs_2038_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2038_date_brin ON public.service_history_services_2038 USING brin (date);


--
-- Name: index_shs_2038_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2038_date_client_id ON public.service_history_services_2038 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2038_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2038_date_en_id ON public.service_history_services_2038 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2038_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2038_date_project_type ON public.service_history_services_2038 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2038_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2038_en_id_only ON public.service_history_services_2038 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2039_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2039_c_id_en_id ON public.service_history_services_2039 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2039_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2039_client_id_only ON public.service_history_services_2039 USING btree (client_id);


--
-- Name: index_shs_2039_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2039_date_brin ON public.service_history_services_2039 USING brin (date);


--
-- Name: index_shs_2039_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2039_date_client_id ON public.service_history_services_2039 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2039_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2039_date_en_id ON public.service_history_services_2039 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2039_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2039_date_project_type ON public.service_history_services_2039 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2039_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2039_en_id_only ON public.service_history_services_2039 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2040_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2040_c_id_en_id ON public.service_history_services_2040 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2040_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2040_client_id_only ON public.service_history_services_2040 USING btree (client_id);


--
-- Name: index_shs_2040_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2040_date_brin ON public.service_history_services_2040 USING brin (date);


--
-- Name: index_shs_2040_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2040_date_client_id ON public.service_history_services_2040 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2040_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2040_date_en_id ON public.service_history_services_2040 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2040_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2040_date_project_type ON public.service_history_services_2040 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2040_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2040_en_id_only ON public.service_history_services_2040 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2041_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2041_c_id_en_id ON public.service_history_services_2041 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2041_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2041_client_id_only ON public.service_history_services_2041 USING btree (client_id);


--
-- Name: index_shs_2041_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2041_date_brin ON public.service_history_services_2041 USING brin (date);


--
-- Name: index_shs_2041_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2041_date_client_id ON public.service_history_services_2041 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2041_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2041_date_en_id ON public.service_history_services_2041 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2041_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2041_date_project_type ON public.service_history_services_2041 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2041_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2041_en_id_only ON public.service_history_services_2041 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2042_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2042_c_id_en_id ON public.service_history_services_2042 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2042_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2042_client_id_only ON public.service_history_services_2042 USING btree (client_id);


--
-- Name: index_shs_2042_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2042_date_brin ON public.service_history_services_2042 USING brin (date);


--
-- Name: index_shs_2042_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2042_date_client_id ON public.service_history_services_2042 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2042_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2042_date_en_id ON public.service_history_services_2042 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2042_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2042_date_project_type ON public.service_history_services_2042 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2042_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2042_en_id_only ON public.service_history_services_2042 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2043_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2043_c_id_en_id ON public.service_history_services_2043 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2043_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2043_client_id_only ON public.service_history_services_2043 USING btree (client_id);


--
-- Name: index_shs_2043_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2043_date_brin ON public.service_history_services_2043 USING brin (date);


--
-- Name: index_shs_2043_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2043_date_client_id ON public.service_history_services_2043 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2043_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2043_date_en_id ON public.service_history_services_2043 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2043_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2043_date_project_type ON public.service_history_services_2043 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2043_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2043_en_id_only ON public.service_history_services_2043 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2044_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2044_c_id_en_id ON public.service_history_services_2044 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2044_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2044_client_id_only ON public.service_history_services_2044 USING btree (client_id);


--
-- Name: index_shs_2044_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2044_date_brin ON public.service_history_services_2044 USING brin (date);


--
-- Name: index_shs_2044_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2044_date_client_id ON public.service_history_services_2044 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2044_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2044_date_en_id ON public.service_history_services_2044 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2044_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2044_date_project_type ON public.service_history_services_2044 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2044_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2044_en_id_only ON public.service_history_services_2044 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2045_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2045_c_id_en_id ON public.service_history_services_2045 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2045_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2045_client_id_only ON public.service_history_services_2045 USING btree (client_id);


--
-- Name: index_shs_2045_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2045_date_brin ON public.service_history_services_2045 USING brin (date);


--
-- Name: index_shs_2045_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2045_date_client_id ON public.service_history_services_2045 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2045_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2045_date_en_id ON public.service_history_services_2045 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2045_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2045_date_project_type ON public.service_history_services_2045 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2045_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2045_en_id_only ON public.service_history_services_2045 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2046_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2046_c_id_en_id ON public.service_history_services_2046 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2046_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2046_client_id_only ON public.service_history_services_2046 USING btree (client_id);


--
-- Name: index_shs_2046_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2046_date_brin ON public.service_history_services_2046 USING brin (date);


--
-- Name: index_shs_2046_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2046_date_client_id ON public.service_history_services_2046 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2046_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2046_date_en_id ON public.service_history_services_2046 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2046_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2046_date_project_type ON public.service_history_services_2046 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2046_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2046_en_id_only ON public.service_history_services_2046 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2047_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2047_c_id_en_id ON public.service_history_services_2047 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2047_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2047_client_id_only ON public.service_history_services_2047 USING btree (client_id);


--
-- Name: index_shs_2047_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2047_date_brin ON public.service_history_services_2047 USING brin (date);


--
-- Name: index_shs_2047_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2047_date_client_id ON public.service_history_services_2047 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2047_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2047_date_en_id ON public.service_history_services_2047 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2047_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2047_date_project_type ON public.service_history_services_2047 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2047_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2047_en_id_only ON public.service_history_services_2047 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2048_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2048_c_id_en_id ON public.service_history_services_2048 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2048_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2048_client_id_only ON public.service_history_services_2048 USING btree (client_id);


--
-- Name: index_shs_2048_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2048_date_brin ON public.service_history_services_2048 USING brin (date);


--
-- Name: index_shs_2048_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2048_date_client_id ON public.service_history_services_2048 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2048_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2048_date_en_id ON public.service_history_services_2048 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2048_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2048_date_project_type ON public.service_history_services_2048 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2048_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2048_en_id_only ON public.service_history_services_2048 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2049_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2049_c_id_en_id ON public.service_history_services_2049 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2049_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2049_client_id_only ON public.service_history_services_2049 USING btree (client_id);


--
-- Name: index_shs_2049_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2049_date_brin ON public.service_history_services_2049 USING brin (date);


--
-- Name: index_shs_2049_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2049_date_client_id ON public.service_history_services_2049 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2049_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2049_date_en_id ON public.service_history_services_2049 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2049_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2049_date_project_type ON public.service_history_services_2049 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2049_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2049_en_id_only ON public.service_history_services_2049 USING btree (service_history_enrollment_id);


--
-- Name: index_shs_2050_c_id_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2050_c_id_en_id ON public.service_history_services_2050 USING btree (client_id, service_history_enrollment_id);


--
-- Name: index_shs_2050_client_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2050_client_id_only ON public.service_history_services_2050 USING btree (client_id);


--
-- Name: index_shs_2050_date_brin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2050_date_brin ON public.service_history_services_2050 USING brin (date);


--
-- Name: index_shs_2050_date_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2050_date_client_id ON public.service_history_services_2050 USING btree (client_id, date, record_type);


--
-- Name: index_shs_2050_date_en_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shs_2050_date_en_id ON public.service_history_services_2050 USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_2050_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2050_date_project_type ON public.service_history_services_2050 USING btree (project_type, date, record_type);


--
-- Name: index_shs_2050_en_id_only; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2050_en_id_only ON public.service_history_services_2050 USING btree (service_history_enrollment_id);


--
-- Name: index_shsm_c_id_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shsm_c_id_date ON public.service_history_services_materialized USING btree (client_id, date);


--
-- Name: index_shsm_c_id_p_type_r_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shsm_c_id_p_type_r_type ON public.service_history_services_materialized USING btree (client_id, project_type, record_type);


--
-- Name: index_shsm_homeless_p_type_c_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shsm_homeless_p_type_c_id ON public.service_history_services_materialized USING btree (homeless, project_type, client_id);


--
-- Name: index_shsm_literally_homeless_p_type_c_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shsm_literally_homeless_p_type_c_id ON public.service_history_services_materialized USING btree (literally_homeless, project_type, client_id);


--
-- Name: index_shsm_shse_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shsm_shse_id ON public.service_history_services_materialized USING btree (service_history_enrollment_id);


--
-- Name: index_simple_report_cells_on_report_instance_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_simple_report_cells_on_report_instance_id ON public.simple_report_cells USING btree (report_instance_id);


--
-- Name: index_simple_report_instances_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_simple_report_instances_on_user_id ON public.simple_report_instances USING btree (user_id);


--
-- Name: index_simple_report_universe_members_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_simple_report_universe_members_on_client_id ON public.simple_report_universe_members USING btree (client_id);


--
-- Name: index_simple_report_universe_members_on_report_cell_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_simple_report_universe_members_on_report_cell_id ON public.simple_report_universe_members USING btree (report_cell_id);


--
-- Name: index_staff_x_client_s_id_c_id_r_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_staff_x_client_s_id_c_id_r_id ON public.hmis_staff_x_clients USING btree (staff_id, client_id, relationship_id);


--
-- Name: index_synthetic_assessments_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synthetic_assessments_on_client_id ON public.synthetic_assessments USING btree (client_id);


--
-- Name: index_synthetic_assessments_on_enrollment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synthetic_assessments_on_enrollment_id ON public.synthetic_assessments USING btree (enrollment_id);


--
-- Name: index_synthetic_assessments_on_hud_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synthetic_assessments_on_hud_assessment_id ON public.synthetic_assessments USING btree (hud_assessment_id);


--
-- Name: index_synthetic_assessments_on_source_type_and_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synthetic_assessments_on_source_type_and_source_id ON public.synthetic_assessments USING btree (source_type, source_id);


--
-- Name: index_synthetic_events_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synthetic_events_on_client_id ON public.synthetic_events USING btree (client_id);


--
-- Name: index_synthetic_events_on_enrollment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synthetic_events_on_enrollment_id ON public.synthetic_events USING btree (enrollment_id);


--
-- Name: index_synthetic_events_on_hud_event_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synthetic_events_on_hud_event_id ON public.synthetic_events USING btree (hud_event_id);


--
-- Name: index_synthetic_events_on_source_type_and_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_synthetic_events_on_source_type_and_source_id ON public.synthetic_events USING btree (source_type, source_id);


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
-- Name: index_talentlms_logins_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_talentlms_logins_on_user_id ON public.talentlms_logins USING btree (user_id);


--
-- Name: index_text_message_messages_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_text_message_messages_on_created_at ON public.text_message_messages USING btree (created_at);


--
-- Name: index_text_message_messages_on_subscriber_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_text_message_messages_on_subscriber_id ON public.text_message_messages USING btree (subscriber_id);


--
-- Name: index_text_message_messages_on_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_text_message_messages_on_topic_id ON public.text_message_messages USING btree (topic_id);


--
-- Name: index_text_message_messages_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_text_message_messages_on_updated_at ON public.text_message_messages USING btree (updated_at);


--
-- Name: index_text_message_topic_subscribers_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_text_message_topic_subscribers_on_created_at ON public.text_message_topic_subscribers USING btree (created_at);


--
-- Name: index_text_message_topic_subscribers_on_topic_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_text_message_topic_subscribers_on_topic_id ON public.text_message_topic_subscribers USING btree (topic_id);


--
-- Name: index_text_message_topic_subscribers_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_text_message_topic_subscribers_on_updated_at ON public.text_message_topic_subscribers USING btree (updated_at);


--
-- Name: index_text_message_topics_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_text_message_topics_on_created_at ON public.text_message_topics USING btree (created_at);


--
-- Name: index_text_message_topics_on_title; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_text_message_topics_on_title ON public.text_message_topics USING btree (title);


--
-- Name: index_text_message_topics_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_text_message_topics_on_updated_at ON public.text_message_topics USING btree (updated_at);


--
-- Name: index_universe_type_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_universe_type_and_id ON public.hud_report_universe_members USING btree (universe_membership_type, universe_membership_id);


--
-- Name: index_uploads_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_uploads_on_deleted_at ON public.uploads USING btree (deleted_at);


--
-- Name: index_user_client_permissions_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_client_permissions_on_client_id ON public.user_client_permissions USING btree (client_id);


--
-- Name: index_user_client_permissions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_client_permissions_on_user_id ON public.user_client_permissions USING btree (user_id);


--
-- Name: index_user_clients_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_clients_on_client_id ON public.user_clients USING btree (client_id);


--
-- Name: index_user_clients_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_clients_on_user_id ON public.user_clients USING btree (user_id);


--
-- Name: index_vispdats_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vispdats_on_client_id ON public.vispdats USING btree (client_id);


--
-- Name: index_vispdats_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vispdats_on_user_id ON public.vispdats USING btree (user_id);


--
-- Name: index_warehouse_client_service_history_on_computed_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_computed_project_type ON public.warehouse_client_service_history USING btree (computed_project_type);


--
-- Name: index_warehouse_client_service_history_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_data_source_id ON public.warehouse_client_service_history USING btree (data_source_id);


--
-- Name: index_warehouse_client_service_history_on_enrollment_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_enrollment_group_id ON public.warehouse_client_service_history USING btree (enrollment_group_id);


--
-- Name: index_warehouse_client_service_history_on_first_date_in_program; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_first_date_in_program ON public.warehouse_client_service_history USING btree (first_date_in_program);


--
-- Name: index_warehouse_client_service_history_on_household_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_household_id ON public.warehouse_client_service_history USING btree (household_id);


--
-- Name: index_warehouse_client_service_history_on_last_date_in_program; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_last_date_in_program ON public.warehouse_client_service_history USING btree (last_date_in_program);


--
-- Name: index_warehouse_client_service_history_on_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_project_type ON public.warehouse_client_service_history USING btree (project_type);


--
-- Name: index_warehouse_client_service_history_on_record_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_record_type ON public.warehouse_client_service_history USING btree (record_type);


--
-- Name: index_warehouse_clients_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_clients_on_data_source_id ON public.warehouse_clients USING btree (data_source_id);


--
-- Name: index_warehouse_clients_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_clients_on_deleted_at ON public.warehouse_clients USING btree (deleted_at);


--
-- Name: index_warehouse_clients_on_destination_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_clients_on_destination_id ON public.warehouse_clients USING btree (destination_id);


--
-- Name: index_warehouse_clients_on_id_in_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_clients_on_id_in_source ON public.warehouse_clients USING btree (id_in_source);


--
-- Name: index_warehouse_clients_on_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_warehouse_clients_on_source_id ON public.warehouse_clients USING btree (source_id);


--
-- Name: index_warehouse_clients_processed_on_chronic_days; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_clients_processed_on_chronic_days ON public.warehouse_clients_processed USING btree (chronic_days);


--
-- Name: index_warehouse_clients_processed_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_clients_processed_on_client_id ON public.warehouse_clients_processed USING btree (client_id);


--
-- Name: index_warehouse_clients_processed_on_days_served; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_clients_processed_on_days_served ON public.warehouse_clients_processed USING btree (days_served);


--
-- Name: index_warehouse_clients_processed_on_homeless_days; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_clients_processed_on_homeless_days ON public.warehouse_clients_processed USING btree (homeless_days);


--
-- Name: index_warehouse_clients_processed_on_routine; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_clients_processed_on_routine ON public.warehouse_clients_processed USING btree (routine);


--
-- Name: index_weather_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_weather_on_url ON public.weather USING btree (url);


--
-- Name: index_wsh_on_last_date_in_program; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wsh_on_last_date_in_program ON public.new_service_history USING btree (first_date_in_program, last_date_in_program, record_type, date);


--
-- Name: index_youth_case_managements_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_youth_case_managements_on_deleted_at ON public.youth_case_managements USING btree (deleted_at);


--
-- Name: index_youth_exports_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_youth_exports_on_created_at ON public.youth_exports USING btree (created_at);


--
-- Name: index_youth_exports_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_youth_exports_on_updated_at ON public.youth_exports USING btree (updated_at);


--
-- Name: index_youth_exports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_youth_exports_on_user_id ON public.youth_exports USING btree (user_id);


--
-- Name: index_youth_follow_ups_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_youth_follow_ups_on_deleted_at ON public.youth_follow_ups USING btree (deleted_at);


--
-- Name: index_youth_intakes_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_youth_intakes_on_created_at ON public.youth_intakes USING btree (created_at);


--
-- Name: index_youth_intakes_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_youth_intakes_on_deleted_at ON public.youth_intakes USING btree (deleted_at);


--
-- Name: index_youth_intakes_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_youth_intakes_on_updated_at ON public.youth_intakes USING btree (updated_at);


--
-- Name: index_youth_referrals_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_youth_referrals_on_deleted_at ON public.youth_referrals USING btree (deleted_at);


--
-- Name: inventory_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inventory_date_created ON public."Inventory" USING btree ("DateCreated");


--
-- Name: inventory_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inventory_date_updated ON public."Inventory" USING btree ("DateUpdated");


--
-- Name: inventory_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inventory_export_id ON public."Inventory" USING btree ("ExportID");


--
-- Name: involved_in_imports_by_hud_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX involved_in_imports_by_hud_key ON public.involved_in_imports USING btree (hud_key, importer_log_id, record_type, record_action);


--
-- Name: involved_in_imports_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX involved_in_imports_by_id ON public.involved_in_imports USING btree (record_id, importer_log_id, record_type, record_action);


--
-- Name: involved_in_imports_by_importer_log; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX involved_in_imports_by_importer_log ON public.involved_in_imports USING btree (importer_log_id, record_type, record_action);


--
-- Name: one_entity_per_type_per_group; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX one_entity_per_type_per_group ON public.group_viewable_entities USING btree (access_group_id, entity_id, entity_type);


--
-- Name: one_entity_per_type_per_user_allows_delete; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX one_entity_per_type_per_user_allows_delete ON public.user_viewable_entities USING btree (user_id, entity_id, entity_type, deleted_at);


--
-- Name: organization_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX organization_export_id ON public."Organization" USING btree ("ExportID");


--
-- Name: ppfc_ppfp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ppfc_ppfp_idx ON public.project_pass_fails_clients USING btree (project_id);


--
-- Name: project_coc_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_coc_date_created ON public."ProjectCoC" USING btree ("DateCreated");


--
-- Name: project_coc_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_coc_date_updated ON public."ProjectCoC" USING btree ("DateUpdated");


--
-- Name: project_coc_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_coc_export_id ON public."ProjectCoC" USING btree ("ExportID");


--
-- Name: project_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_date_created ON public."Project" USING btree ("DateCreated");


--
-- Name: project_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_date_updated ON public."Project" USING btree ("DateUpdated");


--
-- Name: project_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_export_id ON public."Project" USING btree ("ExportID");


--
-- Name: project_project_override_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_project_override_index ON public."Project" USING btree (COALESCE(act_as_project_type, "ProjectType"));


--
-- Name: project_tracking_method_rsh_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_tracking_method_rsh_index ON public.recent_service_history USING btree (project_tracking_method);


--
-- Name: project_type_rsh_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_type_rsh_index ON public.recent_service_history USING btree (project_type);


--
-- Name: services_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX services_date_created ON public."Services" USING btree ("DateCreated");


--
-- Name: services_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX services_date_updated ON public."Services" USING btree ("DateUpdated");


--
-- Name: services_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX services_export_id ON public."Services" USING btree ("ExportID");


--
-- Name: sh_date_ds_id_org_id_proj_id_proj_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sh_date_ds_id_org_id_proj_id_proj_type ON public.warehouse_client_service_history USING btree (date, data_source_id, organization_id, project_id, project_type);


--
-- Name: shs_unique_date_she_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX shs_unique_date_she_id ON public.service_history_services USING btree (date, service_history_enrollment_id);


--
-- Name: simple_report_univ_type_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX simple_report_univ_type_and_id ON public.simple_report_universe_members USING btree (universe_membership_type, universe_membership_id);


--
-- Name: site_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX site_date_created ON public."Geography" USING btree ("DateCreated");


--
-- Name: site_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX site_date_updated ON public."Geography" USING btree ("DateUpdated");


--
-- Name: site_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX site_export_id ON public."Geography" USING btree ("ExportID");


--
-- Name: spm_client_conflict_columns; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX spm_client_conflict_columns ON public.hud_report_spm_clients USING btree (report_instance_id, client_id, data_source_id);


--
-- Name: taggings_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX taggings_idx ON public.taggings USING btree (tag_id, taggable_id, taggable_type, context, tagger_id, tagger_type);


--
-- Name: taggings_idy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX taggings_idy ON public.taggings USING btree (taggable_id, taggable_type, tagger_id, context);


--
-- Name: test_shs; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX test_shs ON public.service_history_services_2000 USING btree (service_history_enrollment_id, date);


--
-- Name: uniq_hud_report_universe_members; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uniq_hud_report_universe_members ON public.hud_report_universe_members USING btree (report_cell_id, universe_membership_id, universe_membership_type) WHERE (deleted_at IS NULL);


--
-- Name: uniq_simple_report_universe_members; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uniq_simple_report_universe_members ON public.simple_report_universe_members USING btree (report_cell_id, universe_membership_id, universe_membership_type) WHERE (deleted_at IS NULL);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- Name: unk_Geography; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Geography" ON public."Geography" USING btree (data_source_id, "GeographyID");


--
-- Name: unk_Organization; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Organization" ON public."Organization" USING btree (data_source_id, "OrganizationID");


--
-- Name: unk_Project; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Project" ON public."Project" USING btree (data_source_id, "ProjectID");


--
-- Name: unk_Site; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Site" ON public."Geography" USING btree (data_source_id, "GeographyID");


--
-- Name: youth_ed_ev_id_ds_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX youth_ed_ev_id_ds_id ON public."YouthEducationStatus" USING btree ("YouthEducationStatusID", data_source_id);


--
-- Name: youth_eds_id_e_id_p_id_ds_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX youth_eds_id_e_id_p_id_ds_id ON public."YouthEducationStatus" USING btree ("YouthEducationStatusID", "EnrollmentID", "PersonalID", data_source_id);


--
-- Name: stats_shs_2000_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2000_age_homeless ON age, homeless FROM public.service_history_services_2000;


--
-- Name: stats_shs_2000_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2000_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2000;


--
-- Name: stats_shs_2000_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2000_homeless ON homeless, literally_homeless FROM public.service_history_services_2000;


--
-- Name: stats_shs_2001_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2001_age_homeless ON age, homeless FROM public.service_history_services_2001;


--
-- Name: stats_shs_2001_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2001_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2001;


--
-- Name: stats_shs_2001_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2001_homeless ON homeless, literally_homeless FROM public.service_history_services_2001;


--
-- Name: stats_shs_2002_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2002_age_homeless ON age, homeless FROM public.service_history_services_2002;


--
-- Name: stats_shs_2002_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2002_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2002;


--
-- Name: stats_shs_2002_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2002_homeless ON homeless, literally_homeless FROM public.service_history_services_2002;


--
-- Name: stats_shs_2003_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2003_age_homeless ON age, homeless FROM public.service_history_services_2003;


--
-- Name: stats_shs_2003_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2003_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2003;


--
-- Name: stats_shs_2003_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2003_homeless ON homeless, literally_homeless FROM public.service_history_services_2003;


--
-- Name: stats_shs_2004_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2004_age_homeless ON age, homeless FROM public.service_history_services_2004;


--
-- Name: stats_shs_2004_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2004_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2004;


--
-- Name: stats_shs_2004_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2004_homeless ON homeless, literally_homeless FROM public.service_history_services_2004;


--
-- Name: stats_shs_2005_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2005_age_homeless ON age, homeless FROM public.service_history_services_2005;


--
-- Name: stats_shs_2005_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2005_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2005;


--
-- Name: stats_shs_2005_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2005_homeless ON homeless, literally_homeless FROM public.service_history_services_2005;


--
-- Name: stats_shs_2006_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2006_age_homeless ON age, homeless FROM public.service_history_services_2006;


--
-- Name: stats_shs_2006_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2006_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2006;


--
-- Name: stats_shs_2006_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2006_homeless ON homeless, literally_homeless FROM public.service_history_services_2006;


--
-- Name: stats_shs_2007_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2007_age_homeless ON age, homeless FROM public.service_history_services_2007;


--
-- Name: stats_shs_2007_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2007_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2007;


--
-- Name: stats_shs_2007_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2007_homeless ON homeless, literally_homeless FROM public.service_history_services_2007;


--
-- Name: stats_shs_2008_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2008_age_homeless ON age, homeless FROM public.service_history_services_2008;


--
-- Name: stats_shs_2008_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2008_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2008;


--
-- Name: stats_shs_2008_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2008_homeless ON homeless, literally_homeless FROM public.service_history_services_2008;


--
-- Name: stats_shs_2009_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2009_age_homeless ON age, homeless FROM public.service_history_services_2009;


--
-- Name: stats_shs_2009_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2009_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2009;


--
-- Name: stats_shs_2009_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2009_homeless ON homeless, literally_homeless FROM public.service_history_services_2009;


--
-- Name: stats_shs_2010_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2010_age_homeless ON age, homeless FROM public.service_history_services_2010;


--
-- Name: stats_shs_2010_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2010_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2010;


--
-- Name: stats_shs_2010_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2010_homeless ON homeless, literally_homeless FROM public.service_history_services_2010;


--
-- Name: stats_shs_2011_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2011_age_homeless ON age, homeless FROM public.service_history_services_2011;


--
-- Name: stats_shs_2011_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2011_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2011;


--
-- Name: stats_shs_2011_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2011_homeless ON homeless, literally_homeless FROM public.service_history_services_2011;


--
-- Name: stats_shs_2012_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2012_age_homeless ON age, homeless FROM public.service_history_services_2012;


--
-- Name: stats_shs_2012_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2012_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2012;


--
-- Name: stats_shs_2012_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2012_homeless ON homeless, literally_homeless FROM public.service_history_services_2012;


--
-- Name: stats_shs_2013_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2013_age_homeless ON age, homeless FROM public.service_history_services_2013;


--
-- Name: stats_shs_2013_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2013_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2013;


--
-- Name: stats_shs_2013_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2013_homeless ON homeless, literally_homeless FROM public.service_history_services_2013;


--
-- Name: stats_shs_2014_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2014_age_homeless ON age, homeless FROM public.service_history_services_2014;


--
-- Name: stats_shs_2014_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2014_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2014;


--
-- Name: stats_shs_2014_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2014_homeless ON homeless, literally_homeless FROM public.service_history_services_2014;


--
-- Name: stats_shs_2015_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2015_age_homeless ON age, homeless FROM public.service_history_services_2015;


--
-- Name: stats_shs_2015_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2015_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2015;


--
-- Name: stats_shs_2015_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2015_homeless ON homeless, literally_homeless FROM public.service_history_services_2015;


--
-- Name: stats_shs_2016_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2016_age_homeless ON age, homeless FROM public.service_history_services_2016;


--
-- Name: stats_shs_2016_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2016_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2016;


--
-- Name: stats_shs_2016_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2016_homeless ON homeless, literally_homeless FROM public.service_history_services_2016;


--
-- Name: stats_shs_2017_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2017_age_homeless ON age, homeless FROM public.service_history_services_2017;


--
-- Name: stats_shs_2017_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2017_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2017;


--
-- Name: stats_shs_2017_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2017_homeless ON homeless, literally_homeless FROM public.service_history_services_2017;


--
-- Name: stats_shs_2018_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2018_age_homeless ON age, homeless FROM public.service_history_services_2018;


--
-- Name: stats_shs_2018_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2018_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2018;


--
-- Name: stats_shs_2018_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2018_homeless ON homeless, literally_homeless FROM public.service_history_services_2018;


--
-- Name: stats_shs_2019_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2019_age_homeless ON age, homeless FROM public.service_history_services_2019;


--
-- Name: stats_shs_2019_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2019_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2019;


--
-- Name: stats_shs_2019_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2019_homeless ON homeless, literally_homeless FROM public.service_history_services_2019;


--
-- Name: stats_shs_2020_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2020_age_homeless ON age, homeless FROM public.service_history_services_2020;


--
-- Name: stats_shs_2020_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2020_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2020;


--
-- Name: stats_shs_2020_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2020_homeless ON homeless, literally_homeless FROM public.service_history_services_2020;


--
-- Name: stats_shs_2021_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2021_age_homeless ON age, homeless FROM public.service_history_services_2021;


--
-- Name: stats_shs_2021_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2021_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2021;


--
-- Name: stats_shs_2021_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2021_homeless ON homeless, literally_homeless FROM public.service_history_services_2021;


--
-- Name: stats_shs_2022_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2022_age_homeless ON age, homeless FROM public.service_history_services_2022;


--
-- Name: stats_shs_2022_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2022_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2022;


--
-- Name: stats_shs_2022_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2022_homeless ON homeless, literally_homeless FROM public.service_history_services_2022;


--
-- Name: stats_shs_2023_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2023_age_homeless ON age, homeless FROM public.service_history_services_2023;


--
-- Name: stats_shs_2023_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2023_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2023;


--
-- Name: stats_shs_2023_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2023_homeless ON homeless, literally_homeless FROM public.service_history_services_2023;


--
-- Name: stats_shs_2024_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2024_age_homeless ON age, homeless FROM public.service_history_services_2024;


--
-- Name: stats_shs_2024_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2024_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2024;


--
-- Name: stats_shs_2024_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2024_homeless ON homeless, literally_homeless FROM public.service_history_services_2024;


--
-- Name: stats_shs_2025_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2025_age_homeless ON age, homeless FROM public.service_history_services_2025;


--
-- Name: stats_shs_2025_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2025_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2025;


--
-- Name: stats_shs_2025_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2025_homeless ON homeless, literally_homeless FROM public.service_history_services_2025;


--
-- Name: stats_shs_2026_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2026_age_homeless ON age, homeless FROM public.service_history_services_2026;


--
-- Name: stats_shs_2026_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2026_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2026;


--
-- Name: stats_shs_2026_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2026_homeless ON homeless, literally_homeless FROM public.service_history_services_2026;


--
-- Name: stats_shs_2027_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2027_age_homeless ON age, homeless FROM public.service_history_services_2027;


--
-- Name: stats_shs_2027_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2027_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2027;


--
-- Name: stats_shs_2027_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2027_homeless ON homeless, literally_homeless FROM public.service_history_services_2027;


--
-- Name: stats_shs_2028_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2028_age_homeless ON age, homeless FROM public.service_history_services_2028;


--
-- Name: stats_shs_2028_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2028_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2028;


--
-- Name: stats_shs_2028_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2028_homeless ON homeless, literally_homeless FROM public.service_history_services_2028;


--
-- Name: stats_shs_2029_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2029_age_homeless ON age, homeless FROM public.service_history_services_2029;


--
-- Name: stats_shs_2029_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2029_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2029;


--
-- Name: stats_shs_2029_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2029_homeless ON homeless, literally_homeless FROM public.service_history_services_2029;


--
-- Name: stats_shs_2030_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2030_age_homeless ON age, homeless FROM public.service_history_services_2030;


--
-- Name: stats_shs_2030_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2030_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2030;


--
-- Name: stats_shs_2030_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2030_homeless ON homeless, literally_homeless FROM public.service_history_services_2030;


--
-- Name: stats_shs_2031_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2031_age_homeless ON age, homeless FROM public.service_history_services_2031;


--
-- Name: stats_shs_2031_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2031_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2031;


--
-- Name: stats_shs_2031_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2031_homeless ON homeless, literally_homeless FROM public.service_history_services_2031;


--
-- Name: stats_shs_2032_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2032_age_homeless ON age, homeless FROM public.service_history_services_2032;


--
-- Name: stats_shs_2032_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2032_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2032;


--
-- Name: stats_shs_2032_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2032_homeless ON homeless, literally_homeless FROM public.service_history_services_2032;


--
-- Name: stats_shs_2033_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2033_age_homeless ON age, homeless FROM public.service_history_services_2033;


--
-- Name: stats_shs_2033_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2033_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2033;


--
-- Name: stats_shs_2033_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2033_homeless ON homeless, literally_homeless FROM public.service_history_services_2033;


--
-- Name: stats_shs_2034_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2034_age_homeless ON age, homeless FROM public.service_history_services_2034;


--
-- Name: stats_shs_2034_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2034_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2034;


--
-- Name: stats_shs_2034_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2034_homeless ON homeless, literally_homeless FROM public.service_history_services_2034;


--
-- Name: stats_shs_2035_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2035_age_homeless ON age, homeless FROM public.service_history_services_2035;


--
-- Name: stats_shs_2035_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2035_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2035;


--
-- Name: stats_shs_2035_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2035_homeless ON homeless, literally_homeless FROM public.service_history_services_2035;


--
-- Name: stats_shs_2036_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2036_age_homeless ON age, homeless FROM public.service_history_services_2036;


--
-- Name: stats_shs_2036_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2036_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2036;


--
-- Name: stats_shs_2036_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2036_homeless ON homeless, literally_homeless FROM public.service_history_services_2036;


--
-- Name: stats_shs_2037_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2037_age_homeless ON age, homeless FROM public.service_history_services_2037;


--
-- Name: stats_shs_2037_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2037_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2037;


--
-- Name: stats_shs_2037_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2037_homeless ON homeless, literally_homeless FROM public.service_history_services_2037;


--
-- Name: stats_shs_2038_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2038_age_homeless ON age, homeless FROM public.service_history_services_2038;


--
-- Name: stats_shs_2038_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2038_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2038;


--
-- Name: stats_shs_2038_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2038_homeless ON homeless, literally_homeless FROM public.service_history_services_2038;


--
-- Name: stats_shs_2039_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2039_age_homeless ON age, homeless FROM public.service_history_services_2039;


--
-- Name: stats_shs_2039_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2039_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2039;


--
-- Name: stats_shs_2039_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2039_homeless ON homeless, literally_homeless FROM public.service_history_services_2039;


--
-- Name: stats_shs_2040_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2040_age_homeless ON age, homeless FROM public.service_history_services_2040;


--
-- Name: stats_shs_2040_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2040_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2040;


--
-- Name: stats_shs_2040_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2040_homeless ON homeless, literally_homeless FROM public.service_history_services_2040;


--
-- Name: stats_shs_2041_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2041_age_homeless ON age, homeless FROM public.service_history_services_2041;


--
-- Name: stats_shs_2041_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2041_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2041;


--
-- Name: stats_shs_2041_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2041_homeless ON homeless, literally_homeless FROM public.service_history_services_2041;


--
-- Name: stats_shs_2042_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2042_age_homeless ON age, homeless FROM public.service_history_services_2042;


--
-- Name: stats_shs_2042_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2042_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2042;


--
-- Name: stats_shs_2042_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2042_homeless ON homeless, literally_homeless FROM public.service_history_services_2042;


--
-- Name: stats_shs_2043_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2043_age_homeless ON age, homeless FROM public.service_history_services_2043;


--
-- Name: stats_shs_2043_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2043_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2043;


--
-- Name: stats_shs_2043_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2043_homeless ON homeless, literally_homeless FROM public.service_history_services_2043;


--
-- Name: stats_shs_2044_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2044_age_homeless ON age, homeless FROM public.service_history_services_2044;


--
-- Name: stats_shs_2044_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2044_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2044;


--
-- Name: stats_shs_2044_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2044_homeless ON homeless, literally_homeless FROM public.service_history_services_2044;


--
-- Name: stats_shs_2045_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2045_age_homeless ON age, homeless FROM public.service_history_services_2045;


--
-- Name: stats_shs_2045_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2045_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2045;


--
-- Name: stats_shs_2045_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2045_homeless ON homeless, literally_homeless FROM public.service_history_services_2045;


--
-- Name: stats_shs_2046_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2046_age_homeless ON age, homeless FROM public.service_history_services_2046;


--
-- Name: stats_shs_2046_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2046_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2046;


--
-- Name: stats_shs_2046_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2046_homeless ON homeless, literally_homeless FROM public.service_history_services_2046;


--
-- Name: stats_shs_2047_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2047_age_homeless ON age, homeless FROM public.service_history_services_2047;


--
-- Name: stats_shs_2047_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2047_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2047;


--
-- Name: stats_shs_2047_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2047_homeless ON homeless, literally_homeless FROM public.service_history_services_2047;


--
-- Name: stats_shs_2048_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2048_age_homeless ON age, homeless FROM public.service_history_services_2048;


--
-- Name: stats_shs_2048_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2048_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2048;


--
-- Name: stats_shs_2048_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2048_homeless ON homeless, literally_homeless FROM public.service_history_services_2048;


--
-- Name: stats_shs_2049_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2049_age_homeless ON age, homeless FROM public.service_history_services_2049;


--
-- Name: stats_shs_2049_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2049_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2049;


--
-- Name: stats_shs_2049_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2049_homeless ON homeless, literally_homeless FROM public.service_history_services_2049;


--
-- Name: stats_shs_2050_age_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2050_age_homeless ON age, homeless FROM public.service_history_services_2050;


--
-- Name: stats_shs_2050_age_literally_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2050_age_literally_homeless ON age, literally_homeless FROM public.service_history_services_2050;


--
-- Name: stats_shs_2050_homeless; Type: STATISTICS; Schema: public; Owner: -
--

CREATE STATISTICS public.stats_shs_2050_homeless ON homeless, literally_homeless FROM public.service_history_services_2050;


--
-- Name: service_history_services service_history_service_insert_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER service_history_service_insert_trigger BEFORE INSERT ON public.service_history_services FOR EACH ROW EXECUTE FUNCTION public.service_history_service_insert_trigger();


--
-- Name: service_history_services_2036 fk_rails_000b38b036; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2036
    ADD CONSTRAINT fk_rails_000b38b036 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2023 fk_rails_0702601703; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2023
    ADD CONSTRAINT fk_rails_0702601703 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2000 fk_rails_07fab86018; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2000
    ADD CONSTRAINT fk_rails_07fab86018 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2019 fk_rails_085ca57b2a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2019
    ADD CONSTRAINT fk_rails_085ca57b2a FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2020 fk_rails_085ca57b2b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2020
    ADD CONSTRAINT fk_rails_085ca57b2b FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: HealthAndDV fk_rails_09dc8ad251; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."HealthAndDV"
    ADD CONSTRAINT fk_rails_09dc8ad251 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: service_history_services_2012 fk_rails_0af8ea813e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2012
    ADD CONSTRAINT fk_rails_0af8ea813e FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2021 fk_rails_0e5acc7371; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2021
    ADD CONSTRAINT fk_rails_0e5acc7371 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: EnrollmentCoC fk_rails_10c0c54102; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EnrollmentCoC"
    ADD CONSTRAINT fk_rails_10c0c54102 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: service_history_services_2014 fk_rails_1461872ff4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2014
    ADD CONSTRAINT fk_rails_1461872ff4 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2016 fk_rails_16de1abefc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2016
    ADD CONSTRAINT fk_rails_16de1abefc FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2046 fk_rails_1f5ddaaa59; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2046
    ADD CONSTRAINT fk_rails_1f5ddaaa59 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: warehouse_clients_processed fk_rails_20932f9907; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_clients_processed
    ADD CONSTRAINT fk_rails_20932f9907 FOREIGN KEY (client_id) REFERENCES public."Client"(id);


--
-- Name: service_history_services_2032 fk_rails_2130a25e33; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2032
    ADD CONSTRAINT fk_rails_2130a25e33 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: Exit fk_rails_2338303c55; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Exit"
    ADD CONSTRAINT fk_rails_2338303c55 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: Enrollment fk_rails_24e267b7b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Enrollment"
    ADD CONSTRAINT fk_rails_24e267b7b6 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: service_history_services_2018 fk_rails_2dbd22e951; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2018
    ADD CONSTRAINT fk_rails_2dbd22e951 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_remainder fk_rails_330ff927f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_remainder
    ADD CONSTRAINT fk_rails_330ff927f7 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: Organization fk_rails_3675320ed1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Organization"
    ADD CONSTRAINT fk_rails_3675320ed1 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: service_history_services_2045 fk_rails_368a9d283a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2045
    ADD CONSTRAINT fk_rails_368a9d283a FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2006 fk_rails_3ab91d734b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2006
    ADD CONSTRAINT fk_rails_3ab91d734b FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2030 fk_rails_3c74c16802; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2030
    ADD CONSTRAINT fk_rails_3c74c16802 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2008 fk_rails_4726c968a2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2008
    ADD CONSTRAINT fk_rails_4726c968a2 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2013 fk_rails_4839d689fb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2013
    ADD CONSTRAINT fk_rails_4839d689fb FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: Client fk_rails_4f7ec0cedf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Client"
    ADD CONSTRAINT fk_rails_4f7ec0cedf FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: service_history_services_2037 fk_rails_564f7bf6cb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2037
    ADD CONSTRAINT fk_rails_564f7bf6cb FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: Inventory fk_rails_5890c7efe3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Inventory"
    ADD CONSTRAINT fk_rails_5890c7efe3 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: service_history_services_2040 fk_rails_5ebdc04142; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2040
    ADD CONSTRAINT fk_rails_5ebdc04142 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: warehouse_clients fk_rails_5f845fa144; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_clients
    ADD CONSTRAINT fk_rails_5f845fa144 FOREIGN KEY (destination_id) REFERENCES public."Client"(id);


--
-- Name: service_history_services_2017 fk_rails_6371c8a27f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2017
    ADD CONSTRAINT fk_rails_6371c8a27f FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2039 fk_rails_6c0d4085ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2039
    ADD CONSTRAINT fk_rails_6c0d4085ac FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2047 fk_rails_6d17ecb13d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2047
    ADD CONSTRAINT fk_rails_6d17ecb13d FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2024 fk_rails_7119cac661; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2024
    ADD CONSTRAINT fk_rails_7119cac661 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: Project fk_rails_78558d1502; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Project"
    ADD CONSTRAINT fk_rails_78558d1502 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: service_history_services_2002 fk_rails_785e6f2460; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2002
    ADD CONSTRAINT fk_rails_785e6f2460 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2026 fk_rails_7963d447f9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2026
    ADD CONSTRAINT fk_rails_7963d447f9 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2044 fk_rails_7b2d095d38; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2044
    ADD CONSTRAINT fk_rails_7b2d095d38 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2029 fk_rails_7be3374454; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2029
    ADD CONSTRAINT fk_rails_7be3374454 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2028 fk_rails_7d15674636; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2028
    ADD CONSTRAINT fk_rails_7d15674636 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2038 fk_rails_7eb4e58ed1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2038
    ADD CONSTRAINT fk_rails_7eb4e58ed1 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: Affiliation fk_rails_81babe0602; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Affiliation"
    ADD CONSTRAINT fk_rails_81babe0602 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: service_history_services_2027 fk_rails_836f2b3b4c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2027
    ADD CONSTRAINT fk_rails_836f2b3b4c FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2011 fk_rails_839e109dda; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2011
    ADD CONSTRAINT fk_rails_839e109dda FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: project_pass_fails_projects fk_rails_83dc39b7e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_pass_fails_projects
    ADD CONSTRAINT fk_rails_83dc39b7e7 FOREIGN KEY (project_pass_fail_id) REFERENCES public.project_pass_fails(id) ON DELETE CASCADE;


--
-- Name: project_pass_fails_clients fk_rails_8455b3472c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_pass_fails_clients
    ADD CONSTRAINT fk_rails_8455b3472c FOREIGN KEY (project_pass_fail_id) REFERENCES public.project_pass_fails(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2022 fk_rails_85cc8de3dc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2022
    ADD CONSTRAINT fk_rails_85cc8de3dc FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: ProjectCoC fk_rails_8625e4a1e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."ProjectCoC"
    ADD CONSTRAINT fk_rails_8625e4a1e0 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: Disabilities fk_rails_866e73470f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Disabilities"
    ADD CONSTRAINT fk_rails_866e73470f FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: service_history_services_2049 fk_rails_9783c16a4a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2049
    ADD CONSTRAINT fk_rails_9783c16a4a FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: Services fk_rails_9ed8af19a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Services"
    ADD CONSTRAINT fk_rails_9ed8af19a8 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: service_history_services_2007 fk_rails_aa1aa9ac7b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2007
    ADD CONSTRAINT fk_rails_aa1aa9ac7b FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2033 fk_rails_afa6422b2d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2033
    ADD CONSTRAINT fk_rails_afa6422b2d FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2015 fk_rails_b1aaab6a9f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2015
    ADD CONSTRAINT fk_rails_b1aaab6a9f FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2041 fk_rails_b5bc457eae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2041
    ADD CONSTRAINT fk_rails_b5bc457eae FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2025 fk_rails_ba72bd8b03; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2025
    ADD CONSTRAINT fk_rails_ba72bd8b03 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2005 fk_rails_bb256798ab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2005
    ADD CONSTRAINT fk_rails_bb256798ab FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2010 fk_rails_c5190f1b4c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2010
    ADD CONSTRAINT fk_rails_c5190f1b4c FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2009 fk_rails_c5575072fd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2009
    ADD CONSTRAINT fk_rails_c5575072fd FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: warehouse_clients fk_rails_c59e9106a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_clients
    ADD CONSTRAINT fk_rails_c59e9106a8 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: files fk_rails_c6ea865a3f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT fk_rails_c6ea865a3f FOREIGN KEY (vispdat_id) REFERENCES public.vispdats(id);


--
-- Name: EmploymentEducation fk_rails_c7677f1ea0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EmploymentEducation"
    ADD CONSTRAINT fk_rails_c7677f1ea0 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: Geography fk_rails_c78f6db1f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Geography"
    ADD CONSTRAINT fk_rails_c78f6db1f0 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: service_history_services_2031 fk_rails_cac068aa22; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2031
    ADD CONSTRAINT fk_rails_cac068aa22 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2034 fk_rails_cb8588c967; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2034
    ADD CONSTRAINT fk_rails_cb8588c967 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2003 fk_rails_cc683168a0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2003
    ADD CONSTRAINT fk_rails_cc683168a0 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2004 fk_rails_cf4f3c98df; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2004
    ADD CONSTRAINT fk_rails_cf4f3c98df FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2001 fk_rails_d8259b9233; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2001
    ADD CONSTRAINT fk_rails_d8259b9233 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2035 fk_rails_d8a5070dc4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2035
    ADD CONSTRAINT fk_rails_d8a5070dc4 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: warehouse_clients fk_rails_db9104e0c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_clients
    ADD CONSTRAINT fk_rails_db9104e0c0 FOREIGN KEY (source_id) REFERENCES public."Client"(id);


--
-- Name: service_history_services_2042 fk_rails_dd2860de91; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2042
    ADD CONSTRAINT fk_rails_dd2860de91 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: IncomeBenefits fk_rails_e0715eab03; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."IncomeBenefits"
    ADD CONSTRAINT fk_rails_e0715eab03 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: service_history_services_2043 fk_rails_e5a92ecf01; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2043
    ADD CONSTRAINT fk_rails_e5a92ecf01 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2048 fk_rails_e959e189d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2048
    ADD CONSTRAINT fk_rails_e959e189d1 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services_2050 fk_rails_eb51169a46; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2050
    ADD CONSTRAINT fk_rails_eb51169a46 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: service_history_services fk_rails_ee37ed289e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services
    ADD CONSTRAINT fk_rails_ee37ed289e FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


--
-- Name: Funder fk_rails_ee7363191f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Funder"
    ADD CONSTRAINT fk_rails_ee7363191f FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: import_logs fk_rails_fbb77b1f46; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_logs
    ADD CONSTRAINT fk_rails_fbb77b1f46 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20160727190957'),
('20160729135359'),
('20160729183141'),
('20160816131814'),
('20160816173101'),
('20160818180405'),
('20160823130251'),
('20160823144637'),
('20160824150416'),
('20160826140306'),
('20160902162623'),
('20160902185045'),
('20160910000538'),
('20160913132444'),
('20160913152926'),
('20160913155401'),
('20160913160306'),
('20160913161311'),
('20160914185810'),
('20160919210259'),
('20160919212545'),
('20160922142402'),
('20160922162359'),
('20160922185930'),
('20160923113802'),
('20160926002900'),
('20160926145351'),
('20160926170204'),
('20160927134516'),
('20160927183151'),
('20160927184003'),
('20160927202506'),
('20160927202843'),
('20160927203650'),
('20160927205852'),
('20160928125517'),
('20160928140906'),
('20160928202720'),
('20160929010237'),
('20160929153319'),
('20160930142027'),
('20161004181613'),
('20161006180229'),
('20161007160124'),
('20161007182409'),
('20161011135522'),
('20161017193504'),
('20161019122336'),
('20161019181914'),
('20161020175933'),
('20161021142349'),
('20161021185201'),
('20161024205300'),
('20161025142716'),
('20161027160241'),
('20161027173838'),
('20161029184725'),
('20161030141156'),
('20161102131838'),
('20161102194513'),
('20161103173010'),
('20161104131304'),
('20161108150033'),
('20161109173403'),
('20161111194734'),
('20161111200331'),
('20161111205557'),
('20161111210852'),
('20161111214343'),
('20161115160857'),
('20161115163024'),
('20161115173437'),
('20161115181519'),
('20161115194005'),
('20161117042632'),
('20161117211439'),
('20161121134639'),
('20161122193356'),
('20161122205922'),
('20161122212446'),
('20161123145006'),
('20161128164214'),
('20161212154456'),
('20161213184140'),
('20161222172617'),
('20161223181314'),
('20161228184803'),
('20161229150159'),
('20170110183158'),
('20170210211420'),
('20170314123357'),
('20170420193254'),
('20170505131647'),
('20170505135248'),
('20170508001011'),
('20170508003906'),
('20170509183056'),
('20170510131916'),
('20170518194049'),
('20170526142051'),
('20170526162435'),
('20170530203255'),
('20170531152936'),
('20170602183611'),
('20170602235909'),
('20170604225122'),
('20170605004541'),
('20170605011844'),
('20170607195038'),
('20170609162811'),
('20170619211924'),
('20170620000812'),
('20170620013208'),
('20170622125121'),
('20170626133126'),
('20170705125336'),
('20170706145106'),
('20170712174621'),
('20170712182033'),
('20170714172533'),
('20170714195436'),
('20170716180758'),
('20170716202346'),
('20170718132138'),
('20170719172444'),
('20170726140915'),
('20170727231741'),
('20170728151813'),
('20170728201723'),
('20170801120635'),
('20170809173044'),
('20170815174824'),
('20170816175326'),
('20170816205625'),
('20170817150519'),
('20170818140329'),
('20170829131400'),
('20170830171507'),
('20170904132001'),
('20170904140427'),
('20170904202838'),
('20170905122913'),
('20170905122914'),
('20170905122915'),
('20170905122916'),
('20170905122917'),
('20170905122918'),
('20170905183117'),
('20170905202251'),
('20170905202611'),
('20170906161906'),
('20170911124040'),
('20170911194951'),
('20170912134710'),
('20170913192945'),
('20170918135821'),
('20170921201252'),
('20170922193229'),
('20170922200507'),
('20170924001510'),
('20170924005724'),
('20170924193906'),
('20170925000145'),
('20170926124009'),
('20170926200356'),
('20170927194653'),
('20170928185422'),
('20170928191904'),
('20170929193327'),
('20170930184143'),
('20171003122627'),
('20171005191828'),
('20171016191359'),
('20171019085351'),
('20171019143151'),
('20171020131243'),
('20171021194831'),
('20171023175038'),
('20171023194703'),
('20171024123740'),
('20171024180819'),
('20171025165617'),
('20171026122017'),
('20171026152842'),
('20171027031033'),
('20171102134710'),
('20171103003947'),
('20171103134010'),
('20171103154925'),
('20171106005358'),
('20171106211934'),
('20171108195513'),
('20171110180121'),
('20171111032952'),
('20171111190457'),
('20171113134728'),
('20171113142927'),
('20171113182656'),
('20171114132110'),
('20171115182249'),
('20171115193025'),
('20171116155352'),
('20171116184557'),
('20171127191122'),
('20171127203632'),
('20171127234210'),
('20171128161058'),
('20171129131811'),
('20171129172903'),
('20171201180334'),
('20171201180412'),
('20171204161239'),
('20171204180630'),
('20171205135225'),
('20171206131931'),
('20171208151137'),
('20171211131328'),
('20171211142747'),
('20171211194546'),
('20171212182935'),
('20171213002710'),
('20171213002924'),
('20171215203448'),
('20171218211735'),
('20171219160943'),
('20171222140958'),
('20171222142957'),
('20171222143540'),
('20171222151018'),
('20180114165737'),
('20180114181159'),
('20180115165003'),
('20180115195008'),
('20180117210259'),
('20180120142315'),
('20180120145651'),
('20180120184755'),
('20180122135635'),
('20180122190528'),
('20180123145547'),
('20180123151137'),
('20180125214133'),
('20180126184544'),
('20180126212658'),
('20180126230757'),
('20180127151221'),
('20180129211310'),
('20180129222234'),
('20180130173319'),
('20180203202523'),
('20180205134947'),
('20180205160021'),
('20180206132151'),
('20180206132418'),
('20180206132549'),
('20180206211300'),
('20180209140514'),
('20180209145558'),
('20180211182226'),
('20180211191923'),
('20180212154518'),
('20180213132145'),
('20180213133619'),
('20180215212401'),
('20180216221704'),
('20180218004200'),
('20180218194158'),
('20180218195838'),
('20180219003427'),
('20180219011911'),
('20180219213751'),
('20180221172154'),
('20180221200920'),
('20180222132714'),
('20180223131630'),
('20180226181023'),
('20180227184226'),
('20180228134319'),
('20180228202408'),
('20180302005549'),
('20180303012057'),
('20180304020707'),
('20180307184913'),
('20180309152824'),
('20180309161833'),
('20180309194413'),
('20180309200416'),
('20180313170616'),
('20180314121340'),
('20180319204410'),
('20180326140546'),
('20180330145925'),
('20180408102020'),
('20180410081403'),
('20180424182721'),
('20180424185646'),
('20180424190544'),
('20180425140146'),
('20180510001923'),
('20180510002556'),
('20180510130324'),
('20180516130234'),
('20180516133454'),
('20180521173754'),
('20180528152133'),
('20180528155555'),
('20180528174021'),
('20180529122603'),
('20180605164543'),
('20180613193551'),
('20180614004301'),
('20180615232905'),
('20180616123004'),
('20180617111542'),
('20180617130414'),
('20180626134714'),
('20180626140358'),
('20180628035131'),
('20180707180119'),
('20180707183425'),
('20180709173131'),
('20180710174412'),
('20180710195222'),
('20180713143703'),
('20180716142944'),
('20180716175514'),
('20180716181552'),
('20180718152629'),
('20180723180257'),
('20180731125029'),
('20180801185645'),
('20180810142730'),
('20180810175903'),
('20180813144056'),
('20180814144715'),
('20180815162429'),
('20180831171525'),
('20180909174113'),
('20180910121905'),
('20180910130909'),
('20180912121943'),
('20180912154937'),
('20180914235727'),
('20180917204430'),
('20180919135034'),
('20181001174159'),
('20181001180812'),
('20181001193048'),
('20181005171232'),
('20181005172849'),
('20181010193431'),
('20181012130754'),
('20181015132913'),
('20181015132958'),
('20181019160628'),
('20181019182438'),
('20181019185052'),
('20181022144551'),
('20181026125946'),
('20181030142001'),
('20181031151924'),
('20181107183718'),
('20181107184057'),
('20181107184157'),
('20181107184258'),
('20181119165528'),
('20181206135841'),
('20181206195139'),
('20181207011350'),
('20181210141734'),
('20181218184800'),
('20181219184841'),
('20181227145018'),
('20190107135250'),
('20190108133610'),
('20190110145430'),
('20190110205705'),
('20190111154442'),
('20190111162407'),
('20190114175107'),
('20190129175440'),
('20190129193710'),
('20190129193718'),
('20190129193734'),
('20190130141818'),
('20190201172226'),
('20190204194825'),
('20190208173854'),
('20190209204636'),
('20190211182446'),
('20190211212757'),
('20190215151428'),
('20190215174811'),
('20190216193115'),
('20190221211525'),
('20190225173734'),
('20190228151509'),
('20190306011413'),
('20190307205203'),
('20190313191758'),
('20190314233300'),
('20190315202420'),
('20190319174002'),
('20190320132816'),
('20190320135300'),
('20190321154235'),
('20190322182648'),
('20190324204257'),
('20190325205709'),
('20190327174322'),
('20190328135601'),
('20190328183719'),
('20190328201651'),
('20190329122650'),
('20190408180044'),
('20190423144729'),
('20190424185158'),
('20190424194714'),
('20190501154934'),
('20190502150143'),
('20190507184540'),
('20190508181020'),
('20190509161703'),
('20190510123307'),
('20190512175652'),
('20190531005415'),
('20190603155216'),
('20190603192544'),
('20190603204753'),
('20190604164934'),
('20190605121550'),
('20190605153143'),
('20190605155107'),
('20190606000839'),
('20190606111838'),
('20190611020510'),
('20190612194424'),
('20190614132143'),
('20190617141627'),
('20190617154412'),
('20190701175345'),
('20190701203722'),
('20190701203738'),
('20190705192539'),
('20190709170452'),
('20190710202403'),
('20190712190215'),
('20190715191354'),
('20190715195832'),
('20190715203906'),
('20190715371835'),
('20190717171417'),
('20190719141740'),
('20190725172606'),
('20190725183917'),
('20190725205710'),
('20190726191455'),
('20190726201314'),
('20190730141425'),
('20190801130133'),
('20190801131014'),
('20190802121551'),
('20190805172310'),
('20190808155531'),
('20190814011156'),
('20190814174740'),
('20190814194736'),
('20190814195700'),
('20190814202518'),
('20190816160117'),
('20190819235806'),
('20190820145158'),
('20190821163752'),
('20190821200216'),
('20190823150100'),
('20190823175037'),
('20190902140838'),
('20190909171338'),
('20190913131118'),
('20190916192050'),
('20190917000129'),
('20190917001135'),
('20190917172920'),
('20190918132924'),
('20190918191348'),
('20190918204616'),
('20190919153540'),
('20190919164531'),
('20190919211227'),
('20190923153128'),
('20190924134442'),
('20190927193254'),
('20191007155052'),
('20191011124048'),
('20191014144407'),
('20191017122329'),
('20191017141927'),
('20191021192058'),
('20191025130319'),
('20191029172244'),
('20191101143044'),
('20191101171753'),
('20191102185935'),
('20191104145557'),
('20191106135508'),
('20191107212914'),
('20191111144437'),
('20191112142922'),
('20191114212804'),
('20191115192256'),
('20191120171159'),
('20191205155752'),
('20191216210204'),
('20191219154817'),
('20191223133641'),
('20191223141858'),
('20191223161021'),
('20191223203007'),
('20191227161033'),
('20200106005041'),
('20200106010648'),
('20200106161751'),
('20200106175129'),
('20200108174617'),
('20200108184052'),
('20200110150204'),
('20200114154449'),
('20200120191326'),
('20200205010344'),
('20200207165957'),
('20200211150300'),
('20200211154527'),
('20200212140919'),
('20200214200455'),
('20200217152806'),
('20200217194551'),
('20200219175547'),
('20200221194355'),
('20200225181344'),
('20200225181450'),
('20200225190151'),
('20200302164716'),
('20200303174258'),
('20200303183252'),
('20200304153159'),
('20200306172853'),
('20200307210926'),
('20200310141315'),
('20200312175312'),
('20200319123357'),
('20200324151503'),
('20200325181533'),
('20200325200620'),
('20200326183628'),
('20200326203618'),
('20200327143205'),
('20200327203519'),
('20200328122019'),
('20200328124124'),
('20200402121258'),
('20200408133149'),
('20200414121843'),
('20200415124657'),
('20200417164547'),
('20200420123748'),
('20200420144827'),
('20200421121604'),
('20200424152842'),
('20200424202136'),
('20200429142723'),
('20200430124823'),
('20200430173113'),
('20200504140400'),
('20200506181929'),
('20200506195939'),
('20200514185800'),
('20200518125929'),
('20200519175104'),
('20200530134853'),
('20200608183800'),
('20200617123752'),
('20200625130802'),
('20200627165150'),
('20200628001355'),
('20200628002641'),
('20200628153252'),
('20200629153416'),
('20200629180206'),
('20200630152328'),
('20200701150708'),
('20200701171520'),
('20200701192839'),
('20200702125231'),
('20200703025438'),
('20200703154239'),
('20200703154409'),
('20200703223937'),
('20200703234840'),
('20200706171817'),
('20200706180800'),
('20200706193249'),
('20200713203505'),
('20200716132417'),
('20200718194102'),
('20200719235413'),
('20200721190101'),
('20200722194242'),
('20200722200713'),
('20200723143000'),
('20200723144121'),
('20200723172609'),
('20200723204046'),
('20200724153536'),
('20200724173742'),
('20200724180227'),
('20200729203440'),
('20200731143840'),
('20200731181511'),
('20200806183758'),
('20200812144640'),
('20200812153339'),
('20200814173200'),
('20200821185026'),
('20200824174347'),
('20200826165713'),
('20200827130841'),
('20200827224602'),
('20200831151807'),
('20200831193024'),
('20200901201024'),
('20200903133437'),
('20200904191736'),
('20200910142617'),
('20200914190210'),
('20200915230624'),
('20200916144557'),
('20200916195351'),
('20200917185233'),
('20200917193037'),
('20200921194630'),
('20200922192121'),
('20200923184619'),
('20200925172414'),
('20200925201420'),
('20200927201419'),
('20200928194005'),
('20200929203230'),
('20201001171704'),
('20201006134420'),
('20201006194015'),
('20201008204557'),
('20201009165424'),
('20201019193328'),
('20201020181913'),
('20201023130124'),
('20201027200503'),
('20201030145808'),
('20201104133922'),
('20201104182139'),
('20201104183517'),
('20201109142122'),
('20201110201513'),
('20201111165550'),
('20201116211113'),
('20201125130708'),
('20201201162902'),
('20201202135347'),
('20201203140706'),
('20201208140125'),
('20201208210326'),
('20201209163906'),
('20201211142334'),
('20201211213255'),
('20201216164355'),
('20201218132535'),
('20201218134107'),
('20201218180004'),
('20201223180342'),
('20210106173839'),
('20210106195019'),
('20210111123325'),
('20210113151049'),
('20210116192833'),
('20210118133014'),
('20210118160904'),
('20210125151501'),
('20210201195631'),
('20210204141807'),
('20210209182423'),
('20210216125622'),
('20210217173551'),
('20210217202610'),
('20210223011452'),
('20210225144651'),
('20210303180023'),
('20210303181117'),
('20210303200052'),
('20210305204708'),
('20210312200044'),
('20210325202706'),
('20210330124825'),
('20210413143040'),
('20210422191627'),
('20210426165914'),
('20210427184522'),
('20210428193540'),
('20210503165055'),
('20210505010944'),
('20210507180711'),
('20210507180738'),
('20210507180809'),
('20210510182341'),
('20210513185514'),
('20210514154843'),
('20210515142741'),
('20210517144348'),
('20210520184416'),
('20210526182148'),
('20210527140359'),
('20210601135719'),
('20210601173704'),
('20210603121547'),
('20210603143037'),
('20210604155334'),
('20210615131534'),
('20210616181054'),
('20210616193735'),
('20210622171720'),
('20210623184626'),
('20210623184729'),
('20210623195645'),
('20210625231326'),
('20210630201802'),
('20210702143811'),
('20210702144442'),
('20210707122337'),
('20210707172124'),
('20210707190613'),
('20210707193633'),
('20210708183958'),
('20210708192452'),
('20210714131449'),
('20210716144139'),
('20210717154701'),
('20210722155210'),
('20210723161722'),
('20210726155740'),
('20210727134415'),
('20210729175328'),
('20210729201521'),
('20210806202832'),
('20210809124146'),
('20210809130851'),
('20210809154208'),
('20210809184745'),
('20210810182752'),
('20210813121134'),
('20210819132406'),
('20210819133035'),
('20210823203031'),
('20210825182548'),
('20210901200255'),
('20210902113909'),
('20210903113401'),
('20210904021301');


