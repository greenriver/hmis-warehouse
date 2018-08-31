load 'lib/rds_sql_server/sql_server_base.rb'
SqlServerBase.connection.execute (<<~SQL);
  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_Affiliation' AND xtype='U')
    DROP TABLE [hmis_Affiliation]
    CREATE TABLE [hmis_Affiliation] (
      id int not null identity primary key,
      [AffiliationID] varchar(255),
      [ProjectID] varchar(255),
      [ResProjectID] varchar(255),
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(100),
      [DateDeleted] datetime,
      [ExportID] varchar(255)
    );

    create index affiliation_date_created ON [hmis_Affiliation] ([DateCreated]);
    create index affiliation_date_updated ON [hmis_Affiliation] ([DateUpdated]);
    create index affiliation_export_id ON [hmis_Affiliation] ([ExportID]);
    create unique index unk_Affiliation ON [hmis_Affiliation] ( [AffiliationID]);
  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_Client' AND xtype='U')
    DROP TABLE [hmis_Client]
    CREATE TABLE [hmis_Client] (
      id int not null identity primary key,
      [PersonalID] varchar(255),
      [FirstName] varchar(150),
      [MiddleName] varchar(150),
      [LastName] varchar(150),
      [NameSuffix] varchar(50),
      [NameDataQuality] int,
      [SSN] varchar(9),
      [SSNDataQuality] int,
      [DOB] date,
      [DOBDataQuality] int,
      [AmIndAKNative] int,
      [Asian] int,
      [BlackAfAmerican] int,
      [NativeHIOtherPacific] int,
      [White] int,
      [RaceNone] int,
      [Ethnicity] int,
      [Gender] int,
      [OtherGender] varchar(50),
      [VeteranStatus] int,
      [YearEnteredService] int,
      [YearSeparated] int,
      [WorldWarII] int,
      [KoreanWar] int,
      [VietnamWar] int,
      [DesertStorm] int,
      [AfghanistanOEF] int,
      [IraqOIF] int,
      [IraqOND] int,
      [OtherTheater] int,
      [MilitaryBranch] int,
      [DischargeStatus] int,
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(255),
      [DateDeleted] datetime,
      [ExportID] varchar(255)
    );

    create index client_date_created ON [hmis_Client] ([DateCreated]);
    create index client_date_updated ON [hmis_Client] ([DateUpdated]);
    create index client_export_id ON [hmis_Client] ([ExportID]);
    create index client_first_name ON [hmis_Client] ([FirstName]);
    create index client_last_name ON [hmis_Client] ([LastName]);
    create index client_personal_id ON [hmis_Client] ([PersonalID]);
    create index client_dob_idx ON [hmis_Client] ([DOB]);

  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_Disabilities' AND xtype='U')
    DROP TABLE [hmis_Disabilities]
    CREATE TABLE [hmis_Disabilities] (
      id int not null identity primary key,
      [DisabilitiesID] varchar(255),
      [EnrollmentID] varchar(255),
      [PersonalID] varchar(255),
      [InformationDate] date,
      [DisabilityType] int,
      [DisabilityResponse] int,
      [IndefiniteAndImpairs] int,
      [DocumentationOnFile] int,
      [ReceivingServices] int,
      [PATHHowConfirmed] int,
      [PATHSMIInformation] int,
      [TCellCountAvailable] int,
      [TCellCount] int,
      [TCellSource] int,
      [ViralLoadAvailable] int,
      [ViralLoad] int,
      [ViralLoadSource] int,
      [DataCollectionStage] int,
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(100),
      [DateDeleted] datetime,
      [ExportID] varchar(255)
    );

    create index disabilities_date_created ON [hmis_Disabilities] ([DateCreated]);
    create index disabilities_date_updated ON [hmis_Disabilities] ([DateUpdated]);
    create index index_Disabilities_on_EnrollmentID ON [hmis_Disabilities] ([EnrollmentID]);
    create index disabilities_export_id ON [hmis_Disabilities] ([ExportID]);
    create index index_Disabilities_on_PersonalID ON [hmis_Disabilities] ([PersonalID]);
    create unique index unk_Disabilities ON [hmis_Disabilities] ([DisabilitiesID]);

  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_EmploymentEducation' AND xtype='U')
    DROP TABLE [hmis_EmploymentEducation]
    CREATE TABLE [hmis_EmploymentEducation] (
      id int not null identity primary key,
      [EmploymentEducationID] varchar(255),
      [EnrollmentID] varchar(255),
      [PersonalID] varchar(255),
      [InformationDate] date,
      [LastGradeCompleted] int,
      [SchoolStatus] int,
      [Employed] int,
      [EmploymentType] int,
      [NotEmployedReason] int,
      [DataCollectionStage] int,
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(100),
      [DateDeleted] datetime,
      [ExportID] varchar(255)
    );

    create index employment_education_date_created ON [hmis_EmploymentEducation] ([DateCreated]);
    create index employment_education_date_updated ON [hmis_EmploymentEducation] ([DateUpdated]);
    create index index_EmploymentEducation_on_EnrollmentID ON [hmis_EmploymentEducation] ([EnrollmentID]);
    create index employment_education_export_id ON [hmis_EmploymentEducation] ([ExportID]);
    create index index_EmploymentEducation_on_PersonalID ON [hmis_EmploymentEducation] ([PersonalID]);
    create unique index unk_EmploymentEducation ON [hmis_EmploymentEducation] ([EmploymentEducationID]);

  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_Enrollment' AND xtype='U')
    DROP TABLE [hmis_Enrollment]
    CREATE TABLE [hmis_Enrollment] (
      id int not null identity primary key,
      [EnrollmentID] varchar(50),
      [PersonalID] varchar(255),
      [ProjectID] varchar(50),
      [EntryDate] date,
      [HouseholdID] varchar(255),
      [RelationshipToHoH] int,
      [LivingSituation] int,
      [OtherResidencePrior] varchar(255),
      [LengthOfStay] int,
      [DisablingCondition] int,
      [EntryFromStreetESSH] int,
      [DateToStreetESSH] date,
      [ContinuouslyHomelessOneYear] int,
      [TimesHomelessPastThreeYears] int,
      [MonthsHomelessPastThreeYears] int,
      [MonthsHomelessThisTime] int,
      [StatusDocumented] int,
      [HousingStatus] int,
      [DateOfEngagement] date,
      [InPermanentHousing] int,
      [MoveInDate] date,
      [DateOfPATHStatus] date,
      [ClientEnrolledInPATH] int,
      [ReasonNotEnrolled] int,
      [WorstHousingSituation] int,
      [PercentAMI] int,
      [LastPermanentStreet] varchar(255),
      [LastPermanentCity] varchar(50),
      [LastPermanentState] varchar(2),
      [LastPermanentZIP] varchar(10),
      [AddressDataQuality] int,
      [DateOfBCPStatus] date,
      [EligibleForRHY] int,
      [ReasonNoServices] int,
      [SexualOrientation] int,
      [FormerWardChildWelfare] int,
      [ChildWelfareYears] int,
      [ChildWelfareMonths] int,
      [FormerWardJuvenileJustice] int,
      [JuvenileJusticeYears] int,
      [JuvenileJusticeMonths] int,
      [HouseholdDynamics] int,
      [SexualOrientationG)erIDYouth] int,
      [SexualOrientationG)erIDFam] int,
      [HousingIssuesYouth] int,
      [HousingIssuesFam] int,
      [SchoolEducationalIssuesYouth] int,
      [SchoolEducationalIssuesFam] int,
      [UnemploymentYouth] int,
      [UnemploymentFam] int,
      [MentalHealthIssuesYouth] int,
      [MentalHealthIssuesFam] int,
      [HealthIssuesYouth] int,
      [HealthIssuesFam] int,
      [PhysicalDisabilityYouth] int,
      [PhysicalDisabilityFam] int,
      [MentalDisabilityYouth] int,
      [MentalDisabilityFam] int,
      [AbuseAndNeglectYouth] int,
      [AbuseAndNeglectFam] int,
      [AlcoholDrugAbuseYouth] int,
      [AlcoholDrugAbuseFam] int,
      [InsufficientIncome] int,
      [ActiveMilitaryParent] int,
      [IncarceratedParent] int,
      [IncarceratedParentStatus] int,
      [ReferralSource] int,
      [CountOutreachReferralApproaches] int,
      [ExchangeForSex] int,
      [ExchangeForSexPastThreeMonths] int,
      [CountOfExchangeForSex] int,
      [AskedOrForcedToExchangeForSex] int,
      [AskedOrForcedToExchangeForSexPastThreeMonths] int,
      [WorkPlaceViolenceThreats] int,
      [WorkplacePromiseDifference] int,
      [CoercedToContinueWork] int,
      [LaborExploitPastThreeMonths] int,
      [HPScreeningScore] int,
      [VAMCStation] int,
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(100),
      [DateDeleted] datetime,
      [ExportID] varchar(255),
      [LOSUnderThreshold] int,
      [PreviousStreetESSH] int,
      [UrgentReferral] int,
      [TimeToHousingLoss] int,
      [ZeroIncome] int,
      [AnnualPercentAMI] int,
      [FinancialChange] int,
      [HouseholdChange] int,
      [EvictionHistory] int,
      [SubsidyAtRisk] int,
      [LiteralHomelessHistory] int,
      [DisabledHoH] int,
      [CriminalRecord] int,
      [SexOffender] int,
      [DependentUnder6] int,
      [SingleParent] int,
      [HH5Plus] int,
      [IraqAfghanistan] int,
      [FemVet] int,
      [ThresholdScore] int,
      [ERVisits] int,
      [JailNights] int,
      [HospitalNights] int,
      [RunawayYouth] int
    );

    create index enrollment_date_created ON [hmis_Enrollment] ([DateCreated]);
    create index index_Enrollment_on_DateDeleted ON [hmis_Enrollment] ([DateDeleted]);
    create index enrollment_date_updated ON [hmis_Enrollment] ([DateUpdated]);
    create index index_Enrollment_on_EnrollmentID ON [hmis_Enrollment] ([EnrollmentID]);
    create index index_Enrollment_on_EntryDate ON [hmis_Enrollment] ([EntryDate]);
    create index enrollment_export_id ON [hmis_Enrollment] ([ExportID]);
    create index index_Enrollment_on_PersonalID ON [hmis_Enrollment] ([PersonalID]);
    create index index_Enrollment_on_ProjectID ON [hmis_Enrollment] ([ProjectID]);
    create index index_Enrollment_on_HouseholdID ON [hmis_Enrollment] ([HouseholdID]);
    create index index_Enrollment_on_ProjectID_HouseholdID ON [hmis_Enrollment] ([ProjectID], [HouseholdID]);
    create unique index unk_Enrollment ON [hmis_Enrollment] ([EnrollmentID], [PersonalID]);
    create unique index index_Enrollment_on_EnrollmentID_ProjectID_EntryDate ON [hmis_Enrollment] ([EnrollmentID], [ProjectID], [EntryDate]);
    create index index_Enrollment_on_RelationshipToHoH ON [hmis_Enrollment] ([RelationshipToHoH]);

  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_EnrollmentCoC' AND xtype='U')
    DROP TABLE [hmis_EnrollmentCoC]
    CREATE TABLE [hmis_EnrollmentCoC] (
      id int not null identity primary key,
      [EnrollmentCoCID] varchar(255),
      [EnrollmentID] varchar(255),
      [ProjectID] varchar(255),
      [PersonalID] varchar(255),
      [InformationDate] date,
      [CoCCode] varchar(50),
      [DataCollectionStage] int,
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(100),
      [DateDeleted] datetime,
      [ExportID] varchar(255),
      [HouseholdID] varchar(32)
    );

    create index enrollment_coc_date_created ON [hmis_EnrollmentCoC] ([DateCreated]);
    create index enrollment_coc_date_updated ON [hmis_EnrollmentCoC] ([DateUpdated]);
    create index index_EnrollmentCoC_on_EnrollmentCoCID ON [hmis_EnrollmentCoC] ([EnrollmentCoCID]);
    create index enrollment_coc_export_id ON [hmis_EnrollmentCoC] ([ExportID]);
    create index index_EnrollmentCoC_on_CoCCode ON [hmis_EnrollmentCoC] ([CoCCode]);
    create index index_EnrollmentCoC_on_EnrollmentID ON [hmis_EnrollmentCoC] ([EnrollmentID]);
    create index index_EnrollmentCoC_on_data_source_id_PersonalID ON [hmis_EnrollmentCoC] ([PersonalID]);


  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_Exit' AND xtype='U')
    DROP TABLE [hmis_Exit]
    CREATE TABLE [hmis_Exit] (
      id int not null identity primary key,
      [ExitID] varchar(255),
      [EnrollmentID] varchar(255),
      [PersonalID] varchar(255),
      [ExitDate] date,
      [Destination] int,
      [OtherDestination] varchar(255),
      [AssessmentDisposition] int,
      [OtherDisposition] varchar(255),
      [HousingAssessment] int,
      [SubsidyInformation] int,
      [ConnectionWithSOAR] int,
      [WrittenAftercarePlan] int,
      [AssistanceMainstreamBenefits] int,
      [PermanentHousingPlacement] int,
      [TemporaryShelterPlacement] int,
      [ExitCounseling] int,
      [FurtherFollowUpServices] int,
      [ScheduledFollowUpContacts] int,
      [ResourcePackage] int,
      [OtherAftercarePlanOrAction] int,
      [ProjectCompletionStatus] int,
      [EarlyExitReason] int,
      [FamilyReunificationAchieved] int,
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(100),
      [DateDeleted] datetime,
      [ExportID] varchar(255),
      [ExchangeForSex] int,
      [ExchangeForSexPastThreeMonths] int,
      [CountOfExchangeForSex] int,
      [AskedOrForcedToExchangeForSex] int,
      [AskedOrForcedToExchangeForSexPastThreeMonths] int,
      [WorkPlaceViolenceThreats] int,
      [WorkplacePromiseDifference] int,
      [CoercedToContinueWork] int,
      [LaborExploitPastThreeMonths] int,
      [CounselingReceived] int,
      [IndividualCounseling] int,
      [FamilyCounseling] int,
      [GroupCounseling] int,
      [SessionCountAtExit] int,
      [PostExitCounselingPlan] int,
      [SessionsInPlan] int,
      [DestinationSafeClient] int,
      [DestinationSafeWorker] int,
      [PosAdultConnections] int,
      [PosPeerConnections] int,
      [PosCommunityConnections] int,
      [AftercareDate] date,
      [AftercareProvided] int,
      [EmailSocialMedia] int,
      [Telephone] int,
      [InPersonIndividual] int,
      [InPersonGroup] int,
      [CMExitReason] int
    );

    create index exit_date_created ON [hmis_Exit] ([DateCreated]);
    create index index_Exit_on_DateDeleted ON [hmis_Exit] ([DateDeleted]);
    create index exit_date_updated ON [hmis_Exit] ([DateUpdated]);
    create index index_Exit_on_EnrollmentID ON [hmis_Exit] ([EnrollmentID]);
    create index index_Exit_on_ExitDate ON [hmis_Exit] ([ExitDate]);
    create index exit_export_id ON [hmis_Exit] ([ExportID]);
    create index index_Exit_on_PersonalID ON [hmis_Exit] ([PersonalID]);
    create unique index unk_Exit ON [hmis_Exit] ([ExitID]);

  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_Export' AND xtype='U')
    DROP TABLE [hmis_Export]
    CREATE TABLE [hmis_Export] (
      id int not null identity primary key,
      [ExportID] varchar(255),
      [SourceID] varchar(255),
      [SourceName] varchar(255),
      [SourceContactFirst] varchar(255),
      [SourceContactLast] varchar(255),
      [SourceContactPhone] varchar(255),
      [SourceContactExtension] varchar(255),
      [SourceContactEmail] varchar(255),
      [ExportDate] datetime,
      [ExportStartDate] date,
      [ExportEndDate] date,
      [SoftwareName] varchar(255),
      [SoftwareVersion] varchar(255),
      [ExportPeriodType] int,
      [ExportDirective] int,
      [HashStatus] int,
      [SourceType] int
    );

    create index export_export_id ON [hmis_Export] ([ExportID]);

  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_Funder' AND xtype='U')
    DROP TABLE [hmis_Funder]
    CREATE TABLE [hmis_Funder] (
      id int not null identity primary key,
      [FunderID] varchar(255),
      [ProjectID] varchar(255),
      [Funder] varchar(255),
      [GrantID] varchar(255),
      [StartDate] date,
      [EndDate] date,
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(100),
      [DateDeleted] datetime,
      [ExportID] varchar(255)
    );

    create index funder_date_created ON [hmis_Funder] ([DateCreated]);
    create index funder_date_updated ON [hmis_Funder] ([DateUpdated]);
    create index funder_export_id ON [hmis_Funder] ([ExportID]);
    create unique index unk_Funder ON [hmis_Funder] ([FunderID]);

  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_Geography' AND xtype='U')
    DROP TABLE [hmis_Geography]
    CREATE TABLE [hmis_Geography] (
      id int not null identity primary key,
      [GeographyID] varchar(255),
      [ProjectID] varchar(255),
      [CoCCode] varchar(50),
      [InformationDate] date,
      [Geocode] varchar(50),
      [GeographyType] int,
      [Address1] varchar(255),
      [Address2] varchar(255),
      [City] varchar(255),
      [State] varchar(2),
      [ZIP] varchar(10),
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(100),
      [DateDeleted] datetime,
      [ExportID] varchar(255)
    );

    create index site_date_created ON [hmis_Geography] ([DateCreated]);
    create index site_date_updated ON [hmis_Geography] ([DateUpdated]);
    create index site_export_id ON [hmis_Geography] ([ExportID]);
    create unique index unk_Site ON [hmis_Geography] ([GeographyID]);

  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_HealthAndDV' AND xtype='U')
    DROP TABLE [hmis_HealthAndDV]
    CREATE TABLE [hmis_HealthAndDV] (
      id int not null identity primary key,
      [HealthAndDVID] varchar(255),
      [EnrollmentID] varchar(255),
      [PersonalID] varchar(255),
      [InformationDate] date,
      [DomesticViolenceVictim] int,
      [WhenOccurred] int,
      [CurrentlyFleeing] int,
      [GeneralHealthStatus] int,
      [DentalHealthStatus] int,
      [MentalHealthStatus] int,
      [PregnancyStatus] int,
      [DueDate] date,
      [DataCollectionStage] int,
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(100),
      [DateDeleted] datetime,
      [ExportID] varchar(255)
    );

    create index health_and_dv_date_created ON [hmis_HealthAndDV] ([DateCreated]);
    create index health_and_dv_date_updated ON [hmis_HealthAndDV] ([DateUpdated]);
    create index index_HealthAndDV_on_EnrollmentID ON [hmis_HealthAndDV] ([EnrollmentID]);
    create index health_and_dv_export_id ON [hmis_HealthAndDV] ([ExportID]);
    create index index_HealthAndDV_on_PersonalID ON [hmis_HealthAndDV] ([PersonalID]);
    create unique index unk_HealthAndDV ON [hmis_HealthAndDV] ( [HealthAndDVID]);

  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_IncomeBenefits' AND xtype='U')
    DROP TABLE [hmis_IncomeBenefits]
    CREATE TABLE [hmis_IncomeBenefits] (
      id int not null identity primary key,
      [IncomeBenefitsID] varchar(255),
      [EnrollmentID] varchar(255),
      [PersonalID] varchar(255),
      [InformationDate] date,
      [IncomeFromAnySource] int,
      [TotalMonthlyIncome] varchar(50),
      [Earned] int,
      [EarnedAmount] varchar(50),
      [Unemployment] int,
      [UnemploymentAmount] varchar(50),
      [SSI] int,
      [SSIAmount] varchar(50),
      [SSDI] int,
      [SSDIAmount] varchar(50),
      [VADisabilityService] int,
      [VADisabilityServiceAmount] varchar(50),
      [VADisabilityNonService] int,
      [VADisabilityNonServiceAmount] varchar(50),
      [PrivateDisability] int,
      [PrivateDisabilityAmount] varchar(50),
      [WorkersComp] int,
      [WorkersCompAmount] varchar(50),
      [TANF] int,
      [TANFAmount] varchar(50),
      [GA] int,
      [GAAmount] varchar(50),
      [SocSecRetirement] int,
      [SocSecRetirementAmount] varchar(50),
      [Pension] int,
      [PensionAmount] varchar(50),
      [ChildSupport] int,
      [ChildSupportAmount] varchar(50),
      [Alimony] int,
      [AlimonyAmount] varchar(50),
      [OtherIncomeSource] int,
      [OtherIncomeAmount] varchar(50),
      [OtherIncomeSourceIdentify] varchar(255),
      [BenefitsFromAnySource] int,
      [SNAP] int,
      [WIC] int,
      [TANFChildCare] int,
      [TANFTransportation] int,
      [OtherTANF] int,
      [RentalAssistanceOngoing] int,
      [RentalAssistanceTemp] int,
      [OtherBenefitsSource] int,
      [OtherBenefitsSourceIdentify] varchar(255),
      [InsuranceFromAnySource] int,
      [Medicaid] int,
      [NoMedicaidReason] int,
      [Medicare] int,
      [NoMedicareReason] int,
      [SCHIP] int,
      [NoSCHIPReason] int,
      [VAMedicalServices] int,
      [NoVAMedReason] int,
      [EmployerProvided] int,
      [NoEmployerProvidedReason] int,
      [COBRA] int,
      [NoCOBRAReason] int,
      [PrivatePay] int,
      [NoPrivatePayReason] int,
      [StateHealthIns] int,
      [NoStateHealthInsReason] int,
      [HIVAIDSAssistance] int,
      [NoHIVAIDSAssistanceReason] int,
      [ADAP] int,
      [NoADAPReason] int,
      [DataCollectionStage] int,
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(100),
      [DateDeleted] datetime,
      [ExportID] varchar(255),
      [IndianHealthServices] int,
      [NoIndianHealthServicesReason] int,
      [OtherInsurance] int,
      [OtherInsuranceIdentify] varchar(50),
      [ConnectionWithSOAR] int
    );

    create index income_benefits_date_created ON [hmis_IncomeBenefits] ([DateCreated]);
    create index income_benefits_date_updated ON [hmis_IncomeBenefits] ([DateUpdated]);
    create index index_IncomeBenefits_on_EnrollmentID ON [hmis_IncomeBenefits] ([EnrollmentID]);
    create index income_benefits_export_id ON [hmis_IncomeBenefits] ([ExportID]);
    create index index_IncomeBenefits_on_PersonalID ON [hmis_IncomeBenefits] ([PersonalID]);
    create unique index unk_IncomeBenefits ON [hmis_IncomeBenefits] ( [IncomeBenefitsID]);

  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_Inventory' AND xtype='U')
    DROP TABLE [hmis_Inventory]
    CREATE TABLE [hmis_Inventory] (
      id int not null identity primary key,
      [InventoryID] varchar(255),
      [ProjectID] varchar(255),
      [CoCCode] varchar(50),
      [InformationDate] date,
      [HouseholdType] int,
      [Availability] int,
      [UnitInventory] int,
      [BedInventory] int,
      [CHBedInventory] int,
      [VetBedInventory] int,
      [YouthBedInventory] int,
      [BedType] int,
      [InventoryStartDate] date,
      [InventoryEndDate] date,
      [HMISParticipatingBeds] int,
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(100),
      [DateDeleted] datetime,
      [ExportID] varchar(255)
    );

    create index inventory_date_created ON [hmis_Inventory] ([DateCreated]);
    create index inventory_date_updated ON [hmis_Inventory] ([DateUpdated]);
    create index inventory_export_id ON [hmis_Inventory] ([ExportID]);
    create index index_Inventory_on_ProjectID_and_CoCCode ON [hmis_Inventory] ([ProjectID], [CoCCode]);
    create unique index unk_Inventory ON [hmis_Inventory] ([InventoryID]);

  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_Organization' AND xtype='U')
    DROP TABLE [hmis_Organization]
    CREATE TABLE [hmis_Organization] (
      id int not null identity primary key,
      [OrganizationID] varchar(50),
      [OrganizationName] varchar(255),
      [OrganizationCommonName] varchar(255),
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(100),
      [DateDeleted] datetime,
      [ExportID] varchar(255)
    );

    create index organization_export_id ON [hmis_Organization] ([ExportID]);
    create unique index unk_Organization ON [hmis_Organization] ([OrganizationID]);

  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_Project' AND xtype='U')
    DROP TABLE [hmis_Project]
    CREATE TABLE [hmis_Project] (
      id int not null identity primary key,
      [ProjectID] varchar(50),
      [OrganizationID] varchar(50),
      [ProjectName] varchar(255),
      [ProjectCommonName] varchar(255),
      [OperatingStartDate] date,
      [OperatingEndDate] date,
      [ContinuumProject] int,
      [ProjectType] int,
      [ResidentialAffiliation] int,
      [TrackingMethod] int,
      [TargetPopulation] int,
      [VictimServicesProvider] int,
      [HousingType] int,
      [PITCount] int,
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(100),
      [DateDeleted] datetime,
      [ExportID] varchar(255)
    );

    create index project_date_created ON [hmis_Project] ([DateCreated]);
    create index project_date_updated ON [hmis_Project] ([DateUpdated]);
    create index project_export_id ON [hmis_Project] ([ExportID]);
    create index index_proj_proj_id_org_id_ds_id ON [hmis_Project] ([ProjectID], [OrganizationID]);
    create index index_Project_on_ProjectType ON [hmis_Project] ([ProjectType]);
    create index index_Project_on_computed_project_type ON [hmis_Project] ([computed_project_type]);


  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_ProjectCoC' AND xtype='U')
    DROP TABLE [hmis_ProjectCoC]
    CREATE TABLE [hmis_ProjectCoC] (
      id int not null identity primary key,
      [ProjectCoCID] varchar(50),
      [ProjectID] varchar(255),
      [CoCCode] varchar(50),
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(100),
      [DateDeleted] datetime,
      [ExportID] varchar(255)
    );

    create index project_coc_date_created ON [hmis_ProjectCoC] ([DateCreated]);
    create index project_coc_date_updated ON [hmis_ProjectCoC] ([DateUpdated]);
    create index project_coc_export_id ON [hmis_ProjectCoC] ([ExportID]);
    create unique index unk_ProjectCoC ON [hmis_ProjectCoC] ([ProjectCoCID]);
    create index index_ProjectCoC_on_ProjectID_and_CoCCode ON [hmis_ProjectCoC] ([ProjectID], [CoCCode]);


  IF EXISTS (SELECT * FROM sysobjects WHERE name='hmis_Services' AND xtype='U')
    DROP TABLE [hmis_Services]
    CREATE TABLE [hmis_Services] (
      id int not null identity primary key,
      [ServicesID] varchar(255),
      [EnrollmentID] varchar(255),
      [PersonalID] varchar(255),
      [DateProvided] date,
      [RecordType] int,
      [TypeProvided] int,
      [OtherTypeProvided] varchar(255),
      [SubTypeProvided] int,
      [FAAmount] varchar(50),
      [ReferralOutcome] int,
      [DateCreated] datetime,
      [DateUpdated] datetime,
      [UserID] varchar(100),
      [DateDeleted] datetime,
      [ExportID] varchar(255)
    );

    create index services_date_created ON [hmis_Services] ([DateCreated]);
    create index index_Services_on_DateDeleted ON [hmis_Services] ([DateDeleted]);
    create index index_Services_on_DateProvided ON [hmis_Services] ([DateProvided]);
    create index services_date_updated ON [hmis_Services] ([DateUpdated]);
    create index index_serv_on_proj_entry_per_id_ds_id ON [hmis_Services] ([EnrollmentID], [PersonalID]);
    create index services_export_id ON [hmis_Services] ([ExportID]);
    create index index_Services_on_PersonalID ON [hmis_Services] ([PersonalID]);
    create index index_services_ds_id_p_id_type_entry_id_date ON [hmis_Services] ([PersonalID], [RecordType], [EnrollmentID], [DateProvided]);
    create unique index unk_Services ON [hmis_Services] ([ServicesID]);

SQL