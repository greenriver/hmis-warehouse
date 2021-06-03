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
-- Name: record_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.record_type AS ENUM (
    'first',
    'entry',
    'exit',
    'service',
    'extrapolated'
);


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
    id integer NOT NULL
);


--
-- Name: Affiliation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Affiliation_id_seq"
    AS integer
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
    consent_form_signed_on date
);


--
-- Name: Client_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Client_id_seq"
    AS integer
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

CREATE SEQUENCE public."Disabilities_id_seq"
    AS integer
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

CREATE SEQUENCE public."EmploymentEducation_id_seq"
    AS integer
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
    processed_hash character varying
);


--
-- Name: EnrollmentCoC; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."EnrollmentCoC" (
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

CREATE SEQUENCE public."EnrollmentCoC_id_seq"
    AS integer
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
    AS integer
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
    "CMExitReason" integer
);


--
-- Name: Exit_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Exit_id_seq"
    AS integer
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
    effective_export_end_date date
);


--
-- Name: Export_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Export_id_seq"
    AS integer
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
    id integer NOT NULL
);


--
-- Name: Funder_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Funder_id_seq"
    AS integer
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
-- Name: HealthAndDV; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."HealthAndDV" (
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

CREATE SEQUENCE public."HealthAndDV_id_seq"
    AS integer
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

CREATE SEQUENCE public."IncomeBenefits_id_seq"
    AS integer
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
    id integer NOT NULL
);


--
-- Name: Inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Inventory_id_seq"
    AS integer
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
    dmh boolean DEFAULT false NOT NULL
);


--
-- Name: Organization_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Organization_id_seq"
    AS integer
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
    "HousingType" integer
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
    hud_coc_code character varying
);


--
-- Name: ProjectCoC_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."ProjectCoC_id_seq"
    AS integer
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
    AS integer
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

CREATE SEQUENCE public."Services_id_seq"
    AS integer
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
-- Name: Site; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."Site" (
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
    id integer NOT NULL,
    "InformationDate" date,
    "Address2" character varying,
    "GeographyType" integer
);


--
-- Name: Site_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public."Site_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: Site_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public."Site_id_seq" OWNED BY public."Site".id;


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
    AS integer
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
    last_contact date
);


--
-- Name: api_client_data_source_ids_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_client_data_source_ids_id_seq
    AS integer
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
    hsp_contacts json
);


--
-- Name: cas_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cas_reports_id_seq
    AS integer
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
    AS integer
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
    AS integer
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
    AS integer
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
    AS integer
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
    AS integer
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
    AS integer
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
    migrated_username character varying
);


--
-- Name: client_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_notes_id_seq
    AS integer
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
    AS integer
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
    housing_track character varying,
    va_eligible date,
    vash_eligible character varying,
    chapter_115 character varying
);


--
-- Name: cohort_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cohort_clients_id_seq
    AS integer
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
-- Name: cohorts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cohorts (
    id integer NOT NULL,
    name character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    deleted_at timestamp without time zone,
    effective_date date,
    column_state text
);


--
-- Name: cohorts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cohorts_id_seq
    AS integer
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
    ahar_psh_includes_rrh boolean DEFAULT true
);


--
-- Name: configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configs_id_seq
    AS integer
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
    AS integer
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
    AS integer
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
    authoritative boolean DEFAULT false
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
    project_ids json,
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
    AS integer
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
    AS integer
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
    consent_form_confirmed boolean
);


--
-- Name: files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.files_id_seq
    AS integer
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
    AS integer
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
    AS integer
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
    AS integer
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
    exclude_from_window boolean DEFAULT false NOT NULL
);


--
-- Name: hmis_assessments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_assessments_id_seq
    AS integer
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
    AS integer
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
    subject_id integer
);


--
-- Name: hmis_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_clients_id_seq
    AS integer
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
    assessment_id integer,
    data_source_id integer NOT NULL,
    site_id integer
);


--
-- Name: hmis_forms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.hmis_forms_id_seq
    AS integer
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
    AS integer
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
    AS integer
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
    AS integer
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
    AS integer
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
    AS integer
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
    AS integer
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
    support json
);


--
-- Name: project_data_quality_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_data_quality_id_seq
    AS integer
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
    AS integer
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
    AS integer
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
-- Name: report_definitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_definitions (
    id integer NOT NULL,
    report_group character varying,
    url text,
    name text,
    description text
);


