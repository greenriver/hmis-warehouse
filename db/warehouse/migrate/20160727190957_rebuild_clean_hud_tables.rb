class RebuildCleanHudTables < ActiveRecord::Migration[4.2]
  def change
    create_table :data_sources do |t|
      t.string :name
      t.string :file_path
      t.datetime :last_imported_at
      t.date :newest_updated_at
      t.timestamps null: false
    end

    create_table :warehouse_clients do |t|
      t.integer :unduplicated_client_id, index: true
      t.string :id_in_source, index: true, null: false
      t.references :data_source
      t.datetime :proposed_at
      t.datetime :reviewed_at
      t.string :reviewd_by
      t.datetime :approved_at
      t.datetime :rejected_at
      t.timestamps null: false
      t.datetime :deleted_at, index: true, null: true
    end
    add_foreign_key :warehouse_clients, :data_sources

    create_table :warehouse_clients_processed do |t|
      t.references :warehouse_client
      t.string :routine
      t.timestamps null: false
    end

    add_foreign_key :warehouse_clients_processed, :warehouse_clients

    create_table :import_logs do |t|
      t.references :data_source
      t.string :files
      t.text :import_errors
      t.string :summary
      t.datetime :completed_at
      t.timestamps null: false
    end
    add_foreign_key :import_logs, :data_sources

    create_table :warehouse_client_service_history do |t|
      t.integer :unduplicated_client_id, null: false
      t.references :data_source, index: true
      t.date :date, index: true, null: false
      t.date :first_date_in_program, index: true, null: false
      t.date :last_date_in_program, index: true
      t.string :enrollment_group_id # ProjectEntryID
      t.integer :age
      t.integer :destination
      t.string :head_of_household_id
      t.string :household_id
      t.string :project_id
      t.string :project_name
      t.integer :project_type, index: true
      t.integer :project_tracking_method
      t.string :organization_id
      t.string :record_type, null: false, index: true
      t.integer :housing_status_at_entry
      t.integer :housing_status_at_exit
    end
    add_index :warehouse_client_service_history, :unduplicated_client_id, name: :index_service_history_on_client_id

    create_table 'Client', id: false do |t|
      t.string 'PersonalID'#, index: true
      t.string 'FirstName', limit: 150#, index: true
      t.string 'MiddleName', limit: 150
      t.string 'LastName', limit: 150#, index: true
      t.string 'NameSuffix', limit: 50
      t.integer 'NameDataQuality'
      t.string 'SSN', limit: 9
      t.integer 'SSNDataQuality'
      t.date 'DOB'
      t.integer 'DOBDataQuality'
      t.integer 'AmIndAKNative'
      t.integer 'Asian'
      t.integer 'BlackAfAmerican'
      t.integer 'NativeHIOtherPacific'
      t.integer 'White'
      t.integer 'RaceNone'
      t.integer 'Ethnicity'
      t.integer 'Gender'
      t.string 'OtherGender', limit: 50
      t.integer 'VeteranStatus'
      t.integer 'YearEnteredService'
      t.integer 'YearSeparated'
      t.integer 'WorldWarII'
      t.integer 'KoreanWar'
      t.integer 'VietnamWar'
      t.integer 'DesertStorm'
      t.integer 'AfghanistanOEF'
      t.integer 'IraqOIF'
      t.integer 'IraqOND'
      t.integer 'OtherTheater'
      t.integer 'MilitaryBranch'
      t.integer 'DischargeStatus'
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID'
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end

    add_index 'Client', 'PersonalID', name: 'client_personal_id'
    add_index 'Client', 'FirstName', name: 'client_first_name'
    add_index 'Client', 'LastName', name: 'client_last_name'
    add_index 'Client', 'DateCreated', name: 'client_date_created'
    add_index 'Client', 'DateUpdated', name: 'client_date_updated'
    add_index 'Client', 'ExportID', name: 'client_export_id'

    create_table 'Affiliation', id: false do |t|
      t.string 'AffiliationID'
      t.string 'ProjectID'
      t.string 'ResProjectID'
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID', limit: 100
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end
    add_index 'Affiliation', 'DateCreated', name: 'affiliation_date_created'
    add_index 'Affiliation', 'DateUpdated', name: 'affiliation_date_updated'
    add_index 'Affiliation', 'ExportID', name: 'affiliation_export_id'

    create_table 'Disabilities', id: false do |t|
      t.string 'DisabilitiesID'
      t.string 'ProjectEntryID'
      t.string 'PersonalID'
      t.date 'InformationDate'
      t.integer 'DisabilityType'
      t.integer 'DisabilityResponse'
      t.integer 'IndefiniteAndImpairs'
      t.integer 'DocumentationOnFile'
      t.integer 'ReceivingServices'
      t.integer 'PATHHowConfirmed'
      t.integer 'PATHSMIInformation'
      t.integer 'TCellCountAvailable'
      t.integer 'TCellCount'
      t.integer 'TCellSource'
      t.integer 'ViralLoadAvailable'
      t.integer 'ViralLoad'
      t.integer 'ViralLoadSource'
      t.integer 'DataCollectionStage'
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID', limit: 100
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end
    add_index 'Disabilities', 'DateCreated', name: 'disabilities_date_created'
    add_index 'Disabilities', 'DateUpdated', name: 'disabilities_date_updated'
    add_index 'Disabilities', 'ExportID', name: 'disabilities_export_id'

    create_table 'EmploymentEducation', id: false do |t|
      t.string 'EmploymentEducationID'
      t.string 'ProjectEntryID'
      t.string 'PersonalID'
      t.date 'InformationDate'
      t.integer 'LastGradeCompleted'
      t.integer 'SchoolStatus'
      t.integer 'Employed'
      t.integer 'EmploymentType'
      t.integer 'NotEmployedReason'
      t.integer 'DataCollectionStage'
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID', limit: 100
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end
    add_index 'EmploymentEducation', 'DateCreated', name: 'employment_education_date_created'
    add_index 'EmploymentEducation', 'DateUpdated', name: 'employment_education_date_updated'
    add_index 'EmploymentEducation', 'ExportID', name: 'employment_education_export_id'

    create_table 'Enrollment', id: false do |t|
      t.string 'ProjectEntryID'
      t.string 'PersonalID'
      t.string 'ProjectID'
      t.date 'EntryDate'
      t.string 'HouseholdID'
      t.integer 'RelationshipToHoH'
      t.integer 'ResidencePrior'
      t.string 'OtherResidencePrior'
      t.integer 'ResidencePriorLengthOfStay'
      t.integer 'DisablingCondition'
      t.integer 'EntryFromStreetESSH'
      t.date 'DateToStreetESSH'
      t.integer 'ContinuouslyHomelessOneYear' # removed in HUD Spec 4.1
      t.integer 'TimesHomelessPastThreeYears'
      t.integer 'MonthsHomelessPastThreeYears'
      t.integer 'MonthsHomelessThisTime' # removed in HUD Spec 4.1
      t.integer 'StatusDocumented' # removed in HUD Spec 4.1
      t.integer 'HousingStatus'
      t.date 'DateOfEngagement'
      t.integer 'InPermanentHousing'
      t.date 'ResidentialMoveInDate'
      t.date 'DateOfPATHStatus'
      t.integer 'ClientEnrolledInPATH'
      t.integer 'ReasonNotEnrolled'
      t.integer 'WorstHousingSituation'
      t.integer 'PercentAMI'
      t.string 'LastPermanentStreet'
      t.integer 'LastPermanentCity'
      t.string 'LastPermanentState', limit: 2
      t.string 'LastPermanentZIP', limit: 10
      t.integer 'AddressDataQuality'
      t.date 'DateOfBCPStatus'
      t.integer 'FYSBYouth'
      t.integer 'ReasonNoServices'
      t.integer 'SexualOrientation'
      t.integer 'FormerWardChildWelfare'
      t.integer 'ChildWelfareYears'
      t.integer 'ChildWelfareMonths'
      t.integer 'FormerWardJuvenileJustice'
      t.integer 'JuvenileJusticeYears'
      t.integer 'JuvenileJusticeMonths'
      t.integer 'HouseholdDynamics'
      t.integer 'SexualOrientationGenderIDYouth'
      t.integer 'SexualOrientationGenderIDFam'
      t.integer 'HousingIssuesYouth'
      t.integer 'HousingIssuesFam'
      t.integer 'SchoolEducationalIssuesYouth'
      t.integer 'SchoolEducationalIssuesFam'
      t.integer 'UnemploymentYouth'
      t.integer 'UnemploymentFam'
      t.integer 'MentalHealthIssuesYouth'
      t.integer 'MentalHealthIssuesFam'
      t.integer 'HealthIssuesYouth'
      t.integer 'HealthIssuesFam'
      t.integer 'PhysicalDisabilityYouth'
      t.integer 'PhysicalDisabilityFam'
      t.integer 'MentalDisabilityYouth'
      t.integer 'MentalDisabilityFam'
      t.integer 'AbuseAndNeglectYouth'
      t.integer 'AbuseAndNeglectFam'
      t.integer 'AlcoholDrugAbuseYouth'
      t.integer 'AlcoholDrugAbuseFam'
      t.integer 'InsufficientIncome'
      t.integer 'ActiveMilitaryParent'
      t.integer 'IncarceratedParent'
      t.integer 'IncarceratedParentStatus'
      t.integer 'ReferralSource'
      t.integer 'CountOutreachReferralApproaches'
      t.integer 'ExchangeForSex'
      t.integer 'ExchangeForSexPastThreeMonths'
      t.integer 'CountOfExchangeForSex'
      t.integer 'AskedOrForcedToExchangeForSex'
      t.integer 'AskedOrForcedToExchangeForSexPastThreeMonths'
      t.integer 'WorkPlaceViolenceThreats'
      t.integer 'WorkplacePromiseDifference'
      t.integer 'CoercedToContinueWork'
      t.integer 'LaborExploitPastThreeMonths'
      t.integer 'HPScreeningScore'
      t.integer 'VAMCStation'
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID', limit: 100
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end
    add_index 'Enrollment', 'DateCreated', name: 'enrollment_date_created'
    add_index 'Enrollment', 'DateUpdated', name: 'enrollment_date_updated'
    add_index 'Enrollment', 'ExportID', name: 'enrollment_export_id'

    create_table 'EnrollmentCoC', id: false do |t|
      t.string 'EnrollmentCoCID', index: true
      t.string 'ProjectEntryID'
      t.string 'ProjectID'
      t.string 'PersonalID'
      t.date 'InformationDate'
      t.string 'CoCCode', limit: 50
      t.integer 'DataCollectionStage'
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID', limit: 100
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end
    add_index 'EnrollmentCoC', 'DateCreated', name: 'enrollment_coc_date_created'
    add_index 'EnrollmentCoC', 'DateUpdated', name: 'enrollment_coc_date_updated'
    add_index 'EnrollmentCoC', 'ExportID', name: 'enrollment_coc_export_id'

    create_table 'Exit', id: false do |t|
      t.string 'ExitID'
      t.string 'ProjectEntryID'
      t.string 'PersonalID'
      t.date 'ExitDate'
      t.integer 'Destination'
      t.string 'OtherDestination'
      t.integer 'AssessmentDisposition'
      t.string 'OtherDisposition'
      t.integer 'HousingAssessment'
      t.integer 'SubsidyInformation'
      t.integer 'ConnectionWithSOAR'
      t.integer 'WrittenAftercarePlan'
      t.integer 'AssistanceMainstreamBenefits'
      t.integer 'PermanentHousingPlacement'
      t.integer 'TemporaryShelterPlacement'
      t.integer 'ExitCounseling'
      t.integer 'FurtherFollowUpServices'
      t.integer 'ScheduledFollowUpContacts'
      t.integer 'ResourcePackage'
      t.integer 'OtherAftercarePlanOrAction'
      t.integer 'ProjectCompletionStatus'
      t.integer 'EarlyExitReason'
      t.integer 'FamilyReunificationAchieved'
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID', limit: 100
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end
    add_index 'Exit', 'DateCreated', name: 'exit_date_created'
    add_index 'Exit', 'DateUpdated', name: 'exit_date_updated'
    add_index 'Exit', 'ExportID', name: 'exit_export_id'

    create_table 'Export', id: false do |t|
      t.string 'ExportID'
      t.string 'SourceID'
      t.string 'SourceName'
      t.string 'SourceContactFirst'
      t.string 'SourceContactLast'
      t.string 'SourceContactPhone'
      t.string 'SourceContactExtension'
      t.string 'SourceContactEmail'
      t.datetime 'ExportDate'
      t.date 'ExportStartDate'
      t.date 'ExportEndDate'
      t.string 'SoftwareName'
      t.string 'SoftwareVersion'
      t.integer 'ExportPeriodType'
      t.integer 'ExportDirective'
      t.integer 'HashStatus'
      t.references :data_source, index: true
    end

    add_index 'Export', 'ExportID', name: 'export_export_id'

    create_table 'Funder', id: false do |t|
      t.string 'FunderID'
      t.string 'ProjectID'
      t.string 'Funder'
      t.string 'GrantID'
      t.date 'StartDate'
      t.date 'EndDate'
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID', limit: 100
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end
    add_index 'Funder', 'DateCreated', name: 'funder_date_created'
    add_index 'Funder', 'DateUpdated', name: 'funder_date_updated'
    add_index 'Funder', 'ExportID', name: 'funder_export_id'

    create_table 'HealthAndDV', id: false do |t|
      t.string 'HealthAndDVID'
      t.string 'ProjectEntryID'
      t.string 'PersonalID'
      t.date 'InformationDate'
      t.integer 'DomesticViolenceVictim'
      t.integer 'WhenOccurred'
      t.integer 'CurrentlyFleeing'
      t.integer 'GeneralHealthStatus'
      t.integer 'DentalHealthStatus'
      t.integer 'MentalHealthStatus'
      t.integer 'PregnancyStatus'
      t.date 'DueDate'
      t.integer 'DataCollectionStage'
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID', limit: 100
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end
    add_index 'HealthAndDV', 'DateCreated', name: 'health_and_dv_date_created'
    add_index 'HealthAndDV', 'DateUpdated', name: 'health_and_dv_date_updated'
    add_index 'HealthAndDV', 'ExportID', name: 'health_and_dv_export_id'

    create_table 'IncomeBenefits', id: false do |t|
      t.string 'IncomeBenefitsID'
      t.string 'ProjectEntryID'
      t.string 'PersonalID'
      t.date 'InformationDate'
      t.integer 'IncomeFromAnySource'
      t.decimal 'TotalMonthlyIncome'
      t.integer 'Earned'
      t.decimal 'EarnedAmount'
      t.integer 'Unemployment'
      t.decimal 'UnemploymentAmount'
      t.integer 'SSI'
      t.decimal 'SSIAmount'
      t.integer 'SSDI'
      t.decimal 'SSDIAmount'
      t.integer 'VADisabilityService'
      t.decimal 'VADisabilityServiceAmount'
      t.integer 'VADisabilityNonService'
      t.decimal 'VADisabilityNonServiceAmount'
      t.integer 'PrivateDisability'
      t.decimal 'PrivateDisabilityAmount'
      t.integer 'WorkersComp'
      t.decimal 'WorkersCompAmount'
      t.integer 'TANF'
      t.decimal 'TANFAmount'
      t.integer 'GA'
      t.decimal 'GAAmount'
      t.integer 'SocSecRetirement'
      t.decimal 'SocSecRetirementAmount'
      t.integer 'Pension'
      t.decimal 'PensionAmount'
      t.integer 'ChildSupport'
      t.decimal 'ChildSupportAmount'
      t.integer 'Alimony'
      t.decimal 'AlimonyAmount'
      t.integer 'OtherIncomeSource'
      t.decimal 'OtherIncomeAmount'
      t.string 'OtherIncomeSourceIdentify'
      t.integer 'BenefitsFromAnySource'
      t.integer 'SNAP'
      t.integer 'WIC'
      t.integer 'TANFChildCare'
      t.integer 'TANFTransportation'
      t.integer 'OtherTANF'
      t.integer 'RentalAssistanceOngoing'
      t.integer 'RentalAssistanceTemp'
      t.integer 'OtherBenefitsSource'
      t.string 'OtherBenefitsSourceIdentify'
      t.integer 'InsuranceFromAnySource'
      t.integer 'Medicaid'
      t.integer 'NoMedicaidReason'
      t.integer 'Medicare'
      t.integer 'NoMedicareReason'
      t.integer 'SCHIP'
      t.integer 'NoSCHIPReason'
      t.integer 'VAMedicalServices'
      t.integer 'NoVAMedReason'
      t.integer 'EmployerProvided'
      t.integer 'NoEmployerProvidedReason'
      t.integer 'COBRA'
      t.integer 'NoCOBRAReason'
      t.integer 'PrivatePay'
      t.integer 'NoPrivatePayReason'
      t.integer 'StateHealthIns'
      t.integer 'NoStateHealthInsReason'
      t.integer 'HIVAIDSAssistance'
      t.integer 'NoHIVAIDSAssistanceReason'
      t.integer 'ADAP'
      t.integer 'NoADAPReason'
      t.integer 'DataCollectionStage'
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID', limit: 100
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end
    add_index 'IncomeBenefits', 'DateCreated', name: 'income_benefits_date_created'
    add_index 'IncomeBenefits', 'DateUpdated', name: 'income_benefits_date_updated'
    add_index 'IncomeBenefits', 'ExportID', name: 'income_benefits_export_id'

    create_table 'Inventory', id: false do |t|
      t.string 'InventoryID'
      t.string 'ProjectID'
      t.string 'CoCCode', limit: 50
      t.date 'InformationDate'
      t.integer 'HouseholdType'
      t.integer 'BedType'
      t.integer 'Availability'
      t.integer 'UnitInventory'
      t.integer 'BedInventory'
      t.integer 'CHBedInventory'
      t.integer 'VetBedInventory'
      t.integer 'YouthBedInventory'
      t.integer 'YouthAgeGroup'
      t.date 'InventoryStartDate'
      t.date 'InventoryEndDate'
      t.integer 'HMISParticipatingBeds'
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID', limit: 100
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end
    add_index 'Inventory', 'DateCreated', name: 'inventory_date_created'
    add_index 'Inventory', 'DateUpdated', name: 'inventory_date_updated'
    add_index 'Inventory', 'ExportID', name: 'inventory_export_id'

    create_table 'Organization', id: false do |t|
      t.string 'OrganizationID'
      t.string 'OrganizationName'
      t.string 'OrganizationCommonName'
      # t.integer 'DateCreated'
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID', limit: 100
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end
    add_index 'Organization', 'ExportID', name: 'organization_export_id'

    create_table 'Project', id: false do |t|
      t.string 'ProjectID'
      t.string 'OrganizationID'
      t.string 'ProjectName'
      t.string 'ProjectCommonName'
      t.integer 'ContinuumProject'
      t.integer 'ProjectType'
      t.integer 'ResidentialAffiliation'
      t.integer 'TrackingMethod'
      t.integer 'TargetPopulation'
      t.integer 'PITCount'
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID', limit: 100
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end
    add_index 'Project', 'DateCreated', name: 'project_date_created'
    add_index 'Project', 'DateUpdated', name: 'project_date_updated'
    add_index 'Project', 'ExportID', name: 'project_export_id'

    create_table 'ProjectCoC', id: false do |t|
      t.string 'ProjectCoCID', limit: 50
      t.string 'ProjectID'
      t.string 'CoCCode', limit: 50
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID', limit: 100
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end
    add_index 'ProjectCoC', 'DateCreated', name: 'project_coc_date_created'
    add_index 'ProjectCoC', 'DateUpdated', name: 'project_coc_date_updated'
    add_index 'ProjectCoC', 'ExportID', name: 'project_coc_export_id'

    create_table 'Services', id: false do |t|
      t.string 'ServicesID'
      t.string 'ProjectEntryID'
      t.string 'PersonalID'
      t.date 'DateProvided'
      t.integer 'RecordType'
      t.integer 'TypeProvided'
      t.string 'OtherTypeProvided'
      t.integer 'SubTypeProvided'
      t.decimal 'FAAmount'
      t.integer 'ReferralOutcome'
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID', limit: 100
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end
    add_index 'Services', 'DateCreated', name: 'services_date_created'
    add_index 'Services', 'DateUpdated', name: 'services_date_updated'
    add_index 'Services', 'ExportID', name: 'services_export_id'

    create_table 'Site', id: false do |t|
      t.string 'SiteID'
      t.string 'ProjectID'
      t.string 'CoCCode', limit: 50
      t.integer 'PrincipalSite'
      t.string 'Geocode', limit: 50
      t.string 'Address'
      t.string 'City'
      t.string 'State', limit: 2
      t.string 'ZIP', limit: 10
      t.datetime 'DateCreated'
      t.datetime 'DateUpdated'
      t.string 'UserID', limit: 100
      t.datetime 'DateDeleted'
      t.string 'ExportID'
      t.references :data_source, index: true
    end
    add_index 'Site', 'DateCreated', name: 'site_date_created'
    add_index 'Site', 'DateUpdated', name: 'site_date_updated'
    add_index 'Site', 'ExportID', name: 'site_export_id'

    add_foreign_key 'Client', :data_sources, column: :data_source_id, primary_key: :id
    add_foreign_key 'Affiliation', :data_sources, column: :data_source_id, primary_key: :id
    add_foreign_key 'Disabilities', :data_sources, column: :data_source_id, primary_key: :id
    add_foreign_key 'EmploymentEducation', :data_sources, column: :data_source_id, primary_key: :id
    add_foreign_key 'Enrollment', :data_sources, column: :data_source_id, primary_key: :id
    add_foreign_key 'EnrollmentCoC', :data_sources, column: :data_source_id, primary_key: :id
    add_foreign_key 'Exit', :data_sources, column: :data_source_id, primary_key: :id
    add_foreign_key 'Funder', :data_sources, column: :data_source_id, primary_key: :id
    add_foreign_key 'HealthAndDV', :data_sources, column: :data_source_id, primary_key: :id
    add_foreign_key 'IncomeBenefits', :data_sources, column: :data_source_id, primary_key: :id
    add_foreign_key 'Inventory', :data_sources, column: :data_source_id, primary_key: :id
    add_foreign_key 'Organization', :data_sources, column: :data_source_id, primary_key: :id
    add_foreign_key 'Project', :data_sources, column: :data_source_id, primary_key: :id
    add_foreign_key 'ProjectCoC', :data_sources, column: :data_source_id, primary_key: :id
    add_foreign_key 'Services', :data_sources, column: :data_source_id, primary_key: :id
    add_foreign_key 'Site', :data_sources, column: :data_source_id, primary_key: :id

  end
end
