require_relative 'sql_server_base'

class Bootstraper
  def run!
    hmis_6_11_table_structure!
  end

  def hmis_6_11_table_structure!
    SqlServerBase.connection.execute (<<~SQL);
      IF EXISTS (SELECT * FROM sysobjects WHERE name='Affiliation' AND xtype='U')
        DROP TABLE [Affiliation]
        CREATE TABLE [Affiliation] (
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

        create index affiliation_date_created ON [Affiliation] ([DateCreated]);
        create index affiliation_date_updated ON [Affiliation] ([DateUpdated]);
        create index affiliation_export_id ON [Affiliation] ([ExportID]);
        create unique index unk_Affiliation ON [Affiliation] ( [AffiliationID]);
      IF EXISTS (SELECT * FROM sysobjects WHERE name='Client' AND xtype='U')
        DROP TABLE [Client]
        CREATE TABLE [Client] (
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

        create index client_date_created ON [Client] ([DateCreated]);
        create index client_date_updated ON [Client] ([DateUpdated]);
        create index client_export_id ON [Client] ([ExportID]);
        create index client_first_name ON [Client] ([FirstName]);
        create index client_last_name ON [Client] ([LastName]);
        create index client_personal_id ON [Client] ([PersonalID]);

      IF EXISTS (SELECT * FROM sysobjects WHERE name='Disabilities' AND xtype='U')
        DROP TABLE [Disabilities]
        CREATE TABLE [Disabilities] (
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

        create index disabilities_date_created ON [Disabilities] ([DateCreated]);
        create index disabilities_date_updated ON [Disabilities] ([DateUpdated]);
        create index index_Disabilities_on_EnrollmentID ON [Disabilities] ([EnrollmentID]);
        create index disabilities_export_id ON [Disabilities] ([ExportID]);
        create index index_Disabilities_on_PersonalID ON [Disabilities] ([PersonalID]);
        create unique index unk_Disabilities ON [Disabilities] ([DisabilitiesID]);

      IF EXISTS (SELECT * FROM sysobjects WHERE name='EmploymentEducation' AND xtype='U')
        DROP TABLE [EmploymentEducation]
        CREATE TABLE [EmploymentEducation] (
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

        create index employment_education_date_created ON [EmploymentEducation] ([DateCreated]);
        create index employment_education_date_updated ON [EmploymentEducation] ([DateUpdated]);
        create index index_EmploymentEducation_on_EnrollmentID ON [EmploymentEducation] ([EnrollmentID]);
        create index employment_education_export_id ON [EmploymentEducation] ([ExportID]);
        create index index_EmploymentEducation_on_PersonalID ON [EmploymentEducation] ([PersonalID]);
        create unique index unk_EmploymentEducation ON [EmploymentEducation] ([EmploymentEducationID]);

      IF EXISTS (SELECT * FROM sysobjects WHERE name='Enrollment' AND xtype='U')
        DROP TABLE [Enrollment]
        CREATE TABLE [Enrollment] (
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

        create index enrollment_date_created ON [Enrollment] ([DateCreated]);
        create index index_Enrollment_on_DateDeleted ON [Enrollment] ([DateDeleted]);
        create index enrollment_date_updated ON [Enrollment] ([DateUpdated]);
        create index index_Enrollment_on_EnrollmentID ON [Enrollment] ([EnrollmentID]);
        create index index_Enrollment_on_EntryDate ON [Enrollment] ([EntryDate]);
        create index enrollment_export_id ON [Enrollment] ([ExportID]);
        create index index_Enrollment_on_PersonalID ON [Enrollment] ([PersonalID]);
        create index index_Enrollment_on_ProjectID ON [Enrollment] ([ProjectID]);
        create unique index unk_Enrollment ON [Enrollment] ([EnrollmentID], [PersonalID]);

      IF EXISTS (SELECT * FROM sysobjects WHERE name='EnrollmentCoC' AND xtype='U')
        DROP TABLE [EnrollmentCoC]
        CREATE TABLE [EnrollmentCoC] (
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

        create index enrollment_coc_date_created ON [EnrollmentCoC] ([DateCreated]);
        create index enrollment_coc_date_updated ON [EnrollmentCoC] ([DateUpdated]);
        create index index_EnrollmentCoC_on_EnrollmentCoCID ON [EnrollmentCoC] ([EnrollmentCoCID]);
        create index enrollment_coc_export_id ON [EnrollmentCoC] ([ExportID]);
        create index index_EnrollmentCoC_on_data_source_id_PersonalID ON [EnrollmentCoC] ([PersonalID]);


      IF EXISTS (SELECT * FROM sysobjects WHERE name='Exit' AND xtype='U')
        DROP TABLE [Exit]
        CREATE TABLE [Exit] (
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

        create index exit_date_created ON [Exit] ([DateCreated]);
        create index index_Exit_on_DateDeleted ON [Exit] ([DateDeleted]);
        create index exit_date_updated ON [Exit] ([DateUpdated]);
        create index index_Exit_on_EnrollmentID ON [Exit] ([EnrollmentID]);
        create index index_Exit_on_ExitDate ON [Exit] ([ExitDate]);
        create index exit_export_id ON [Exit] ([ExportID]);
        create index index_Exit_on_PersonalID ON [Exit] ([PersonalID]);
        create unique index unk_Exit ON [Exit] ([ExitID]);

      IF EXISTS (SELECT * FROM sysobjects WHERE name='Export' AND xtype='U')
        DROP TABLE [Export]
        CREATE TABLE [Export] (
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

        create index export_export_id ON [Export] ([ExportID]);

      IF EXISTS (SELECT * FROM sysobjects WHERE name='Funder' AND xtype='U')
        DROP TABLE [Funder]
        CREATE TABLE [Funder] (
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

        create index funder_date_created ON [Funder] ([DateCreated]);
        create index funder_date_updated ON [Funder] ([DateUpdated]);
        create index funder_export_id ON [Funder] ([ExportID]);
        create unique index unk_Funder ON [Funder] ([FunderID]);

      IF EXISTS (SELECT * FROM sysobjects WHERE name='Geography' AND xtype='U')
        DROP TABLE [Geography]
        CREATE TABLE [Geography] (
          id int not null identity primary key,
          [GeographyID] varchar(255),
          [ProjectID] varchar(255),
          [CoCCode] varchar(50),
          [PrincipalSite] int,
          [Geocode] varchar(50),
          [Address1] varchar(255),
          [City] varchar(255),
          [State] varchar(2),
          [ZIP] varchar(10),
          [DateCreated] datetime,
          [DateUpdated] datetime,
          [UserID] varchar(100),
          [DateDeleted] datetime,
          [ExportID] varchar(255),
          [InformationDate] date,
          [Address2] varchar(255),
          [GeographyType] int
        );

        create index site_date_created ON [Geography] ([DateCreated]);
        create index site_date_updated ON [Geography] ([DateUpdated]);
        create index site_export_id ON [Geography] ([ExportID]);
        create unique index unk_Site ON [Geography] ([GeographyID]);

      IF EXISTS (SELECT * FROM sysobjects WHERE name='HealthAndDV' AND xtype='U')
        DROP TABLE [HealthAndDV]
        CREATE TABLE [HealthAndDV] (
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

        create index health_and_dv_date_created ON [HealthAndDV] ([DateCreated]);
        create index health_and_dv_date_updated ON [HealthAndDV] ([DateUpdated]);
        create index index_HealthAndDV_on_EnrollmentID ON [HealthAndDV] ([EnrollmentID]);
        create index health_and_dv_export_id ON [HealthAndDV] ([ExportID]);
        create index index_HealthAndDV_on_PersonalID ON [HealthAndDV] ([PersonalID]);
        create unique index unk_HealthAndDV ON [HealthAndDV] ( [HealthAndDVID]);

      IF EXISTS (SELECT * FROM sysobjects WHERE name='IncomeBenefits' AND xtype='U')
        DROP TABLE [IncomeBenefits]
        CREATE TABLE [IncomeBenefits] (
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

        create index income_benefits_date_created ON [IncomeBenefits] ([DateCreated]);
        create index income_benefits_date_updated ON [IncomeBenefits] ([DateUpdated]);
        create index index_IncomeBenefits_on_EnrollmentID ON [IncomeBenefits] ([EnrollmentID]);
        create index income_benefits_export_id ON [IncomeBenefits] ([ExportID]);
        create index index_IncomeBenefits_on_PersonalID ON [IncomeBenefits] ([PersonalID]);
        create unique index unk_IncomeBenefits ON [IncomeBenefits] ( [IncomeBenefitsID]);

      IF EXISTS (SELECT * FROM sysobjects WHERE name='Inventory' AND xtype='U')
        DROP TABLE [Inventory]
        CREATE TABLE [Inventory] (
          id int not null identity primary key,
          [InventoryID] varchar(255),
          [ProjectID] varchar(255),
          [CoCCode] varchar(50),
          [InformationDate] date,
          [HouseholdType] int,
          [BedType] int,
          [Availability] int,
          [UnitInventory] int,
          [BedInventory] int,
          [CHBedInventory] int,
          [VetBedInventory] int,
          [YouthBedInventory] int,
          [YouthAgeGroup] int,
          [InventoryStartDate] date,
          [InventoryEndDate] date,
          [HMISParticipatingBeds] int,
          [DateCreated] datetime,
          [DateUpdated] datetime,
          [UserID] varchar(100),
          [DateDeleted] datetime,
          [ExportID] varchar(255)
        );

        create index inventory_date_created ON [Inventory] ([DateCreated]);
        create index inventory_date_updated ON [Inventory] ([DateUpdated]);
        create index inventory_export_id ON [Inventory] ([ExportID]);
        create index index_Inventory_on_ProjectID_and_CoCCode ON [Inventory] ([ProjectID], [CoCCode]);
        create unique index unk_Inventory ON [Inventory] ([InventoryID]);

      IF EXISTS (SELECT * FROM sysobjects WHERE name='Organization' AND xtype='U')
        DROP TABLE [Organization]
        CREATE TABLE [Organization] (
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

        create index organization_export_id ON [Organization] ([ExportID]);
        create unique index unk_Organization ON [Organization] ([OrganizationID]);

      IF EXISTS (SELECT * FROM sysobjects WHERE name='Project' AND xtype='U')
        DROP TABLE [Project]
        CREATE TABLE [Project] (
          id int not null identity primary key,
          [ProjectID] varchar(50),
          [OrganizationID] varchar(50),
          [ProjectName] varchar(255),
          [ProjectCommonName] varchar(255),
          [ContinuumProject] int,
          [ProjectType] int,
          [ResidentialAffiliation] int,
          [TrackingMethod] int,
          [TargetPopulation] int,
          [PITCount] int,
          [DateCreated] datetime,
          [DateUpdated] datetime,
          [UserID] varchar(100),
          [DateDeleted] datetime,
          [ExportID] varchar(255),
          [computed_project_type] int,
          [OperatingStartDate] date,
          [OperatingEndDate] date,
          [VictimServicesProvider] int,
          [HousingType] int
        );

        create index project_date_created ON [Project] ([DateCreated]);
        create index project_date_updated ON [Project] ([DateUpdated]);
        create index project_export_id ON [Project] ([ExportID]);
        create index index_proj_proj_id_org_id_ds_id ON [Project] ([ProjectID], [OrganizationID]);
        create index index_Project_on_ProjectType ON [Project] ([ProjectType]);
        create index index_Project_on_computed_project_type ON [Project] ([computed_project_type]);


      IF EXISTS (SELECT * FROM sysobjects WHERE name='ProjectCoC' AND xtype='U')
        DROP TABLE [ProjectCoC]
        CREATE TABLE [ProjectCoC] (
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

        create index project_coc_date_created ON [ProjectCoC] ([DateCreated]);
        create index project_coc_date_updated ON [ProjectCoC] ([DateUpdated]);
        create index project_coc_export_id ON [ProjectCoC] ([ExportID]);
        create unique index unk_ProjectCoC ON [ProjectCoC] ([ProjectCoCID]);
        create index index_ProjectCoC_on_ProjectID_and_CoCCode ON [ProjectCoC] ([ProjectID], [CoCCode]);


      IF EXISTS (SELECT * FROM sysobjects WHERE name='Services' AND xtype='U')
        DROP TABLE [Services]
        CREATE TABLE [Services] (
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

        create index services_date_created ON [Services] ([DateCreated]);
        create index index_Services_on_DateDeleted ON [Services] ([DateDeleted]);
        create index index_Services_on_DateProvided ON [Services] ([DateProvided]);
        create index services_date_updated ON [Services] ([DateUpdated]);
        create index index_serv_on_proj_entry_per_id_ds_id ON [Services] ([EnrollmentID], [PersonalID]);
        create index services_export_id ON [Services] ([ExportID]);
        create index index_Services_on_PersonalID ON [Services] ([PersonalID]);
        create index index_services_ds_id_p_id_type_entry_id_date ON [Services] ([PersonalID], [RecordType], [EnrollmentID], [DateProvided]);
        create unique index unk_Services ON [Services] ([ServicesID]);
    SQL
  end
end