--
-- Name: report_definitions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.report_definitions_id_seq
    AS integer
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
    AS integer
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
    delayed_job_id integer
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
    AS integer
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
    entity_type character varying NOT NULL,
    entity_id integer NOT NULL
);


--
-- Name: user_viewable_entities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_viewable_entities_id_seq
    AS integer
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
    AS integer
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
    household_id character varying,
    project_id character varying,
    project_name character varying,
    project_type integer,
    project_tracking_method integer,
    organization_id character varying,
    record_type character varying NOT NULL,
    housing_status_at_entry integer,
    housing_status_at_exit integer,
    service_type integer,
    computed_project_type integer,
    presented_as_individual boolean
);


--
-- Name: warehouse_client_service_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_client_service_history_id_seq
    AS integer
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
-- Name: warehouse_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_clients_id_seq
    AS integer
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
    last_date_served date
);


--
-- Name: warehouse_clients_processed_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_clients_processed_id_seq
    AS integer
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
    client_count integer
);


--
-- Name: warehouse_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.warehouse_reports_id_seq
    AS integer
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
    AS integer
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
-- Name: Site id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Site" ALTER COLUMN id SET DEFAULT nextval('public."Site_id_seq"'::regclass);


--
-- Name: anomalies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.anomalies ALTER COLUMN id SET DEFAULT nextval('public.anomalies_id_seq'::regclass);


--
-- Name: api_client_data_source_ids id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_client_data_source_ids ALTER COLUMN id SET DEFAULT nextval('public.api_client_data_source_ids_id_seq'::regclass);


--
-- Name: cas_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_reports ALTER COLUMN id SET DEFAULT nextval('public.cas_reports_id_seq'::regclass);


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
-- Name: client_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_notes ALTER COLUMN id SET DEFAULT nextval('public.client_notes_id_seq'::regclass);


--
-- Name: cohort_client_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cohort_client_notes ALTER COLUMN id SET DEFAULT nextval('public.cohort_client_notes_id_seq'::regclass);


--
-- Name: cohort_clients id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cohort_clients ALTER COLUMN id SET DEFAULT nextval('public.cohort_clients_id_seq'::regclass);


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
-- Name: data_monitorings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_monitorings ALTER COLUMN id SET DEFAULT nextval('public.data_monitorings_id_seq'::regclass);


--
-- Name: data_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.data_sources ALTER COLUMN id SET DEFAULT nextval('public.data_sources_id_seq'::regclass);


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
-- Name: report_definitions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_definitions ALTER COLUMN id SET DEFAULT nextval('public.report_definitions_id_seq'::regclass);


--
-- Name: report_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_tokens ALTER COLUMN id SET DEFAULT nextval('public.report_tokens_id_seq'::regclass);


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
-- Name: Site Site_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Site"
    ADD CONSTRAINT "Site_pkey" PRIMARY KEY (id);


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
-- Name: cas_reports cas_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cas_reports
    ADD CONSTRAINT cas_reports_pkey PRIMARY KEY (id);


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
-- Name: client_notes client_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_notes
    ADD CONSTRAINT client_notes_pkey PRIMARY KEY (id);


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
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


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
-- Name: client_last_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_last_name ON public."Client" USING btree ("LastName");


--
-- Name: client_personal_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX client_personal_id ON public."Client" USING btree ("PersonalID");


--
-- Name: disabilities_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX disabilities_date_created ON public."Disabilities" USING btree ("DateCreated");


--
-- Name: disabilities_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX disabilities_date_updated ON public."Disabilities" USING btree ("DateUpdated");


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
-- Name: index_Client_on_data_source_id_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Client_on_data_source_id_PersonalID" ON public."Client" USING btree (data_source_id, "PersonalID");


--
-- Name: index_Disabilities_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Disabilities_on_PersonalID" ON public."Disabilities" USING btree ("PersonalID");


--
-- Name: index_Disabilities_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Disabilities_on_data_source_id" ON public."Disabilities" USING btree (data_source_id);


--
-- Name: index_EmploymentEducation_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EmploymentEducation_on_PersonalID" ON public."EmploymentEducation" USING btree ("PersonalID");


--
-- Name: index_EmploymentEducation_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EmploymentEducation_on_data_source_id" ON public."EmploymentEducation" USING btree (data_source_id);


