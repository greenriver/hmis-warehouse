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


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


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

SET default_with_oids = false;

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
    source_hash character varying
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
-- Name: Client; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Client" (
    "PersonalID" character varying,
    "FirstName" character varying(150),
    "MiddleName" character varying(150),
    "LastName" character varying(150),
    "NameSuffix" character varying(50),
    "NameDataQuality" integer,
    "SSN" character varying(9),
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
    consent_expires_on date
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
    source_hash character varying
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
    source_hash character varying
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
    source_hash character varying
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
    source_hash character varying
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
    source_hash character varying
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
    source_hash character varying
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
    source_hash character varying
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
    information_date_override date
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
    source_hash character varying
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
    source_hash character varying
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
    source_hash character varying
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
    source_hash character varying
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
    operating_start_date_override date
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
    source_hash character varying
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
    source_hash character varying
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
    requires_expiration_date boolean DEFAULT false NOT NULL
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
    source_data_source character varying
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
    sent_at timestamp without time zone
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
    sif_eligible character varying,
    sensory_impaired character varying,
    housed_date date,
    destination character varying,
    sub_population character varying,
    rank integer,
    st_francis_house character varying,
    last_group_review_date date,
    pre_contemplative_last_date_approached date,
    va_eligible character varying,
    vash_eligible character varying,
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
    hmis_destination character varying
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
    tag_id integer
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
          WHERE ((cohort_client_changes.change)::text = ANY ((ARRAY['create'::character varying, 'activate'::character varying])::text[]))) cc
     LEFT JOIN LATERAL ( SELECT cohort_client_changes.id,
            cohort_client_changes.cohort_client_id,
            cohort_client_changes.cohort_id,
            cohort_client_changes.user_id,
            cohort_client_changes.change,
            cohort_client_changes.changed_at,
            cohort_client_changes.reason
           FROM public.cohort_client_changes
          WHERE (((cohort_client_changes.change)::text = ANY ((ARRAY['destroy'::character varying, 'deactivate'::character varying])::text[])) AND (cc.cohort_client_id = cohort_client_changes.cohort_client_id) AND (cc.cohort_id = cohort_client_changes.cohort_id) AND (cc.changed_at < cohort_client_changes.changed_at))
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
    vispdat_prioritization_scheme character varying DEFAULT 'length_of_time'::character varying NOT NULL
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
    import_paused boolean DEFAULT false NOT NULL
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
    deleted_at timestamp without time zone
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
    updated_at timestamp without time zone
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
    delayed_job_id integer
);


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
    delete_detail character varying
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
    health boolean DEFAULT false NOT NULL
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
    consent_expires_on date
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
    staff_email character varying
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
    upload_id integer
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
    updated_at timestamp without time zone NOT NULL
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
    updated_at timestamp without time zone NOT NULL
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
    updated_at timestamp without time zone NOT NULL
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
    updated_at timestamp without time zone NOT NULL
);


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
-- Name: recent_report_enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recent_report_enrollments (
    "ProjectEntryID" character varying(50),
    "PersonalID" character varying,
    "ProjectID" character varying(50),
    "EntryDate" date,
    "HouseholdID" character varying,
    "RelationshipToHoH" integer,
    "ResidencePrior" integer,
    "OtherResidencePrior" character varying,
    "ResidencePriorLengthOfStay" integer,
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
    "ResidentialMoveInDate" date,
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
    "FYSBYouth" integer,
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
    demographic_id integer,
    client_id integer
);


--
-- Name: recent_service_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recent_service_history (
    id integer,
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
    deleted_at timestamp without time zone
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
-- Name: report_clients; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.report_clients AS
 SELECT "Client"."PersonalID",
    "Client"."FirstName",
    "Client"."MiddleName",
    "Client"."LastName",
    "Client"."NameSuffix",
    "Client"."NameDataQuality",
    "Client"."SSN",
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
    "Client"."OtherGender",
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
    "Client".id
   FROM public."Client"
  WHERE (("Client"."DateDeleted" IS NULL) AND ("Client".data_source_id IN ( SELECT data_sources.id
           FROM public.data_sources
          WHERE (data_sources.source_type IS NULL))));


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
    limitable boolean DEFAULT true NOT NULL
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
-- Name: report_demographics; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.report_demographics AS
 SELECT "Client"."PersonalID",
    "Client"."FirstName",
    "Client"."MiddleName",
    "Client"."LastName",
    "Client"."NameSuffix",
    "Client"."NameDataQuality",
    "Client"."SSN",
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
    "Client"."OtherGender",
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
    "Client".data_source_id,
    "Client".id,
    report_clients.id AS client_id
   FROM ((public."Client"
     JOIN public.warehouse_clients ON ((warehouse_clients.source_id = "Client".id)))
     JOIN public.report_clients ON ((warehouse_clients.destination_id = report_clients.id)))
  WHERE ("Client"."DateDeleted" IS NULL);


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
    head_of_household boolean DEFAULT false NOT NULL
);


