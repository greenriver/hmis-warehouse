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


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: Affiliation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "Affiliation" (
    "AffiliationID" character varying,
    "ProjectID" character varying,
    "ResProjectID" character varying,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL
);


--
-- Name: Affiliation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "Affiliation_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Affiliation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "Affiliation_id_seq" OWNED BY "Affiliation".id;


--
-- Name: Client; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "Client" (
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
    housing_release_status character varying
);


--
-- Name: Client_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "Client_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Client_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "Client_id_seq" OWNED BY "Client".id;


--
-- Name: Disabilities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "Disabilities" (
    "DisabilitiesID" character varying,
    "ProjectEntryID" character varying,
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
    id integer NOT NULL
);


--
-- Name: Disabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "Disabilities_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Disabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "Disabilities_id_seq" OWNED BY "Disabilities".id;


--
-- Name: EmploymentEducation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "EmploymentEducation" (
    "EmploymentEducationID" character varying,
    "ProjectEntryID" character varying,
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
    id integer NOT NULL
);


--
-- Name: EmploymentEducation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "EmploymentEducation_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: EmploymentEducation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "EmploymentEducation_id_seq" OWNED BY "EmploymentEducation".id;


--
-- Name: Enrollment; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "Enrollment" (
    "ProjectEntryID" character varying,
    "PersonalID" character varying,
    "ProjectID" character varying,
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
    "HospitalNights" integer
);


--
-- Name: EnrollmentCoC; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "EnrollmentCoC" (
    "EnrollmentCoCID" character varying,
    "ProjectEntryID" character varying,
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
    "HouseholdID" character varying(32)
);


--
-- Name: EnrollmentCoC_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "EnrollmentCoC_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: EnrollmentCoC_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "EnrollmentCoC_id_seq" OWNED BY "EnrollmentCoC".id;


--
-- Name: Enrollment_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "Enrollment_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Enrollment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "Enrollment_id_seq" OWNED BY "Enrollment".id;


--
-- Name: Exit; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "Exit" (
    "ExitID" character varying,
    "ProjectEntryID" character varying,
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
    id integer NOT NULL
);


--
-- Name: Exit_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "Exit_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Exit_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "Exit_id_seq" OWNED BY "Exit".id;


--
-- Name: Export; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "Export" (
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
    "SourceType" integer
);


--
-- Name: Export_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "Export_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Export_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "Export_id_seq" OWNED BY "Export".id;


--
-- Name: Funder; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "Funder" (
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
    id integer NOT NULL
);


--
-- Name: Funder_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "Funder_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Funder_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "Funder_id_seq" OWNED BY "Funder".id;


--
-- Name: HealthAndDV; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "HealthAndDV" (
    "HealthAndDVID" character varying,
    "ProjectEntryID" character varying,
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
    id integer NOT NULL
);


--
-- Name: HealthAndDV_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "HealthAndDV_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: HealthAndDV_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "HealthAndDV_id_seq" OWNED BY "HealthAndDV".id;


--
-- Name: IncomeBenefits; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "IncomeBenefits" (
    "IncomeBenefitsID" character varying,
    "ProjectEntryID" character varying,
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
    "ConnectionWithSOAR" integer
);


--
-- Name: IncomeBenefits_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "IncomeBenefits_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: IncomeBenefits_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "IncomeBenefits_id_seq" OWNED BY "IncomeBenefits".id;


--
-- Name: Inventory; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "Inventory" (
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
    id integer NOT NULL
);


--
-- Name: Inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "Inventory_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Inventory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "Inventory_id_seq" OWNED BY "Inventory".id;


--
-- Name: Organization; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "Organization" (
    "OrganizationID" character varying,
    "OrganizationName" character varying,
    "OrganizationCommonName" character varying,
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL,
    dmh boolean DEFAULT false NOT NULL
);


--
-- Name: Organization_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "Organization_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Organization_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "Organization_id_seq" OWNED BY "Organization".id;


--
-- Name: Project; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "Project" (
    "ProjectID" character varying,
    "OrganizationID" character varying,
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
    computed_project_type integer
);


--
-- Name: ProjectCoC; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "ProjectCoC" (
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
    hud_coc_code character varying
);


--
-- Name: ProjectCoC_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "ProjectCoC_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ProjectCoC_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "ProjectCoC_id_seq" OWNED BY "ProjectCoC".id;


--
-- Name: Project_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "Project_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Project_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "Project_id_seq" OWNED BY "Project".id;


--
-- Name: Services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "Services" (
    "ServicesID" character varying,
    "ProjectEntryID" character varying,
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
    id integer NOT NULL
);


--
-- Name: Services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "Services_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "Services_id_seq" OWNED BY "Services".id;


--
-- Name: Site; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE "Site" (
    "SiteID" character varying,
    "ProjectID" character varying,
    "CoCCode" character varying(50),
    "PrincipalSite" integer,
    "Geocode" character varying(50),
    "Address" character varying,
    "City" character varying,
    "State" character varying(2),
    "ZIP" character varying(10),
    "DateCreated" timestamp without time zone,
    "DateUpdated" timestamp without time zone,
    "UserID" character varying(100),
    "DateDeleted" timestamp without time zone,
    "ExportID" character varying,
    data_source_id integer,
    id integer NOT NULL
);


--
-- Name: Site_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE "Site_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Site_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE "Site_id_seq" OWNED BY "Site".id;


--
-- Name: api_client_data_source_ids; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE api_client_data_source_ids (
    id integer NOT NULL,
    warehouse_id character varying,
    id_in_data_source character varying,
    site_id_in_data_source integer,
    data_source_id integer,
    client_id integer,
    last_contact date
);


--
-- Name: api_client_data_source_ids_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE api_client_data_source_ids_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_client_data_source_ids_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE api_client_data_source_ids_id_seq OWNED BY api_client_data_source_ids.id;


--
-- Name: cas_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE cas_reports (
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
    program_type character varying
);


--
-- Name: cas_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cas_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cas_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cas_reports_id_seq OWNED BY cas_reports.id;