--
-- Name: index_EnrollmentCoC_on_EnrollmentCoCID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EnrollmentCoC_on_EnrollmentCoCID" ON public."EnrollmentCoC" USING btree ("EnrollmentCoCID");


--
-- Name: index_EnrollmentCoC_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_EnrollmentCoC_on_data_source_id" ON public."EnrollmentCoC" USING btree (data_source_id);


--
-- Name: index_Enrollment_on_DateDeleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_DateDeleted" ON public."Enrollment" USING btree ("DateDeleted");


--
-- Name: index_Enrollment_on_EntryDate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_EntryDate" ON public."Enrollment" USING btree ("EntryDate");


--
-- Name: index_Enrollment_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_PersonalID" ON public."Enrollment" USING btree ("PersonalID");


--
-- Name: index_Enrollment_on_ProjectEntryID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_ProjectEntryID" ON public."Enrollment" USING btree ("ProjectEntryID");


--
-- Name: index_Enrollment_on_ProjectID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_ProjectID" ON public."Enrollment" USING btree ("ProjectID");


--
-- Name: index_Enrollment_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Enrollment_on_data_source_id" ON public."Enrollment" USING btree (data_source_id);


--
-- Name: index_Exit_on_DateDeleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_DateDeleted" ON public."Exit" USING btree ("DateDeleted");


--
-- Name: index_Exit_on_ExitDate; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_ExitDate" ON public."Exit" USING btree ("ExitDate");


--
-- Name: index_Exit_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_PersonalID" ON public."Exit" USING btree ("PersonalID");


--
-- Name: index_Exit_on_ProjectEntryID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_ProjectEntryID" ON public."Exit" USING btree ("ProjectEntryID");


--
-- Name: index_Exit_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Exit_on_data_source_id" ON public."Exit" USING btree (data_source_id);


--
-- Name: index_Export_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Export_on_data_source_id" ON public."Export" USING btree (data_source_id);


--
-- Name: index_Funder_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Funder_on_data_source_id" ON public."Funder" USING btree (data_source_id);


--
-- Name: index_HealthAndDV_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_HealthAndDV_on_PersonalID" ON public."HealthAndDV" USING btree ("PersonalID");


--
-- Name: index_HealthAndDV_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_HealthAndDV_on_data_source_id" ON public."HealthAndDV" USING btree (data_source_id);


--
-- Name: index_IncomeBenefits_on_PersonalID; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_PersonalID" ON public."IncomeBenefits" USING btree ("PersonalID");


--
-- Name: index_IncomeBenefits_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_IncomeBenefits_on_data_source_id" ON public."IncomeBenefits" USING btree (data_source_id);


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
-- Name: index_Site_on_data_source_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "index_Site_on_data_source_id" ON public."Site" USING btree (data_source_id);


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
-- Name: index_cas_reports_on_client_id_and_match_id_and_decision_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_cas_reports_on_client_id_and_match_id_and_decision_id ON public.cas_reports USING btree (client_id, match_id, decision_id);


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
-- Name: index_client_notes_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_notes_on_client_id ON public.client_notes USING btree (client_id);


--
-- Name: index_client_notes_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_client_notes_on_user_id ON public.client_notes USING btree (user_id);


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
-- Name: index_hud_chronics_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_hud_chronics_on_client_id ON public.hud_chronics USING btree (client_id);


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
-- Name: index_proj_proj_id_org_id_ds_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_proj_proj_id_org_id_ds_id ON public."Project" USING btree ("ProjectID", data_source_id, "OrganizationID");


--
-- Name: index_project_data_quality_on_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_project_data_quality_on_project_id ON public.project_data_quality USING btree (project_id);


--
-- Name: index_report_tokens_on_contact_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_tokens_on_contact_id ON public.report_tokens USING btree (contact_id);


--
-- Name: index_report_tokens_on_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_tokens_on_report_id ON public.report_tokens USING btree (report_id);


--
-- Name: index_service_history_on_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_service_history_on_client_id ON public.warehouse_client_service_history USING btree (client_id);


--
-- Name: index_services_ds_id_p_id_type_entry_id_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_services_ds_id_p_id_type_entry_id_date ON public."Services" USING btree (data_source_id, "PersonalID", "RecordType", "ProjectEntryID", "DateProvided");