--
-- Name: service_history_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services (
    id integer NOT NULL,
    service_history_enrollment_id integer NOT NULL,
    record_type character varying(50) NOT NULL,
    date date NOT NULL,
    age smallint,
    service_type smallint,
    client_id integer,
    project_type smallint
);


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
-- Name: service_history_services_2020; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_history_services_2020 (
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
    service_history_services.project_type
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
    project_whitelist boolean DEFAULT false
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
    number_of_bedrooms integer DEFAULT 0
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
    last_exit_destination character varying
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
    user_id integer
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
    other_housing_status character varying
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
    other_agency_involvement character varying NOT NULL,
    owns_cell_phone character varying NOT NULL,
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
    turned_away boolean DEFAULT false NOT NULL
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
    deleted_at timestamp without time zone
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
-- Name: Client id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Client" ALTER COLUMN id SET DEFAULT nextval('public."Client_id_seq"'::regclass);


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
-- Name: cas_availabilities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_availabilities ALTER COLUMN id SET DEFAULT nextval('public.cas_availabilities_id_seq'::regclass);


--
-- Name: cas_houseds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_houseds ALTER COLUMN id SET DEFAULT nextval('public.cas_houseds_id_seq'::regclass);


--
-- Name: cas_non_hmis_client_histories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_non_hmis_client_histories ALTER COLUMN id SET DEFAULT nextval('public.cas_non_hmis_client_histories_id_seq'::regclass);


--
-- Name: cas_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_reports ALTER COLUMN id SET DEFAULT nextval('public.cas_reports_id_seq'::regclass);


--
-- Name: cas_vacancies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_vacancies ALTER COLUMN id SET DEFAULT nextval('public.cas_vacancies_id_seq'::regclass);


--
-- Name: census_by_project_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.census_by_project_types ALTER COLUMN id SET DEFAULT nextval('public.census_by_project_types_id_seq'::regclass);


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
-- Name: exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exports ALTER COLUMN id SET DEFAULT nextval('public.exports_id_seq'::regclass);


--
-- Name: fake_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fake_data ALTER COLUMN id SET DEFAULT nextval('public.fake_data_id_seq'::regclass);


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
-- Name: hmis_forms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_forms ALTER COLUMN id SET DEFAULT nextval('public.hmis_forms_id_seq'::regclass);


--
-- Name: hmis_staff id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_staff ALTER COLUMN id SET DEFAULT nextval('public.hmis_staff_id_seq'::regclass);


--
-- Name: hmis_staff_x_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_staff_x_clients ALTER COLUMN id SET DEFAULT nextval('public.hmis_staff_x_clients_id_seq'::regclass);


--
-- Name: hud_chronics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_chronics ALTER COLUMN id SET DEFAULT nextval('public.hud_chronics_id_seq'::regclass);


--
-- Name: hud_create_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hud_create_logs ALTER COLUMN id SET DEFAULT nextval('public.hud_create_logs_id_seq'::regclass);


--
-- Name: identify_duplicates_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identify_duplicates_log ALTER COLUMN id SET DEFAULT nextval('public.identify_duplicates_log_id_seq'::regclass);


--
-- Name: import_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_logs ALTER COLUMN id SET DEFAULT nextval('public.import_logs_id_seq'::regclass);


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
-- Name: project_data_quality id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_data_quality ALTER COLUMN id SET DEFAULT nextval('public.project_data_quality_id_seq'::regclass);


--
-- Name: project_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_groups ALTER COLUMN id SET DEFAULT nextval('public.project_groups_id_seq'::regclass);


--
-- Name: project_project_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_project_groups ALTER COLUMN id SET DEFAULT nextval('public.project_project_groups_id_seq'::regclass);


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
-- Name: service_history_services_2020 id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2020 ALTER COLUMN id SET DEFAULT nextval('public.service_history_services_id_seq'::regclass);


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
-- Name: taggings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings ALTER COLUMN id SET DEFAULT nextval('public.taggings_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: uploads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uploads ALTER COLUMN id SET DEFAULT nextval('public.uploads_id_seq'::regclass);


--
-- Name: user_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_clients ALTER COLUMN id SET DEFAULT nextval('public.user_clients_id_seq'::regclass);


--
-- Name: user_viewable_entities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_viewable_entities ALTER COLUMN id SET DEFAULT nextval('public.user_viewable_entities_id_seq'::regclass);


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
-- Name: Client Client_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Client"
    ADD CONSTRAINT "Client_pkey" PRIMARY KEY (id);


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
-- Name: available_file_tags available_file_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.available_file_tags
    ADD CONSTRAINT available_file_tags_pkey PRIMARY KEY (id);


--
-- Name: cas_availabilities cas_availabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_availabilities
    ADD CONSTRAINT cas_availabilities_pkey PRIMARY KEY (id);


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
-- Name: census_by_project_types census_by_project_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.census_by_project_types
    ADD CONSTRAINT census_by_project_types_pkey PRIMARY KEY (id);


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
-- Name: hmis_forms hmis_forms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.hmis_forms
    ADD CONSTRAINT hmis_forms_pkey PRIMARY KEY (id);


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
-- Name: project_project_groups project_project_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_project_groups
    ADD CONSTRAINT project_project_groups_pkey PRIMARY KEY (id);


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
-- Name: uploads uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uploads
    ADD CONSTRAINT uploads_pkey PRIMARY KEY (id);


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
-- Name: client_id_ret_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_id_ret_index ON public.recent_report_enrollments USING btree (client_id);


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
-- Name: entrydate_ret_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX entrydate_ret_index ON public.recent_report_enrollments USING btree ("EntryDate");


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
-- Name: household_id_rsh_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX household_id_rsh_index ON public.recent_service_history USING btree (household_id);


--
-- Name: id_ret_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX id_ret_index ON public.recent_report_enrollments USING btree (id);


--
-- Name: id_rsh_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX id_rsh_index ON public.recent_service_history USING btree (id);


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
-- Name: index_Affiliation_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Affiliation_on_data_source_id" ON public."Affiliation" USING btree (data_source_id);


--
-- Name: index_Client_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Client_on_creator_id" ON public."Client" USING btree (creator_id);


--
-- Name: index_Client_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Client_on_data_source_id" ON public."Client" USING btree (data_source_id);


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
-- Name: index_Disabilities_on_data_source_id_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Disabilities_on_data_source_id_PersonalID" ON public."Disabilities" USING btree (data_source_id, "PersonalID");


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
-- Name: index_EmploymentEducation_on_data_source_id_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EmploymentEducation_on_data_source_id_PersonalID" ON public."EmploymentEducation" USING btree (data_source_id, "PersonalID");


--
-- Name: index_EnrollmentCoC_on_EnrollmentCoCID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EnrollmentCoC_on_EnrollmentCoCID" ON public."EnrollmentCoC" USING btree ("EnrollmentCoCID");


--
-- Name: index_EnrollmentCoC_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EnrollmentCoC_on_data_source_id" ON public."EnrollmentCoC" USING btree (data_source_id);


--
-- Name: index_EnrollmentCoC_on_data_source_id_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EnrollmentCoC_on_data_source_id_PersonalID" ON public."EnrollmentCoC" USING btree (data_source_id, "PersonalID");


--
-- Name: index_Enrollment_on_DateDeleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_DateDeleted" ON public."Enrollment" USING btree ("DateDeleted");


--
-- Name: index_Enrollment_on_EnrollmentID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_EnrollmentID" ON public."Enrollment" USING btree ("EnrollmentID");


--
-- Name: index_Enrollment_on_EntryDate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_EntryDate" ON public."Enrollment" USING btree ("EntryDate");


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
-- Name: index_Enrollment_on_data_source_id_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_data_source_id_PersonalID" ON public."Enrollment" USING btree (data_source_id, "PersonalID");


--
-- Name: index_Exit_on_DateDeleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_DateDeleted" ON public."Exit" USING btree ("DateDeleted");


--
-- Name: index_Exit_on_EnrollmentID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_EnrollmentID" ON public."Exit" USING btree ("EnrollmentID");


--
-- Name: index_Exit_on_ExitDate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_ExitDate" ON public."Exit" USING btree ("ExitDate");


--
-- Name: index_Exit_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_PersonalID" ON public."Exit" USING btree ("PersonalID");


--
-- Name: index_Exit_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_data_source_id" ON public."Exit" USING btree (data_source_id);


--
-- Name: index_Exit_on_data_source_id_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_data_source_id_PersonalID" ON public."Exit" USING btree (data_source_id, "PersonalID");


--
-- Name: index_Export_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Export_on_data_source_id" ON public."Export" USING btree (data_source_id);


--
-- Name: index_Funder_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Funder_on_data_source_id" ON public."Funder" USING btree (data_source_id);


--
-- Name: index_Geography_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Geography_on_data_source_id" ON public."Geography" USING btree (data_source_id);


--
-- Name: index_HealthAndDV_on_EnrollmentID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_HealthAndDV_on_EnrollmentID" ON public."HealthAndDV" USING btree ("EnrollmentID");


--
-- Name: index_HealthAndDV_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_HealthAndDV_on_PersonalID" ON public."HealthAndDV" USING btree ("PersonalID");


--
-- Name: index_HealthAndDV_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_HealthAndDV_on_data_source_id" ON public."HealthAndDV" USING btree (data_source_id);


--
-- Name: index_HealthAndDV_on_data_source_id_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_HealthAndDV_on_data_source_id_PersonalID" ON public."HealthAndDV" USING btree (data_source_id, "PersonalID");


--
-- Name: index_IncomeBenefits_on_EnrollmentID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_EnrollmentID" ON public."IncomeBenefits" USING btree ("EnrollmentID");


--
-- Name: index_IncomeBenefits_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_PersonalID" ON public."IncomeBenefits" USING btree ("PersonalID");


--
-- Name: index_IncomeBenefits_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_data_source_id" ON public."IncomeBenefits" USING btree (data_source_id);


--
-- Name: index_IncomeBenefits_on_data_source_id_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_data_source_id_PersonalID" ON public."IncomeBenefits" USING btree (data_source_id, "PersonalID");


--
-- Name: index_Inventory_on_ProjectID_and_CoCCode_and_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Inventory_on_ProjectID_and_CoCCode_and_data_source_id" ON public."Inventory" USING btree ("ProjectID", "CoCCode", data_source_id);


--
-- Name: index_Inventory_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Inventory_on_data_source_id" ON public."Inventory" USING btree (data_source_id);


--
-- Name: index_Organization_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Organization_on_data_source_id" ON public."Organization" USING btree (data_source_id);


--
-- Name: index_ProjectCoC_on_data_source_id_and_ProjectID_and_CoCCode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_ProjectCoC_on_data_source_id_and_ProjectID_and_CoCCode" ON public."ProjectCoC" USING btree (data_source_id, "ProjectID", "CoCCode");


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
-- Name: index_Services_on_DateDeleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Services_on_DateDeleted" ON public."Services" USING btree ("DateDeleted");


--
-- Name: index_Services_on_DateProvided; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Services_on_DateProvided" ON public."Services" USING btree ("DateProvided");


--
-- Name: index_Services_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Services_on_PersonalID" ON public."Services" USING btree ("PersonalID");


--
-- Name: index_Services_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Services_on_data_source_id" ON public."Services" USING btree (data_source_id);


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
-- Name: index_cas_houseds_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_houseds_on_client_id ON public.cas_houseds USING btree (client_id);


--
-- Name: index_cas_non_hmis_client_histories_on_cas_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_cas_non_hmis_client_histories_on_cas_client_id ON public.cas_non_hmis_client_histories USING btree (cas_client_id);


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
-- Name: index_client_notes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_notes_on_user_id ON public.client_notes USING btree (user_id);


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
-- Name: index_enrollment_change_histories_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_enrollment_change_histories_on_client_id ON public.enrollment_change_histories USING btree (client_id);


--
-- Name: index_eto_api_configs_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_eto_api_configs_on_data_source_id ON public.eto_api_configs USING btree (data_source_id);


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
-- Name: index_import_logs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_import_logs_on_updated_at ON public.import_logs USING btree (updated_at);


--
-- Name: index_new_service_history_on_first_date_in_program; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_new_service_history_on_first_date_in_program ON public.new_service_history USING brin (first_date_in_program);


--
-- Name: index_non_hmis_uploads_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_non_hmis_uploads_on_deleted_at ON public.non_hmis_uploads USING btree (deleted_at);


--
-- Name: index_proj_proj_id_org_id_ds_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_proj_proj_id_org_id_ds_id ON public."Project" USING btree ("ProjectID", data_source_id, "OrganizationID");


--
-- Name: index_project_data_quality_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_data_quality_on_project_id ON public.project_data_quality USING btree (project_id);


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

CREATE INDEX index_shs_1900_date_en_id ON public.service_history_services_remainder USING btree (date, service_history_enrollment_id);


--
-- Name: index_shs_1900_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_1900_date_project_type ON public.service_history_services_remainder USING btree (date, project_type);


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

CREATE INDEX index_shs_2000_date_en_id ON public.service_history_services_2000 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2000_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2000_date_project_type ON public.service_history_services_2000 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2001_date_en_id ON public.service_history_services_2001 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2001_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2001_date_project_type ON public.service_history_services_2001 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2002_date_en_id ON public.service_history_services_2002 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2002_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2002_date_project_type ON public.service_history_services_2002 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2003_date_en_id ON public.service_history_services_2003 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2003_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2003_date_project_type ON public.service_history_services_2003 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2004_date_en_id ON public.service_history_services_2004 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2004_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2004_date_project_type ON public.service_history_services_2004 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2005_date_en_id ON public.service_history_services_2005 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2005_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2005_date_project_type ON public.service_history_services_2005 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2006_date_en_id ON public.service_history_services_2006 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2006_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2006_date_project_type ON public.service_history_services_2006 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2007_date_en_id ON public.service_history_services_2007 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2007_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2007_date_project_type ON public.service_history_services_2007 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2008_date_en_id ON public.service_history_services_2008 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2008_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2008_date_project_type ON public.service_history_services_2008 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2009_date_en_id ON public.service_history_services_2009 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2009_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2009_date_project_type ON public.service_history_services_2009 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2010_date_en_id ON public.service_history_services_2010 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2010_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2010_date_project_type ON public.service_history_services_2010 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2011_date_en_id ON public.service_history_services_2011 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2011_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2011_date_project_type ON public.service_history_services_2011 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2012_date_en_id ON public.service_history_services_2012 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2012_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2012_date_project_type ON public.service_history_services_2012 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2013_date_en_id ON public.service_history_services_2013 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2013_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2013_date_project_type ON public.service_history_services_2013 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2014_date_en_id ON public.service_history_services_2014 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2014_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2014_date_project_type ON public.service_history_services_2014 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2015_date_en_id ON public.service_history_services_2015 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2015_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2015_date_project_type ON public.service_history_services_2015 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2016_date_en_id ON public.service_history_services_2016 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2016_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2016_date_project_type ON public.service_history_services_2016 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2017_date_en_id ON public.service_history_services_2017 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2017_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2017_date_project_type ON public.service_history_services_2017 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2018_date_en_id ON public.service_history_services_2018 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2018_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2018_date_project_type ON public.service_history_services_2018 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2019_date_en_id ON public.service_history_services_2019 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2019_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2019_date_project_type ON public.service_history_services_2019 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2020_date_en_id ON public.service_history_services_2020 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2020_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2020_date_project_type ON public.service_history_services_2020 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2021_date_en_id ON public.service_history_services_2021 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2021_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2021_date_project_type ON public.service_history_services_2021 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2022_date_en_id ON public.service_history_services_2022 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2022_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2022_date_project_type ON public.service_history_services_2022 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2023_date_en_id ON public.service_history_services_2023 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2023_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2023_date_project_type ON public.service_history_services_2023 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2024_date_en_id ON public.service_history_services_2024 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2024_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2024_date_project_type ON public.service_history_services_2024 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2025_date_en_id ON public.service_history_services_2025 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2025_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2025_date_project_type ON public.service_history_services_2025 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2026_date_en_id ON public.service_history_services_2026 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2026_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2026_date_project_type ON public.service_history_services_2026 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2027_date_en_id ON public.service_history_services_2027 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2027_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2027_date_project_type ON public.service_history_services_2027 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2028_date_en_id ON public.service_history_services_2028 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2028_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2028_date_project_type ON public.service_history_services_2028 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2029_date_en_id ON public.service_history_services_2029 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2029_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2029_date_project_type ON public.service_history_services_2029 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2030_date_en_id ON public.service_history_services_2030 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2030_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2030_date_project_type ON public.service_history_services_2030 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2031_date_en_id ON public.service_history_services_2031 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2031_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2031_date_project_type ON public.service_history_services_2031 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2032_date_en_id ON public.service_history_services_2032 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2032_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2032_date_project_type ON public.service_history_services_2032 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2033_date_en_id ON public.service_history_services_2033 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2033_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2033_date_project_type ON public.service_history_services_2033 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2034_date_en_id ON public.service_history_services_2034 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2034_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2034_date_project_type ON public.service_history_services_2034 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2035_date_en_id ON public.service_history_services_2035 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2035_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2035_date_project_type ON public.service_history_services_2035 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2036_date_en_id ON public.service_history_services_2036 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2036_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2036_date_project_type ON public.service_history_services_2036 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2037_date_en_id ON public.service_history_services_2037 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2037_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2037_date_project_type ON public.service_history_services_2037 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2038_date_en_id ON public.service_history_services_2038 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2038_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2038_date_project_type ON public.service_history_services_2038 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2039_date_en_id ON public.service_history_services_2039 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2039_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2039_date_project_type ON public.service_history_services_2039 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2040_date_en_id ON public.service_history_services_2040 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2040_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2040_date_project_type ON public.service_history_services_2040 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2041_date_en_id ON public.service_history_services_2041 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2041_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2041_date_project_type ON public.service_history_services_2041 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2042_date_en_id ON public.service_history_services_2042 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2042_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2042_date_project_type ON public.service_history_services_2042 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2043_date_en_id ON public.service_history_services_2043 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2043_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2043_date_project_type ON public.service_history_services_2043 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2044_date_en_id ON public.service_history_services_2044 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2044_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2044_date_project_type ON public.service_history_services_2044 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2045_date_en_id ON public.service_history_services_2045 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2045_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2045_date_project_type ON public.service_history_services_2045 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2046_date_en_id ON public.service_history_services_2046 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2046_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2046_date_project_type ON public.service_history_services_2046 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2047_date_en_id ON public.service_history_services_2047 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2047_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2047_date_project_type ON public.service_history_services_2047 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2048_date_en_id ON public.service_history_services_2048 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2048_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2048_date_project_type ON public.service_history_services_2048 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2049_date_en_id ON public.service_history_services_2049 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2049_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2049_date_project_type ON public.service_history_services_2049 USING btree (project_type, date, record_type);


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

CREATE INDEX index_shs_2050_date_en_id ON public.service_history_services_2050 USING btree (service_history_enrollment_id, date, record_type);


--
-- Name: index_shs_2050_date_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shs_2050_date_project_type ON public.service_history_services_2050 USING btree (project_type, date, record_type);


--
-- Name: index_shsm_c_id_p_type_r_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shsm_c_id_p_type_r_type ON public.service_history_services_materialized USING btree (client_id, project_type, record_type);


--
-- Name: index_shsm_p_type_r_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shsm_p_type_r_type ON public.service_history_services_materialized USING btree (project_type, record_type);


--
-- Name: index_staff_x_client_s_id_c_id_r_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_staff_x_client_s_id_c_id_r_id ON public.hmis_staff_x_clients USING btree (staff_id, client_id, relationship_id);


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
-- Name: index_uploads_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_uploads_on_deleted_at ON public.uploads USING btree (deleted_at);


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
-- Name: one_entity_per_type_per_user_allows_delete; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX one_entity_per_type_per_user_allows_delete ON public.user_viewable_entities USING btree (user_id, entity_id, entity_type, deleted_at);


--
-- Name: organization_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX organization_export_id ON public."Organization" USING btree ("ExportID");


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

CREATE INDEX project_project_override_index ON public."Project" USING btree ((COALESCE(act_as_project_type, "ProjectType")));


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
-- Name: unk_Affiliation; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Affiliation" ON public."Affiliation" USING btree (data_source_id, "AffiliationID");


--
-- Name: unk_Disabilities; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Disabilities" ON public."Disabilities" USING btree (data_source_id, "DisabilitiesID");


--
-- Name: unk_EmploymentEducation; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_EmploymentEducation" ON public."EmploymentEducation" USING btree (data_source_id, "EmploymentEducationID");


--
-- Name: unk_Enrollment; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Enrollment" ON public."Enrollment" USING btree (data_source_id, "EnrollmentID", "PersonalID");


--
-- Name: unk_EnrollmentCoC; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_EnrollmentCoC" ON public."EnrollmentCoC" USING btree (data_source_id, "EnrollmentCoCID");


--
-- Name: unk_Exit; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Exit" ON public."Exit" USING btree (data_source_id, "ExitID");


--
-- Name: unk_Export; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Export" ON public."Export" USING btree (data_source_id, "ExportID");


--
-- Name: unk_Funder; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Funder" ON public."Funder" USING btree (data_source_id, "FunderID");


--
-- Name: unk_Geography; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Geography" ON public."Geography" USING btree (data_source_id, "GeographyID");


--
-- Name: unk_HealthAndDV; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_HealthAndDV" ON public."HealthAndDV" USING btree (data_source_id, "HealthAndDVID");


--
-- Name: unk_IncomeBenefits; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_IncomeBenefits" ON public."IncomeBenefits" USING btree (data_source_id, "IncomeBenefitsID");


--
-- Name: unk_Inventory; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Inventory" ON public."Inventory" USING btree (data_source_id, "InventoryID");


--
-- Name: unk_Organization; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Organization" ON public."Organization" USING btree (data_source_id, "OrganizationID");


--
-- Name: unk_Project; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Project" ON public."Project" USING btree (data_source_id, "ProjectID");


--
-- Name: unk_ProjectCoC; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_ProjectCoC" ON public."ProjectCoC" USING btree (data_source_id, "ProjectCoCID");


--
-- Name: unk_Services; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Services" ON public."Services" USING btree (data_source_id, "ServicesID");


--
-- Name: unk_Site; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Site" ON public."Geography" USING btree (data_source_id, "GeographyID");


--
-- Name: service_history_services service_history_service_insert_trigger; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER service_history_service_insert_trigger BEFORE INSERT ON public.service_history_services FOR EACH ROW EXECUTE PROCEDURE public.service_history_service_insert_trigger();


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
-- Name: service_history_services_2020 fk_rails_62836f1ae6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_history_services_2020
    ADD CONSTRAINT fk_rails_62836f1ae6 FOREIGN KEY (service_history_enrollment_id) REFERENCES public.service_history_enrollments(id) ON DELETE CASCADE;


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

INSERT INTO schema_migrations (version) VALUES ('20160727190957');

INSERT INTO schema_migrations (version) VALUES ('20160729135359');

INSERT INTO schema_migrations (version) VALUES ('20160729183141');

INSERT INTO schema_migrations (version) VALUES ('20160816131814');

INSERT INTO schema_migrations (version) VALUES ('20160816173101');

INSERT INTO schema_migrations (version) VALUES ('20160818180405');

INSERT INTO schema_migrations (version) VALUES ('20160823130251');

INSERT INTO schema_migrations (version) VALUES ('20160823144637');

INSERT INTO schema_migrations (version) VALUES ('20160824150416');

INSERT INTO schema_migrations (version) VALUES ('20160826140306');

INSERT INTO schema_migrations (version) VALUES ('20160902162623');

INSERT INTO schema_migrations (version) VALUES ('20160902185045');

INSERT INTO schema_migrations (version) VALUES ('20160910000538');

INSERT INTO schema_migrations (version) VALUES ('20160913132444');

INSERT INTO schema_migrations (version) VALUES ('20160913152926');

INSERT INTO schema_migrations (version) VALUES ('20160913155401');

INSERT INTO schema_migrations (version) VALUES ('20160913160306');

INSERT INTO schema_migrations (version) VALUES ('20160913161311');

INSERT INTO schema_migrations (version) VALUES ('20160914185810');

INSERT INTO schema_migrations (version) VALUES ('20160919210259');

INSERT INTO schema_migrations (version) VALUES ('20160919212545');

INSERT INTO schema_migrations (version) VALUES ('20160922142402');

INSERT INTO schema_migrations (version) VALUES ('20160922162359');

INSERT INTO schema_migrations (version) VALUES ('20160922185930');

INSERT INTO schema_migrations (version) VALUES ('20160923113802');

INSERT INTO schema_migrations (version) VALUES ('20160926002900');

INSERT INTO schema_migrations (version) VALUES ('20160926145351');

INSERT INTO schema_migrations (version) VALUES ('20160926170204');

INSERT INTO schema_migrations (version) VALUES ('20160927134516');

INSERT INTO schema_migrations (version) VALUES ('20160927183151');

INSERT INTO schema_migrations (version) VALUES ('20160927184003');

INSERT INTO schema_migrations (version) VALUES ('20160927202506');

INSERT INTO schema_migrations (version) VALUES ('20160927202843');

INSERT INTO schema_migrations (version) VALUES ('20160927203650');

INSERT INTO schema_migrations (version) VALUES ('20160927205852');

INSERT INTO schema_migrations (version) VALUES ('20160928125517');

INSERT INTO schema_migrations (version) VALUES ('20160928140906');

INSERT INTO schema_migrations (version) VALUES ('20160928202720');

INSERT INTO schema_migrations (version) VALUES ('20160929010237');

INSERT INTO schema_migrations (version) VALUES ('20160929153319');

INSERT INTO schema_migrations (version) VALUES ('20160930142027');

INSERT INTO schema_migrations (version) VALUES ('20161004181613');

INSERT INTO schema_migrations (version) VALUES ('20161006180229');

INSERT INTO schema_migrations (version) VALUES ('20161007160124');

INSERT INTO schema_migrations (version) VALUES ('20161007182409');

INSERT INTO schema_migrations (version) VALUES ('20161011135522');

INSERT INTO schema_migrations (version) VALUES ('20161017193504');

INSERT INTO schema_migrations (version) VALUES ('20161019122336');

INSERT INTO schema_migrations (version) VALUES ('20161019181914');

INSERT INTO schema_migrations (version) VALUES ('20161020175933');

INSERT INTO schema_migrations (version) VALUES ('20161021142349');

INSERT INTO schema_migrations (version) VALUES ('20161021185201');

INSERT INTO schema_migrations (version) VALUES ('20161024205300');

INSERT INTO schema_migrations (version) VALUES ('20161025142716');

INSERT INTO schema_migrations (version) VALUES ('20161027160241');

INSERT INTO schema_migrations (version) VALUES ('20161027173838');

INSERT INTO schema_migrations (version) VALUES ('20161029184725');

INSERT INTO schema_migrations (version) VALUES ('20161030141156');

INSERT INTO schema_migrations (version) VALUES ('20161102131838');

INSERT INTO schema_migrations (version) VALUES ('20161102194513');

INSERT INTO schema_migrations (version) VALUES ('20161103173010');

INSERT INTO schema_migrations (version) VALUES ('20161104131304');

INSERT INTO schema_migrations (version) VALUES ('20161108150033');

INSERT INTO schema_migrations (version) VALUES ('20161109173403');

INSERT INTO schema_migrations (version) VALUES ('20161111194734');

INSERT INTO schema_migrations (version) VALUES ('20161111200331');

INSERT INTO schema_migrations (version) VALUES ('20161111205557');

INSERT INTO schema_migrations (version) VALUES ('20161111210852');

INSERT INTO schema_migrations (version) VALUES ('20161111214343');

INSERT INTO schema_migrations (version) VALUES ('20161115160857');

INSERT INTO schema_migrations (version) VALUES ('20161115163024');

INSERT INTO schema_migrations (version) VALUES ('20161115173437');

INSERT INTO schema_migrations (version) VALUES ('20161115181519');

INSERT INTO schema_migrations (version) VALUES ('20161115194005');

INSERT INTO schema_migrations (version) VALUES ('20161117042632');

INSERT INTO schema_migrations (version) VALUES ('20161117211439');

INSERT INTO schema_migrations (version) VALUES ('20161121134639');

INSERT INTO schema_migrations (version) VALUES ('20161122193356');

INSERT INTO schema_migrations (version) VALUES ('20161122205922');

INSERT INTO schema_migrations (version) VALUES ('20161122212446');

INSERT INTO schema_migrations (version) VALUES ('20161123145006');

INSERT INTO schema_migrations (version) VALUES ('20161128164214');

INSERT INTO schema_migrations (version) VALUES ('20161212154456');

INSERT INTO schema_migrations (version) VALUES ('20161213184140');

INSERT INTO schema_migrations (version) VALUES ('20161222172617');

INSERT INTO schema_migrations (version) VALUES ('20161223181314');

INSERT INTO schema_migrations (version) VALUES ('20161228184803');

INSERT INTO schema_migrations (version) VALUES ('20161229150159');

INSERT INTO schema_migrations (version) VALUES ('20170110183158');

INSERT INTO schema_migrations (version) VALUES ('20170210211420');

INSERT INTO schema_migrations (version) VALUES ('20170314123357');

INSERT INTO schema_migrations (version) VALUES ('20170420193254');

INSERT INTO schema_migrations (version) VALUES ('20170505131647');

INSERT INTO schema_migrations (version) VALUES ('20170505135248');

INSERT INTO schema_migrations (version) VALUES ('20170508001011');

INSERT INTO schema_migrations (version) VALUES ('20170508003906');

INSERT INTO schema_migrations (version) VALUES ('20170509183056');

INSERT INTO schema_migrations (version) VALUES ('20170510131916');

INSERT INTO schema_migrations (version) VALUES ('20170518194049');

INSERT INTO schema_migrations (version) VALUES ('20170526142051');

INSERT INTO schema_migrations (version) VALUES ('20170526162435');

INSERT INTO schema_migrations (version) VALUES ('20170530203255');

INSERT INTO schema_migrations (version) VALUES ('20170531152936');

INSERT INTO schema_migrations (version) VALUES ('20170602183611');

INSERT INTO schema_migrations (version) VALUES ('20170602235909');

INSERT INTO schema_migrations (version) VALUES ('20170604225122');

INSERT INTO schema_migrations (version) VALUES ('20170605004541');

INSERT INTO schema_migrations (version) VALUES ('20170605011844');

INSERT INTO schema_migrations (version) VALUES ('20170607195038');

INSERT INTO schema_migrations (version) VALUES ('20170609162811');

INSERT INTO schema_migrations (version) VALUES ('20170619211924');

INSERT INTO schema_migrations (version) VALUES ('20170620000812');

INSERT INTO schema_migrations (version) VALUES ('20170620013208');

INSERT INTO schema_migrations (version) VALUES ('20170622125121');

INSERT INTO schema_migrations (version) VALUES ('20170626133126');

INSERT INTO schema_migrations (version) VALUES ('20170705125336');

INSERT INTO schema_migrations (version) VALUES ('20170706145106');

INSERT INTO schema_migrations (version) VALUES ('20170712174621');

INSERT INTO schema_migrations (version) VALUES ('20170712182033');

INSERT INTO schema_migrations (version) VALUES ('20170714172533');

INSERT INTO schema_migrations (version) VALUES ('20170714195436');

INSERT INTO schema_migrations (version) VALUES ('20170716180758');

INSERT INTO schema_migrations (version) VALUES ('20170716202346');

INSERT INTO schema_migrations (version) VALUES ('20170718132138');

INSERT INTO schema_migrations (version) VALUES ('20170719172444');

INSERT INTO schema_migrations (version) VALUES ('20170726140915');

INSERT INTO schema_migrations (version) VALUES ('20170727231741');

INSERT INTO schema_migrations (version) VALUES ('20170728151813');

INSERT INTO schema_migrations (version) VALUES ('20170728201723');

INSERT INTO schema_migrations (version) VALUES ('20170801120635');

INSERT INTO schema_migrations (version) VALUES ('20170809173044');

INSERT INTO schema_migrations (version) VALUES ('20170815174824');

INSERT INTO schema_migrations (version) VALUES ('20170816175326');

INSERT INTO schema_migrations (version) VALUES ('20170816205625');

INSERT INTO schema_migrations (version) VALUES ('20170817150519');

INSERT INTO schema_migrations (version) VALUES ('20170818140329');

INSERT INTO schema_migrations (version) VALUES ('20170829131400');

INSERT INTO schema_migrations (version) VALUES ('20170830171507');

INSERT INTO schema_migrations (version) VALUES ('20170904132001');

INSERT INTO schema_migrations (version) VALUES ('20170904140427');

INSERT INTO schema_migrations (version) VALUES ('20170904202838');

INSERT INTO schema_migrations (version) VALUES ('20170905122913');

INSERT INTO schema_migrations (version) VALUES ('20170905122914');

INSERT INTO schema_migrations (version) VALUES ('20170905122915');

INSERT INTO schema_migrations (version) VALUES ('20170905122916');

INSERT INTO schema_migrations (version) VALUES ('20170905122917');

INSERT INTO schema_migrations (version) VALUES ('20170905122918');

INSERT INTO schema_migrations (version) VALUES ('20170905183117');

INSERT INTO schema_migrations (version) VALUES ('20170905202251');

INSERT INTO schema_migrations (version) VALUES ('20170905202611');

INSERT INTO schema_migrations (version) VALUES ('20170906161906');

INSERT INTO schema_migrations (version) VALUES ('20170911124040');

INSERT INTO schema_migrations (version) VALUES ('20170911194951');

INSERT INTO schema_migrations (version) VALUES ('20170912134710');

INSERT INTO schema_migrations (version) VALUES ('20170913192945');

INSERT INTO schema_migrations (version) VALUES ('20170918135821');

INSERT INTO schema_migrations (version) VALUES ('20170921201252');

INSERT INTO schema_migrations (version) VALUES ('20170922193229');

INSERT INTO schema_migrations (version) VALUES ('20170922200507');

INSERT INTO schema_migrations (version) VALUES ('20170924001510');

INSERT INTO schema_migrations (version) VALUES ('20170924005724');

INSERT INTO schema_migrations (version) VALUES ('20170924193906');

INSERT INTO schema_migrations (version) VALUES ('20170925000145');

INSERT INTO schema_migrations (version) VALUES ('20170926124009');

INSERT INTO schema_migrations (version) VALUES ('20170926200356');

INSERT INTO schema_migrations (version) VALUES ('20170927194653');

INSERT INTO schema_migrations (version) VALUES ('20170928185422');

INSERT INTO schema_migrations (version) VALUES ('20170928191904');

INSERT INTO schema_migrations (version) VALUES ('20170929193327');

INSERT INTO schema_migrations (version) VALUES ('20170930184143');

INSERT INTO schema_migrations (version) VALUES ('20171003122627');

INSERT INTO schema_migrations (version) VALUES ('20171005191828');

INSERT INTO schema_migrations (version) VALUES ('20171016191359');

INSERT INTO schema_migrations (version) VALUES ('20171019085351');

INSERT INTO schema_migrations (version) VALUES ('20171019143151');

INSERT INTO schema_migrations (version) VALUES ('20171020131243');

INSERT INTO schema_migrations (version) VALUES ('20171021194831');

INSERT INTO schema_migrations (version) VALUES ('20171023175038');

INSERT INTO schema_migrations (version) VALUES ('20171023194703');

INSERT INTO schema_migrations (version) VALUES ('20171024123740');

INSERT INTO schema_migrations (version) VALUES ('20171024180819');

INSERT INTO schema_migrations (version) VALUES ('20171025165617');

INSERT INTO schema_migrations (version) VALUES ('20171026122017');

INSERT INTO schema_migrations (version) VALUES ('20171026152842');

INSERT INTO schema_migrations (version) VALUES ('20171027031033');

INSERT INTO schema_migrations (version) VALUES ('20171102134710');

INSERT INTO schema_migrations (version) VALUES ('20171103003947');

INSERT INTO schema_migrations (version) VALUES ('20171103134010');

INSERT INTO schema_migrations (version) VALUES ('20171103154925');

INSERT INTO schema_migrations (version) VALUES ('20171106005358');

INSERT INTO schema_migrations (version) VALUES ('20171106211934');

INSERT INTO schema_migrations (version) VALUES ('20171108195513');

INSERT INTO schema_migrations (version) VALUES ('20171110180121');

INSERT INTO schema_migrations (version) VALUES ('20171111032952');

INSERT INTO schema_migrations (version) VALUES ('20171111190457');

INSERT INTO schema_migrations (version) VALUES ('20171113134728');

INSERT INTO schema_migrations (version) VALUES ('20171113142927');

INSERT INTO schema_migrations (version) VALUES ('20171113182656');

INSERT INTO schema_migrations (version) VALUES ('20171114132110');

INSERT INTO schema_migrations (version) VALUES ('20171115182249');

INSERT INTO schema_migrations (version) VALUES ('20171115193025');

INSERT INTO schema_migrations (version) VALUES ('20171116155352');

INSERT INTO schema_migrations (version) VALUES ('20171116184557');

INSERT INTO schema_migrations (version) VALUES ('20171127191122');

INSERT INTO schema_migrations (version) VALUES ('20171127203632');

INSERT INTO schema_migrations (version) VALUES ('20171127234210');

INSERT INTO schema_migrations (version) VALUES ('20171128161058');

INSERT INTO schema_migrations (version) VALUES ('20171129131811');

INSERT INTO schema_migrations (version) VALUES ('20171129172903');

INSERT INTO schema_migrations (version) VALUES ('20171204161239');

INSERT INTO schema_migrations (version) VALUES ('20171204180630');

INSERT INTO schema_migrations (version) VALUES ('20171205135225');

INSERT INTO schema_migrations (version) VALUES ('20171206131931');

INSERT INTO schema_migrations (version) VALUES ('20171208151137');

INSERT INTO schema_migrations (version) VALUES ('20171211131328');

INSERT INTO schema_migrations (version) VALUES ('20171211142747');

INSERT INTO schema_migrations (version) VALUES ('20171211194546');

INSERT INTO schema_migrations (version) VALUES ('20171212182935');

INSERT INTO schema_migrations (version) VALUES ('20171213002710');

INSERT INTO schema_migrations (version) VALUES ('20171213002924');

INSERT INTO schema_migrations (version) VALUES ('20171215203448');

INSERT INTO schema_migrations (version) VALUES ('20171218211735');

INSERT INTO schema_migrations (version) VALUES ('20171219160943');

INSERT INTO schema_migrations (version) VALUES ('20171222140958');

INSERT INTO schema_migrations (version) VALUES ('20171222142957');

INSERT INTO schema_migrations (version) VALUES ('20171222143540');

INSERT INTO schema_migrations (version) VALUES ('20171222151018');

INSERT INTO schema_migrations (version) VALUES ('20180114165737');

INSERT INTO schema_migrations (version) VALUES ('20180114181159');

INSERT INTO schema_migrations (version) VALUES ('20180115165003');

INSERT INTO schema_migrations (version) VALUES ('20180115195008');

INSERT INTO schema_migrations (version) VALUES ('20180117210259');

INSERT INTO schema_migrations (version) VALUES ('20180120142315');

INSERT INTO schema_migrations (version) VALUES ('20180120145651');

INSERT INTO schema_migrations (version) VALUES ('20180120184755');

INSERT INTO schema_migrations (version) VALUES ('20180123145547');

INSERT INTO schema_migrations (version) VALUES ('20180123151137');

INSERT INTO schema_migrations (version) VALUES ('20180125214133');

INSERT INTO schema_migrations (version) VALUES ('20180126184544');

INSERT INTO schema_migrations (version) VALUES ('20180126212658');

INSERT INTO schema_migrations (version) VALUES ('20180126230757');

INSERT INTO schema_migrations (version) VALUES ('20180127151221');

INSERT INTO schema_migrations (version) VALUES ('20180129211310');

INSERT INTO schema_migrations (version) VALUES ('20180129222234');

INSERT INTO schema_migrations (version) VALUES ('20180130173319');

INSERT INTO schema_migrations (version) VALUES ('20180203202523');

INSERT INTO schema_migrations (version) VALUES ('20180205134947');

INSERT INTO schema_migrations (version) VALUES ('20180205160021');

INSERT INTO schema_migrations (version) VALUES ('20180206132151');

INSERT INTO schema_migrations (version) VALUES ('20180206132418');

INSERT INTO schema_migrations (version) VALUES ('20180206132549');

INSERT INTO schema_migrations (version) VALUES ('20180206211300');

INSERT INTO schema_migrations (version) VALUES ('20180209140514');

INSERT INTO schema_migrations (version) VALUES ('20180209145558');

INSERT INTO schema_migrations (version) VALUES ('20180211182226');

INSERT INTO schema_migrations (version) VALUES ('20180211191923');

INSERT INTO schema_migrations (version) VALUES ('20180212154518');

INSERT INTO schema_migrations (version) VALUES ('20180213132145');

INSERT INTO schema_migrations (version) VALUES ('20180213133619');

INSERT INTO schema_migrations (version) VALUES ('20180215212401');

INSERT INTO schema_migrations (version) VALUES ('20180216221704');

INSERT INTO schema_migrations (version) VALUES ('20180218004200');

INSERT INTO schema_migrations (version) VALUES ('20180218194158');

INSERT INTO schema_migrations (version) VALUES ('20180218195838');

INSERT INTO schema_migrations (version) VALUES ('20180219003427');

INSERT INTO schema_migrations (version) VALUES ('20180219011911');

INSERT INTO schema_migrations (version) VALUES ('20180219213751');

INSERT INTO schema_migrations (version) VALUES ('20180221172154');

INSERT INTO schema_migrations (version) VALUES ('20180221200920');

INSERT INTO schema_migrations (version) VALUES ('20180222132714');

INSERT INTO schema_migrations (version) VALUES ('20180223131630');

INSERT INTO schema_migrations (version) VALUES ('20180226181023');

INSERT INTO schema_migrations (version) VALUES ('20180227184226');

INSERT INTO schema_migrations (version) VALUES ('20180228134319');

INSERT INTO schema_migrations (version) VALUES ('20180228202408');

INSERT INTO schema_migrations (version) VALUES ('20180302005549');

INSERT INTO schema_migrations (version) VALUES ('20180303012057');

INSERT INTO schema_migrations (version) VALUES ('20180304020707');

INSERT INTO schema_migrations (version) VALUES ('20180307184913');

INSERT INTO schema_migrations (version) VALUES ('20180309152824');

INSERT INTO schema_migrations (version) VALUES ('20180309161833');

INSERT INTO schema_migrations (version) VALUES ('20180309194413');

INSERT INTO schema_migrations (version) VALUES ('20180309200416');

INSERT INTO schema_migrations (version) VALUES ('20180313170616');

INSERT INTO schema_migrations (version) VALUES ('20180314121340');

INSERT INTO schema_migrations (version) VALUES ('20180319204410');

INSERT INTO schema_migrations (version) VALUES ('20180326140546');

INSERT INTO schema_migrations (version) VALUES ('20180330145925');

INSERT INTO schema_migrations (version) VALUES ('20180408102020');

INSERT INTO schema_migrations (version) VALUES ('20180410081403');

INSERT INTO schema_migrations (version) VALUES ('20180424182721');

INSERT INTO schema_migrations (version) VALUES ('20180424185646');

INSERT INTO schema_migrations (version) VALUES ('20180424190544');

INSERT INTO schema_migrations (version) VALUES ('20180425140146');

INSERT INTO schema_migrations (version) VALUES ('20180510001923');

INSERT INTO schema_migrations (version) VALUES ('20180510002556');

INSERT INTO schema_migrations (version) VALUES ('20180510130324');

INSERT INTO schema_migrations (version) VALUES ('20180516130234');

INSERT INTO schema_migrations (version) VALUES ('20180516133454');

INSERT INTO schema_migrations (version) VALUES ('20180521173754');

INSERT INTO schema_migrations (version) VALUES ('20180528152133');

INSERT INTO schema_migrations (version) VALUES ('20180528155555');

INSERT INTO schema_migrations (version) VALUES ('20180528174021');

INSERT INTO schema_migrations (version) VALUES ('20180529122603');

INSERT INTO schema_migrations (version) VALUES ('20180605164543');

INSERT INTO schema_migrations (version) VALUES ('20180613193551');

INSERT INTO schema_migrations (version) VALUES ('20180614004301');

INSERT INTO schema_migrations (version) VALUES ('20180615232905');

INSERT INTO schema_migrations (version) VALUES ('20180616123004');

INSERT INTO schema_migrations (version) VALUES ('20180617111542');

INSERT INTO schema_migrations (version) VALUES ('20180617130414');

INSERT INTO schema_migrations (version) VALUES ('20180626134714');

INSERT INTO schema_migrations (version) VALUES ('20180626140358');

INSERT INTO schema_migrations (version) VALUES ('20180628035131');

INSERT INTO schema_migrations (version) VALUES ('20180707180119');

INSERT INTO schema_migrations (version) VALUES ('20180707183425');

INSERT INTO schema_migrations (version) VALUES ('20180709173131');

INSERT INTO schema_migrations (version) VALUES ('20180710174412');

INSERT INTO schema_migrations (version) VALUES ('20180710195222');

INSERT INTO schema_migrations (version) VALUES ('20180713143703');

INSERT INTO schema_migrations (version) VALUES ('20180716142944');

INSERT INTO schema_migrations (version) VALUES ('20180716175514');

INSERT INTO schema_migrations (version) VALUES ('20180716181552');

INSERT INTO schema_migrations (version) VALUES ('20180718152629');

INSERT INTO schema_migrations (version) VALUES ('20180723180257');

INSERT INTO schema_migrations (version) VALUES ('20180731125029');

INSERT INTO schema_migrations (version) VALUES ('20180801185645');

INSERT INTO schema_migrations (version) VALUES ('20180810142730');

INSERT INTO schema_migrations (version) VALUES ('20180810175903');

INSERT INTO schema_migrations (version) VALUES ('20180813144056');

INSERT INTO schema_migrations (version) VALUES ('20180814144715');

INSERT INTO schema_migrations (version) VALUES ('20180815162429');

INSERT INTO schema_migrations (version) VALUES ('20180831171525');

INSERT INTO schema_migrations (version) VALUES ('20180909174113');

INSERT INTO schema_migrations (version) VALUES ('20180910121905');

INSERT INTO schema_migrations (version) VALUES ('20180910130909');

INSERT INTO schema_migrations (version) VALUES ('20180912121943');

INSERT INTO schema_migrations (version) VALUES ('20180912154937');

INSERT INTO schema_migrations (version) VALUES ('20180914235727');

INSERT INTO schema_migrations (version) VALUES ('20180917204430');

INSERT INTO schema_migrations (version) VALUES ('20180919135034');

INSERT INTO schema_migrations (version) VALUES ('20181001174159');

INSERT INTO schema_migrations (version) VALUES ('20181001180812');

INSERT INTO schema_migrations (version) VALUES ('20181001193048');

INSERT INTO schema_migrations (version) VALUES ('20181005171232');

INSERT INTO schema_migrations (version) VALUES ('20181005172849');

INSERT INTO schema_migrations (version) VALUES ('20181010193431');

INSERT INTO schema_migrations (version) VALUES ('20181012130754');

INSERT INTO schema_migrations (version) VALUES ('20181015132913');

INSERT INTO schema_migrations (version) VALUES ('20181015132958');

INSERT INTO schema_migrations (version) VALUES ('20181019160628');

INSERT INTO schema_migrations (version) VALUES ('20181019182438');

INSERT INTO schema_migrations (version) VALUES ('20181019185052');

INSERT INTO schema_migrations (version) VALUES ('20181022144551');

INSERT INTO schema_migrations (version) VALUES ('20181026125946');

INSERT INTO schema_migrations (version) VALUES ('20181030142001');

INSERT INTO schema_migrations (version) VALUES ('20181031151924');

INSERT INTO schema_migrations (version) VALUES ('20181107183718');

INSERT INTO schema_migrations (version) VALUES ('20181107184057');

INSERT INTO schema_migrations (version) VALUES ('20181107184157');

INSERT INTO schema_migrations (version) VALUES ('20181107184258');

INSERT INTO schema_migrations (version) VALUES ('20181119165528');

INSERT INTO schema_migrations (version) VALUES ('20181206135841');

INSERT INTO schema_migrations (version) VALUES ('20181206195139');

INSERT INTO schema_migrations (version) VALUES ('20181207011350');

INSERT INTO schema_migrations (version) VALUES ('20181210141734');

INSERT INTO schema_migrations (version) VALUES ('20181218184800');

INSERT INTO schema_migrations (version) VALUES ('20181219184841');

INSERT INTO schema_migrations (version) VALUES ('20181227145018');

INSERT INTO schema_migrations (version) VALUES ('20190107135250');

INSERT INTO schema_migrations (version) VALUES ('20190108133610');

INSERT INTO schema_migrations (version) VALUES ('20190110145430');

INSERT INTO schema_migrations (version) VALUES ('20190110205705');

INSERT INTO schema_migrations (version) VALUES ('20190111154442');

INSERT INTO schema_migrations (version) VALUES ('20190111162407');

INSERT INTO schema_migrations (version) VALUES ('20190114175107');

INSERT INTO schema_migrations (version) VALUES ('20190129175440');

INSERT INTO schema_migrations (version) VALUES ('20190129193710');

INSERT INTO schema_migrations (version) VALUES ('20190129193718');

INSERT INTO schema_migrations (version) VALUES ('20190129193734');

INSERT INTO schema_migrations (version) VALUES ('20190130141818');

INSERT INTO schema_migrations (version) VALUES ('20190201172226');

INSERT INTO schema_migrations (version) VALUES ('20190204194825');

INSERT INTO schema_migrations (version) VALUES ('20190208173854');

INSERT INTO schema_migrations (version) VALUES ('20190209204636');

INSERT INTO schema_migrations (version) VALUES ('20190211182446');

INSERT INTO schema_migrations (version) VALUES ('20190211212757');

INSERT INTO schema_migrations (version) VALUES ('20190215151428');

INSERT INTO schema_migrations (version) VALUES ('20190215174811');

INSERT INTO schema_migrations (version) VALUES ('20190216193115');

INSERT INTO schema_migrations (version) VALUES ('20190221211525');

INSERT INTO schema_migrations (version) VALUES ('20190225173734');

INSERT INTO schema_migrations (version) VALUES ('20190228151509');

INSERT INTO schema_migrations (version) VALUES ('20190306011413');

INSERT INTO schema_migrations (version) VALUES ('20190307205203');

INSERT INTO schema_migrations (version) VALUES ('20190313191758');

INSERT INTO schema_migrations (version) VALUES ('20190314233300');

INSERT INTO schema_migrations (version) VALUES ('20190315202420');

INSERT INTO schema_migrations (version) VALUES ('20190319174002');

INSERT INTO schema_migrations (version) VALUES ('20190320132816');

INSERT INTO schema_migrations (version) VALUES ('20190320135300');

INSERT INTO schema_migrations (version) VALUES ('20190321154235');

INSERT INTO schema_migrations (version) VALUES ('20190322182648');

INSERT INTO schema_migrations (version) VALUES ('20190324204257');

INSERT INTO schema_migrations (version) VALUES ('20190325205709');

INSERT INTO schema_migrations (version) VALUES ('20190327174322');

INSERT INTO schema_migrations (version) VALUES ('20190328135601');

INSERT INTO schema_migrations (version) VALUES ('20190328183719');

INSERT INTO schema_migrations (version) VALUES ('20190328201651');

INSERT INTO schema_migrations (version) VALUES ('20190329122650');

INSERT INTO schema_migrations (version) VALUES ('20190408180044');

INSERT INTO schema_migrations (version) VALUES ('20190423144729');

INSERT INTO schema_migrations (version) VALUES ('20190424185158');

INSERT INTO schema_migrations (version) VALUES ('20190424194714');

INSERT INTO schema_migrations (version) VALUES ('20190501154934');

INSERT INTO schema_migrations (version) VALUES ('20190502150143');

INSERT INTO schema_migrations (version) VALUES ('20190507184540');

INSERT INTO schema_migrations (version) VALUES ('20190508181020');

INSERT INTO schema_migrations (version) VALUES ('20190509161703');

INSERT INTO schema_migrations (version) VALUES ('20190510123307');