--
-- Name: census_by_project_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE census_by_project_types (
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

CREATE SEQUENCE census_by_project_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: census_by_project_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE census_by_project_types_id_seq OWNED BY census_by_project_types.id;


--
-- Name: censuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE censuses (
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

CREATE TABLE censuses_averaged_by_year (
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

CREATE SEQUENCE censuses_averaged_by_year_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: censuses_averaged_by_year_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE censuses_averaged_by_year_id_seq OWNED BY censuses_averaged_by_year.id;


--
-- Name: censuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE censuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: censuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE censuses_id_seq OWNED BY censuses.id;


--
-- Name: chronics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE chronics (
    id integer NOT NULL,
    date date NOT NULL,
    client_id integer NOT NULL,
    days_in_last_three_years integer,
    months_in_last_three_years integer,
    individual boolean,
    age integer,
    homeless_since date,
    dmh boolean DEFAULT false,
    trigger character varying
);


--
-- Name: chronics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE chronics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chronics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE chronics_id_seq OWNED BY chronics.id;


--
-- Name: client_matches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE client_matches (
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

CREATE SEQUENCE client_matches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_matches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE client_matches_id_seq OWNED BY client_matches.id;


--
-- Name: client_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE client_notes (
    id integer NOT NULL,
    client_id integer NOT NULL,
    user_id integer NOT NULL,
    type character varying NOT NULL,
    note text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


--
-- Name: client_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE client_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE client_notes_id_seq OWNED BY client_notes.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE contacts (
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

CREATE SEQUENCE contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE contacts_id_seq OWNED BY contacts.id;


--
-- Name: data_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE data_sources (
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
    visible_in_window boolean DEFAULT false NOT NULL
);


--
-- Name: data_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE data_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: data_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE data_sources_id_seq OWNED BY data_sources.id;


--
-- Name: fake_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE fake_data (
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

CREATE SEQUENCE fake_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fake_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE fake_data_id_seq OWNED BY fake_data.id;


--
-- Name: generate_service_history_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE generate_service_history_log (
    id integer NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    to_delete integer,
    to_add integer,
    to_update integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: generate_service_history_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE generate_service_history_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: generate_service_history_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE generate_service_history_log_id_seq OWNED BY generate_service_history_log.id;


--
-- Name: hmis_assessments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE hmis_assessments (
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
    exclude_from_window boolean DEFAULT false NOT NULL
);


--
-- Name: hmis_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE hmis_assessments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_assessments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE hmis_assessments_id_seq OWNED BY hmis_assessments.id;


--
-- Name: hmis_client_attributes_defined_text; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE hmis_client_attributes_defined_text (
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

CREATE SEQUENCE hmis_client_attributes_defined_text_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_client_attributes_defined_text_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE hmis_client_attributes_defined_text_id_seq OWNED BY hmis_client_attributes_defined_text.id;


--
-- Name: hmis_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE hmis_clients (
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
    subject_id integer
);


--
-- Name: hmis_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE hmis_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE hmis_clients_id_seq OWNED BY hmis_clients.id;


--
-- Name: hmis_forms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE hmis_forms (
    id integer NOT NULL,
    client_id integer,
    response text,
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
    assessment_id integer
);


--
-- Name: hmis_forms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE hmis_forms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_forms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE hmis_forms_id_seq OWNED BY hmis_forms.id;


--
-- Name: hmis_staff; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE hmis_staff (
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

CREATE SEQUENCE hmis_staff_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_staff_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE hmis_staff_id_seq OWNED BY hmis_staff.id;


--
-- Name: hmis_staff_x_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE hmis_staff_x_clients (
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

CREATE SEQUENCE hmis_staff_x_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: hmis_staff_x_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE hmis_staff_x_clients_id_seq OWNED BY hmis_staff_x_clients.id;


--
-- Name: identify_duplicates_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE identify_duplicates_log (
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

CREATE SEQUENCE identify_duplicates_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identify_duplicates_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE identify_duplicates_log_id_seq OWNED BY identify_duplicates_log.id;


--
-- Name: import_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE import_logs (
    id integer NOT NULL,
    data_source_id integer,
    files character varying,
    import_errors text,
    summary character varying,
    completed_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    zip character varying
);


--
-- Name: import_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE import_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: import_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE import_logs_id_seq OWNED BY import_logs.id;


--
-- Name: project_data_quality; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_data_quality (
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
    support json
);


--
-- Name: project_data_quality_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_data_quality_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_data_quality_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_data_quality_id_seq OWNED BY project_data_quality.id;


--
-- Name: project_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_groups (
    id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


--
-- Name: project_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE project_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_groups_id_seq OWNED BY project_groups.id;


--
-- Name: project_project_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE project_project_groups (
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

CREATE SEQUENCE project_project_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_project_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE project_project_groups_id_seq OWNED BY project_project_groups.id;


--
-- Name: report_clients; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW report_clients AS
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
   FROM "Client"
  WHERE (("Client"."DateDeleted" IS NULL) AND ("Client".data_source_id IN ( SELECT data_sources.id
           FROM data_sources
          WHERE (data_sources.source_type IS NULL))));


--
-- Name: warehouse_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE warehouse_clients (
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

CREATE VIEW report_demographics AS
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
   FROM (("Client"
     JOIN warehouse_clients ON ((warehouse_clients.source_id = "Client".id)))
     JOIN report_clients ON ((warehouse_clients.destination_id = report_clients.id)))
  WHERE ("Client"."DateDeleted" IS NULL);


--
-- Name: report_enrollments; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW report_enrollments AS
 SELECT "Enrollment"."ProjectEntryID",
    "Enrollment"."PersonalID",
    "Enrollment"."ProjectID",
    "Enrollment"."EntryDate",
    "Enrollment"."HouseholdID",
    "Enrollment"."RelationshipToHoH",
    "Enrollment"."ResidencePrior",
    "Enrollment"."OtherResidencePrior",
    "Enrollment"."ResidencePriorLengthOfStay",
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
    "Enrollment"."ResidentialMoveInDate",
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
    "Enrollment"."FYSBYouth",
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
    report_demographics.id AS demographic_id,
    report_demographics.client_id
   FROM ("Enrollment"
     LEFT JOIN report_demographics ON (((report_demographics.data_source_id = "Enrollment".data_source_id) AND ((report_demographics."PersonalID")::text = ("Enrollment"."PersonalID")::text))))
  WHERE ("Enrollment"."DateDeleted" IS NULL);


--
-- Name: report_disabilities; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW report_disabilities AS
 SELECT "Disabilities"."DisabilitiesID",
    "Disabilities"."ProjectEntryID",
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
    report_enrollments.id AS enrollment_id,
    report_demographics.id AS demographic_id,
    report_demographics.client_id
   FROM (("Disabilities"
     LEFT JOIN report_enrollments ON (((report_enrollments.data_source_id = "Disabilities".data_source_id) AND ((report_enrollments."ProjectEntryID")::text = ("Disabilities"."ProjectEntryID")::text))))
     LEFT JOIN report_demographics ON (((report_demographics.data_source_id = "Disabilities".data_source_id) AND ((report_demographics."PersonalID")::text = ("Disabilities"."PersonalID")::text))))
  WHERE ("Disabilities"."DateDeleted" IS NULL);


--
-- Name: report_employment_educations; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW report_employment_educations AS
 SELECT "EmploymentEducation"."EmploymentEducationID",
    "EmploymentEducation"."ProjectEntryID",
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
    report_enrollments.id AS enrollment_id,
    report_demographics.id AS demographic_id,
    report_demographics.client_id
   FROM (("EmploymentEducation"
     JOIN report_enrollments ON (((report_enrollments.data_source_id = "EmploymentEducation".data_source_id) AND ((report_enrollments."ProjectEntryID")::text = ("EmploymentEducation"."ProjectEntryID")::text))))
     JOIN report_demographics ON (((report_demographics.data_source_id = "EmploymentEducation".data_source_id) AND ((report_demographics."PersonalID")::text = ("EmploymentEducation"."PersonalID")::text))))
  WHERE ("EmploymentEducation"."DateDeleted" IS NULL);


--
-- Name: report_exits; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW report_exits AS
 SELECT "Exit"."ExitID",
    "Exit"."ProjectEntryID",
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
    report_enrollments.id AS enrollment_id,
    report_enrollments.client_id
   FROM ("Exit"
     JOIN report_enrollments ON (((report_enrollments.data_source_id = "Exit".data_source_id) AND ((report_enrollments."ProjectEntryID")::text = ("Exit"."ProjectEntryID")::text))))
  WHERE ("Exit"."DateDeleted" IS NULL);


--
-- Name: report_health_and_dvs; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW report_health_and_dvs AS
 SELECT "HealthAndDV"."HealthAndDVID",
    "HealthAndDV"."ProjectEntryID",
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
    report_enrollments.id AS enrollment_id,
    report_demographics.id AS demographic_id,
    report_demographics.client_id
   FROM (("HealthAndDV"
     JOIN report_enrollments ON (((report_enrollments.data_source_id = "HealthAndDV".data_source_id) AND ((report_enrollments."ProjectEntryID")::text = ("HealthAndDV"."ProjectEntryID")::text))))
     JOIN report_demographics ON (((report_demographics.data_source_id = "HealthAndDV".data_source_id) AND ((report_demographics."PersonalID")::text = ("HealthAndDV"."PersonalID")::text))))
  WHERE ("HealthAndDV"."DateDeleted" IS NULL);


--
-- Name: report_income_benefits; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW report_income_benefits AS
 SELECT "IncomeBenefits"."IncomeBenefitsID",
    "IncomeBenefits"."ProjectEntryID",
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
    report_enrollments.id AS enrollment_id,
    report_demographics.id AS demographic_id,
    report_demographics.client_id
   FROM (("IncomeBenefits"
     JOIN report_enrollments ON (((report_enrollments.data_source_id = "IncomeBenefits".data_source_id) AND ((report_enrollments."ProjectEntryID")::text = ("IncomeBenefits"."ProjectEntryID")::text))))
     JOIN report_demographics ON (((report_demographics.data_source_id = "IncomeBenefits".data_source_id) AND ((report_demographics."PersonalID")::text = ("IncomeBenefits"."PersonalID")::text))))
  WHERE ("IncomeBenefits"."DateDeleted" IS NULL);


--
-- Name: report_services; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW report_services AS
 SELECT "Services"."ServicesID",
    "Services"."ProjectEntryID",
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
    report_demographics.id AS demographic_id,
    report_demographics.client_id
   FROM ("Services"
     JOIN report_demographics ON (((report_demographics.data_source_id = "Services".data_source_id) AND ((report_demographics."PersonalID")::text = ("Services"."PersonalID")::text))))
  WHERE ("Services"."DateDeleted" IS NULL);


--
-- Name: report_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE report_tokens (
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

CREATE SEQUENCE report_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE report_tokens_id_seq OWNED BY report_tokens.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE uploads (
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
    deleted_at timestamp without time zone
);


--
-- Name: uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE uploads_id_seq OWNED BY uploads.id;


--
-- Name: user_viewable_entities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE user_viewable_entities (
    id integer NOT NULL,
    user_id integer NOT NULL,
    entity_id integer NOT NULL,
    entity_type character varying NOT NULL
);


--
-- Name: user_viewable_entities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_viewable_entities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_viewable_entities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_viewable_entities_id_seq OWNED BY user_viewable_entities.id;


--
-- Name: warehouse_client_service_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE warehouse_client_service_history (
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
    computed_project_type integer
);


--
-- Name: warehouse_client_service_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE warehouse_client_service_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_client_service_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE warehouse_client_service_history_id_seq OWNED BY warehouse_client_service_history.id;


--
-- Name: warehouse_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE warehouse_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE warehouse_clients_id_seq OWNED BY warehouse_clients.id;


--
-- Name: warehouse_clients_processed; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE warehouse_clients_processed (
    id integer NOT NULL,
    client_id integer,
    routine character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_service_updated_at timestamp without time zone,
    days_served integer,
    first_date_served date,
    last_date_served date,
    chronically_homeless boolean DEFAULT false NOT NULL
);


--
-- Name: warehouse_clients_processed_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE warehouse_clients_processed_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouse_clients_processed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE warehouse_clients_processed_id_seq OWNED BY warehouse_clients_processed.id;


--
-- Name: weather; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE weather (
    id integer NOT NULL,
    url character varying NOT NULL,
    body text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: weather_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE weather_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: weather_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE weather_id_seq OWNED BY weather.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Affiliation" ALTER COLUMN id SET DEFAULT nextval('"Affiliation_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Client" ALTER COLUMN id SET DEFAULT nextval('"Client_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Disabilities" ALTER COLUMN id SET DEFAULT nextval('"Disabilities_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "EmploymentEducation" ALTER COLUMN id SET DEFAULT nextval('"EmploymentEducation_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Enrollment" ALTER COLUMN id SET DEFAULT nextval('"Enrollment_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "EnrollmentCoC" ALTER COLUMN id SET DEFAULT nextval('"EnrollmentCoC_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Exit" ALTER COLUMN id SET DEFAULT nextval('"Exit_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Export" ALTER COLUMN id SET DEFAULT nextval('"Export_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Funder" ALTER COLUMN id SET DEFAULT nextval('"Funder_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "HealthAndDV" ALTER COLUMN id SET DEFAULT nextval('"HealthAndDV_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "IncomeBenefits" ALTER COLUMN id SET DEFAULT nextval('"IncomeBenefits_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Inventory" ALTER COLUMN id SET DEFAULT nextval('"Inventory_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Organization" ALTER COLUMN id SET DEFAULT nextval('"Organization_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Project" ALTER COLUMN id SET DEFAULT nextval('"Project_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "ProjectCoC" ALTER COLUMN id SET DEFAULT nextval('"ProjectCoC_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Services" ALTER COLUMN id SET DEFAULT nextval('"Services_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Site" ALTER COLUMN id SET DEFAULT nextval('"Site_id_seq"'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY api_client_data_source_ids ALTER COLUMN id SET DEFAULT nextval('api_client_data_source_ids_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cas_reports ALTER COLUMN id SET DEFAULT nextval('cas_reports_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY census_by_project_types ALTER COLUMN id SET DEFAULT nextval('census_by_project_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY censuses ALTER COLUMN id SET DEFAULT nextval('censuses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY censuses_averaged_by_year ALTER COLUMN id SET DEFAULT nextval('censuses_averaged_by_year_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY chronics ALTER COLUMN id SET DEFAULT nextval('chronics_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY client_matches ALTER COLUMN id SET DEFAULT nextval('client_matches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY client_notes ALTER COLUMN id SET DEFAULT nextval('client_notes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY contacts ALTER COLUMN id SET DEFAULT nextval('contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY data_sources ALTER COLUMN id SET DEFAULT nextval('data_sources_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY fake_data ALTER COLUMN id SET DEFAULT nextval('fake_data_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY generate_service_history_log ALTER COLUMN id SET DEFAULT nextval('generate_service_history_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY hmis_assessments ALTER COLUMN id SET DEFAULT nextval('hmis_assessments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY hmis_client_attributes_defined_text ALTER COLUMN id SET DEFAULT nextval('hmis_client_attributes_defined_text_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY hmis_clients ALTER COLUMN id SET DEFAULT nextval('hmis_clients_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY hmis_forms ALTER COLUMN id SET DEFAULT nextval('hmis_forms_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY hmis_staff ALTER COLUMN id SET DEFAULT nextval('hmis_staff_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY hmis_staff_x_clients ALTER COLUMN id SET DEFAULT nextval('hmis_staff_x_clients_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY identify_duplicates_log ALTER COLUMN id SET DEFAULT nextval('identify_duplicates_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY import_logs ALTER COLUMN id SET DEFAULT nextval('import_logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_data_quality ALTER COLUMN id SET DEFAULT nextval('project_data_quality_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_groups ALTER COLUMN id SET DEFAULT nextval('project_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_project_groups ALTER COLUMN id SET DEFAULT nextval('project_project_groups_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY report_tokens ALTER COLUMN id SET DEFAULT nextval('report_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY uploads ALTER COLUMN id SET DEFAULT nextval('uploads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_viewable_entities ALTER COLUMN id SET DEFAULT nextval('user_viewable_entities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY warehouse_client_service_history ALTER COLUMN id SET DEFAULT nextval('warehouse_client_service_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY warehouse_clients ALTER COLUMN id SET DEFAULT nextval('warehouse_clients_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY warehouse_clients_processed ALTER COLUMN id SET DEFAULT nextval('warehouse_clients_processed_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY weather ALTER COLUMN id SET DEFAULT nextval('weather_id_seq'::regclass);


--
-- Name: Affiliation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Affiliation"
    ADD CONSTRAINT "Affiliation_pkey" PRIMARY KEY (id);


--
-- Name: Client_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Client"
    ADD CONSTRAINT "Client_pkey" PRIMARY KEY (id);


--
-- Name: Disabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Disabilities"
    ADD CONSTRAINT "Disabilities_pkey" PRIMARY KEY (id);


--
-- Name: EmploymentEducation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "EmploymentEducation"
    ADD CONSTRAINT "EmploymentEducation_pkey" PRIMARY KEY (id);


--
-- Name: EnrollmentCoC_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "EnrollmentCoC"
    ADD CONSTRAINT "EnrollmentCoC_pkey" PRIMARY KEY (id);


--
-- Name: Enrollment_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Enrollment"
    ADD CONSTRAINT "Enrollment_pkey" PRIMARY KEY (id);


--
-- Name: Exit_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Exit"
    ADD CONSTRAINT "Exit_pkey" PRIMARY KEY (id);


--
-- Name: Export_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Export"
    ADD CONSTRAINT "Export_pkey" PRIMARY KEY (id);


--
-- Name: Funder_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Funder"
    ADD CONSTRAINT "Funder_pkey" PRIMARY KEY (id);


--
-- Name: HealthAndDV_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "HealthAndDV"
    ADD CONSTRAINT "HealthAndDV_pkey" PRIMARY KEY (id);


--
-- Name: IncomeBenefits_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "IncomeBenefits"
    ADD CONSTRAINT "IncomeBenefits_pkey" PRIMARY KEY (id);


--
-- Name: Inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Inventory"
    ADD CONSTRAINT "Inventory_pkey" PRIMARY KEY (id);


--
-- Name: Organization_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Organization"
    ADD CONSTRAINT "Organization_pkey" PRIMARY KEY (id);


--
-- Name: ProjectCoC_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "ProjectCoC"
    ADD CONSTRAINT "ProjectCoC_pkey" PRIMARY KEY (id);


--
-- Name: Project_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Project"
    ADD CONSTRAINT "Project_pkey" PRIMARY KEY (id);


--
-- Name: Services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Services"
    ADD CONSTRAINT "Services_pkey" PRIMARY KEY (id);


--
-- Name: Site_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Site"
    ADD CONSTRAINT "Site_pkey" PRIMARY KEY (id);


--
-- Name: api_client_data_source_ids_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY api_client_data_source_ids
    ADD CONSTRAINT api_client_data_source_ids_pkey PRIMARY KEY (id);


--
-- Name: cas_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cas_reports
    ADD CONSTRAINT cas_reports_pkey PRIMARY KEY (id);


--
-- Name: census_by_project_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY census_by_project_types
    ADD CONSTRAINT census_by_project_types_pkey PRIMARY KEY (id);


--
-- Name: censuses_averaged_by_year_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY censuses_averaged_by_year
    ADD CONSTRAINT censuses_averaged_by_year_pkey PRIMARY KEY (id);


--
-- Name: censuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY censuses
    ADD CONSTRAINT censuses_pkey PRIMARY KEY (id);


--
-- Name: chronics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY chronics
    ADD CONSTRAINT chronics_pkey PRIMARY KEY (id);


--
-- Name: client_matches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY client_matches
    ADD CONSTRAINT client_matches_pkey PRIMARY KEY (id);


--
-- Name: client_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY client_notes
    ADD CONSTRAINT client_notes_pkey PRIMARY KEY (id);


--
-- Name: contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: data_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY data_sources
    ADD CONSTRAINT data_sources_pkey PRIMARY KEY (id);


--
-- Name: fake_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY fake_data
    ADD CONSTRAINT fake_data_pkey PRIMARY KEY (id);


--
-- Name: generate_service_history_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY generate_service_history_log
    ADD CONSTRAINT generate_service_history_log_pkey PRIMARY KEY (id);


--
-- Name: hmis_assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY hmis_assessments
    ADD CONSTRAINT hmis_assessments_pkey PRIMARY KEY (id);


--
-- Name: hmis_client_attributes_defined_text_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY hmis_client_attributes_defined_text
    ADD CONSTRAINT hmis_client_attributes_defined_text_pkey PRIMARY KEY (id);


--
-- Name: hmis_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY hmis_clients
    ADD CONSTRAINT hmis_clients_pkey PRIMARY KEY (id);


--
-- Name: hmis_forms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY hmis_forms
    ADD CONSTRAINT hmis_forms_pkey PRIMARY KEY (id);


--
-- Name: hmis_staff_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY hmis_staff
    ADD CONSTRAINT hmis_staff_pkey PRIMARY KEY (id);


--
-- Name: hmis_staff_x_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY hmis_staff_x_clients
    ADD CONSTRAINT hmis_staff_x_clients_pkey PRIMARY KEY (id);


--
-- Name: identify_duplicates_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY identify_duplicates_log
    ADD CONSTRAINT identify_duplicates_log_pkey PRIMARY KEY (id);


--
-- Name: import_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY import_logs
    ADD CONSTRAINT import_logs_pkey PRIMARY KEY (id);


--
-- Name: project_data_quality_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_data_quality
    ADD CONSTRAINT project_data_quality_pkey PRIMARY KEY (id);


--
-- Name: project_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_groups
    ADD CONSTRAINT project_groups_pkey PRIMARY KEY (id);


--
-- Name: project_project_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_project_groups
    ADD CONSTRAINT project_project_groups_pkey PRIMARY KEY (id);


--
-- Name: report_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY report_tokens
    ADD CONSTRAINT report_tokens_pkey PRIMARY KEY (id);


--
-- Name: uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY uploads
    ADD CONSTRAINT uploads_pkey PRIMARY KEY (id);


--
-- Name: user_viewable_entities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_viewable_entities
    ADD CONSTRAINT user_viewable_entities_pkey PRIMARY KEY (id);


--
-- Name: warehouse_client_service_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY warehouse_client_service_history
    ADD CONSTRAINT warehouse_client_service_history_pkey PRIMARY KEY (id);


--
-- Name: warehouse_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY warehouse_clients
    ADD CONSTRAINT warehouse_clients_pkey PRIMARY KEY (id);


--
-- Name: warehouse_clients_processed_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY warehouse_clients_processed
    ADD CONSTRAINT warehouse_clients_processed_pkey PRIMARY KEY (id);


--
-- Name: weather_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY weather
    ADD CONSTRAINT weather_pkey PRIMARY KEY (id);


--
-- Name: affiliation_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX affiliation_date_created ON "Affiliation" USING btree ("DateCreated");


--
-- Name: affiliation_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX affiliation_date_updated ON "Affiliation" USING btree ("DateUpdated");


--
-- Name: affiliation_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX affiliation_export_id ON "Affiliation" USING btree ("ExportID");


--
-- Name: client_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_date_created ON "Client" USING btree ("DateCreated");


--
-- Name: client_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_date_updated ON "Client" USING btree ("DateUpdated");


--
-- Name: client_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_export_id ON "Client" USING btree ("ExportID");


--
-- Name: client_first_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_first_name ON "Client" USING btree ("FirstName");


--
-- Name: client_last_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_last_name ON "Client" USING btree ("LastName");


--
-- Name: client_personal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_personal_id ON "Client" USING btree ("PersonalID");


--
-- Name: disabilities_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX disabilities_date_created ON "Disabilities" USING btree ("DateCreated");


--
-- Name: disabilities_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX disabilities_date_updated ON "Disabilities" USING btree ("DateUpdated");


--
-- Name: disabilities_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX disabilities_export_id ON "Disabilities" USING btree ("ExportID");


--
-- Name: employment_education_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX employment_education_date_created ON "EmploymentEducation" USING btree ("DateCreated");


--
-- Name: employment_education_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX employment_education_date_updated ON "EmploymentEducation" USING btree ("DateUpdated");


--
-- Name: employment_education_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX employment_education_export_id ON "EmploymentEducation" USING btree ("ExportID");


--
-- Name: enrollment_coc_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enrollment_coc_date_created ON "EnrollmentCoC" USING btree ("DateCreated");


--
-- Name: enrollment_coc_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enrollment_coc_date_updated ON "EnrollmentCoC" USING btree ("DateUpdated");


--
-- Name: enrollment_coc_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enrollment_coc_export_id ON "EnrollmentCoC" USING btree ("ExportID");


--
-- Name: enrollment_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enrollment_date_created ON "Enrollment" USING btree ("DateCreated");


--
-- Name: enrollment_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enrollment_date_updated ON "Enrollment" USING btree ("DateUpdated");


--
-- Name: enrollment_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enrollment_export_id ON "Enrollment" USING btree ("ExportID");


--
-- Name: exit_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX exit_date_created ON "Exit" USING btree ("DateCreated");


--
-- Name: exit_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX exit_date_updated ON "Exit" USING btree ("DateUpdated");


--
-- Name: exit_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX exit_export_id ON "Exit" USING btree ("ExportID");


--
-- Name: export_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX export_export_id ON "Export" USING btree ("ExportID");


--
-- Name: funder_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX funder_date_created ON "Funder" USING btree ("DateCreated");


--
-- Name: funder_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX funder_date_updated ON "Funder" USING btree ("DateUpdated");


--
-- Name: funder_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX funder_export_id ON "Funder" USING btree ("ExportID");


--
-- Name: health_and_dv_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX health_and_dv_date_created ON "HealthAndDV" USING btree ("DateCreated");


--
-- Name: health_and_dv_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX health_and_dv_date_updated ON "HealthAndDV" USING btree ("DateUpdated");


--
-- Name: health_and_dv_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX health_and_dv_export_id ON "HealthAndDV" USING btree ("ExportID");


--
-- Name: income_benefits_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX income_benefits_date_created ON "IncomeBenefits" USING btree ("DateCreated");


--
-- Name: income_benefits_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX income_benefits_date_updated ON "IncomeBenefits" USING btree ("DateUpdated");


--
-- Name: income_benefits_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX income_benefits_export_id ON "IncomeBenefits" USING btree ("ExportID");


--
-- Name: index_Affiliation_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Affiliation_on_data_source_id" ON "Affiliation" USING btree (data_source_id);


--
-- Name: index_Client_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Client_on_data_source_id" ON "Client" USING btree (data_source_id);


--
-- Name: index_Disabilities_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Disabilities_on_PersonalID" ON "Disabilities" USING btree ("PersonalID");


--
-- Name: index_Disabilities_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Disabilities_on_data_source_id" ON "Disabilities" USING btree (data_source_id);


--
-- Name: index_Disabilities_on_data_source_id_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Disabilities_on_data_source_id_PersonalID" ON "Disabilities" USING btree (data_source_id, "PersonalID");


--
-- Name: index_EmploymentEducation_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EmploymentEducation_on_PersonalID" ON "EmploymentEducation" USING btree ("PersonalID");


--
-- Name: index_EmploymentEducation_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EmploymentEducation_on_data_source_id" ON "EmploymentEducation" USING btree (data_source_id);


--
-- Name: index_EmploymentEducation_on_data_source_id_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EmploymentEducation_on_data_source_id_PersonalID" ON "EmploymentEducation" USING btree (data_source_id, "PersonalID");


--
-- Name: index_EnrollmentCoC_on_EnrollmentCoCID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EnrollmentCoC_on_EnrollmentCoCID" ON "EnrollmentCoC" USING btree ("EnrollmentCoCID");


--
-- Name: index_EnrollmentCoC_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EnrollmentCoC_on_data_source_id" ON "EnrollmentCoC" USING btree (data_source_id);


--
-- Name: index_EnrollmentCoC_on_data_source_id_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EnrollmentCoC_on_data_source_id_PersonalID" ON "EnrollmentCoC" USING btree (data_source_id, "PersonalID");


--
-- Name: index_Enrollment_on_DateDeleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_DateDeleted" ON "Enrollment" USING btree ("DateDeleted");


--
-- Name: index_Enrollment_on_EntryDate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_EntryDate" ON "Enrollment" USING btree ("EntryDate");


--
-- Name: index_Enrollment_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_PersonalID" ON "Enrollment" USING btree ("PersonalID");


--
-- Name: index_Enrollment_on_ProjectEntryID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_ProjectEntryID" ON "Enrollment" USING btree ("ProjectEntryID");


--
-- Name: index_Enrollment_on_ProjectID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_ProjectID" ON "Enrollment" USING btree ("ProjectID");


--
-- Name: index_Enrollment_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_data_source_id" ON "Enrollment" USING btree (data_source_id);


--
-- Name: index_Enrollment_on_data_source_id_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_data_source_id_PersonalID" ON "Enrollment" USING btree (data_source_id, "PersonalID");


--
-- Name: index_Exit_on_DateDeleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_DateDeleted" ON "Exit" USING btree ("DateDeleted");


--
-- Name: index_Exit_on_ExitDate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_ExitDate" ON "Exit" USING btree ("ExitDate");


--
-- Name: index_Exit_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_PersonalID" ON "Exit" USING btree ("PersonalID");


--
-- Name: index_Exit_on_ProjectEntryID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_ProjectEntryID" ON "Exit" USING btree ("ProjectEntryID");


--
-- Name: index_Exit_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_data_source_id" ON "Exit" USING btree (data_source_id);


--
-- Name: index_Exit_on_data_source_id_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_data_source_id_PersonalID" ON "Exit" USING btree (data_source_id, "PersonalID");


--
-- Name: index_Export_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Export_on_data_source_id" ON "Export" USING btree (data_source_id);


--
-- Name: index_Funder_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Funder_on_data_source_id" ON "Funder" USING btree (data_source_id);


--
-- Name: index_HealthAndDV_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_HealthAndDV_on_PersonalID" ON "HealthAndDV" USING btree ("PersonalID");


--
-- Name: index_HealthAndDV_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_HealthAndDV_on_data_source_id" ON "HealthAndDV" USING btree (data_source_id);


--
-- Name: index_HealthAndDV_on_data_source_id_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_HealthAndDV_on_data_source_id_PersonalID" ON "HealthAndDV" USING btree (data_source_id, "PersonalID");


--
-- Name: index_IncomeBenefits_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_PersonalID" ON "IncomeBenefits" USING btree ("PersonalID");


--
-- Name: index_IncomeBenefits_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_data_source_id" ON "IncomeBenefits" USING btree (data_source_id);


--
-- Name: index_IncomeBenefits_on_data_source_id_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_data_source_id_PersonalID" ON "IncomeBenefits" USING btree (data_source_id, "PersonalID");


--
-- Name: index_Inventory_on_ProjectID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Inventory_on_ProjectID" ON "Inventory" USING btree ("ProjectID");


--
-- Name: index_Inventory_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Inventory_on_data_source_id" ON "Inventory" USING btree (data_source_id);


--
-- Name: index_Organization_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Organization_on_data_source_id" ON "Organization" USING btree (data_source_id);


--
-- Name: index_ProjectCoC_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_ProjectCoC_on_data_source_id" ON "ProjectCoC" USING btree (data_source_id);


--
-- Name: index_Project_on_ProjectID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Project_on_ProjectID" ON "Project" USING btree ("ProjectID");


--
-- Name: index_Project_on_ProjectType; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Project_on_ProjectType" ON "Project" USING btree ("ProjectType");


--
-- Name: index_Project_on_computed_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Project_on_computed_project_type" ON "Project" USING btree (computed_project_type);


--
-- Name: index_Project_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Project_on_data_source_id" ON "Project" USING btree (data_source_id);


--
-- Name: index_Services_on_DateDeleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Services_on_DateDeleted" ON "Services" USING btree ("DateDeleted");


--
-- Name: index_Services_on_DateProvided; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Services_on_DateProvided" ON "Services" USING btree ("DateProvided");


--
-- Name: index_Services_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Services_on_PersonalID" ON "Services" USING btree ("PersonalID");


--
-- Name: index_Services_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Services_on_data_source_id" ON "Services" USING btree (data_source_id);


--
-- Name: index_Site_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Site_on_data_source_id" ON "Site" USING btree (data_source_id);


--
-- Name: index_api_client_data_source_ids_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_api_client_data_source_ids_on_client_id ON api_client_data_source_ids USING btree (client_id);


--
-- Name: index_api_client_data_source_ids_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_api_client_data_source_ids_on_data_source_id ON api_client_data_source_ids USING btree (data_source_id);


--
-- Name: index_api_client_data_source_ids_on_warehouse_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_api_client_data_source_ids_on_warehouse_id ON api_client_data_source_ids USING btree (warehouse_id);


--
-- Name: index_cas_reports_on_client_id_and_match_id_and_decision_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cas_reports_on_client_id_and_match_id_and_decision_id ON cas_reports USING btree (client_id, match_id, decision_id);


--
-- Name: index_censuses_ave_year_ds_id_proj_type_org_id_proj_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_censuses_ave_year_ds_id_proj_type_org_id_proj_id ON censuses_averaged_by_year USING btree (year, data_source_id, "ProjectType", "OrganizationID", "ProjectID");


--
-- Name: index_censuses_ds_id_proj_type_org_id_proj_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_censuses_ds_id_proj_type_org_id_proj_id ON censuses USING btree (data_source_id, "ProjectType", "OrganizationID", "ProjectID");


--
-- Name: index_censuses_on_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_censuses_on_date ON censuses USING btree (date);


--
-- Name: index_censuses_on_date_and_ProjectType; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_censuses_on_date_and_ProjectType" ON censuses USING btree (date, "ProjectType");


--
-- Name: index_chronics_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chronics_on_client_id ON chronics USING btree (client_id);


--
-- Name: index_chronics_on_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chronics_on_date ON chronics USING btree (date);


--
-- Name: index_client_matches_on_destination_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_matches_on_destination_client_id ON client_matches USING btree (destination_client_id);


--
-- Name: index_client_matches_on_source_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_matches_on_source_client_id ON client_matches USING btree (source_client_id);


--
-- Name: index_client_matches_on_updated_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_matches_on_updated_by_id ON client_matches USING btree (updated_by_id);


--
-- Name: index_client_notes_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_notes_on_client_id ON client_notes USING btree (client_id);


--
-- Name: index_client_notes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_notes_on_user_id ON client_notes USING btree (user_id);


--
-- Name: index_contacts_on_entity_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_entity_id ON contacts USING btree (entity_id);


--
-- Name: index_contacts_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_type ON contacts USING btree (type);


--
-- Name: index_hmis_assessments_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_assessments_on_assessment_id ON hmis_assessments USING btree (assessment_id);


--
-- Name: index_hmis_assessments_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_assessments_on_data_source_id ON hmis_assessments USING btree (data_source_id);


--
-- Name: index_hmis_assessments_on_site_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_assessments_on_site_id ON hmis_assessments USING btree (site_id);


--
-- Name: index_hmis_client_attributes_defined_text_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_client_attributes_defined_text_on_client_id ON hmis_client_attributes_defined_text USING btree (client_id);


--
-- Name: index_hmis_client_attributes_defined_text_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_client_attributes_defined_text_on_data_source_id ON hmis_client_attributes_defined_text USING btree (data_source_id);


--
-- Name: index_hmis_clients_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_clients_on_client_id ON hmis_clients USING btree (client_id);


--
-- Name: index_hmis_forms_on_assessment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_forms_on_assessment_id ON hmis_forms USING btree (assessment_id);


--
-- Name: index_hmis_forms_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hmis_forms_on_client_id ON hmis_forms USING btree (client_id);


--
-- Name: index_import_logs_on_completed_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_import_logs_on_completed_at ON import_logs USING btree (completed_at);


--
-- Name: index_import_logs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_import_logs_on_created_at ON import_logs USING btree (created_at);


--
-- Name: index_import_logs_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_import_logs_on_data_source_id ON import_logs USING btree (data_source_id);


--
-- Name: index_import_logs_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_import_logs_on_updated_at ON import_logs USING btree (updated_at);


--
-- Name: index_project_data_quality_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_data_quality_on_project_id ON project_data_quality USING btree (project_id);


--
-- Name: index_report_tokens_on_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_tokens_on_contact_id ON report_tokens USING btree (contact_id);


--
-- Name: index_report_tokens_on_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_tokens_on_report_id ON report_tokens USING btree (report_id);


--
-- Name: index_service_history_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_history_on_client_id ON warehouse_client_service_history USING btree (client_id);


--
-- Name: index_services_ds_id_p_id_type_entry_id_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_services_ds_id_p_id_type_entry_id_date ON "Services" USING btree (data_source_id, "PersonalID", "RecordType", "ProjectEntryID", "DateProvided");


--
-- Name: index_sh_ds_id_org_id_proj_id_r_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sh_ds_id_org_id_proj_id_r_type ON warehouse_client_service_history USING btree (data_source_id, organization_id, project_id, record_type);


--
-- Name: index_sh_tracking_method; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sh_tracking_method ON warehouse_client_service_history USING btree (project_tracking_method);


--
-- Name: index_staff_x_client_s_id_c_id_r_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_staff_x_client_s_id_c_id_r_id ON hmis_staff_x_clients USING btree (staff_id, client_id, relationship_id);


--
-- Name: index_uploads_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_uploads_on_deleted_at ON uploads USING btree (deleted_at);


--
-- Name: index_warehouse_client_service_history_on_computed_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_computed_project_type ON warehouse_client_service_history USING btree (computed_project_type);


--
-- Name: index_warehouse_client_service_history_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_data_source_id ON warehouse_client_service_history USING btree (data_source_id);


--
-- Name: index_warehouse_client_service_history_on_enrollment_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_enrollment_group_id ON warehouse_client_service_history USING btree (enrollment_group_id);


--
-- Name: index_warehouse_client_service_history_on_first_date_in_program; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_first_date_in_program ON warehouse_client_service_history USING btree (first_date_in_program);


--
-- Name: index_warehouse_client_service_history_on_household_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_household_id ON warehouse_client_service_history USING btree (household_id);


--
-- Name: index_warehouse_client_service_history_on_last_date_in_program; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_last_date_in_program ON warehouse_client_service_history USING btree (last_date_in_program);


--
-- Name: index_warehouse_client_service_history_on_project_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_project_type ON warehouse_client_service_history USING btree (project_type);


--
-- Name: index_warehouse_client_service_history_on_record_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_record_type ON warehouse_client_service_history USING btree (record_type);


--
-- Name: index_warehouse_clients_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_clients_on_deleted_at ON warehouse_clients USING btree (deleted_at);


--
-- Name: index_warehouse_clients_on_destination_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_clients_on_destination_id ON warehouse_clients USING btree (destination_id);


--
-- Name: index_warehouse_clients_on_id_in_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_clients_on_id_in_source ON warehouse_clients USING btree (id_in_source);


--
-- Name: index_warehouse_clients_on_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_warehouse_clients_on_source_id ON warehouse_clients USING btree (source_id);


--
-- Name: index_warehouse_clients_processed_on_routine; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_clients_processed_on_routine ON warehouse_clients_processed USING btree (routine);


--
-- Name: index_weather_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_weather_on_url ON weather USING btree (url);


--
-- Name: inventory_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inventory_date_created ON "Inventory" USING btree ("DateCreated");


--
-- Name: inventory_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inventory_date_updated ON "Inventory" USING btree ("DateUpdated");


--
-- Name: inventory_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inventory_export_id ON "Inventory" USING btree ("ExportID");


--
-- Name: one_entity_per_type_per_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX one_entity_per_type_per_user ON user_viewable_entities USING btree (user_id, entity_id, entity_type);


--
-- Name: organization_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX organization_export_id ON "Organization" USING btree ("ExportID");


--
-- Name: project_coc_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_coc_date_created ON "ProjectCoC" USING btree ("DateCreated");


--
-- Name: project_coc_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_coc_date_updated ON "ProjectCoC" USING btree ("DateUpdated");


--
-- Name: project_coc_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_coc_export_id ON "ProjectCoC" USING btree ("ExportID");


--
-- Name: project_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_date_created ON "Project" USING btree ("DateCreated");


--
-- Name: project_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_date_updated ON "Project" USING btree ("DateUpdated");


--
-- Name: project_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_export_id ON "Project" USING btree ("ExportID");


--
-- Name: project_project_override_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX project_project_override_index ON "Project" USING btree ((COALESCE(act_as_project_type, "ProjectType")));


--
-- Name: services_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX services_date_created ON "Services" USING btree ("DateCreated");


--
-- Name: services_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX services_date_updated ON "Services" USING btree ("DateUpdated");


--
-- Name: services_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX services_export_id ON "Services" USING btree ("ExportID");


--
-- Name: sh_date_ds_id_org_id_proj_id_proj_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sh_date_ds_id_org_id_proj_id_proj_type ON warehouse_client_service_history USING btree (date, data_source_id, organization_id, project_id, project_type);


--
-- Name: site_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX site_date_created ON "Site" USING btree ("DateCreated");


--
-- Name: site_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX site_date_updated ON "Site" USING btree ("DateUpdated");


--
-- Name: site_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX site_export_id ON "Site" USING btree ("ExportID");


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: unk_Affiliation; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Affiliation" ON "Affiliation" USING btree (data_source_id, "AffiliationID");


--
-- Name: unk_Disabilities; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Disabilities" ON "Disabilities" USING btree (data_source_id, "DisabilitiesID");


--
-- Name: unk_EmploymentEducation; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_EmploymentEducation" ON "EmploymentEducation" USING btree (data_source_id, "EmploymentEducationID");


--
-- Name: unk_Enrollment; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Enrollment" ON "Enrollment" USING btree (data_source_id, "ProjectEntryID");


--
-- Name: unk_Exit; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Exit" ON "Exit" USING btree (data_source_id, "ExitID");


--
-- Name: unk_Export; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Export" ON "Export" USING btree (data_source_id, "ExportID");


--
-- Name: unk_Funder; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Funder" ON "Funder" USING btree (data_source_id, "FunderID");


--
-- Name: unk_HealthAndDV; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_HealthAndDV" ON "HealthAndDV" USING btree (data_source_id, "HealthAndDVID");


--
-- Name: unk_IncomeBenefits; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_IncomeBenefits" ON "IncomeBenefits" USING btree (data_source_id, "IncomeBenefitsID");


--
-- Name: unk_Inventory; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Inventory" ON "Inventory" USING btree (data_source_id, "InventoryID");


--
-- Name: unk_Organization; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Organization" ON "Organization" USING btree (data_source_id, "OrganizationID");


--
-- Name: unk_Project; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Project" ON "Project" USING btree (data_source_id, "ProjectID");


--
-- Name: unk_ProjectCoC; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_ProjectCoC" ON "ProjectCoC" USING btree (data_source_id, "ProjectCoCID");


--
-- Name: unk_Services; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Services" ON "Services" USING btree (data_source_id, "ServicesID");


--
-- Name: unk_Site; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "unk_Site" ON "Site" USING btree (data_source_id, "SiteID");


--
-- Name: fk_rails_09dc8ad251; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "HealthAndDV"
    ADD CONSTRAINT fk_rails_09dc8ad251 FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_10c0c54102; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "EnrollmentCoC"
    ADD CONSTRAINT fk_rails_10c0c54102 FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_20932f9907; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY warehouse_clients_processed
    ADD CONSTRAINT fk_rails_20932f9907 FOREIGN KEY (client_id) REFERENCES "Client"(id);


--
-- Name: fk_rails_2338303c55; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Exit"
    ADD CONSTRAINT fk_rails_2338303c55 FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_24e267b7b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Enrollment"
    ADD CONSTRAINT fk_rails_24e267b7b6 FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_3675320ed1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Organization"
    ADD CONSTRAINT fk_rails_3675320ed1 FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_4f7ec0cedf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Client"
    ADD CONSTRAINT fk_rails_4f7ec0cedf FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_5890c7efe3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Inventory"
    ADD CONSTRAINT fk_rails_5890c7efe3 FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_5f845fa144; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY warehouse_clients
    ADD CONSTRAINT fk_rails_5f845fa144 FOREIGN KEY (destination_id) REFERENCES "Client"(id);


--
-- Name: fk_rails_78558d1502; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Project"
    ADD CONSTRAINT fk_rails_78558d1502 FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_81babe0602; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Affiliation"
    ADD CONSTRAINT fk_rails_81babe0602 FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_8625e4a1e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "ProjectCoC"
    ADD CONSTRAINT fk_rails_8625e4a1e0 FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_866e73470f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Disabilities"
    ADD CONSTRAINT fk_rails_866e73470f FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_9ed8af19a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Services"
    ADD CONSTRAINT fk_rails_9ed8af19a8 FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_c59e9106a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY warehouse_clients
    ADD CONSTRAINT fk_rails_c59e9106a8 FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_c7677f1ea0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "EmploymentEducation"
    ADD CONSTRAINT fk_rails_c7677f1ea0 FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_c78f6db1f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Site"
    ADD CONSTRAINT fk_rails_c78f6db1f0 FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_db9104e0c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY warehouse_clients
    ADD CONSTRAINT fk_rails_db9104e0c0 FOREIGN KEY (source_id) REFERENCES "Client"(id);


--
-- Name: fk_rails_e0715eab03; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "IncomeBenefits"
    ADD CONSTRAINT fk_rails_e0715eab03 FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_ee7363191f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY "Funder"
    ADD CONSTRAINT fk_rails_ee7363191f FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


--
-- Name: fk_rails_fbb77b1f46; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY import_logs
    ADD CONSTRAINT fk_rails_fbb77b1f46 FOREIGN KEY (data_source_id) REFERENCES data_sources(id);


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