--
-- Name: index_sh__enrollment_id_track_meth; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sh__enrollment_id_track_meth ON public.new_service_history USING btree (enrollment_group_id, project_tracking_method);


--
-- Name: index_sh_date_ds_id_org_id_proj_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sh_date_ds_id_org_id_proj_id ON public.warehouse_client_service_history USING btree (date, data_source_id, organization_id, project_id);


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
-- Name: index_warehouse_client_service_history_on_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_date ON public.warehouse_client_service_history USING btree (date);


--
-- Name: index_warehouse_client_service_history_on_first_date_in_program; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_warehouse_client_service_history_on_first_date_in_program ON public.warehouse_client_service_history USING btree (first_date_in_program);


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
-- Name: one_entity_per_type_per_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX one_entity_per_type_per_user ON public.user_viewable_entities USING btree (user_id, entity_id, entity_type);


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

CREATE INDEX project_project_override_index ON public."Project" USING btree (COALESCE(act_as_project_type, "ProjectType"));


--
-- Name: service_history_date_desc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX service_history_date_desc ON public.warehouse_client_service_history USING btree (date DESC);


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
-- Name: site_date_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX site_date_created ON public."Site" USING btree ("DateCreated");


--
-- Name: site_date_updated; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX site_date_updated ON public."Site" USING btree ("DateUpdated");


--
-- Name: site_export_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX site_export_id ON public."Site" USING btree ("ExportID");


--
-- Name: taggings_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX taggings_idx ON public.taggings USING btree (tag_id, taggable_id, taggable_type, context, tagger_id, tagger_type);


--
-- Name: taggings_idy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX taggings_idy ON public.taggings USING btree (taggable_id, taggable_type, tagger_id, context);


--
-- Name: HealthAndDV fk_rails_09dc8ad251; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."HealthAndDV"
    ADD CONSTRAINT fk_rails_09dc8ad251 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: EnrollmentCoC fk_rails_10c0c54102; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."EnrollmentCoC"
    ADD CONSTRAINT fk_rails_10c0c54102 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: warehouse_clients_processed fk_rails_20932f9907; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_clients_processed
    ADD CONSTRAINT fk_rails_20932f9907 FOREIGN KEY (client_id) REFERENCES public."Client"(id);


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
-- Name: Organization fk_rails_3675320ed1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Organization"
    ADD CONSTRAINT fk_rails_3675320ed1 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: Client fk_rails_4f7ec0cedf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Client"
    ADD CONSTRAINT fk_rails_4f7ec0cedf FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: Inventory fk_rails_5890c7efe3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Inventory"
    ADD CONSTRAINT fk_rails_5890c7efe3 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: warehouse_clients fk_rails_5f845fa144; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_clients
    ADD CONSTRAINT fk_rails_5f845fa144 FOREIGN KEY (destination_id) REFERENCES public."Client"(id);


--
-- Name: Project fk_rails_78558d1502; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Project"
    ADD CONSTRAINT fk_rails_78558d1502 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: Affiliation fk_rails_81babe0602; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Affiliation"
    ADD CONSTRAINT fk_rails_81babe0602 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


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
-- Name: Services fk_rails_9ed8af19a8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Services"
    ADD CONSTRAINT fk_rails_9ed8af19a8 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


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
-- Name: Site fk_rails_c78f6db1f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."Site"
    ADD CONSTRAINT fk_rails_c78f6db1f0 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


--
-- Name: warehouse_clients fk_rails_db9104e0c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.warehouse_clients
    ADD CONSTRAINT fk_rails_db9104e0c0 FOREIGN KEY (source_id) REFERENCES public."Client"(id);


--
-- Name: IncomeBenefits fk_rails_e0715eab03; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."IncomeBenefits"
    ADD CONSTRAINT fk_rails_e0715eab03 FOREIGN KEY (data_source_id) REFERENCES public.data_sources(id);


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
('20160922162359'),
('20160922185930'),
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
('20161111200331'),
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
('20171204161239'),
('20171204180630'),
('20171205135225'),
('20171206131931'),
('20171208151137'),
('20171211131328'),
('20171211142747'),
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
('20200716132417'),
('20200718194102'),
('20200719235413'),
('20200721190101'),
('20200722194242'),
('20200722200713'),
('20200723144121'),
('20200723172609'),
('20200723204046'),
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
('20210601173704'),
('20210603143037');


