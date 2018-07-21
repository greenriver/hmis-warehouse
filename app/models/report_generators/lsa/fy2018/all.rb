# Some testing code:
# reload!; report_id = Reports::Lsa::Fy2018::All.last.id; ReportResult.where(report_id: report_id).last.update(percent_complete: 0); ReportGenerators::Lsa::Fy2018::All.new.run!
#
# Conversion notes:
# 1. Break table creation sections into their own methods
# 2. Move lSA reference tables from the end to before the lsa queries method
# 3. Break up the queries (submitting after each) to prevent timeouts (maybe increase timeout?)
#   Replace "/*"" with
#   "SQL
#    SqlServerBase.connection.execute (<<~SQL);
#    /*"

load 'lib/rds_sql_server/rds.rb'
load 'lib/rds_sql_server/sql_server_base.rb'
module ReportGenerators::Lsa::Fy2018
  class All < Base
    include TsqlImport
    def run!
      # Disable logging so we don't fill the disk
      # ActiveRecord::Base.logger.silence do
        calculate()
        Rails.logger.info "Done"
      # end # End silence ActiveRecord Log
    end

    private

    def calculate
      if start_report(Reports::Lsa::Fy2018::All.first)
        setup_filters()
        @report_start ||= @report.options['report_start'].to_date
        @report_end ||= @report.options['report_end'].to_date
        Rails.logger.info "Starting report #{@report.report.name}"
        begin
          @hmis_export = create_hmis_csv_export()
          setup_temporary_rds()
          setup_hmis_table_structure()
          setup_lsa_table_structure()
          setup_lsa_reference_tables()
          setup_lsa_table_indexes()
          populate_hmis_tables()


          run_lsa_queries()
          fetch_results()
        ensure
          # remove_temporary_rds()
        end
        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end

    def sql_server_identifier
      "#{ ENV.fetch('CLIENT') }-#{ Rails.env }-LSA".downcase
    end

    def create_hmis_csv_export
      # debugging
      return GrdaWarehouse::HmisExport.find(56)

      Exporters::HmisSixOneOne::Base.new(
        start_date: '2017-01-01'.to_date, #@report_start,
        end_date: '2017-01-03'.to_date, #@report_end,
        projects: @project_ids,
        period_type: 3,
        directive: 2,
        hash_status:1,
        include_deleted: false,
        user_id: @report.user_id
      ).export!
    end

    def setup_temporary_rds
      Rds.identifier = sql_server_identifier
      Rds.timeout = 600_000
      @rds = Rds.new
      @rds.setup!
    end

    def unzip_path
      File.join('var', 'lsa', @report.id.to_s)
    end

    def populate_hmis_tables
      load 'lib/rds_sql_server/hmis_sql_server.rb' # provides thin wrappers to all HMIS tables
      extract_path = @hmis_export.unzip_to(unzip_path)
      HmisSqlServer.models_by_hud_filename.each do |file_name, klass|
        arr_of_arrs = CSV.read(File.join(extract_path, file_name))
        headers = arr_of_arrs.first
        content = arr_of_arrs.drop(1)
        if content.any?
          insert_batch(klass, headers, content)
        end
      end
      #TODO: Remove expanded files
    end

    def fetch_results
      load 'lib/rds_sql_server/lsa_sql_server.rb'
      binding.pry
    end

    def remove_temporary_rds
      @rds.terminate!
    end

    def setup_hmis_table_structure
      Rds.identifier = sql_server_identifier
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
          create unique index unk_Enrollment ON [hmis_Enrollment] ([EnrollmentID], [PersonalID]);

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
    end

    def setup_lsa_table_indexes
      SqlServerBase.connection.execute (<<~SQL);
        create index ref_populations_HHType_idx ON [ref_Populations] ([HHType]);
        create index ref_populations_HHAdultAge_idx ON [ref_Populations] ([HHAdultAge]);
        create index ref_populations_HHVet_idx ON [ref_Populations] ([HHVet]);
        create index ref_populations_HHDisability_idx ON [ref_Populations] ([HHDisability]);
        create index ref_populations_HHChronic_idx ON [ref_Populations] ([HHChronic]);
        create index ref_populations_HHFleeingDV_idx ON [ref_Populations] ([HHFleeingDV]);
        create index ref_populations_HHParent_idx ON [ref_Populations] ([HHParent]);
        create index ref_populations_HHChild_idx ON [ref_Populations] ([HHChild]);
        create index ref_populations_Stat_idx ON [ref_Populations] ([Stat]);
        create index ref_populations_PSHMoveIn_idx ON [ref_Populations] ([PSHMoveIn]);
        create index ref_populations_HoHRace_idx ON [ref_Populations] ([HoHRace]);
        create index ref_populations_HoHEthnicity_idx ON [ref_Populations] ([HoHEthnicity]);

        create index active_enrollment_personal_id_idx ON [active_Enrollment] ([PersonalID]);
        create index active_enrollment_household_id_idx ON [active_Enrollment] ([HouseholdID]);
        create index active_enrollment_entry_date_idx ON [active_Enrollment] ([EntryDate]);
        create index active_enrollment_project_type_idx ON [active_Enrollment] ([ProjectType]);
        create index active_enrollment_project_id_idx ON [active_Enrollment] ([ProjectID]);
        create index active_enrollment_relationship_to_hoh_idx ON [active_Enrollment] ([RelationshipToHoH]);

        create index active_household_household_id_idx ON [active_Household] ([HouseholdID]);
        create index active_household_ho_hid_idx ON [active_Household] ([HoHID]);
        create index active_household_hh_type_idx ON [active_Household] ([HHType]);

        create index ch_enrollment_personal_id_idx ON [ch_Enrollment] ([PersonalID]);

        create index ch_episodes_personal_id_idx ON [ch_Episodes] ([PersonalID]);

      SQL
    end


    def setup_lsa_reference_tables
      SqlServerBase.connection.execute (<<~SQL);
        /**********************************************************************
        5.1 Create and Populate Reference Tables
        **********************************************************************/
        if object_id ('ref_Populations') is not null drop table ref_Populations
        CREATE TABLE dbo.ref_Populations(
          id int IDENTITY(1,1) NOT NULL,
          PopID int NULL,
          PopName varchar(255) NULL,
          PopType int NULL,
          HHType int NULL,
          HHAdultAge int NULL,
          HHVet int NULL,
          HHDisability int NULL,
          HHChronic int NULL,
          HHFleeingDV int NULL,
          HHParent int NULL,
          HHChild int NULL,
          AC3Plus int NULL,
          Stat int NULL,
          PSHMoveIn int NULL,
          HoHRace int NULL,
          HoHEthnicity int NULL,
          Race int NULL,
          Ethnicity int NULL,
          Age int NULL,
          Gender int NULL,
          VetStatus int NULL,
          CHTime int NULL,
          CHTimeStatus int NULL,
          DisabilityStatus int NULL,
          Core bit NULL,
          LOTH bit NULL,
          ReturnSummary bit NULL,
          ProjectTypeCount bit NULL,
          ProjectLevelCount bit NULL
        )
        ;
      SQL
      SqlServerBase.connection.execute (<<~SQL);
        if object_id ('ref_Calendar') is not null drop table ref_Calendar
        create table ref_Calendar (
          theDate date not null
          , yyyy smallint
          , mm tinyint
          , dd tinyint
          , month_name varchar(10)
          , day_name varchar(10)
          , fy smallint
          , PRIMARY KEY (theDate)
        )
        ;

        declare @start date = '2012-10-01'
        declare @end date = '2020-09-30'
        declare @i int = 0
        declare @total_days int = DATEDIFF(d, @start, @end)

        while @i <= @total_days
        begin
            insert into ref_Calendar (theDate)
            select cast(dateadd(d, @i, @start) as date)
            set @i = @i + 1
        end

        update ref_Calendar
        set month_name = datename(month, theDate),
          day_name = datename(weekday, theDate),
          yyyy = datepart(yyyy, theDate),
          mm = datepart(mm, theDate),
          dd = datepart(dd, theDate),
          fy = case when datepart(mm, theDate) between 10 and 12 then datepart(yyyy, theDate) + 1
            else datepart(yyyy, theDate) end

        SET IDENTITY_INSERT dbo.ref_Populations ON
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (1, 0, N'All', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (2, 0, N'All', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (3, 0, N'All', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (4, 0, N'All', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (5, 1, N'Youth Household 18-21', 1, 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (6, 2, N'Youth Household 22-24', 1, 1, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (7, 3, N'Veteran Household', 1, 1, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (8, 3, N'Veteran Household', 1, 2, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (9, 4, N'Non-Veteran Household 25+', 1, 1, 25, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (10, 4, N'Non-Veteran Household 25+', 1, 1, 55, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (11, 5, N'Household with Disabled Adult/HoH', 1, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (12, 5, N'Household with Disabled Adult/HoH', 1, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (13, 5, N'Household with Disabled Adult/HoH', 1, 2, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (14, 5, N'Household with Disabled Adult/HoH', 1, 3, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (15, 6, N'Household with Chronically Homeless Adult/HoH', 1, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (16, 6, N'Household with Chronically Homeless Adult/HoH', 1, 1, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (17, 6, N'Household with Chronically Homeless Adult/HoH', 1, 2, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (18, 6, N'Household with Chronically Homeless Adult/HoH', 1, 3, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (19, 7, N'Household Fleeing Domestic Violence', 1, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (20, 7, N'Household Fleeing Domestic Violence', 1, 1, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (21, 7, N'Household Fleeing Domestic Violence', 1, 2, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (22, 7, N'Household Fleeing Domestic Violence', 1, 3, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (23, 8, N'Senior Household 55+', 1, 1, 55, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (24, 9, N'Parenting Youth Household 18-24', 1, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (25, 9, N'Parenting Youth Household 18-24', 1, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (26, 10, N'Parenting Child Household', 1, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (27, 11, N'Household with 3+ Children', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (28, 12, N'First Time Homeless Household', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (29, 12, N'First Time Homeless Household', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (30, 12, N'First Time Homeless Household', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (31, 12, N'First Time Homeless Household', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (32, 13, N'Household Returning After Exit to PH', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (33, 13, N'Household Returning After Exit to PH', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (34, 13, N'Household Returning After Exit to PH', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (35, 13, N'Household Returning After Exit to PH', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (36, 14, N'Household with PSH Move-In During Report Period', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 0, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (37, 14, N'Household with PSH Move-In During Report Period', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 0, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (38, 14, N'Household with PSH Move-In During Report Period', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 0, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (39, 14, N'Household with PSH Move-In During Report Period', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 0, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (40, 15, N'White, non-Hispanic/Latino HoH', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (41, 15, N'White, non-Hispanic/Latino HoH', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (42, 15, N'White, non-Hispanic/Latino HoH', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (43, 15, N'White, non-Hispanic/Latino HoH', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (44, 16, N'White, Hispanic/Latino HoH', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (45, 16, N'White, Hispanic/Latino HoH', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (46, 16, N'White, Hispanic/Latino HoH', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (47, 16, N'White, Hispanic/Latino HoH', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (48, 17, N'Black or African American HoH', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (49, 17, N'Black or African American HoH', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (50, 17, N'Black or African American HoH', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (51, 17, N'Black or African American HoH', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (52, 18, N'Asian HoH', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (53, 18, N'Asian HoH', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (54, 18, N'Asian HoH', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (55, 18, N'Asian HoH', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (56, 19, N'American Indian/Alaska Native HoH', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (57, 19, N'American Indian/Alaska Native HoH', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (58, 19, N'American Indian/Alaska Native HoH', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (59, 19, N'American Indian/Alaska Native HoH', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (60, 20, N'Native Hawaiian/Other Pacific Islander HoH', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (61, 20, N'Native Hawaiian/Other Pacific Islander HoH', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (62, 20, N'Native Hawaiian/Other Pacific Islander HoH', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (63, 20, N'Native Hawaiian/Other Pacific Islander HoH', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (64, 21, N'Multi-Racial HoH', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (65, 21, N'Multi-Racial HoH', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (66, 21, N'Multi-Racial HoH', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (67, 21, N'Multi-Racial HoH', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (68, 22, N'Non-Hispanic/Latino HoH', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (69, 22, N'Non-Hispanic/Latino HoH', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (70, 22, N'Non-Hispanic/Latino HoH', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (71, 22, N'Non-Hispanic/Latino HoH', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (72, 23, N'Hispanic/Latino HoH', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (73, 23, N'Hispanic/Latino HoH', 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (74, 23, N'Hispanic/Latino HoH', 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (75, 23, N'Hispanic/Latino HoH', 1, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (76, 39, N'Youth Household 18-21 - Disabled Adult/HoH', 1, 1, 18, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (77, 40, N'Youth Household 18-21 - Fleeing Domestic Violence', 1, 1, 18, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (78, 41, N'Youth Household 18-21 - First Time Homeless', 1, 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (79, 42, N'Youth Household 18-21 - Returning after Exit to PH', 1, 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (80, 43, N'Youth Household 18-21 - PSH Move-In During Report Period', 1, 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 0, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (81, 44, N'Youth Household 18-21 - White, non-Hispanic/Latino HoH', 1, 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (82, 45, N'Youth Household 18-21 - White, Hispanic/Latino HoH', 1, 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (83, 46, N'Youth Household 18-21 - Black or African American HoH', 1, 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (84, 47, N'Youth Household 18-21 - Asian HoH', 1, 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (85, 48, N'Youth Household 18-21 - American Indian/Alaska Native HoH', 1, 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (86, 49, N'Youth Household 18-21 - Native Hawaiian/Other Pacific Islander HoH', 1, 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (87, 50, N'Youth Household 18-21 - Multi-Racial HoH', 1, 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (88, 51, N'Youth Household 18-21 - Non-Hispanic/Latino HoH', 1, 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (89, 52, N'Youth Household 18-21 - Hispanic/Latino HoH', 1, 1, 18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (90, 53, N'Youth Household 22-24 - Disabled Adult/HoH', 1, 1, 24, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (91, 54, N'Youth Household 22-24 - Fleeing Domestic Violence', 1, 1, 24, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (92, 55, N'Youth Household 22-24 - First Time Homeless', 1, 1, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (93, 56, N'Youth Household 22-24 - Returning after Exit to PH', 1, 1, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (94, 57, N'Youth Household 22-24 - PSH Move-In During Report Period', 1, 1, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 0, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (95, 58, N'Youth Household 22-24 - White, non-Hispanic/Latino HoH', 1, 1, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (96, 59, N'Youth Household 22-24 - White, Hispanic/Latino HoH', 1, 1, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (97, 60, N'Youth Household 22-24 - Black or African American HoH', 1, 1, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (98, 61, N'Youth Household 22-24 - Asian HoH', 1, 1, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (99, 62, N'Youth Household 22-24 - American Indian/Alaska Native HoH', 1, 1, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (100, 63, N'Youth Household 22-24 - Native Hawaiian/Other Pacific Islander HoH', 1, 1, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (101, 64, N'Youth Household 22-24 - Multi-Racial HoH', 1, 1, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (102, 65, N'Youth Household 22-24 - Non-Hispanic/Latino HoH', 1, 1, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (103, 66, N'Youth Household 22-24 - Hispanic/Latino HoH', 1, 1, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (104, 67, N'Non-Veteran Household 25+ - Disabled Adult/HoH', 1, 1, 55, 0, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (105, 68, N'Non-Veteran Household 25+ - Fleeing Domestic Violence', 1, 1, 55, 0, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (106, 69, N'Non-Veteran Household 25+ - First Time Homeless', 1, 1, 55, 0, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (107, 70, N'Non-Veteran Household 25+ - Returning after Exit to PH', 1, 1, 25, 0, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (108, 71, N'Non-Veteran Household 25+ - Household with PSH Move-In During Report Period', 1, 1, 55, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 0, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (109, 72, N'Non-Veteran Household 25+ - White, non-Hispanic/Latino HoH', 1, 1, 55, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (110, 73, N'Non-Veteran Household 25+ - White, Hispanic/Latino HoH', 1, 1, 25, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (111, 74, N'Non-Veteran Household 25+ - Black or African American HoH', 1, 1, 55, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (112, 75, N'Non-Veteran Household 25+ - Asian HoH', 1, 1, 25, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (113, 76, N'Non-Veteran Household 25+ - American Indian/Alaska Native HoH', 1, 1, 55, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (114, 77, N'Non-Veteran Household 25+ - Native Hawaiian/Other Pacific Islander HoH', 1, 1, 25, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (115, 78, N'Non-Veteran Household 25+ - Multi-Racial HoH', 1, 1, 55, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (116, 79, N'Non-Veteran Household 25+ - Non-Hispanic/Latino HoH', 1, 1, 25, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (117, 80, N'Non-Veteran Household 25+ - Hispanic/Latino HoH', 1, 1, 55, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (118, 81, N'Veteran Household - Disabled Adult/HoH', 1, 1, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (119, 82, N'Veteran Household - Fleeing Domestic Violence', 1, 1, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (120, 83, N'Veteran Household - First Time Homeless', 1, 1, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (121, 84, N'Veteran Household - Returning after Exit to PH', 1, 1, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (122, 85, N'Veteran Household - PSH Move-In During Report Period', 1, 1, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 0, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (123, 86, N'Veteran Household - White, non-Hispanic/Latino HoH', 1, 1, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (124, 87, N'Veteran Household - White, Hispanic/Latino HoH', 1, 1, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (125, 88, N'Veteran Household - Black or African American HoH', 1, 1, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (126, 89, N'Veteran Household - Asian HoH', 1, 1, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (127, 90, N'Veteran Household - American Indian/Alaska Native HoH', 1, 1, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (128, 91, N'Veteran Household - Native Hawaiian/Other Pacific Islander HoH', 1, 1, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (129, 92, N'Veteran Household - Multi-Racial HoH', 1, 1, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (130, 93, N'Veteran Household - Non-Hispanic/Latino HoH', 1, 1, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (131, 94, N'Veteran Household - Hispanic/Latino HoH', 1, 1, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (132, 95, N'Veteran Household 55+', 1, 1, 55, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (133, 96, N'Non-Veteran Household 55+', 1, 1, 55, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, 1, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (134, 3, N'Veteran', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (135, 3, N'Veteran', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (136, 3, N'Veteran', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (137, 6, N'Chronically Homeless Adult/HoH', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 365, 1, 1, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (138, 6, N'Chronically Homeless Adult/HoH', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 365, 2, 1, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (139, 15, N'White, non-Hispanic/Latino', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (140, 16, N'White, Hispanic/Latino', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (141, 17, N'Black or African American', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (142, 18, N'Asian', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (143, 19, N'American Indian or Alaska Native', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (144, 20, N'Native Hawaiian / Other Pacific Islander', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (145, 21, N'Multi-Racial', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (146, 22, N'Non-Hispanic/Latino', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (147, 23, N'Hispanic/Latino', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (148, 24, N'<1 year', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (149, 25, N'1 to 2 years', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (150, 26, N'3 to 5 years', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (151, 27, N'6 to 17 years', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 17, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (152, 28, N'18 to 21 years', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 21, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (153, 29, N'22 to 24 years', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (154, 30, N'25 to 34 years', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 34, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (155, 31, N'35 to 44 years', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 44, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (156, 32, N'45 to 54 years', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 54, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (157, 33, N'55 to 64 years', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 64, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (158, 34, N'65 and older', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 65, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (159, 35, N'Female', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (160, 36, N'Male', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (161, 37, N'Transgender', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (162, 38, N'Gender non-conforming', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (163, 97, N'Veteran - Female', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (164, 97, N'Veteran - Gender non-conforming', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (165, 98, N'Veteran - Male', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (166, 99, N'Veteran - Transgender', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (167, 101, N'Veteran - White, non-Hispanic/Latino', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (168, 102, N'Veteran - White, Hispanic/Latino', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (169, 103, N'Veteran - Black or African American', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (170, 104, N'Veteran - Asian', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (171, 105, N'Veteran - American Indian or Alaska Native', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (172, 106, N'Veteran - Native Hawaiian / Other Pacific Islander', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (173, 107, N'Veteran - Multiple Races', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (174, 108, N'Veteran - Non-Hispanic/Latino', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (175, 109, N'Veteran - Hispanic/Latino', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (176, 110, N'Veteran - Chronically Homeless', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 365, 1, 1, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (177, 110, N'Veteran - Chronically Homeless', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 365, 2, 1, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (178, 111, N'Veteran - Disabled', 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (179, 112, N'Veteran - Fleeing Domestic Violence', 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (180, 113, N'Parenting Youth - Female', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (181, 113, N'Parenting Youth - Gender non-conforming', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (182, 113, N'Parenting Youth - Gender non-conforming', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (183, 113, N'Parenting Youth - Female', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (184, 114, N'Parenting Youth - Male', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (185, 114, N'Parenting Youth - Male', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (186, 115, N'Parenting Youth - Transgender', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (187, 115, N'Parenting Youth - Transgender', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (188, 117, N'Parenting Youth - White, non-Hispanic/Latino', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (189, 117, N'Parenting Youth - White, non-Hispanic/Latino', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (190, 118, N'Parenting Youth - White, Hispanic/Latino', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (191, 118, N'Parenting Youth - White, Hispanic/Latino', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (192, 119, N'Parenting Youth - Black or African American', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (193, 119, N'Parenting Youth - Black or African American', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (194, 120, N'Parenting Youth - Asian', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (195, 120, N'Parenting Youth - Asian', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (196, 121, N'Parenting Youth - American Indian or Alaska Native', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (197, 121, N'Parenting Youth - American Indian or Alaska Native', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (198, 122, N'Parenting Youth - Native Hawaiian / Other Pacific Islander', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (199, 122, N'Parenting Youth - Native Hawaiian / Other Pacific Islander', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (200, 123, N'Parenting Youth - Multiple Races', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (201, 123, N'Parenting Youth - Multiple Races', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (202, 124, N'Parenting Youth - Non-Hispanic/Latino', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (203, 124, N'Parenting Youth - Non-Hispanic/Latino', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (204, 125, N'Parenting Youth - Hispanic/Latino', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (205, 125, N'Parenting Youth - Hispanic/Latino', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (206, 126, N'Parenting Youth - Chronically Homeless', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 365, 1, 1, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (207, 126, N'Parenting Youth - Chronically Homeless', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 365, 2, 1, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (208, 126, N'Parenting Youth - Chronically Homeless', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 365, 1, 1, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (209, 126, N'Parenting Youth - Chronically Homeless', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 365, 2, 1, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (210, 127, N'Parenting Youth - Disabled', 3, 2, 24, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (211, 127, N'Parenting Youth - Disabled', 3, 2, 18, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (212, 128, N'Parenting Youth - Fleeing Domestic Violence', 3, 2, 18, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (213, 128, N'Parenting Youth - Fleeing Domestic Violence', 3, 2, 24, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (214, 129, N'Parenting Child - Female', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (215, 129, N'Parenting Child - Gender non-conforming', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (216, 130, N'Parenting Child - Male', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (217, 131, N'Parenting Child - Transgender', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (218, 133, N'Parenting Child - White, non-Hispanic/Latino', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (219, 134, N'Parenting Child - White, Hispanic/Latino', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (220, 135, N'Parenting Child - Black or African American', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (221, 136, N'Parenting Child - Asian', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (222, 137, N'Parenting Child - American Indian or Alaska Native', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (223, 138, N'Parenting Child - Native Hawaiian / Other Pacific Islander', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (224, 139, N'Parenting Child - Multiple Races', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, 6, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (225, 140, N'Parenting Child - Non-Hispanic/Latino', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (226, 141, N'Parenting Child - Hispanic/Latino', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (227, 142, N'Parenting Child - Chronically Homeless', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 365, 1, 1, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (228, 142, N'Parenting Child - Chronically Homeless', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 365, 2, 1, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (229, 143, N'Parenting Child - Disabled', 3, 3, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (230, 144, N'Parenting Child - Fleeing Domestic Violence', 3, 3, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (231, 6, N'Chronically Homeless Adult/HoH', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 365, 1, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (232, 6, N'Chronically Homeless Adult/HoH', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 365, 2, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (237, 28, N'18 to 21 years', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 21, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (238, 29, N'22 to 24 years', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (239, 30, N'25 to 34 years', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 34, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (240, 31, N'35 to 44 years', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 44, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (241, 32, N'45 to 54 years', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 54, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (242, 33, N'55 to 64 years', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 64, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (243, 34, N'65 and older', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 65, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (251, 15, N'White, non-Hispanic/Latino', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (252, 16, N'White, Hispanic/Latino', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (253, 17, N'Black or African American', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (254, 18, N'Asian', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (255, 19, N'American Indian or Alaska Native', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (256, 20, N'Native Hawaiian / Other Pacific Islander', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (257, 21, N'Multi-Racial', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (258, 22, N'Non-Hispanic/Latino', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (259, 23, N'Hispanic/Latino', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (267, 35, N'Female', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (268, 36, N'Male', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (269, 37, N'Transgender', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (270, 38, N'Gender non-conforming', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (271, 97, N'Veteran - Female', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (272, 97, N'Veteran - Gender non-conforming', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (273, 98, N'Veteran - Male', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (274, 99, N'Veteran - Transgender', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (275, 101, N'Veteran - White, non-Hispanic/Latino', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (276, 102, N'Veteran - White, Hispanic/Latino', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (277, 103, N'Veteran - Black or African American', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (278, 104, N'Veteran - Asian', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (279, 105, N'Veteran - American Indian or Alaska Native', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (280, 106, N'Veteran - Native Hawaiian / Other Pacific Islander', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (281, 107, N'Veteran - Multiple Races', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (282, 108, N'Veteran - Non-Hispanic/Latino', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (283, 109, N'Veteran - Hispanic/Latino', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (284, 110, N'Veteran - Chronically Homeless', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 365, 1, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (285, 110, N'Veteran - Chronically Homeless', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 365, 2, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (286, 111, N'Veteran - Disabled', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (287, 112, N'Veteran - Fleeing Domestic Violence', 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (288, 15, N'White, non-Hispanic/Latino', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (289, 16, N'White, Hispanic/Latino', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (290, 17, N'Black or African American', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (291, 18, N'Asian', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (292, 19, N'American Indian or Alaska Native', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (293, 20, N'Native Hawaiian / Other Pacific Islander', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (294, 21, N'Multi-Racial', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (295, 22, N'Non-Hispanic/Latino', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (296, 23, N'Hispanic/Latino', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (297, 24, N'<1 year', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (298, 25, N'1 to 2 years', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (299, 26, N'3 to 5 years', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (300, 27, N'6 to 17 years', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 17, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (301, 28, N'18 to 21 years', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 21, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (302, 29, N'22 to 24 years', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 24, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (303, 30, N'25 to 34 years', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 34, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (304, 31, N'35 to 44 years', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 44, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (305, 32, N'45 to 54 years', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 54, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (306, 33, N'55 to 64 years', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 64, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (307, 34, N'65 and older', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 65, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (308, 35, N'Female', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (309, 36, N'Male', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (310, 37, N'Transgender', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (311, 38, N'Gender non-conforming', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (312, 97, N'Veteran - Female', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (313, 97, N'Veteran - Gender non-conforming', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (314, 98, N'Veteran - Male', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (315, 99, N'Veteran - Transgender', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (316, 101, N'Veteran - White, non-Hispanic/Latino', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (317, 102, N'Veteran - White, Hispanic/Latino', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (318, 103, N'Veteran - Black or African American', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (319, 104, N'Veteran - Asian', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (320, 105, N'Veteran - American Indian or Alaska Native', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (321, 106, N'Veteran - Native Hawaiian / Other Pacific Islander', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (322, 107, N'Veteran - Multiple Races', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (323, 108, N'Veteran - Non-Hispanic/Latino', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (324, 109, N'Veteran - Hispanic/Latino', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (325, 110, N'Veteran - Chronically Homeless', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 365, 1, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (326, 110, N'Veteran - Chronically Homeless', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 365, 2, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (327, 111, N'Veteran - Disabled', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (328, 112, N'Veteran - Fleeing Domestic Violence', 3, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (329, 15, N'White, non-Hispanic/Latino', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (330, 16, N'White, Hispanic/Latino', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (331, 17, N'Black or African American', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (332, 18, N'Asian', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (333, 19, N'American Indian or Alaska Native', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (334, 20, N'Native Hawaiian / Other Pacific Islander', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (335, 21, N'Multi-Racial', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (336, 22, N'Non-Hispanic/Latino', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (337, 23, N'Hispanic/Latino', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (338, 24, N'<1 year', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (339, 25, N'1 to 2 years', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (340, 26, N'3 to 5 years', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (341, 27, N'6 to 17 years', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 17, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (349, 35, N'Female', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (350, 36, N'Male', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (351, 37, N'Transgender', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        INSERT dbo.ref_Populations (id, PopID, PopName, PopType, HHType, HHAdultAge, HHVet, HHDisability, HHChronic, HHFleeingDV, HHParent, HHChild, AC3Plus, Stat, PSHMoveIn, HoHRace, HoHEthnicity, Race, Ethnicity, Age, Gender, VetStatus, CHTime, CHTimeStatus, DisabilityStatus, Core, LOTH, ReturnSummary, ProjectTypeCount, ProjectLevelCount) VALUES (352, 38, N'Gender non-conforming', 3, 3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1)
        ;
        SET IDENTITY_INSERT dbo.ref_Populations OFF
        ;
        SQL
      end
    def setup_lsa_table_structure
      Rds.identifier = sql_server_identifier
      SqlServerBase.connection.execute (<<~SQL);
        SET ANSI_NULLS ON
      SQL
      SqlServerBase.connection.execute (<<~SQL);
        SET QUOTED_IDENTIFIER ON
      SQL
      SqlServerBase.connection.execute (<<~SQL);

        if object_id ('active_Enrollment') is not null drop table active_Enrollment
        CREATE TABLE dbo.active_Enrollment(
          EnrollmentID varchar(32) NOT NULL,
          PersonalID varchar(32) NOT NULL,
          HouseholdID varchar(32) NOT NULL,
          RelationshipToHoH int NULL,
          EntryDate date NULL,
          MoveInDate date NULL,
          ExitDate date NULL,
          AgeDate date NULL,
          AgeGroup int NULL,
          MostRecent int NULL,
          HHType int NULL,
          ProjectID varchar(32) NULL,
          ProjectType int NULL,
          TrackingMethod int NULL,
            PRIMARY KEY (EnrollmentID)
        )
        ;

        if object_id ('active_Household') is not null drop table active_Household
        CREATE TABLE dbo.active_Household(
          HouseholdID varchar(32) NOT NULL,
          HoHID varchar(32) NULL,
          HHType int NULL,
          ProjectID int NULL,
          ProjectType int NULL,
          TrackingMethod int NULL,
          MoveInDate date NULL,
          HHChronic int NULL,
          HHVet int NULL,
          HHDisability int NULL,
          HHFleeingDV int NULL,
          HHAdultAge int NULL,
          HHParent int NULL,
          HHAdult int NULL,
          HHChild int NULL,
          HHNoDOB int NULL,
          AC3Plus int NULL,
          PRIMARY KEY (HouseholdID)
        );

        if object_id ('ch_Enrollment') is not null drop table ch_Enrollment
        CREATE TABLE dbo.ch_Enrollment(
          PersonalID varchar(32) NULL,
          EnrollmentID varchar(32) NOT NULL,
          ProjectType int NULL,
          TrackingMethod int NULL,
          StartDate date NULL,
          MoveInDate date NULL,
          StopDate date NULL
            PRIMARY KEY (EnrollmentID)
        )
        ;

        if object_id ('ch_Episodes') is not null drop table ch_Episodes
        CREATE TABLE dbo.ch_Episodes(
          PersonalID varchar(32) NULL,
          episodeStart date NULL,
          episodeEnd date NULL,
          episodeDays int NULL
        )
        ;

        if object_id ('ch_Exclude') is not null drop table ch_Exclude
        CREATE TABLE dbo.ch_Exclude(
          PersonalID varchar(32) NOT NULL,
          excludeDate date NOT NULL,
          PRIMARY KEY (PersonalID, excludeDate)
        )
        ;

        if object_id ('ch_Time') is not null drop table ch_Time
        CREATE TABLE dbo.ch_Time(
          PersonalID varchar(32) NOT NULL,
          chDate date NOT NULL,
          PRIMARY KEY (PersonalID, chDate)
        )
        ;

        if object_id ('dq_Enrollment') is not null drop table dq_Enrollment
        CREATE TABLE dbo.dq_Enrollment(
          EnrollmentID varchar(32) NOT NULL,
          PersonalID varchar(32) NULL,
          HouseholdID varchar(32) NULL,
          RelationshipToHoH int NULL,
          ProjectType int NULL,
          EntryDate date NULL,
          MoveInDate date NULL,
          ExitDate date NULL,
          Adult int NULL,
          SSNValid int NULL,
          PRIMARY KEY (EnrollmentID)
        )
        ;

        if object_id ('ex_Enrollment') is not null drop table ex_Enrollment
        CREATE TABLE dbo.ex_Enrollment(
          Cohort int NOT NULL,
          HoHID varchar(32) NOT NULL,
          HHType int NOT NULL,
          EnrollmentID varchar(32) NOT NULL,
          ProjectType int NULL,
          EntryDate date NULL,
          MoveInDate date NULL,
          ExitDate date NULL,
          ExitTo int NULL,
          Active bit NULL,
          PRIMARY KEY (EnrollmentID)
        )
        ;

        if object_id ('lsa_Calculated') is not null drop table lsa_Calculated
        CREATE TABLE dbo.lsa_Calculated(
          Value int NULL,
          Cohort int NULL,
          Universe int NULL,
          HHType int NULL,
          Population int NULL,
          SystemPath int NULL,
          ProjectID varchar(32) NULL,
          ReportRow int NULL,
          ReportID int NULL
        )
        ;

        if object_id ('lsa_Exit') is not null drop table lsa_Exit
        CREATE TABLE dbo.lsa_Exit(
          RowTotal int NULL,
          Cohort int NULL,
          Stat int NULL,
          ExitFrom int NULL,
          ExitTo int NULL,
          ReturnTime int NULL,
          HHType int NULL,
          HHVet int NULL,
          HHDisability int NULL,
          HHFleeingDV int NULL,
          HoHRace int NULL,
          HoHEthnicity int NULL,
          HHAdultAge int NULL,
          HHParent int NULL,
          AC3Plus int NULL,
          SystemPath int NULL,
          ReportID int NULL
        )
        ;

        if object_id ('lsa_Inventory') is not null drop table lsa_Inventory
        if object_id ('lsa_Geography') is not null drop table lsa_Geography
        if object_id ('lsa_Funder') is not null drop table lsa_Funder
        if object_id ('lsa_Project') is not null drop table lsa_Project
        if object_id ('lsa_Organization') is not null drop table lsa_Organization
        CREATE TABLE dbo.lsa_Organization(
          OrganizationID varchar(32) NOT NULL,
          OrganizationName varchar(50) NOT NULL,
          OrganizationCommonName varchar(50) NULL,
          DateCreated datetime NOT NULL,
          DateUpdated datetime NOT NULL,
          UserID varchar(32) NULL,
          DateDeleted datetime NULL,
          ExportID varchar(32) NOT NULL,
          PRIMARY KEY (OrganizationID)
        )
        ;
        CREATE TABLE dbo.lsa_Project(
          ProjectID varchar(32) NOT NULL,
          OrganizationID varchar(32) NULL,
          ProjectName varchar(50) NOT NULL,
          ProjectCommonName varchar(50) NULL,
          OperatingStartDate date NULL,
          OperatingEndDate date NULL,
          ContinuumProject int NOT NULL,
          ProjectType int NOT NULL,
          ResidentialAffiliation int NULL,
          TrackingMethod int NULL,
          TargetPopulation int NULL,
          VictimServicesProvider int NOT NULL,
          HousingType int NOT NULL,
          PITCount int NULL,
          DateCreated datetime NOT NULL,
          DateUpdated datetime NOT NULL,
          UserID varchar(32) NULL,
          DateDeleted datetime NULL,
          ExportID varchar(32) NOT NULL,
          PRIMARY KEY (ProjectID)
        )
        ;
        CREATE TABLE dbo.lsa_Inventory(
          InventoryID varchar(32) NOT NULL,
          ProjectID varchar(32) NOT NULL,
          CoCCode varchar(6) NOT NULL,
          InformationDate date NOT NULL,
          HouseholdType int NOT NULL,
          Availability int NULL,
          UnitInventory int NOT NULL,
          BedInventory int NOT NULL,
          CHBedInventory int NULL,
          VetBedInventory int NULL,
          YouthBedInventory int NULL,
          BedType int NULL,
          InventoryStartDate date NOT NULL,
          InventoryEndDate date NULL,
          HMISParticipatingBeds int NOT NULL,
          DateCreated datetime NOT NULL,
          DateUpdated datetime NOT NULL,
          UserID varchar(32) NULL,
          DateDeleted datetime NULL,
          ExportID varchar(32) NOT NULL,
          PRIMARY KEY (InventoryID),
          FOREIGN KEY(ProjectID) REFERENCES dbo.lsa_Project (ProjectID)
        )
        ;

        CREATE TABLE dbo.lsa_Funder(
          FunderID varchar(32) NOT NULL,
          ProjectID varchar(32) NOT NULL,
          Funder int NOT NULL,
          GrantID varchar(32) NULL,
          StartDate date NOT NULL,
          EndDate date NULL,
          DateCreated datetime NOT NULL,
          DateUpdated datetime NOT NULL,
          UserID varchar(32) NULL,
          DateDeleted datetime NULL,
          ExportID varchar(32) NOT NULL,
          FOREIGN KEY(ProjectID) REFERENCES dbo.lsa_Project (ProjectID)
        )
        ;

        CREATE TABLE dbo.lsa_Geography(
          GeographyID varchar(32) NOT NULL,
          ProjectID varchar(32) NOT NULL,
          CoCCode varchar(6) NOT NULL,
          InformationDate datetime NOT NULL,
          Geocode varchar(6) NOT NULL,
          GeographyType int NOT NULL,
          Address1 varchar(50) NULL,
          Address2 varchar(50) NULL,
          City varchar(50) NULL,
          State varchar(2) NULL,
          ZIP varchar(5) NULL,
          DateCreated datetime NOT NULL,
          DateUpdated datetime NOT NULL,
          UserID varchar(32) NULL,
          DateDeleted datetime NULL,
          ExportID varchar(32) NOT NULL,
          PRIMARY KEY (GeographyID),
          FOREIGN KEY(ProjectID) REFERENCES dbo.lsa_Project (ProjectID)
        )
        ;

        if object_id ('lsa_Household') is not null drop table lsa_Household
        CREATE TABLE dbo.lsa_Household(
          RowTotal int NULL,
          Stat int NULL,
          ReturnTime int NULL,
          HHType int NULL,
          HHChronic int NULL,
          HHVet int NULL,
          HHDisability int NULL,
          HHFleeingDV int NULL,
          HoHRace int NULL,
          HoHEthnicity int NULL,
          HHAdult int NULL,
          HHChild int NULL,
          HHNoDOB int NULL,
          HHAdultAge int NULL,
          HHParent int NULL,
          ESTStatus int NULL,
          RRHStatus int NULL,
          RRHMoveIn int NULL,
          PSHStatus int NULL,
          PSHMoveIn int NULL,
          ESDays int NULL,
          THDays int NULL,
          ESTDays int NULL,
          ESTGeography int NULL,
          ESTLivingSit int NULL,
          ESTDestination int NULL,
          RRHPreMoveInDays int NULL,
          RRHPSHPreMoveInDays int NULL,
          RRHHousedDays int NULL,
          SystemDaysNotPSHHoused int NULL,
          RRHGeography int NULL,
          RRHLivingSit int NULL,
          RRHDestination int NULL,
          SystemHomelessDays int NULL,
          Other3917Days int NULL,
          TotalHomelessDays int NULL,
          PSHGeography int NULL,
          PSHLivingSit int NULL,
          PSHDestination int NULL,
          PSHHousedDays int NULL,
          SystemPath int NULL,
          ReportID int NULL
        )
        ;

        if object_id ('lsa_Person') is not null drop table lsa_Person
        CREATE TABLE dbo.lsa_Person(
          RowTotal int NULL,
          Age int NULL,
          Gender int NULL,
          Race int NULL,
          Ethnicity int NULL,
          VetStatus int NULL,
          DisabilityStatus int NULL,
          CHTime int NULL,
          CHTimeStatus int NULL,
          DVStatus int NULL,
          HHTypeEST int NULL,
          HoHEST int NULL,
          HHTypeRRH int NULL,
          HoHRRH int NULL,
          HHTypePSH int NULL,
          HoHPSH int NULL,
          HHChronic int NULL,
          HHVet int NULL,
          HHDisability int NULL,
          HHFleeingDV int NULL,
          HHAdultAge int NULL,
          HHParent int NULL,
          AC3Plus int NULL,
          ReportID int NULL
        )
        ;

        if object_id ('lsa_Report') is not null drop table lsa_Report
        CREATE TABLE dbo.lsa_Report(
          ReportID int NOT NULL,
          ReportDate datetime NOT NULL,
          ReportStart date NOT NULL,
          ReportEnd date NOT NULL,
          ReportCoC varchar(6) NOT NULL,
          SoftwareVendor varchar(50) NOT NULL,
          SoftwareName varchar(50) NOT NULL,
          VendorContact varchar(50) NOT NULL,
          VendorEmail varchar(50) NOT NULL,
          LSAScope int NOT NULL,
          UnduplicatedClient1 int NULL,
          UnduplicatedClient3 int NULL,
          UnduplicatedAdult1 int NULL,
          UnduplicatedAdult3 int NULL,
          AdultHoHEntry1 int NULL,
          AdultHoHEntry3 int NULL,
          ClientEntry1 int NULL,
          ClientEntry3 int NULL,
          ClientExit1 int NULL,
          ClientExit3 int NULL,
          Household1 int NULL,
          Household3 int NULL,
          HoHPermToPH1 int NULL,
          HoHPermToPH3 int NULL,
          NoCoC int NULL,
          SSNNotProvided int NULL,
          SSNMissingOrInvalid int NULL,
          ClientSSNNotUnique int NULL,
          DistinctSSNValueNotUnique int NULL,
          DOB1 int NULL,
          DOB3 int NULL,
          Gender1 int NULL,
          Gender3 int NULL,
          Race1 int NULL,
          Race3 int NULL,
          Ethnicity1 int NULL,
          Ethnicity3 int NULL,
          VetStatus1 int NULL,
          VetStatus3 int NULL,
          RelationshipToHoH1 int NULL,
          RelationshipToHoH3 int NULL,
          DisablingCond1 int NULL,
          DisablingCond3 int NULL,
          LivingSituation1 int NULL,
          LivingSituation3 int NULL,
          LengthOfStay1 int NULL,
          LengthOfStay3 int NULL,
          HomelessDate1 int NULL,
          HomelessDate3 int NULL,
          TimesHomeless1 int NULL,
          TimesHomeless3 int NULL,
          MonthsHomeless1 int NULL,
          MonthsHomeless3 int NULL,
          DV1 int NULL,
          DV3 int NULL,
          Destination1 int NULL,
          Destination3 int NULL,
          NotOneHoH1 int NULL,
          NotOneHoH3 int NULL,
          MoveInDate1 int NULL,
          MoveInDate3 int NULL
        )
        ;
        INSERT [dbo].[lsa_Report] ([ReportID], [ReportDate], [ReportStart], [ReportEnd], [ReportCoC], [SoftwareVendor], [SoftwareName], [VendorContact], [VendorEmail], [LSAScope]) VALUES (1009, CAST(N'2018-05-07T17:47:35.977' AS DateTime), CAST(N'2016-10-01' AS Date), CAST(N'2017-09-30' AS Date), N'XX-500', N'Tamale Inc.', N'Tamale Online', N'Molly', N'molly@squarepegdata.com', 1)

        if object_id ('sys_Enrollment') is not null drop table sys_Enrollment
        CREATE TABLE dbo.sys_Enrollment(
          HoHID varchar(32) NULL,
          HHType int NULL,
          EnrollmentID varchar(32) NULL,
          ProjectType int NULL,
          EntryDate date NULL,
          MoveInDate date NULL,
          ExitDate date NULL,
          Active bit NULL
        )
        ;

        if object_id ('sys_Time') is not null drop table sys_Time
        CREATE TABLE dbo.sys_Time(
          HoHID varchar(32) NOT NULL,
          HHType int NOT NULL,
          sysDate date NOT NULL,
          sysStatus varchar(8) NULL,
          PRIMARY KEY (HoHID,HHType,sysDate)
        )
        ;

        if object_id ('tmp_CohortDates') is not null drop table tmp_CohortDates
        CREATE TABLE dbo.tmp_CohortDates(
          Cohort int NOT NULL,
          CohortStart date NULL,
          CohortEnd date NULL
        )
        ;

        if object_id ('tmp_Exit') is not null drop table tmp_Exit
        CREATE TABLE dbo.tmp_Exit(
          HoHID varchar(32) NOT NULL,
          EnrollmentID varchar(32) NULL,
          EntryDate date NULL,
          ExitDate date NULL,
          ReturnDate date NULL,
          StatEnrollmentID varchar(32) NULL,
          LastInactive date NULL,
          Cohort int NOT NULL,
          Stat int NULL,
          ExitFrom int NOT NULL,
          ExitTo int NOT NULL,
          ReturnTime int NULL,
          HHType int NOT NULL,
          HHVet int NULL,
          HHDisability int NULL,
          HHFleeingDV int NULL,
          HoHRace int NULL,
          HoHEthnicity int NULL,
          HHAdultAge int NULL,
          HHParent int NULL,
          AC3Plus int NULL,
          SystemPath int NULL,
          ReportID int NULL,
          PRIMARY KEY (Cohort, HoHID, HHType)
        )
        ;

        if object_id ('tmp_Household') is not null drop table tmp_Household
        CREATE TABLE dbo.tmp_Household(
          HoHID varchar(32) NOT NULL,
          LastInactive date NULL,
          Stat int NULL,
          StatEnrollmentID varchar(32) NULL,
          ReturnTime int NULL,
          HHType int NOT NULL,
          HHChronic int NULL,
          HHVet int NULL,
          HHDisability int NULL,
          HHFleeingDV int NULL,
          HoHRace int NULL,
          HoHEthnicity int NULL,
          HHAdult int NULL,
          HHChild int NULL,
          HHNoDOB int NULL,
          HHAdultAge int NULL,
          HHParent int NULL,
          ESTStatus int NULL,
          RRHStatus int NULL,
          RRHMoveIn int NULL,
          PSHStatus int NULL,
          PSHMoveIn int NULL,
          ESDays int NULL,
          THDays int NULL,
          ESTDays int NULL,
          ESTGeography int NULL,
          ESTLivingSit int NULL,
          ESTDestination int NULL,
          RRHPreMoveInDays int NULL,
          RRHPSHPreMoveInDays int NULL,
          RRHHousedDays int NULL,
          SystemDaysnotPSHHoused int NULL,
          RRHGeography int NULL,
          RRHLivingSit int NULL,
          RRHDestination int NULL,
          SystemHomelessDays int NULL,
          Other3917Days int NULL,
          TotalHomelessDays int NULL,
          PSHGeography int NULL,
          PSHLivingSit int NULL,
          PSHDestination int NULL,
          PSHHousedDays int NULL,
          SystemPath int NULL,
          ReportID int NULL,
          FirstEntry date NULL,
          LastActive date NULL,
          PRIMARY KEY (HoHID, HHType)
        )
        ;

        if object_id ('tmp_Person') is not null drop table tmp_Person
        CREATE TABLE dbo.tmp_Person(
          PersonalID varchar(32) NOT NULL,
          HoHAdult int NULL,
          LastActive date NULL,
          CHStart date NULL,
          Age int NULL,
          Gender int NULL,
          Race int NULL,
          Ethnicity int NULL,
          VetStatus int NULL,
          DisabilityStatus int NULL,
          CHTime int NULL,
          CHTimeStatus int NULL,
          DVStatus int NULL,
          HHTypeEST int NULL,
          HoHEST int NULL,
          HHTypeRRH int NULL,
          HoHRRH int NULL,
          HHTypePSH int NULL,
          HoHPSH int NULL,
          HHChronic int NULL,
          HHVet int NULL,
          HHDisability int NULL,
          HHFleeingDV int NULL,
          HHAdultAge int NULL,
          HHParent int NULL,
          AC3Plus int NULL,
          ReportID int NULL,
          PRIMARY KEY (PersonalID)
        )
      SQL
    end



    def run_lsa_queries
      Rds.identifier = sql_server_identifier
      Rds.timeout = 600_000
      load 'app/models/report_generators/lsa/fy2018/lsa_queries.rb'
    end
  end
end
