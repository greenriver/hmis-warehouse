# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180605164543) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "fuzzystrmatch"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"

  create_table "Affiliation", force: :cascade do |t|
    t.string   "AffiliationID"
    t.string   "ProjectID"
    t.string   "ResProjectID"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",         limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
  end

  add_index "Affiliation", ["DateCreated"], name: "affiliation_date_created", using: :btree
  add_index "Affiliation", ["DateUpdated"], name: "affiliation_date_updated", using: :btree
  add_index "Affiliation", ["ExportID"], name: "affiliation_export_id", using: :btree
  add_index "Affiliation", ["data_source_id", "AffiliationID"], name: "unk_Affiliation", unique: true, using: :btree
  add_index "Affiliation", ["data_source_id"], name: "index_Affiliation_on_data_source_id", using: :btree

  create_table "Client", force: :cascade do |t|
    t.string   "PersonalID"
    t.string   "FirstName",                              limit: 150
    t.string   "MiddleName",                             limit: 150
    t.string   "LastName",                               limit: 150
    t.string   "NameSuffix",                             limit: 50
    t.integer  "NameDataQuality"
    t.string   "SSN",                                    limit: 9
    t.integer  "SSNDataQuality"
    t.date     "DOB"
    t.integer  "DOBDataQuality"
    t.integer  "AmIndAKNative"
    t.integer  "Asian"
    t.integer  "BlackAfAmerican"
    t.integer  "NativeHIOtherPacific"
    t.integer  "White"
    t.integer  "RaceNone"
    t.integer  "Ethnicity"
    t.integer  "Gender"
    t.string   "OtherGender",                            limit: 50
    t.integer  "VeteranStatus"
    t.integer  "YearEnteredService"
    t.integer  "YearSeparated"
    t.integer  "WorldWarII"
    t.integer  "KoreanWar"
    t.integer  "VietnamWar"
    t.integer  "DesertStorm"
    t.integer  "AfghanistanOEF"
    t.integer  "IraqOIF"
    t.integer  "IraqOND"
    t.integer  "OtherTheater"
    t.integer  "MilitaryBranch"
    t.integer  "DischargeStatus"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID"
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
    t.datetime "disability_verified_on"
    t.datetime "housing_assistance_network_released_on"
    t.boolean  "sync_with_cas",                                      default: false, null: false
    t.boolean  "dmh_eligible",                                       default: false, null: false
    t.boolean  "va_eligible",                                        default: false, null: false
    t.boolean  "hues_eligible",                                      default: false, null: false
    t.boolean  "hiv_positive",                                       default: false, null: false
    t.string   "housing_release_status"
    t.boolean  "chronically_homeless_for_cas",                       default: false, null: false
    t.boolean  "us_citizen",                                         default: false, null: false
    t.boolean  "asylee",                                             default: false, null: false
    t.boolean  "ineligible_immigrant",                               default: false, null: false
    t.boolean  "lifetime_sex_offender",                              default: false, null: false
    t.boolean  "meth_production_conviction",                         default: false, null: false
    t.boolean  "family_member",                                      default: false, null: false
    t.boolean  "child_in_household",                                 default: false, null: false
    t.boolean  "ha_eligible",                                        default: false, null: false
    t.boolean  "api_update_in_process",                              default: false, null: false
    t.datetime "api_update_started_at"
    t.datetime "api_last_updated_at"
    t.integer  "creator_id"
    t.boolean  "cspech_eligible",                                    default: false
    t.date     "consent_form_signed_on"
    t.integer  "vispdat_prioritization_days_homeless"
    t.boolean  "generate_history_pdf",                               default: false
    t.boolean  "congregate_housing",                                 default: false
    t.boolean  "sober_housing",                                      default: false
    t.integer  "consent_form_id"
    t.integer  "rrh_assessment_score"
    t.boolean  "ssvf_eligible",                                      default: false, null: false
    t.boolean  "rrh_desired",                                        default: false, null: false
    t.boolean  "youth_rrh_desired",                                  default: false, null: false
    t.string   "rrh_assessment_contact_info"
    t.datetime "rrh_assessment_collected_at"
  end

  add_index "Client", ["DateCreated"], name: "client_date_created", using: :btree
  add_index "Client", ["DateUpdated"], name: "client_date_updated", using: :btree
  add_index "Client", ["ExportID"], name: "client_export_id", using: :btree
  add_index "Client", ["FirstName"], name: "client_first_name", using: :btree
  add_index "Client", ["LastName"], name: "client_last_name", using: :btree
  add_index "Client", ["PersonalID"], name: "client_personal_id", using: :btree
  add_index "Client", ["creator_id"], name: "index_Client_on_creator_id", using: :btree
  add_index "Client", ["data_source_id"], name: "index_Client_on_data_source_id", using: :btree

  create_table "Disabilities", force: :cascade do |t|
    t.string   "DisabilitiesID"
    t.string   "ProjectEntryID"
    t.string   "PersonalID"
    t.date     "InformationDate"
    t.integer  "DisabilityType"
    t.integer  "DisabilityResponse"
    t.integer  "IndefiniteAndImpairs"
    t.integer  "DocumentationOnFile"
    t.integer  "ReceivingServices"
    t.integer  "PATHHowConfirmed"
    t.integer  "PATHSMIInformation"
    t.integer  "TCellCountAvailable"
    t.integer  "TCellCount"
    t.integer  "TCellSource"
    t.integer  "ViralLoadAvailable"
    t.integer  "ViralLoad"
    t.integer  "ViralLoadSource"
    t.integer  "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",               limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
  end

  add_index "Disabilities", ["DateCreated"], name: "disabilities_date_created", using: :btree
  add_index "Disabilities", ["DateUpdated"], name: "disabilities_date_updated", using: :btree
  add_index "Disabilities", ["ExportID"], name: "disabilities_export_id", using: :btree
  add_index "Disabilities", ["PersonalID"], name: "index_Disabilities_on_PersonalID", using: :btree
  add_index "Disabilities", ["ProjectEntryID"], name: "index_Disabilities_on_ProjectEntryID", using: :btree
  add_index "Disabilities", ["data_source_id", "DisabilitiesID"], name: "unk_Disabilities", unique: true, using: :btree
  add_index "Disabilities", ["data_source_id", "PersonalID"], name: "index_Disabilities_on_data_source_id_PersonalID", using: :btree
  add_index "Disabilities", ["data_source_id"], name: "index_Disabilities_on_data_source_id", using: :btree

  create_table "EmploymentEducation", force: :cascade do |t|
    t.string   "EmploymentEducationID"
    t.string   "ProjectEntryID"
    t.string   "PersonalID"
    t.date     "InformationDate"
    t.integer  "LastGradeCompleted"
    t.integer  "SchoolStatus"
    t.integer  "Employed"
    t.integer  "EmploymentType"
    t.integer  "NotEmployedReason"
    t.integer  "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
  end

  add_index "EmploymentEducation", ["DateCreated"], name: "employment_education_date_created", using: :btree
  add_index "EmploymentEducation", ["DateUpdated"], name: "employment_education_date_updated", using: :btree
  add_index "EmploymentEducation", ["ExportID"], name: "employment_education_export_id", using: :btree
  add_index "EmploymentEducation", ["PersonalID"], name: "index_EmploymentEducation_on_PersonalID", using: :btree
  add_index "EmploymentEducation", ["ProjectEntryID"], name: "index_EmploymentEducation_on_ProjectEntryID", using: :btree
  add_index "EmploymentEducation", ["data_source_id", "EmploymentEducationID"], name: "unk_EmploymentEducation", unique: true, using: :btree
  add_index "EmploymentEducation", ["data_source_id", "PersonalID"], name: "index_EmploymentEducation_on_data_source_id_PersonalID", using: :btree
  add_index "EmploymentEducation", ["data_source_id"], name: "index_EmploymentEducation_on_data_source_id", using: :btree

  create_table "Enrollment", force: :cascade do |t|
    t.string   "ProjectEntryID",                               limit: 50
    t.string   "PersonalID"
    t.string   "ProjectID",                                    limit: 50
    t.date     "EntryDate"
    t.string   "HouseholdID"
    t.integer  "RelationshipToHoH"
    t.integer  "ResidencePrior"
    t.string   "OtherResidencePrior"
    t.integer  "ResidencePriorLengthOfStay"
    t.integer  "DisablingCondition"
    t.integer  "EntryFromStreetESSH"
    t.date     "DateToStreetESSH"
    t.integer  "ContinuouslyHomelessOneYear"
    t.integer  "TimesHomelessPastThreeYears"
    t.integer  "MonthsHomelessPastThreeYears"
    t.integer  "MonthsHomelessThisTime"
    t.integer  "StatusDocumented"
    t.integer  "HousingStatus"
    t.date     "DateOfEngagement"
    t.integer  "InPermanentHousing"
    t.date     "ResidentialMoveInDate"
    t.date     "DateOfPATHStatus"
    t.integer  "ClientEnrolledInPATH"
    t.integer  "ReasonNotEnrolled"
    t.integer  "WorstHousingSituation"
    t.integer  "PercentAMI"
    t.string   "LastPermanentStreet"
    t.string   "LastPermanentCity",                            limit: 50
    t.string   "LastPermanentState",                           limit: 2
    t.string   "LastPermanentZIP",                             limit: 10
    t.integer  "AddressDataQuality"
    t.date     "DateOfBCPStatus"
    t.integer  "FYSBYouth"
    t.integer  "ReasonNoServices"
    t.integer  "SexualOrientation"
    t.integer  "FormerWardChildWelfare"
    t.integer  "ChildWelfareYears"
    t.integer  "ChildWelfareMonths"
    t.integer  "FormerWardJuvenileJustice"
    t.integer  "JuvenileJusticeYears"
    t.integer  "JuvenileJusticeMonths"
    t.integer  "HouseholdDynamics"
    t.integer  "SexualOrientationGenderIDYouth"
    t.integer  "SexualOrientationGenderIDFam"
    t.integer  "HousingIssuesYouth"
    t.integer  "HousingIssuesFam"
    t.integer  "SchoolEducationalIssuesYouth"
    t.integer  "SchoolEducationalIssuesFam"
    t.integer  "UnemploymentYouth"
    t.integer  "UnemploymentFam"
    t.integer  "MentalHealthIssuesYouth"
    t.integer  "MentalHealthIssuesFam"
    t.integer  "HealthIssuesYouth"
    t.integer  "HealthIssuesFam"
    t.integer  "PhysicalDisabilityYouth"
    t.integer  "PhysicalDisabilityFam"
    t.integer  "MentalDisabilityYouth"
    t.integer  "MentalDisabilityFam"
    t.integer  "AbuseAndNeglectYouth"
    t.integer  "AbuseAndNeglectFam"
    t.integer  "AlcoholDrugAbuseYouth"
    t.integer  "AlcoholDrugAbuseFam"
    t.integer  "InsufficientIncome"
    t.integer  "ActiveMilitaryParent"
    t.integer  "IncarceratedParent"
    t.integer  "IncarceratedParentStatus"
    t.integer  "ReferralSource"
    t.integer  "CountOutreachReferralApproaches"
    t.integer  "ExchangeForSex"
    t.integer  "ExchangeForSexPastThreeMonths"
    t.integer  "CountOfExchangeForSex"
    t.integer  "AskedOrForcedToExchangeForSex"
    t.integer  "AskedOrForcedToExchangeForSexPastThreeMonths"
    t.integer  "WorkPlaceViolenceThreats"
    t.integer  "WorkplacePromiseDifference"
    t.integer  "CoercedToContinueWork"
    t.integer  "LaborExploitPastThreeMonths"
    t.integer  "HPScreeningScore"
    t.integer  "VAMCStation"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                                       limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
    t.integer  "LOSUnderThreshold"
    t.integer  "PreviousStreetESSH"
    t.integer  "UrgentReferral"
    t.integer  "TimeToHousingLoss"
    t.integer  "ZeroIncome"
    t.integer  "AnnualPercentAMI"
    t.integer  "FinancialChange"
    t.integer  "HouseholdChange"
    t.integer  "EvictionHistory"
    t.integer  "SubsidyAtRisk"
    t.integer  "LiteralHomelessHistory"
    t.integer  "DisabledHoH"
    t.integer  "CriminalRecord"
    t.integer  "SexOffender"
    t.integer  "DependentUnder6"
    t.integer  "SingleParent"
    t.integer  "HH5Plus"
    t.integer  "IraqAfghanistan"
    t.integer  "FemVet"
    t.integer  "ThresholdScore"
    t.integer  "ERVisits"
    t.integer  "JailNights"
    t.integer  "HospitalNights"
    t.integer  "RunawayYouth"
    t.string   "processed_hash"
    t.string   "processed_as"
    t.boolean  "roi_permission"
    t.string   "last_locality"
    t.string   "last_zipcode"
  end

  add_index "Enrollment", ["DateCreated"], name: "enrollment_date_created", using: :btree
  add_index "Enrollment", ["DateDeleted"], name: "index_Enrollment_on_DateDeleted", using: :btree
  add_index "Enrollment", ["DateUpdated"], name: "enrollment_date_updated", using: :btree
  add_index "Enrollment", ["EntryDate"], name: "index_Enrollment_on_EntryDate", using: :btree
  add_index "Enrollment", ["ExportID"], name: "enrollment_export_id", using: :btree
  add_index "Enrollment", ["PersonalID"], name: "index_Enrollment_on_PersonalID", using: :btree
  add_index "Enrollment", ["ProjectEntryID"], name: "index_Enrollment_on_ProjectEntryID", using: :btree
  add_index "Enrollment", ["ProjectID"], name: "index_Enrollment_on_ProjectID", using: :btree
  add_index "Enrollment", ["data_source_id", "PersonalID"], name: "index_Enrollment_on_data_source_id_PersonalID", using: :btree
  add_index "Enrollment", ["data_source_id", "ProjectEntryID", "PersonalID"], name: "unk_Enrollment", unique: true, using: :btree
  add_index "Enrollment", ["data_source_id"], name: "index_Enrollment_on_data_source_id", using: :btree

  create_table "EnrollmentCoC", force: :cascade do |t|
    t.string   "EnrollmentCoCID"
    t.string   "ProjectEntryID"
    t.string   "ProjectID"
    t.string   "PersonalID"
    t.date     "InformationDate"
    t.string   "CoCCode",             limit: 50
    t.integer  "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",              limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
    t.string   "HouseholdID",         limit: 32
  end

  add_index "EnrollmentCoC", ["DateCreated"], name: "enrollment_coc_date_created", using: :btree
  add_index "EnrollmentCoC", ["DateUpdated"], name: "enrollment_coc_date_updated", using: :btree
  add_index "EnrollmentCoC", ["EnrollmentCoCID"], name: "index_EnrollmentCoC_on_EnrollmentCoCID", using: :btree
  add_index "EnrollmentCoC", ["ExportID"], name: "enrollment_coc_export_id", using: :btree
  add_index "EnrollmentCoC", ["data_source_id", "PersonalID"], name: "index_EnrollmentCoC_on_data_source_id_PersonalID", using: :btree
  add_index "EnrollmentCoC", ["data_source_id"], name: "index_EnrollmentCoC_on_data_source_id", using: :btree

  create_table "Exit", force: :cascade do |t|
    t.string   "ExitID"
    t.string   "ProjectEntryID"
    t.string   "PersonalID"
    t.date     "ExitDate"
    t.integer  "Destination"
    t.string   "OtherDestination"
    t.integer  "AssessmentDisposition"
    t.string   "OtherDisposition"
    t.integer  "HousingAssessment"
    t.integer  "SubsidyInformation"
    t.integer  "ConnectionWithSOAR"
    t.integer  "WrittenAftercarePlan"
    t.integer  "AssistanceMainstreamBenefits"
    t.integer  "PermanentHousingPlacement"
    t.integer  "TemporaryShelterPlacement"
    t.integer  "ExitCounseling"
    t.integer  "FurtherFollowUpServices"
    t.integer  "ScheduledFollowUpContacts"
    t.integer  "ResourcePackage"
    t.integer  "OtherAftercarePlanOrAction"
    t.integer  "ProjectCompletionStatus"
    t.integer  "EarlyExitReason"
    t.integer  "FamilyReunificationAchieved"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                                       limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
    t.integer  "ExchangeForSex"
    t.integer  "ExchangeForSexPastThreeMonths"
    t.integer  "CountOfExchangeForSex"
    t.integer  "AskedOrForcedToExchangeForSex"
    t.integer  "AskedOrForcedToExchangeForSexPastThreeMonths"
    t.integer  "WorkPlaceViolenceThreats"
    t.integer  "WorkplacePromiseDifference"
    t.integer  "CoercedToContinueWork"
    t.integer  "LaborExploitPastThreeMonths"
    t.integer  "CounselingReceived"
    t.integer  "IndividualCounseling"
    t.integer  "FamilyCounseling"
    t.integer  "GroupCounseling"
    t.integer  "SessionCountAtExit"
    t.integer  "PostExitCounselingPlan"
    t.integer  "SessionsInPlan"
    t.integer  "DestinationSafeClient"
    t.integer  "DestinationSafeWorker"
    t.integer  "PosAdultConnections"
    t.integer  "PosPeerConnections"
    t.integer  "PosCommunityConnections"
    t.date     "AftercareDate"
    t.integer  "AftercareProvided"
    t.integer  "EmailSocialMedia"
    t.integer  "Telephone"
    t.integer  "InPersonIndividual"
    t.integer  "InPersonGroup"
    t.integer  "CMExitReason"
  end

  add_index "Exit", ["DateCreated"], name: "exit_date_created", using: :btree
  add_index "Exit", ["DateDeleted"], name: "index_Exit_on_DateDeleted", using: :btree
  add_index "Exit", ["DateUpdated"], name: "exit_date_updated", using: :btree
  add_index "Exit", ["ExitDate"], name: "index_Exit_on_ExitDate", using: :btree
  add_index "Exit", ["ExportID"], name: "exit_export_id", using: :btree
  add_index "Exit", ["PersonalID"], name: "index_Exit_on_PersonalID", using: :btree
  add_index "Exit", ["ProjectEntryID"], name: "index_Exit_on_ProjectEntryID", using: :btree
  add_index "Exit", ["data_source_id", "ExitID"], name: "unk_Exit", unique: true, using: :btree
  add_index "Exit", ["data_source_id", "PersonalID"], name: "index_Exit_on_data_source_id_PersonalID", using: :btree
  add_index "Exit", ["data_source_id"], name: "index_Exit_on_data_source_id", using: :btree

  create_table "Export", force: :cascade do |t|
    t.string   "ExportID"
    t.string   "SourceID"
    t.string   "SourceName"
    t.string   "SourceContactFirst"
    t.string   "SourceContactLast"
    t.string   "SourceContactPhone"
    t.string   "SourceContactExtension"
    t.string   "SourceContactEmail"
    t.datetime "ExportDate"
    t.date     "ExportStartDate"
    t.date     "ExportEndDate"
    t.string   "SoftwareName"
    t.string   "SoftwareVersion"
    t.integer  "ExportPeriodType"
    t.integer  "ExportDirective"
    t.integer  "HashStatus"
    t.integer  "data_source_id"
    t.integer  "SourceType"
    t.date     "effective_export_end_date"
  end

  add_index "Export", ["ExportID"], name: "export_export_id", using: :btree
  add_index "Export", ["data_source_id", "ExportID"], name: "unk_Export", unique: true, using: :btree
  add_index "Export", ["data_source_id"], name: "index_Export_on_data_source_id", using: :btree

  create_table "Funder", force: :cascade do |t|
    t.string   "FunderID"
    t.string   "ProjectID"
    t.string   "Funder"
    t.string   "GrantID"
    t.date     "StartDate"
    t.date     "EndDate"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",         limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
  end

  add_index "Funder", ["DateCreated"], name: "funder_date_created", using: :btree
  add_index "Funder", ["DateUpdated"], name: "funder_date_updated", using: :btree
  add_index "Funder", ["ExportID"], name: "funder_export_id", using: :btree
  add_index "Funder", ["data_source_id", "FunderID"], name: "unk_Funder", unique: true, using: :btree
  add_index "Funder", ["data_source_id"], name: "index_Funder_on_data_source_id", using: :btree

  create_table "HealthAndDV", force: :cascade do |t|
    t.string   "HealthAndDVID"
    t.string   "ProjectEntryID"
    t.string   "PersonalID"
    t.date     "InformationDate"
    t.integer  "DomesticViolenceVictim"
    t.integer  "WhenOccurred"
    t.integer  "CurrentlyFleeing"
    t.integer  "GeneralHealthStatus"
    t.integer  "DentalHealthStatus"
    t.integer  "MentalHealthStatus"
    t.integer  "PregnancyStatus"
    t.date     "DueDate"
    t.integer  "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                 limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
  end

  add_index "HealthAndDV", ["DateCreated"], name: "health_and_dv_date_created", using: :btree
  add_index "HealthAndDV", ["DateUpdated"], name: "health_and_dv_date_updated", using: :btree
  add_index "HealthAndDV", ["ExportID"], name: "health_and_dv_export_id", using: :btree
  add_index "HealthAndDV", ["PersonalID"], name: "index_HealthAndDV_on_PersonalID", using: :btree
  add_index "HealthAndDV", ["ProjectEntryID"], name: "index_HealthAndDV_on_ProjectEntryID", using: :btree
  add_index "HealthAndDV", ["data_source_id", "HealthAndDVID"], name: "unk_HealthAndDV", unique: true, using: :btree
  add_index "HealthAndDV", ["data_source_id", "PersonalID"], name: "index_HealthAndDV_on_data_source_id_PersonalID", using: :btree
  add_index "HealthAndDV", ["data_source_id"], name: "index_HealthAndDV_on_data_source_id", using: :btree

  create_table "IncomeBenefits", force: :cascade do |t|
    t.string   "IncomeBenefitsID"
    t.string   "ProjectEntryID"
    t.string   "PersonalID"
    t.date     "InformationDate"
    t.integer  "IncomeFromAnySource"
    t.decimal  "TotalMonthlyIncome"
    t.integer  "Earned"
    t.decimal  "EarnedAmount"
    t.integer  "Unemployment"
    t.decimal  "UnemploymentAmount"
    t.integer  "SSI"
    t.decimal  "SSIAmount"
    t.integer  "SSDI"
    t.decimal  "SSDIAmount"
    t.integer  "VADisabilityService"
    t.decimal  "VADisabilityServiceAmount"
    t.integer  "VADisabilityNonService"
    t.decimal  "VADisabilityNonServiceAmount"
    t.integer  "PrivateDisability"
    t.decimal  "PrivateDisabilityAmount"
    t.integer  "WorkersComp"
    t.decimal  "WorkersCompAmount"
    t.integer  "TANF"
    t.decimal  "TANFAmount"
    t.integer  "GA"
    t.decimal  "GAAmount"
    t.integer  "SocSecRetirement"
    t.decimal  "SocSecRetirementAmount"
    t.integer  "Pension"
    t.decimal  "PensionAmount"
    t.integer  "ChildSupport"
    t.decimal  "ChildSupportAmount"
    t.integer  "Alimony"
    t.decimal  "AlimonyAmount"
    t.integer  "OtherIncomeSource"
    t.decimal  "OtherIncomeAmount"
    t.string   "OtherIncomeSourceIdentify"
    t.integer  "BenefitsFromAnySource"
    t.integer  "SNAP"
    t.integer  "WIC"
    t.integer  "TANFChildCare"
    t.integer  "TANFTransportation"
    t.integer  "OtherTANF"
    t.integer  "RentalAssistanceOngoing"
    t.integer  "RentalAssistanceTemp"
    t.integer  "OtherBenefitsSource"
    t.string   "OtherBenefitsSourceIdentify"
    t.integer  "InsuranceFromAnySource"
    t.integer  "Medicaid"
    t.integer  "NoMedicaidReason"
    t.integer  "Medicare"
    t.integer  "NoMedicareReason"
    t.integer  "SCHIP"
    t.integer  "NoSCHIPReason"
    t.integer  "VAMedicalServices"
    t.integer  "NoVAMedReason"
    t.integer  "EmployerProvided"
    t.integer  "NoEmployerProvidedReason"
    t.integer  "COBRA"
    t.integer  "NoCOBRAReason"
    t.integer  "PrivatePay"
    t.integer  "NoPrivatePayReason"
    t.integer  "StateHealthIns"
    t.integer  "NoStateHealthInsReason"
    t.integer  "HIVAIDSAssistance"
    t.integer  "NoHIVAIDSAssistanceReason"
    t.integer  "ADAP"
    t.integer  "NoADAPReason"
    t.integer  "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                       limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
    t.integer  "IndianHealthServices"
    t.integer  "NoIndianHealthServicesReason"
    t.integer  "OtherInsurance"
    t.string   "OtherInsuranceIdentify",       limit: 50
    t.integer  "ConnectionWithSOAR"
  end

  add_index "IncomeBenefits", ["DateCreated"], name: "income_benefits_date_created", using: :btree
  add_index "IncomeBenefits", ["DateUpdated"], name: "income_benefits_date_updated", using: :btree
  add_index "IncomeBenefits", ["ExportID"], name: "income_benefits_export_id", using: :btree
  add_index "IncomeBenefits", ["PersonalID"], name: "index_IncomeBenefits_on_PersonalID", using: :btree
  add_index "IncomeBenefits", ["ProjectEntryID"], name: "index_IncomeBenefits_on_ProjectEntryID", using: :btree
  add_index "IncomeBenefits", ["data_source_id", "IncomeBenefitsID"], name: "unk_IncomeBenefits", unique: true, using: :btree
  add_index "IncomeBenefits", ["data_source_id", "PersonalID"], name: "index_IncomeBenefits_on_data_source_id_PersonalID", using: :btree
  add_index "IncomeBenefits", ["data_source_id"], name: "index_IncomeBenefits_on_data_source_id", using: :btree

  create_table "Inventory", force: :cascade do |t|
    t.string   "InventoryID"
    t.string   "ProjectID"
    t.string   "CoCCode",               limit: 50
    t.date     "InformationDate"
    t.integer  "HouseholdType"
    t.integer  "BedType"
    t.integer  "Availability"
    t.integer  "UnitInventory"
    t.integer  "BedInventory"
    t.integer  "CHBedInventory"
    t.integer  "VetBedInventory"
    t.integer  "YouthBedInventory"
    t.integer  "YouthAgeGroup"
    t.date     "InventoryStartDate"
    t.date     "InventoryEndDate"
    t.integer  "HMISParticipatingBeds"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
  end

  add_index "Inventory", ["DateCreated"], name: "inventory_date_created", using: :btree
  add_index "Inventory", ["DateUpdated"], name: "inventory_date_updated", using: :btree
  add_index "Inventory", ["ExportID"], name: "inventory_export_id", using: :btree
  add_index "Inventory", ["ProjectID", "CoCCode", "data_source_id"], name: "index_Inventory_on_ProjectID_and_CoCCode_and_data_source_id", using: :btree
  add_index "Inventory", ["data_source_id", "InventoryID"], name: "unk_Inventory", unique: true, using: :btree
  add_index "Inventory", ["data_source_id"], name: "index_Inventory_on_data_source_id", using: :btree

  create_table "Organization", force: :cascade do |t|
    t.string   "OrganizationID",         limit: 50
    t.string   "OrganizationName"
    t.string   "OrganizationCommonName"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                 limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
    t.boolean  "dmh",                                default: false, null: false
  end

  add_index "Organization", ["ExportID"], name: "organization_export_id", using: :btree
  add_index "Organization", ["data_source_id", "OrganizationID"], name: "unk_Organization", unique: true, using: :btree
  add_index "Organization", ["data_source_id"], name: "index_Organization_on_data_source_id", using: :btree

  create_table "Project", force: :cascade do |t|
    t.string   "ProjectID",              limit: 50
    t.string   "OrganizationID",         limit: 50
    t.string   "ProjectName"
    t.string   "ProjectCommonName"
    t.integer  "ContinuumProject"
    t.integer  "ProjectType"
    t.integer  "ResidentialAffiliation"
    t.integer  "TrackingMethod"
    t.integer  "TargetPopulation"
    t.integer  "PITCount"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                 limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
    t.integer  "act_as_project_type"
    t.boolean  "hud_continuum_funded"
    t.boolean  "confidential",                       default: false, null: false
    t.integer  "computed_project_type"
    t.date     "OperatingStartDate"
    t.date     "OperatingEndDate"
    t.integer  "VictimServicesProvider"
    t.integer  "HousingType"
    t.string   "local_planning_group"
  end

  add_index "Project", ["DateCreated"], name: "project_date_created", using: :btree
  add_index "Project", ["DateUpdated"], name: "project_date_updated", using: :btree
  add_index "Project", ["ExportID"], name: "project_export_id", using: :btree
  add_index "Project", ["ProjectID", "data_source_id", "OrganizationID"], name: "index_proj_proj_id_org_id_ds_id", using: :btree
  add_index "Project", ["ProjectType"], name: "index_Project_on_ProjectType", using: :btree
  add_index "Project", ["computed_project_type"], name: "index_Project_on_computed_project_type", using: :btree
  add_index "Project", ["data_source_id", "ProjectID"], name: "unk_Project", unique: true, using: :btree
  add_index "Project", ["data_source_id"], name: "index_Project_on_data_source_id", using: :btree

  create_table "ProjectCoC", force: :cascade do |t|
    t.string   "ProjectCoCID",   limit: 50
    t.string   "ProjectID"
    t.string   "CoCCode",        limit: 50
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",         limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
    t.string   "hud_coc_code"
  end

  add_index "ProjectCoC", ["DateCreated"], name: "project_coc_date_created", using: :btree
  add_index "ProjectCoC", ["DateUpdated"], name: "project_coc_date_updated", using: :btree
  add_index "ProjectCoC", ["ExportID"], name: "project_coc_export_id", using: :btree
  add_index "ProjectCoC", ["data_source_id", "ProjectCoCID"], name: "unk_ProjectCoC", unique: true, using: :btree
  add_index "ProjectCoC", ["data_source_id", "ProjectID", "CoCCode"], name: "index_ProjectCoC_on_data_source_id_and_ProjectID_and_CoCCode", using: :btree

  create_table "Services", force: :cascade do |t|
    t.string   "ServicesID"
    t.string   "ProjectEntryID"
    t.string   "PersonalID"
    t.date     "DateProvided"
    t.integer  "RecordType"
    t.integer  "TypeProvided"
    t.string   "OtherTypeProvided"
    t.integer  "SubTypeProvided"
    t.decimal  "FAAmount"
    t.integer  "ReferralOutcome"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",            limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
  end

  add_index "Services", ["DateCreated"], name: "services_date_created", using: :btree
  add_index "Services", ["DateDeleted"], name: "index_Services_on_DateDeleted", using: :btree
  add_index "Services", ["DateProvided"], name: "index_Services_on_DateProvided", using: :btree
  add_index "Services", ["DateUpdated"], name: "services_date_updated", using: :btree
  add_index "Services", ["ExportID"], name: "services_export_id", using: :btree
  add_index "Services", ["PersonalID"], name: "index_Services_on_PersonalID", using: :btree
  add_index "Services", ["ProjectEntryID", "PersonalID", "data_source_id"], name: "index_serv_on_proj_entry_per_id_ds_id", using: :btree
  add_index "Services", ["data_source_id", "PersonalID", "RecordType", "ProjectEntryID", "DateProvided"], name: "index_services_ds_id_p_id_type_entry_id_date", using: :btree
  add_index "Services", ["data_source_id", "ServicesID"], name: "unk_Services", unique: true, using: :btree
  add_index "Services", ["data_source_id"], name: "index_Services_on_data_source_id", using: :btree

  create_table "Site", force: :cascade do |t|
    t.string   "SiteID"
    t.string   "ProjectID"
    t.string   "CoCCode",         limit: 50
    t.integer  "PrincipalSite"
    t.string   "Geocode",         limit: 50
    t.string   "Address"
    t.string   "City"
    t.string   "State",           limit: 2
    t.string   "ZIP",             limit: 10
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",          limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
    t.date     "InformationDate"
    t.string   "Address2"
    t.integer  "GeographyType"
  end

  add_index "Site", ["DateCreated"], name: "site_date_created", using: :btree
  add_index "Site", ["DateUpdated"], name: "site_date_updated", using: :btree
  add_index "Site", ["ExportID"], name: "site_export_id", using: :btree
  add_index "Site", ["data_source_id", "SiteID"], name: "unk_Site", unique: true, using: :btree
  add_index "Site", ["data_source_id"], name: "index_Site_on_data_source_id", using: :btree

  create_table "administrative_events", force: :cascade do |t|
    t.string   "user_id"
    t.date     "date"
    t.string   "title"
    t.string   "description"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.datetime "deleted_at"
  end

  add_index "administrative_events", ["deleted_at"], name: "index_administrative_events_on_deleted_at", using: :btree

  create_table "anomalies", force: :cascade do |t|
    t.integer  "client_id"
    t.integer  "submitted_by"
    t.string   "description"
    t.string   "status",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "anomalies", ["client_id"], name: "index_anomalies_on_client_id", using: :btree
  add_index "anomalies", ["status"], name: "index_anomalies_on_status", using: :btree

  create_table "api_client_data_source_ids", force: :cascade do |t|
    t.string  "warehouse_id"
    t.string  "id_in_data_source"
    t.integer "site_id_in_data_source"
    t.integer "data_source_id"
    t.integer "client_id"
    t.date    "last_contact"
  end

  add_index "api_client_data_source_ids", ["client_id"], name: "index_api_client_data_source_ids_on_client_id", using: :btree
  add_index "api_client_data_source_ids", ["data_source_id"], name: "index_api_client_data_source_ids_on_data_source_id", using: :btree
  add_index "api_client_data_source_ids", ["warehouse_id"], name: "index_api_client_data_source_ids_on_warehouse_id", using: :btree

  create_table "available_file_tags", force: :cascade do |t|
    t.string   "name"
    t.string   "group"
    t.string   "included_info"
    t.integer  "weight",               default: 0
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.boolean  "document_ready",       default: false
    t.boolean  "notification_trigger", default: false
    t.boolean  "consent_form",         default: false
    t.string   "note"
    t.boolean  "full_release",         default: false, null: false
  end

  create_table "cas_enrollments", force: :cascade do |t|
    t.integer  "client_id"
    t.integer  "enrollment_id"
    t.date     "entry_date"
    t.date     "exit_date"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.json     "history"
  end

  add_index "cas_enrollments", ["client_id"], name: "index_cas_enrollments_on_client_id", using: :btree
  add_index "cas_enrollments", ["enrollment_id"], name: "index_cas_enrollments_on_enrollment_id", using: :btree

  create_table "cas_houseds", force: :cascade do |t|
    t.integer "client_id",                     null: false
    t.integer "cas_client_id",                 null: false
    t.integer "match_id",                      null: false
    t.date    "housed_on",                     null: false
    t.boolean "inactivated",   default: false
  end

  add_index "cas_houseds", ["client_id"], name: "index_cas_houseds_on_client_id", using: :btree

  create_table "cas_reports", force: :cascade do |t|
    t.integer  "client_id",                                          null: false
    t.integer  "match_id",                                           null: false
    t.integer  "decision_id",                                        null: false
    t.integer  "decision_order",                                     null: false
    t.string   "match_step",                                         null: false
    t.string   "decision_status",                                    null: false
    t.boolean  "current_step",                       default: false, null: false
    t.boolean  "active_match",                       default: false, null: false
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.integer  "elapsed_days",                       default: 0,     null: false
    t.datetime "client_last_seen_date"
    t.datetime "criminal_hearing_date"
    t.string   "decline_reason"
    t.string   "not_working_with_client_reason"
    t.string   "administrative_cancel_reason"
    t.boolean  "client_spoken_with_services_agency"
    t.boolean  "cori_release_form_submitted"
    t.datetime "match_started_at"
    t.string   "program_type"
    t.json     "shelter_agency_contacts"
    t.json     "hsa_contacts"
    t.json     "ssp_contacts"
    t.json     "admin_contacts"
    t.json     "clent_contacts"
    t.json     "hsp_contacts"
  end

  add_index "cas_reports", ["client_id", "match_id", "decision_id"], name: "index_cas_reports_on_client_id_and_match_id_and_decision_id", unique: true, using: :btree

  create_table "census_by_project_types", force: :cascade do |t|
    t.integer "ProjectType",                  null: false
    t.date    "date",                         null: false
    t.boolean "veteran",      default: false, null: false
    t.integer "gender",       default: 99,    null: false
    t.integer "client_count", default: 0,     null: false
  end

  create_table "censuses", force: :cascade do |t|
    t.integer "data_source_id",                 null: false
    t.integer "ProjectType",                    null: false
    t.string  "OrganizationID",                 null: false
    t.string  "ProjectID",                      null: false
    t.date    "date",                           null: false
    t.boolean "veteran",        default: false, null: false
    t.integer "gender",         default: 99,    null: false
    t.integer "client_count",   default: 0,     null: false
    t.integer "bed_inventory",  default: 0,     null: false
  end

  add_index "censuses", ["data_source_id", "ProjectType", "OrganizationID", "ProjectID"], name: "index_censuses_ds_id_proj_type_org_id_proj_id", using: :btree
  add_index "censuses", ["date", "ProjectType"], name: "index_censuses_on_date_and_ProjectType", using: :btree
  add_index "censuses", ["date"], name: "index_censuses_on_date", using: :btree

  create_table "censuses_averaged_by_year", force: :cascade do |t|
    t.integer "year",                           null: false
    t.integer "data_source_id"
    t.string  "OrganizationID"
    t.string  "ProjectID"
    t.integer "ProjectType",                    null: false
    t.integer "client_count",       default: 0, null: false
    t.integer "bed_inventory",      default: 0, null: false
    t.integer "seasonal_inventory", default: 0, null: false
    t.integer "overflow_inventory", default: 0, null: false
    t.integer "days_of_service",    default: 0, null: false
  end

  add_index "censuses_averaged_by_year", ["year", "data_source_id", "ProjectType", "OrganizationID", "ProjectID"], name: "index_censuses_ave_year_ds_id_proj_type_org_id_proj_id", using: :btree

  create_table "children", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.date     "dob"
    t.integer  "family_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "children", ["family_id"], name: "index_children_on_family_id", using: :btree

  create_table "chronics", force: :cascade do |t|
    t.date    "date",                                       null: false
    t.integer "client_id",                                  null: false
    t.integer "days_in_last_three_years"
    t.integer "months_in_last_three_years"
    t.boolean "individual"
    t.integer "age"
    t.date    "homeless_since"
    t.boolean "dmh",                        default: false
    t.string  "trigger"
    t.string  "project_names"
  end

  add_index "chronics", ["client_id"], name: "index_chronics_on_client_id", using: :btree
  add_index "chronics", ["date"], name: "index_chronics_on_date", using: :btree

  create_table "client_matches", force: :cascade do |t|
    t.integer  "source_client_id",      null: false
    t.integer  "destination_client_id", null: false
    t.integer  "updated_by_id"
    t.integer  "lock_version"
    t.integer  "defer_count"
    t.string   "status",                null: false
    t.float    "score"
    t.text     "score_details"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "client_matches", ["destination_client_id"], name: "index_client_matches_on_destination_client_id", using: :btree
  add_index "client_matches", ["source_client_id"], name: "index_client_matches_on_source_client_id", using: :btree
  add_index "client_matches", ["updated_by_id"], name: "index_client_matches_on_updated_by_id", using: :btree

  create_table "client_notes", force: :cascade do |t|
    t.integer  "client_id",         null: false
    t.integer  "user_id",           null: false
    t.string   "type",              null: false
    t.text     "note"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string   "migrated_username"
  end

  add_index "client_notes", ["client_id"], name: "index_client_notes_on_client_id", using: :btree
  add_index "client_notes", ["user_id"], name: "index_client_notes_on_user_id", using: :btree

  create_table "cohort_client_changes", force: :cascade do |t|
    t.integer  "cohort_client_id", null: false
    t.integer  "cohort_id",        null: false
    t.integer  "user_id",          null: false
    t.string   "change"
    t.datetime "changed_at",       null: false
    t.string   "reason"
  end

  add_index "cohort_client_changes", ["change"], name: "index_cohort_client_changes_on_change", using: :btree
  add_index "cohort_client_changes", ["changed_at"], name: "index_cohort_client_changes_on_changed_at", using: :btree

  create_table "cohort_client_notes", force: :cascade do |t|
    t.integer  "cohort_client_id", null: false
    t.text     "note"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.datetime "deleted_at"
    t.integer  "user_id",          null: false
  end

  add_index "cohort_client_notes", ["cohort_client_id"], name: "index_cohort_client_notes_on_cohort_client_id", using: :btree
  add_index "cohort_client_notes", ["deleted_at"], name: "index_cohort_client_notes_on_deleted_at", using: :btree

  create_table "cohort_clients", force: :cascade do |t|
    t.integer  "cohort_id",                                                         null: false
    t.integer  "client_id",                                                         null: false
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
    t.datetime "deleted_at"
    t.string   "agency"
    t.string   "case_manager"
    t.string   "housing_manager"
    t.string   "housing_search_agency"
    t.string   "housing_opportunity"
    t.string   "legal_barriers"
    t.string   "criminal_record_status"
    t.string   "document_ready"
    t.boolean  "sif_eligible",                                      default: false
    t.string   "sensory_impaired"
    t.date     "housed_date"
    t.string   "destination"
    t.string   "sub_population"
    t.integer  "rank"
    t.string   "st_francis_house"
    t.date     "last_group_review_date"
    t.date     "pre_contemplative_last_date_approached"
    t.string   "va_eligible"
    t.boolean  "vash_eligible",                                     default: false
    t.string   "chapter_115"
    t.date     "first_date_homeless"
    t.date     "last_date_approached"
    t.boolean  "chronic",                                           default: false
    t.string   "dnd_rank"
    t.boolean  "veteran",                                           default: false
    t.string   "housing_track_suggested"
    t.string   "housing_track_enrolled"
    t.integer  "adjusted_days_homeless"
    t.string   "housing_navigator"
    t.string   "status"
    t.string   "ssvf_eligible"
    t.string   "location"
    t.string   "location_type"
    t.string   "vet_squares_confirmed"
    t.boolean  "active",                                            default: true,  null: false
    t.string   "provider"
    t.string   "next_step"
    t.text     "housing_plan"
    t.date     "document_ready_on"
    t.string   "new_lease_referral"
    t.string   "vulnerability_rank"
    t.boolean  "ineligible",                                        default: false, null: false
    t.integer  "adjusted_days_homeless_last_three_years",           default: 0,     null: false
    t.boolean  "original_chronic",                                  default: false, null: false
    t.string   "not_a_vet"
    t.string   "primary_housing_track_suggested"
    t.integer  "minimum_bedroom_size"
    t.string   "special_needs"
    t.integer  "adjusted_days_literally_homeless_last_three_years"
  end

  add_index "cohort_clients", ["client_id"], name: "index_cohort_clients_on_client_id", using: :btree
  add_index "cohort_clients", ["cohort_id"], name: "index_cohort_clients_on_cohort_id", using: :btree
  add_index "cohort_clients", ["deleted_at"], name: "index_cohort_clients_on_deleted_at", using: :btree

  create_table "cohorts", force: :cascade do |t|
    t.string   "name",                                    null: false
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.datetime "deleted_at"
    t.date     "effective_date"
    t.text     "column_state"
    t.string   "default_sort_direction", default: "desc"
    t.boolean  "only_window",            default: true,   null: false
    t.boolean  "active_cohort",          default: true,   null: false
    t.integer  "static_column_count",    default: 3,      null: false
    t.string   "short_name"
    t.integer  "days_of_inactivity",     default: 90
  end

  add_index "cohorts", ["deleted_at"], name: "index_cohorts_on_deleted_at", using: :btree

  create_table "configs", force: :cascade do |t|
    t.boolean "project_type_override",                     default: true,                     null: false
    t.boolean "eto_api_available",                         default: false,                    null: false
    t.string  "cas_available_method",                      default: "cas_flag",               null: false
    t.boolean "healthcare_available",                      default: false,                    null: false
    t.string  "family_calculation_method",                 default: "adult_child"
    t.string  "site_coc_codes"
    t.string  "default_coc_zipcodes"
    t.string  "continuum_name"
    t.string  "cas_url",                                   default: "https://cas.boston.gov"
    t.string  "release_duration",                          default: "Indefinite"
    t.boolean "allow_partial_release",                     default: true
    t.string  "cas_flag_method",                           default: "manual"
    t.boolean "window_access_requires_release",            default: false
    t.boolean "show_partial_ssn_in_window_search_results", default: false
    t.string  "url_of_blank_consent_form"
    t.boolean "ahar_psh_includes_rrh",                     default: true
    t.boolean "so_day_as_month",                           default: true
    t.text    "client_details"
  end

  create_table "contacts", force: :cascade do |t|
    t.string   "type",       null: false
    t.integer  "entity_id",  null: false
    t.string   "email",      null: false
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "contacts", ["entity_id"], name: "index_contacts_on_entity_id", using: :btree
  add_index "contacts", ["type"], name: "index_contacts_on_type", using: :btree

  create_table "data_monitorings", force: :cascade do |t|
    t.integer "resource_id",     null: false
    t.date    "census"
    t.date    "calculated_on"
    t.date    "calculate_after"
    t.float   "value"
    t.float   "change"
    t.integer "iteration"
    t.integer "of_iterations"
    t.string  "type"
  end

  add_index "data_monitorings", ["calculated_on"], name: "index_data_monitorings_on_calculated_on", using: :btree
  add_index "data_monitorings", ["census"], name: "index_data_monitorings_on_census", using: :btree
  add_index "data_monitorings", ["resource_id"], name: "index_data_monitorings_on_resource_id", using: :btree
  add_index "data_monitorings", ["type"], name: "index_data_monitorings_on_type", using: :btree

  create_table "data_sources", force: :cascade do |t|
    t.string   "name"
    t.string   "file_path"
    t.datetime "last_imported_at"
    t.date     "newest_updated_at"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "source_type"
    t.boolean  "munged_personal_id", default: false, null: false
    t.string   "short_name"
    t.boolean  "visible_in_window",  default: false, null: false
    t.boolean  "authoritative",      default: false
  end

  create_table "enrollment_extras", force: :cascade do |t|
    t.integer  "enrollment_id",       null: false
    t.integer  "vispdat_grand_total"
    t.date     "vispdat_added_at"
    t.date     "vispdat_started_at"
    t.date     "vispdat_ended_at"
    t.string   "source_tab"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "exports", force: :cascade do |t|
    t.string   "export_id"
    t.integer  "user_id"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "period_type"
    t.integer  "directive"
    t.integer  "hash_status"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.datetime "deleted_at"
    t.boolean  "faked_pii",       default: false
    t.json     "project_ids"
    t.boolean  "include_deleted", default: false
    t.string   "content_type"
    t.binary   "content"
    t.string   "file"
    t.integer  "delayed_job_id"
  end

  add_index "exports", ["deleted_at"], name: "index_exports_on_deleted_at", using: :btree
  add_index "exports", ["export_id"], name: "index_exports_on_export_id", using: :btree

  create_table "fake_data", force: :cascade do |t|
    t.string   "environment", null: false
    t.text     "map"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.text     "client_ids"
  end

  create_table "files", force: :cascade do |t|
    t.string   "type",                   null: false
    t.string   "file"
    t.string   "content_type"
    t.binary   "content"
    t.integer  "client_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string   "note"
    t.string   "name"
    t.boolean  "visible_in_window"
    t.string   "migrated_username"
    t.integer  "vispdat_id"
    t.date     "consent_form_signed_on"
    t.boolean  "consent_form_confirmed"
    t.float    "size"
    t.date     "effective_date"
  end

  add_index "files", ["type"], name: "index_files_on_type", using: :btree
  add_index "files", ["vispdat_id"], name: "index_files_on_vispdat_id", using: :btree

  create_table "generate_service_history_batch_logs", force: :cascade do |t|
    t.integer  "generate_service_history_log_id"
    t.integer  "to_process"
    t.integer  "updated"
    t.integer  "patched"
    t.integer  "delayed_job_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
  end

  create_table "generate_service_history_log", force: :cascade do |t|
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer  "to_delete"
    t.integer  "to_add"
    t.integer  "to_update"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "batches"
  end

  create_table "grades", force: :cascade do |t|
    t.string  "type",                                      null: false
    t.string  "grade",                                     null: false
    t.integer "percentage_low"
    t.integer "percentage_high"
    t.integer "percentage_under_low"
    t.integer "percentage_under_high"
    t.integer "percentage_over_low"
    t.integer "percentage_over_high"
    t.string  "color",                 default: "#000000"
    t.integer "weight",                default: 0,         null: false
  end

  add_index "grades", ["type"], name: "index_grades_on_type", using: :btree

  create_table "hmis_assessments", force: :cascade do |t|
    t.integer  "assessment_id",                                  null: false
    t.integer  "site_id",                                        null: false
    t.string   "site_name"
    t.string   "name",                                           null: false
    t.boolean  "fetch",                          default: false, null: false
    t.boolean  "active",                         default: true,  null: false
    t.datetime "last_fetched_at"
    t.integer  "data_source_id",                                 null: false
    t.boolean  "confidential",                   default: false, null: false
    t.boolean  "exclude_from_window",            default: false, null: false
    t.boolean  "details_in_window_with_release", default: false, null: false
    t.boolean  "health",                         default: false, null: false
  end

  add_index "hmis_assessments", ["assessment_id"], name: "index_hmis_assessments_on_assessment_id", using: :btree
  add_index "hmis_assessments", ["data_source_id"], name: "index_hmis_assessments_on_data_source_id", using: :btree
  add_index "hmis_assessments", ["site_id"], name: "index_hmis_assessments_on_site_id", using: :btree

  create_table "hmis_client_attributes_defined_text", force: :cascade do |t|
    t.integer  "client_id"
    t.integer  "data_source_id"
    t.string   "consent_form_status"
    t.datetime "consent_form_updated_at"
    t.string   "source_id"
    t.string   "source_class"
  end

  add_index "hmis_client_attributes_defined_text", ["client_id"], name: "index_hmis_client_attributes_defined_text_on_client_id", using: :btree
  add_index "hmis_client_attributes_defined_text", ["data_source_id"], name: "index_hmis_client_attributes_defined_text_on_data_source_id", using: :btree

  create_table "hmis_clients", force: :cascade do |t|
    t.integer  "client_id"
    t.text     "response"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "consent_form_status"
    t.string   "case_manager_name"
    t.text     "case_manager_attributes"
    t.string   "assigned_staff_name"
    t.text     "assigned_staff_attributes"
    t.string   "counselor_name"
    t.text     "counselor_attributes"
    t.string   "outreach_counselor_name"
    t.integer  "subject_id"
  end

  add_index "hmis_clients", ["client_id"], name: "index_hmis_clients_on_client_id", using: :btree

  create_table "hmis_forms", force: :cascade do |t|
    t.integer  "client_id"
    t.text     "response"
    t.string   "name"
    t.text     "answers"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "response_id"
    t.integer  "subject_id"
    t.datetime "collected_at"
    t.string   "staff"
    t.string   "assessment_type"
    t.string   "collection_location"
    t.integer  "assessment_id"
    t.integer  "data_source_id",      null: false
    t.integer  "site_id"
  end

  add_index "hmis_forms", ["assessment_id"], name: "index_hmis_forms_on_assessment_id", using: :btree
  add_index "hmis_forms", ["client_id"], name: "index_hmis_forms_on_client_id", using: :btree
  add_index "hmis_forms", ["collected_at"], name: "index_hmis_forms_on_collected_at", using: :btree
  add_index "hmis_forms", ["name"], name: "index_hmis_forms_on_name", using: :btree

  create_table "hmis_staff", force: :cascade do |t|
    t.integer "site_id"
    t.string  "first_name"
    t.string  "last_name"
    t.string  "middle_initial"
    t.string  "work_phone"
    t.string  "cell_phone"
    t.string  "email"
    t.string  "ssn"
    t.string  "source_class"
    t.string  "source_id"
    t.integer "data_source_id"
  end

  create_table "hmis_staff_x_clients", force: :cascade do |t|
    t.integer "staff_id"
    t.integer "client_id"
    t.integer "relationship_id"
    t.string  "source_class"
    t.string  "source_id"
  end

  add_index "hmis_staff_x_clients", ["staff_id", "client_id", "relationship_id"], name: "index_staff_x_client_s_id_c_id_r_id", unique: true, using: :btree

  create_table "hud_chronics", force: :cascade do |t|
    t.date     "date"
    t.integer  "client_id"
    t.integer  "months_in_last_three_years"
    t.boolean  "individual"
    t.integer  "age"
    t.date     "homeless_since"
    t.boolean  "dmh"
    t.string   "trigger"
    t.string   "project_names"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "days_in_last_three_years"
  end

  add_index "hud_chronics", ["client_id"], name: "index_hud_chronics_on_client_id", using: :btree

  create_table "hud_create_logs", force: :cascade do |t|
    t.string   "hud_key",        null: false
    t.string   "personal_id",    null: false
    t.string   "type",           null: false
    t.datetime "imported_at",    null: false
    t.date     "effective_date", null: false
    t.integer  "data_source_id", null: false
  end

  add_index "hud_create_logs", ["effective_date"], name: "index_hud_create_logs_on_effective_date", using: :btree
  add_index "hud_create_logs", ["imported_at"], name: "index_hud_create_logs_on_imported_at", using: :btree

  create_table "identify_duplicates_log", force: :cascade do |t|
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer  "to_match"
    t.integer  "matched"
    t.integer  "new_created"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "import_logs", force: :cascade do |t|
    t.integer  "data_source_id"
    t.string   "files"
    t.text     "import_errors"
    t.string   "summary"
    t.datetime "completed_at"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "zip"
    t.integer  "upload_id"
  end

  add_index "import_logs", ["completed_at"], name: "index_import_logs_on_completed_at", using: :btree
  add_index "import_logs", ["created_at"], name: "index_import_logs_on_created_at", using: :btree
  add_index "import_logs", ["data_source_id"], name: "index_import_logs_on_data_source_id", using: :btree
  add_index "import_logs", ["updated_at"], name: "index_import_logs_on_updated_at", using: :btree

  create_table "new_service_history", force: :cascade do |t|
    t.integer "client_id",                                                   null: false
    t.integer "data_source_id"
    t.date    "date",                                                        null: false
    t.date    "first_date_in_program",                                       null: false
    t.date    "last_date_in_program"
    t.string  "enrollment_group_id",             limit: 50
    t.integer "age",                             limit: 2
    t.integer "destination"
    t.string  "head_of_household_id",            limit: 50
    t.string  "household_id",                    limit: 50
    t.string  "project_id",                      limit: 50
    t.string  "project_name",                    limit: 150
    t.integer "project_type",                    limit: 2
    t.integer "project_tracking_method"
    t.string  "organization_id",                 limit: 50
    t.string  "record_type",                     limit: 50,                  null: false
    t.integer "housing_status_at_entry"
    t.integer "housing_status_at_exit"
    t.integer "service_type",                    limit: 2
    t.integer "computed_project_type",           limit: 2
    t.boolean "presented_as_individual"
    t.integer "other_clients_over_25",           limit: 2,   default: 0,     null: false
    t.integer "other_clients_under_18",          limit: 2,   default: 0,     null: false
    t.integer "other_clients_between_18_and_25", limit: 2,   default: 0,     null: false
    t.boolean "unaccompanied_youth",                         default: false, null: false
    t.boolean "parenting_youth",                             default: false, null: false
    t.boolean "parenting_juvenile",                          default: false, null: false
    t.boolean "children_only",                               default: false, null: false
    t.boolean "individual_adult",                            default: false, null: false
    t.boolean "individual_elder",                            default: false, null: false
    t.boolean "head_of_household",                           default: false, null: false
  end

  create_table "project_data_quality", force: :cascade do |t|
    t.integer  "project_id"
    t.string   "type"
    t.date     "start"
    t.date     "end"
    t.json     "report"
    t.datetime "sent_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "processing_errors"
    t.integer  "project_group_id"
    t.json     "support"
  end

  add_index "project_data_quality", ["project_id"], name: "index_project_data_quality_on_project_id", using: :btree

  create_table "project_groups", force: :cascade do |t|
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "project_project_groups", force: :cascade do |t|
    t.integer  "project_group_id"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "recent_report_enrollments", id: false, force: :cascade do |t|
    t.string   "ProjectEntryID",                               limit: 50
    t.string   "PersonalID"
    t.string   "ProjectID",                                    limit: 50
    t.date     "EntryDate"
    t.string   "HouseholdID"
    t.integer  "RelationshipToHoH"
    t.integer  "ResidencePrior"
    t.string   "OtherResidencePrior"
    t.integer  "ResidencePriorLengthOfStay"
    t.integer  "DisablingCondition"
    t.integer  "EntryFromStreetESSH"
    t.date     "DateToStreetESSH"
    t.integer  "ContinuouslyHomelessOneYear"
    t.integer  "TimesHomelessPastThreeYears"
    t.integer  "MonthsHomelessPastThreeYears"
    t.integer  "MonthsHomelessThisTime"
    t.integer  "StatusDocumented"
    t.integer  "HousingStatus"
    t.date     "DateOfEngagement"
    t.integer  "InPermanentHousing"
    t.date     "ResidentialMoveInDate"
    t.date     "DateOfPATHStatus"
    t.integer  "ClientEnrolledInPATH"
    t.integer  "ReasonNotEnrolled"
    t.integer  "WorstHousingSituation"
    t.integer  "PercentAMI"
    t.string   "LastPermanentStreet"
    t.string   "LastPermanentCity",                            limit: 50
    t.string   "LastPermanentState",                           limit: 2
    t.string   "LastPermanentZIP",                             limit: 10
    t.integer  "AddressDataQuality"
    t.date     "DateOfBCPStatus"
    t.integer  "FYSBYouth"
    t.integer  "ReasonNoServices"
    t.integer  "SexualOrientation"
    t.integer  "FormerWardChildWelfare"
    t.integer  "ChildWelfareYears"
    t.integer  "ChildWelfareMonths"
    t.integer  "FormerWardJuvenileJustice"
    t.integer  "JuvenileJusticeYears"
    t.integer  "JuvenileJusticeMonths"
    t.integer  "HouseholdDynamics"
    t.integer  "SexualOrientationGenderIDYouth"
    t.integer  "SexualOrientationGenderIDFam"
    t.integer  "HousingIssuesYouth"
    t.integer  "HousingIssuesFam"
    t.integer  "SchoolEducationalIssuesYouth"
    t.integer  "SchoolEducationalIssuesFam"
    t.integer  "UnemploymentYouth"
    t.integer  "UnemploymentFam"
    t.integer  "MentalHealthIssuesYouth"
    t.integer  "MentalHealthIssuesFam"
    t.integer  "HealthIssuesYouth"
    t.integer  "HealthIssuesFam"
    t.integer  "PhysicalDisabilityYouth"
    t.integer  "PhysicalDisabilityFam"
    t.integer  "MentalDisabilityYouth"
    t.integer  "MentalDisabilityFam"
    t.integer  "AbuseAndNeglectYouth"
    t.integer  "AbuseAndNeglectFam"
    t.integer  "AlcoholDrugAbuseYouth"
    t.integer  "AlcoholDrugAbuseFam"
    t.integer  "InsufficientIncome"
    t.integer  "ActiveMilitaryParent"
    t.integer  "IncarceratedParent"
    t.integer  "IncarceratedParentStatus"
    t.integer  "ReferralSource"
    t.integer  "CountOutreachReferralApproaches"
    t.integer  "ExchangeForSex"
    t.integer  "ExchangeForSexPastThreeMonths"
    t.integer  "CountOfExchangeForSex"
    t.integer  "AskedOrForcedToExchangeForSex"
    t.integer  "AskedOrForcedToExchangeForSexPastThreeMonths"
    t.integer  "WorkPlaceViolenceThreats"
    t.integer  "WorkplacePromiseDifference"
    t.integer  "CoercedToContinueWork"
    t.integer  "LaborExploitPastThreeMonths"
    t.integer  "HPScreeningScore"
    t.integer  "VAMCStation"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string   "UserID",                                       limit: 100
    t.datetime "DateDeleted"
    t.string   "ExportID"
    t.integer  "data_source_id"
    t.integer  "id"
    t.integer  "LOSUnderThreshold"
    t.integer  "PreviousStreetESSH"
    t.integer  "UrgentReferral"
    t.integer  "TimeToHousingLoss"
    t.integer  "ZeroIncome"
    t.integer  "AnnualPercentAMI"
    t.integer  "FinancialChange"
    t.integer  "HouseholdChange"
    t.integer  "EvictionHistory"
    t.integer  "SubsidyAtRisk"
    t.integer  "LiteralHomelessHistory"
    t.integer  "DisabledHoH"
    t.integer  "CriminalRecord"
    t.integer  "SexOffender"
    t.integer  "DependentUnder6"
    t.integer  "SingleParent"
    t.integer  "HH5Plus"
    t.integer  "IraqAfghanistan"
    t.integer  "FemVet"
    t.integer  "ThresholdScore"
    t.integer  "ERVisits"
    t.integer  "JailNights"
    t.integer  "HospitalNights"
    t.integer  "RunawayYouth"
    t.string   "processed_hash"
    t.string   "processed_as"
    t.integer  "demographic_id"
    t.integer  "client_id"
  end

  add_index "recent_report_enrollments", ["EntryDate"], name: "entrydate_ret_index", using: :btree
  add_index "recent_report_enrollments", ["client_id"], name: "client_id_ret_index", using: :btree
  add_index "recent_report_enrollments", ["id"], name: "id_ret_index", unique: true, using: :btree

  create_table "recent_service_history", id: false, force: :cascade do |t|
    t.integer "id"
    t.integer "client_id"
    t.integer "data_source_id"
    t.date    "date"
    t.date    "first_date_in_program"
    t.date    "last_date_in_program"
    t.string  "enrollment_group_id",     limit: 50
    t.integer "age",                     limit: 2
    t.integer "destination"
    t.string  "head_of_household_id",    limit: 50
    t.string  "household_id",            limit: 50
    t.integer "project_id"
    t.integer "project_type",            limit: 2
    t.integer "project_tracking_method"
    t.integer "organization_id"
    t.integer "housing_status_at_entry"
    t.integer "housing_status_at_exit"
    t.integer "service_type",            limit: 2
    t.integer "computed_project_type",   limit: 2
    t.boolean "presented_as_individual"
  end

  add_index "recent_service_history", ["client_id"], name: "client_id_rsh_index", using: :btree
  add_index "recent_service_history", ["computed_project_type"], name: "computed_project_type_rsh_index", using: :btree
  add_index "recent_service_history", ["date"], name: "date_rsh_index", using: :btree
  add_index "recent_service_history", ["household_id"], name: "household_id_rsh_index", using: :btree
  add_index "recent_service_history", ["id"], name: "id_rsh_index", unique: true, using: :btree
  add_index "recent_service_history", ["project_tracking_method"], name: "project_tracking_method_rsh_index", using: :btree
  add_index "recent_service_history", ["project_type"], name: "project_type_rsh_index", using: :btree

  create_table "report_definitions", force: :cascade do |t|
    t.string  "report_group"
    t.text    "url"
    t.text    "name"
    t.text    "description"
    t.integer "weight",       default: 0, null: false
  end

  create_table "report_tokens", force: :cascade do |t|
    t.integer  "report_id",   null: false
    t.integer  "contact_id",  null: false
    t.string   "token",       null: false
    t.datetime "expires_at",  null: false
    t.datetime "accessed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "report_tokens", ["contact_id"], name: "index_report_tokens_on_contact_id", using: :btree
  add_index "report_tokens", ["report_id"], name: "index_report_tokens_on_report_id", using: :btree

  create_table "service_history_enrollments", force: :cascade do |t|
    t.integer "client_id",                                                   null: false
    t.integer "data_source_id"
    t.date    "date",                                                        null: false
    t.date    "first_date_in_program",                                       null: false
    t.date    "last_date_in_program"
    t.string  "enrollment_group_id",             limit: 50
    t.string  "project_id",                      limit: 50
    t.integer "age",                             limit: 2
    t.integer "destination"
    t.string  "head_of_household_id",            limit: 50
    t.string  "household_id",                    limit: 50
    t.string  "project_name",                    limit: 150
    t.integer "project_type",                    limit: 2
    t.integer "project_tracking_method"
    t.string  "organization_id",                 limit: 50
    t.string  "record_type",                     limit: 50,                  null: false
    t.integer "housing_status_at_entry"
    t.integer "housing_status_at_exit"
    t.integer "service_type",                    limit: 2
    t.integer "computed_project_type",           limit: 2
    t.boolean "presented_as_individual"
    t.integer "other_clients_over_25",           limit: 2,   default: 0,     null: false
    t.integer "other_clients_under_18",          limit: 2,   default: 0,     null: false
    t.integer "other_clients_between_18_and_25", limit: 2,   default: 0,     null: false
    t.boolean "unaccompanied_youth",                         default: false, null: false
    t.boolean "parenting_youth",                             default: false, null: false
    t.boolean "parenting_juvenile",                          default: false, null: false
    t.boolean "children_only",                               default: false, null: false
    t.boolean "individual_adult",                            default: false, null: false
    t.boolean "individual_elder",                            default: false, null: false
    t.boolean "head_of_household",                           default: false, null: false
  end

  add_index "service_history_enrollments", ["client_id", "record_type"], name: "index_she_on_client_id", using: :btree
  add_index "service_history_enrollments", ["computed_project_type", "record_type", "client_id"], name: "index_she_on_computed_project_type", using: :btree
  add_index "service_history_enrollments", ["data_source_id", "project_id", "organization_id", "record_type"], name: "index_she_ds_proj_org_r_type", using: :btree
  add_index "service_history_enrollments", ["date", "household_id", "record_type"], name: "index_she_on_household_id", using: :btree
  add_index "service_history_enrollments", ["date", "record_type", "presented_as_individual"], name: "index_she_date_r_type_indiv", using: :btree
  add_index "service_history_enrollments", ["enrollment_group_id", "project_tracking_method"], name: "index_she__enrollment_id_track_meth", using: :btree
  add_index "service_history_enrollments", ["first_date_in_program", "last_date_in_program", "record_type", "date"], name: "index_she_on_last_date_in_program", using: :btree
  add_index "service_history_enrollments", ["first_date_in_program"], name: "index_she_on_first_date_in_program", using: :brin
  add_index "service_history_enrollments", ["record_type", "date", "data_source_id", "organization_id", "project_id", "project_type", "project_tracking_method"], name: "index_she_date_ds_org_proj_proj_type", using: :btree

  create_table "service_history_services", force: :cascade do |t|
    t.integer "service_history_enrollment_id",            null: false
    t.string  "record_type",                   limit: 50, null: false
    t.date    "date",                                     null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  create_table "service_history_services_2000", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2000", ["client_id", "date", "record_type"], name: "index_shs_2000_date_client_id", using: :btree
  add_index "service_history_services_2000", ["date"], name: "index_shs_2000_date_brin", using: :brin
  add_index "service_history_services_2000", ["id"], name: "index_service_history_services_2000_on_id", unique: true, using: :btree
  add_index "service_history_services_2000", ["project_type", "date", "record_type"], name: "index_shs_2000_date_project_type", using: :btree
  add_index "service_history_services_2000", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2000_date_en_id", using: :btree

  create_table "service_history_services_2001", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2001", ["client_id", "date", "record_type"], name: "index_shs_2001_date_client_id", using: :btree
  add_index "service_history_services_2001", ["date"], name: "index_shs_2001_date_brin", using: :brin
  add_index "service_history_services_2001", ["id"], name: "index_service_history_services_2001_on_id", unique: true, using: :btree
  add_index "service_history_services_2001", ["project_type", "date", "record_type"], name: "index_shs_2001_date_project_type", using: :btree
  add_index "service_history_services_2001", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2001_date_en_id", using: :btree

  create_table "service_history_services_2002", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2002", ["client_id", "date", "record_type"], name: "index_shs_2002_date_client_id", using: :btree
  add_index "service_history_services_2002", ["date"], name: "index_shs_2002_date_brin", using: :brin
  add_index "service_history_services_2002", ["id"], name: "index_service_history_services_2002_on_id", unique: true, using: :btree
  add_index "service_history_services_2002", ["project_type", "date", "record_type"], name: "index_shs_2002_date_project_type", using: :btree
  add_index "service_history_services_2002", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2002_date_en_id", using: :btree

  create_table "service_history_services_2003", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2003", ["client_id", "date", "record_type"], name: "index_shs_2003_date_client_id", using: :btree
  add_index "service_history_services_2003", ["date"], name: "index_shs_2003_date_brin", using: :brin
  add_index "service_history_services_2003", ["id"], name: "index_service_history_services_2003_on_id", unique: true, using: :btree
  add_index "service_history_services_2003", ["project_type", "date", "record_type"], name: "index_shs_2003_date_project_type", using: :btree
  add_index "service_history_services_2003", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2003_date_en_id", using: :btree

  create_table "service_history_services_2004", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2004", ["client_id", "date", "record_type"], name: "index_shs_2004_date_client_id", using: :btree
  add_index "service_history_services_2004", ["date"], name: "index_shs_2004_date_brin", using: :brin
  add_index "service_history_services_2004", ["id"], name: "index_service_history_services_2004_on_id", unique: true, using: :btree
  add_index "service_history_services_2004", ["project_type", "date", "record_type"], name: "index_shs_2004_date_project_type", using: :btree
  add_index "service_history_services_2004", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2004_date_en_id", using: :btree

  create_table "service_history_services_2005", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2005", ["client_id", "date", "record_type"], name: "index_shs_2005_date_client_id", using: :btree
  add_index "service_history_services_2005", ["date"], name: "index_shs_2005_date_brin", using: :brin
  add_index "service_history_services_2005", ["id"], name: "index_service_history_services_2005_on_id", unique: true, using: :btree
  add_index "service_history_services_2005", ["project_type", "date", "record_type"], name: "index_shs_2005_date_project_type", using: :btree
  add_index "service_history_services_2005", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2005_date_en_id", using: :btree

  create_table "service_history_services_2006", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2006", ["client_id", "date", "record_type"], name: "index_shs_2006_date_client_id", using: :btree
  add_index "service_history_services_2006", ["date"], name: "index_shs_2006_date_brin", using: :brin
  add_index "service_history_services_2006", ["id"], name: "index_service_history_services_2006_on_id", unique: true, using: :btree
  add_index "service_history_services_2006", ["project_type", "date", "record_type"], name: "index_shs_2006_date_project_type", using: :btree
  add_index "service_history_services_2006", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2006_date_en_id", using: :btree

  create_table "service_history_services_2007", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2007", ["client_id", "date", "record_type"], name: "index_shs_2007_date_client_id", using: :btree
  add_index "service_history_services_2007", ["date"], name: "index_shs_2007_date_brin", using: :brin
  add_index "service_history_services_2007", ["id"], name: "index_service_history_services_2007_on_id", unique: true, using: :btree
  add_index "service_history_services_2007", ["project_type", "date", "record_type"], name: "index_shs_2007_date_project_type", using: :btree
  add_index "service_history_services_2007", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2007_date_en_id", using: :btree

  create_table "service_history_services_2008", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2008", ["client_id", "date", "record_type"], name: "index_shs_2008_date_client_id", using: :btree
  add_index "service_history_services_2008", ["date"], name: "index_shs_2008_date_brin", using: :brin
  add_index "service_history_services_2008", ["id"], name: "index_service_history_services_2008_on_id", unique: true, using: :btree
  add_index "service_history_services_2008", ["project_type", "date", "record_type"], name: "index_shs_2008_date_project_type", using: :btree
  add_index "service_history_services_2008", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2008_date_en_id", using: :btree

  create_table "service_history_services_2009", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2009", ["client_id", "date", "record_type"], name: "index_shs_2009_date_client_id", using: :btree
  add_index "service_history_services_2009", ["date"], name: "index_shs_2009_date_brin", using: :brin
  add_index "service_history_services_2009", ["id"], name: "index_service_history_services_2009_on_id", unique: true, using: :btree
  add_index "service_history_services_2009", ["project_type", "date", "record_type"], name: "index_shs_2009_date_project_type", using: :btree
  add_index "service_history_services_2009", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2009_date_en_id", using: :btree

  create_table "service_history_services_2010", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2010", ["client_id", "date", "record_type"], name: "index_shs_2010_date_client_id", using: :btree
  add_index "service_history_services_2010", ["date"], name: "index_shs_2010_date_brin", using: :brin
  add_index "service_history_services_2010", ["id"], name: "index_service_history_services_2010_on_id", unique: true, using: :btree
  add_index "service_history_services_2010", ["project_type", "date", "record_type"], name: "index_shs_2010_date_project_type", using: :btree
  add_index "service_history_services_2010", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2010_date_en_id", using: :btree

  create_table "service_history_services_2011", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2011", ["client_id", "date", "record_type"], name: "index_shs_2011_date_client_id", using: :btree
  add_index "service_history_services_2011", ["date"], name: "index_shs_2011_date_brin", using: :brin
  add_index "service_history_services_2011", ["id"], name: "index_service_history_services_2011_on_id", unique: true, using: :btree
  add_index "service_history_services_2011", ["project_type", "date", "record_type"], name: "index_shs_2011_date_project_type", using: :btree
  add_index "service_history_services_2011", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2011_date_en_id", using: :btree

  create_table "service_history_services_2012", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2012", ["client_id", "date", "record_type"], name: "index_shs_2012_date_client_id", using: :btree
  add_index "service_history_services_2012", ["date"], name: "index_shs_2012_date_brin", using: :brin
  add_index "service_history_services_2012", ["id"], name: "index_service_history_services_2012_on_id", unique: true, using: :btree
  add_index "service_history_services_2012", ["project_type", "date", "record_type"], name: "index_shs_2012_date_project_type", using: :btree
  add_index "service_history_services_2012", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2012_date_en_id", using: :btree

  create_table "service_history_services_2013", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2013", ["client_id", "date", "record_type"], name: "index_shs_2013_date_client_id", using: :btree
  add_index "service_history_services_2013", ["date"], name: "index_shs_2013_date_brin", using: :brin
  add_index "service_history_services_2013", ["id"], name: "index_service_history_services_2013_on_id", unique: true, using: :btree
  add_index "service_history_services_2013", ["project_type", "date", "record_type"], name: "index_shs_2013_date_project_type", using: :btree
  add_index "service_history_services_2013", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2013_date_en_id", using: :btree

  create_table "service_history_services_2014", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2014", ["client_id", "date", "record_type"], name: "index_shs_2014_date_client_id", using: :btree
  add_index "service_history_services_2014", ["date"], name: "index_shs_2014_date_brin", using: :brin
  add_index "service_history_services_2014", ["id"], name: "index_service_history_services_2014_on_id", unique: true, using: :btree
  add_index "service_history_services_2014", ["project_type", "date", "record_type"], name: "index_shs_2014_date_project_type", using: :btree
  add_index "service_history_services_2014", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2014_date_en_id", using: :btree

  create_table "service_history_services_2015", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2015", ["client_id", "date", "record_type"], name: "index_shs_2015_date_client_id", using: :btree
  add_index "service_history_services_2015", ["date"], name: "index_shs_2015_date_brin", using: :brin
  add_index "service_history_services_2015", ["id"], name: "index_service_history_services_2015_on_id", unique: true, using: :btree
  add_index "service_history_services_2015", ["project_type", "date", "record_type"], name: "index_shs_2015_date_project_type", using: :btree
  add_index "service_history_services_2015", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2015_date_en_id", using: :btree

  create_table "service_history_services_2016", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2016", ["client_id", "date", "record_type"], name: "index_shs_2016_date_client_id", using: :btree
  add_index "service_history_services_2016", ["date"], name: "index_shs_2016_date_brin", using: :brin
  add_index "service_history_services_2016", ["id"], name: "index_service_history_services_2016_on_id", unique: true, using: :btree
  add_index "service_history_services_2016", ["project_type", "date", "record_type"], name: "index_shs_2016_date_project_type", using: :btree
  add_index "service_history_services_2016", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2016_date_en_id", using: :btree

  create_table "service_history_services_2017", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2017", ["client_id", "date", "record_type"], name: "index_shs_2017_date_client_id", using: :btree
  add_index "service_history_services_2017", ["date"], name: "index_shs_2017_date_brin", using: :brin
  add_index "service_history_services_2017", ["id"], name: "index_service_history_services_2017_on_id", unique: true, using: :btree
  add_index "service_history_services_2017", ["project_type", "date", "record_type"], name: "index_shs_2017_date_project_type", using: :btree
  add_index "service_history_services_2017", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2017_date_en_id", using: :btree

  create_table "service_history_services_2018", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2018", ["client_id", "date", "record_type"], name: "index_shs_2018_date_client_id", using: :btree
  add_index "service_history_services_2018", ["date"], name: "index_shs_2018_date_brin", using: :brin
  add_index "service_history_services_2018", ["id"], name: "index_service_history_services_2018_on_id", unique: true, using: :btree
  add_index "service_history_services_2018", ["project_type", "date", "record_type"], name: "index_shs_2018_date_project_type", using: :btree
  add_index "service_history_services_2018", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2018_date_en_id", using: :btree

  create_table "service_history_services_2019", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2019", ["client_id", "date", "record_type"], name: "index_shs_2019_date_client_id", using: :btree
  add_index "service_history_services_2019", ["date"], name: "index_shs_2019_date_brin", using: :brin
  add_index "service_history_services_2019", ["id"], name: "index_service_history_services_2019_on_id", unique: true, using: :btree
  add_index "service_history_services_2019", ["project_type", "date", "record_type"], name: "index_shs_2019_date_project_type", using: :btree
  add_index "service_history_services_2019", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2019_date_en_id", using: :btree

  create_table "service_history_services_2020", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2020", ["client_id", "date", "record_type"], name: "index_shs_2020_date_client_id", using: :btree
  add_index "service_history_services_2020", ["date"], name: "index_shs_2020_date_brin", using: :brin
  add_index "service_history_services_2020", ["id"], name: "index_service_history_services_2020_on_id", unique: true, using: :btree
  add_index "service_history_services_2020", ["project_type", "date", "record_type"], name: "index_shs_2020_date_project_type", using: :btree
  add_index "service_history_services_2020", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2020_date_en_id", using: :btree

  create_table "service_history_services_2021", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2021", ["client_id", "date", "record_type"], name: "index_shs_2021_date_client_id", using: :btree
  add_index "service_history_services_2021", ["date"], name: "index_shs_2021_date_brin", using: :brin
  add_index "service_history_services_2021", ["id"], name: "index_service_history_services_2021_on_id", unique: true, using: :btree
  add_index "service_history_services_2021", ["project_type", "date", "record_type"], name: "index_shs_2021_date_project_type", using: :btree
  add_index "service_history_services_2021", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2021_date_en_id", using: :btree

  create_table "service_history_services_2022", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2022", ["client_id", "date", "record_type"], name: "index_shs_2022_date_client_id", using: :btree
  add_index "service_history_services_2022", ["date"], name: "index_shs_2022_date_brin", using: :brin
  add_index "service_history_services_2022", ["id"], name: "index_service_history_services_2022_on_id", unique: true, using: :btree
  add_index "service_history_services_2022", ["project_type", "date", "record_type"], name: "index_shs_2022_date_project_type", using: :btree
  add_index "service_history_services_2022", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2022_date_en_id", using: :btree

  create_table "service_history_services_2023", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2023", ["client_id", "date", "record_type"], name: "index_shs_2023_date_client_id", using: :btree
  add_index "service_history_services_2023", ["date"], name: "index_shs_2023_date_brin", using: :brin
  add_index "service_history_services_2023", ["id"], name: "index_service_history_services_2023_on_id", unique: true, using: :btree
  add_index "service_history_services_2023", ["project_type", "date", "record_type"], name: "index_shs_2023_date_project_type", using: :btree
  add_index "service_history_services_2023", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2023_date_en_id", using: :btree

  create_table "service_history_services_2024", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2024", ["client_id", "date", "record_type"], name: "index_shs_2024_date_client_id", using: :btree
  add_index "service_history_services_2024", ["date"], name: "index_shs_2024_date_brin", using: :brin
  add_index "service_history_services_2024", ["id"], name: "index_service_history_services_2024_on_id", unique: true, using: :btree
  add_index "service_history_services_2024", ["project_type", "date", "record_type"], name: "index_shs_2024_date_project_type", using: :btree
  add_index "service_history_services_2024", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2024_date_en_id", using: :btree

  create_table "service_history_services_2025", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2025", ["client_id", "date", "record_type"], name: "index_shs_2025_date_client_id", using: :btree
  add_index "service_history_services_2025", ["date"], name: "index_shs_2025_date_brin", using: :brin
  add_index "service_history_services_2025", ["id"], name: "index_service_history_services_2025_on_id", unique: true, using: :btree
  add_index "service_history_services_2025", ["project_type", "date", "record_type"], name: "index_shs_2025_date_project_type", using: :btree
  add_index "service_history_services_2025", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2025_date_en_id", using: :btree

  create_table "service_history_services_2026", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2026", ["client_id", "date", "record_type"], name: "index_shs_2026_date_client_id", using: :btree
  add_index "service_history_services_2026", ["date"], name: "index_shs_2026_date_brin", using: :brin
  add_index "service_history_services_2026", ["id"], name: "index_service_history_services_2026_on_id", unique: true, using: :btree
  add_index "service_history_services_2026", ["project_type", "date", "record_type"], name: "index_shs_2026_date_project_type", using: :btree
  add_index "service_history_services_2026", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2026_date_en_id", using: :btree

  create_table "service_history_services_2027", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2027", ["client_id", "date", "record_type"], name: "index_shs_2027_date_client_id", using: :btree
  add_index "service_history_services_2027", ["date"], name: "index_shs_2027_date_brin", using: :brin
  add_index "service_history_services_2027", ["id"], name: "index_service_history_services_2027_on_id", unique: true, using: :btree
  add_index "service_history_services_2027", ["project_type", "date", "record_type"], name: "index_shs_2027_date_project_type", using: :btree
  add_index "service_history_services_2027", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2027_date_en_id", using: :btree

  create_table "service_history_services_2028", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2028", ["client_id", "date", "record_type"], name: "index_shs_2028_date_client_id", using: :btree
  add_index "service_history_services_2028", ["date"], name: "index_shs_2028_date_brin", using: :brin
  add_index "service_history_services_2028", ["id"], name: "index_service_history_services_2028_on_id", unique: true, using: :btree
  add_index "service_history_services_2028", ["project_type", "date", "record_type"], name: "index_shs_2028_date_project_type", using: :btree
  add_index "service_history_services_2028", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2028_date_en_id", using: :btree

  create_table "service_history_services_2029", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2029", ["client_id", "date", "record_type"], name: "index_shs_2029_date_client_id", using: :btree
  add_index "service_history_services_2029", ["date"], name: "index_shs_2029_date_brin", using: :brin
  add_index "service_history_services_2029", ["id"], name: "index_service_history_services_2029_on_id", unique: true, using: :btree
  add_index "service_history_services_2029", ["project_type", "date", "record_type"], name: "index_shs_2029_date_project_type", using: :btree
  add_index "service_history_services_2029", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2029_date_en_id", using: :btree

  create_table "service_history_services_2030", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2030", ["client_id", "date", "record_type"], name: "index_shs_2030_date_client_id", using: :btree
  add_index "service_history_services_2030", ["date"], name: "index_shs_2030_date_brin", using: :brin
  add_index "service_history_services_2030", ["id"], name: "index_service_history_services_2030_on_id", unique: true, using: :btree
  add_index "service_history_services_2030", ["project_type", "date", "record_type"], name: "index_shs_2030_date_project_type", using: :btree
  add_index "service_history_services_2030", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2030_date_en_id", using: :btree

  create_table "service_history_services_2031", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2031", ["client_id", "date", "record_type"], name: "index_shs_2031_date_client_id", using: :btree
  add_index "service_history_services_2031", ["date"], name: "index_shs_2031_date_brin", using: :brin
  add_index "service_history_services_2031", ["id"], name: "index_service_history_services_2031_on_id", unique: true, using: :btree
  add_index "service_history_services_2031", ["project_type", "date", "record_type"], name: "index_shs_2031_date_project_type", using: :btree
  add_index "service_history_services_2031", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2031_date_en_id", using: :btree

  create_table "service_history_services_2032", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2032", ["client_id", "date", "record_type"], name: "index_shs_2032_date_client_id", using: :btree
  add_index "service_history_services_2032", ["date"], name: "index_shs_2032_date_brin", using: :brin
  add_index "service_history_services_2032", ["id"], name: "index_service_history_services_2032_on_id", unique: true, using: :btree
  add_index "service_history_services_2032", ["project_type", "date", "record_type"], name: "index_shs_2032_date_project_type", using: :btree
  add_index "service_history_services_2032", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2032_date_en_id", using: :btree

  create_table "service_history_services_2033", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2033", ["client_id", "date", "record_type"], name: "index_shs_2033_date_client_id", using: :btree
  add_index "service_history_services_2033", ["date"], name: "index_shs_2033_date_brin", using: :brin
  add_index "service_history_services_2033", ["id"], name: "index_service_history_services_2033_on_id", unique: true, using: :btree
  add_index "service_history_services_2033", ["project_type", "date", "record_type"], name: "index_shs_2033_date_project_type", using: :btree
  add_index "service_history_services_2033", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2033_date_en_id", using: :btree

  create_table "service_history_services_2034", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2034", ["client_id", "date", "record_type"], name: "index_shs_2034_date_client_id", using: :btree
  add_index "service_history_services_2034", ["date"], name: "index_shs_2034_date_brin", using: :brin
  add_index "service_history_services_2034", ["id"], name: "index_service_history_services_2034_on_id", unique: true, using: :btree
  add_index "service_history_services_2034", ["project_type", "date", "record_type"], name: "index_shs_2034_date_project_type", using: :btree
  add_index "service_history_services_2034", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2034_date_en_id", using: :btree

  create_table "service_history_services_2035", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2035", ["client_id", "date", "record_type"], name: "index_shs_2035_date_client_id", using: :btree
  add_index "service_history_services_2035", ["date"], name: "index_shs_2035_date_brin", using: :brin
  add_index "service_history_services_2035", ["id"], name: "index_service_history_services_2035_on_id", unique: true, using: :btree
  add_index "service_history_services_2035", ["project_type", "date", "record_type"], name: "index_shs_2035_date_project_type", using: :btree
  add_index "service_history_services_2035", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2035_date_en_id", using: :btree

  create_table "service_history_services_2036", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2036", ["client_id", "date", "record_type"], name: "index_shs_2036_date_client_id", using: :btree
  add_index "service_history_services_2036", ["date"], name: "index_shs_2036_date_brin", using: :brin
  add_index "service_history_services_2036", ["id"], name: "index_service_history_services_2036_on_id", unique: true, using: :btree
  add_index "service_history_services_2036", ["project_type", "date", "record_type"], name: "index_shs_2036_date_project_type", using: :btree
  add_index "service_history_services_2036", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2036_date_en_id", using: :btree

  create_table "service_history_services_2037", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2037", ["client_id", "date", "record_type"], name: "index_shs_2037_date_client_id", using: :btree
  add_index "service_history_services_2037", ["date"], name: "index_shs_2037_date_brin", using: :brin
  add_index "service_history_services_2037", ["id"], name: "index_service_history_services_2037_on_id", unique: true, using: :btree
  add_index "service_history_services_2037", ["project_type", "date", "record_type"], name: "index_shs_2037_date_project_type", using: :btree
  add_index "service_history_services_2037", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2037_date_en_id", using: :btree

  create_table "service_history_services_2038", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2038", ["client_id", "date", "record_type"], name: "index_shs_2038_date_client_id", using: :btree
  add_index "service_history_services_2038", ["date"], name: "index_shs_2038_date_brin", using: :brin
  add_index "service_history_services_2038", ["id"], name: "index_service_history_services_2038_on_id", unique: true, using: :btree
  add_index "service_history_services_2038", ["project_type", "date", "record_type"], name: "index_shs_2038_date_project_type", using: :btree
  add_index "service_history_services_2038", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2038_date_en_id", using: :btree

  create_table "service_history_services_2039", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2039", ["client_id", "date", "record_type"], name: "index_shs_2039_date_client_id", using: :btree
  add_index "service_history_services_2039", ["date"], name: "index_shs_2039_date_brin", using: :brin
  add_index "service_history_services_2039", ["id"], name: "index_service_history_services_2039_on_id", unique: true, using: :btree
  add_index "service_history_services_2039", ["project_type", "date", "record_type"], name: "index_shs_2039_date_project_type", using: :btree
  add_index "service_history_services_2039", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2039_date_en_id", using: :btree

  create_table "service_history_services_2040", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2040", ["client_id", "date", "record_type"], name: "index_shs_2040_date_client_id", using: :btree
  add_index "service_history_services_2040", ["date"], name: "index_shs_2040_date_brin", using: :brin
  add_index "service_history_services_2040", ["id"], name: "index_service_history_services_2040_on_id", unique: true, using: :btree
  add_index "service_history_services_2040", ["project_type", "date", "record_type"], name: "index_shs_2040_date_project_type", using: :btree
  add_index "service_history_services_2040", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2040_date_en_id", using: :btree

  create_table "service_history_services_2041", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2041", ["client_id", "date", "record_type"], name: "index_shs_2041_date_client_id", using: :btree
  add_index "service_history_services_2041", ["date"], name: "index_shs_2041_date_brin", using: :brin
  add_index "service_history_services_2041", ["id"], name: "index_service_history_services_2041_on_id", unique: true, using: :btree
  add_index "service_history_services_2041", ["project_type", "date", "record_type"], name: "index_shs_2041_date_project_type", using: :btree
  add_index "service_history_services_2041", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2041_date_en_id", using: :btree

  create_table "service_history_services_2042", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2042", ["client_id", "date", "record_type"], name: "index_shs_2042_date_client_id", using: :btree
  add_index "service_history_services_2042", ["date"], name: "index_shs_2042_date_brin", using: :brin
  add_index "service_history_services_2042", ["id"], name: "index_service_history_services_2042_on_id", unique: true, using: :btree
  add_index "service_history_services_2042", ["project_type", "date", "record_type"], name: "index_shs_2042_date_project_type", using: :btree
  add_index "service_history_services_2042", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2042_date_en_id", using: :btree

  create_table "service_history_services_2043", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2043", ["client_id", "date", "record_type"], name: "index_shs_2043_date_client_id", using: :btree
  add_index "service_history_services_2043", ["date"], name: "index_shs_2043_date_brin", using: :brin
  add_index "service_history_services_2043", ["id"], name: "index_service_history_services_2043_on_id", unique: true, using: :btree
  add_index "service_history_services_2043", ["project_type", "date", "record_type"], name: "index_shs_2043_date_project_type", using: :btree
  add_index "service_history_services_2043", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2043_date_en_id", using: :btree

  create_table "service_history_services_2044", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2044", ["client_id", "date", "record_type"], name: "index_shs_2044_date_client_id", using: :btree
  add_index "service_history_services_2044", ["date"], name: "index_shs_2044_date_brin", using: :brin
  add_index "service_history_services_2044", ["id"], name: "index_service_history_services_2044_on_id", unique: true, using: :btree
  add_index "service_history_services_2044", ["project_type", "date", "record_type"], name: "index_shs_2044_date_project_type", using: :btree
  add_index "service_history_services_2044", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2044_date_en_id", using: :btree

  create_table "service_history_services_2045", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2045", ["client_id", "date", "record_type"], name: "index_shs_2045_date_client_id", using: :btree
  add_index "service_history_services_2045", ["date"], name: "index_shs_2045_date_brin", using: :brin
  add_index "service_history_services_2045", ["id"], name: "index_service_history_services_2045_on_id", unique: true, using: :btree
  add_index "service_history_services_2045", ["project_type", "date", "record_type"], name: "index_shs_2045_date_project_type", using: :btree
  add_index "service_history_services_2045", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2045_date_en_id", using: :btree

  create_table "service_history_services_2046", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2046", ["client_id", "date", "record_type"], name: "index_shs_2046_date_client_id", using: :btree
  add_index "service_history_services_2046", ["date"], name: "index_shs_2046_date_brin", using: :brin
  add_index "service_history_services_2046", ["id"], name: "index_service_history_services_2046_on_id", unique: true, using: :btree
  add_index "service_history_services_2046", ["project_type", "date", "record_type"], name: "index_shs_2046_date_project_type", using: :btree
  add_index "service_history_services_2046", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2046_date_en_id", using: :btree

  create_table "service_history_services_2047", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2047", ["client_id", "date", "record_type"], name: "index_shs_2047_date_client_id", using: :btree
  add_index "service_history_services_2047", ["date"], name: "index_shs_2047_date_brin", using: :brin
  add_index "service_history_services_2047", ["id"], name: "index_service_history_services_2047_on_id", unique: true, using: :btree
  add_index "service_history_services_2047", ["project_type", "date", "record_type"], name: "index_shs_2047_date_project_type", using: :btree
  add_index "service_history_services_2047", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2047_date_en_id", using: :btree

  create_table "service_history_services_2048", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2048", ["client_id", "date", "record_type"], name: "index_shs_2048_date_client_id", using: :btree
  add_index "service_history_services_2048", ["date"], name: "index_shs_2048_date_brin", using: :brin
  add_index "service_history_services_2048", ["id"], name: "index_service_history_services_2048_on_id", unique: true, using: :btree
  add_index "service_history_services_2048", ["project_type", "date", "record_type"], name: "index_shs_2048_date_project_type", using: :btree
  add_index "service_history_services_2048", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2048_date_en_id", using: :btree

  create_table "service_history_services_2049", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2049", ["client_id", "date", "record_type"], name: "index_shs_2049_date_client_id", using: :btree
  add_index "service_history_services_2049", ["date"], name: "index_shs_2049_date_brin", using: :brin
  add_index "service_history_services_2049", ["id"], name: "index_service_history_services_2049_on_id", unique: true, using: :btree
  add_index "service_history_services_2049", ["project_type", "date", "record_type"], name: "index_shs_2049_date_project_type", using: :btree
  add_index "service_history_services_2049", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2049_date_en_id", using: :btree

  create_table "service_history_services_2050", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_2050", ["client_id", "date", "record_type"], name: "index_shs_2050_date_client_id", using: :btree
  add_index "service_history_services_2050", ["date"], name: "index_shs_2050_date_brin", using: :brin
  add_index "service_history_services_2050", ["id"], name: "index_service_history_services_2050_on_id", unique: true, using: :btree
  add_index "service_history_services_2050", ["project_type", "date", "record_type"], name: "index_shs_2050_date_project_type", using: :btree
  add_index "service_history_services_2050", ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2050_date_en_id", using: :btree

  create_table "service_history_services_remainder", id: false, force: :cascade do |t|
    t.integer "id",                                       default: "nextval('service_history_services_id_seq'::regclass)", null: false
    t.integer "service_history_enrollment_id",                                                                             null: false
    t.string  "record_type",                   limit: 50,                                                                  null: false
    t.date    "date",                                                                                                      null: false
    t.integer "age",                           limit: 2
    t.integer "service_type",                  limit: 2
    t.integer "client_id"
    t.integer "project_type",                  limit: 2
  end

  add_index "service_history_services_remainder", ["date", "client_id"], name: "index_shs_1900_date_client_id", using: :btree
  add_index "service_history_services_remainder", ["date", "project_type"], name: "index_shs_1900_date_project_type", using: :btree
  add_index "service_history_services_remainder", ["date", "service_history_enrollment_id"], name: "index_shs_1900_date_en_id", using: :btree
  add_index "service_history_services_remainder", ["date"], name: "index_shs_1900_date_brin", using: :brin
  add_index "service_history_services_remainder", ["id"], name: "index_service_history_services_remainder_on_id", unique: true, using: :btree

  create_table "taggings", force: :cascade do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["context"], name: "index_taggings_on_context", using: :btree
  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy", using: :btree
  add_index "taggings", ["taggable_id"], name: "index_taggings_on_taggable_id", using: :btree
  add_index "taggings", ["taggable_type"], name: "index_taggings_on_taggable_type", using: :btree
  add_index "taggings", ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type", using: :btree
  add_index "taggings", ["tagger_id"], name: "index_taggings_on_tagger_id", using: :btree

  create_table "tags", force: :cascade do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "uploads", force: :cascade do |t|
    t.integer  "data_source_id"
    t.integer  "user_id"
    t.string   "file",             null: false
    t.float    "percent_complete"
    t.string   "unzipped_path"
    t.json     "unzipped_files"
    t.json     "summary"
    t.json     "import_errors"
    t.string   "content_type"
    t.binary   "content"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "deleted_at"
    t.integer  "delayed_job_id"
  end

  add_index "uploads", ["deleted_at"], name: "index_uploads_on_deleted_at", using: :btree

  create_table "user_clients", force: :cascade do |t|
    t.integer  "user_id",                              null: false
    t.integer  "client_id",                            null: false
    t.boolean  "confidential",         default: false, null: false
    t.string   "relationship"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.datetime "deleted_at"
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "client_notifications", default: false
  end

  add_index "user_clients", ["client_id"], name: "index_user_clients_on_client_id", using: :btree
  add_index "user_clients", ["user_id"], name: "index_user_clients_on_user_id", using: :btree

  create_table "user_viewable_entities", force: :cascade do |t|
    t.integer "user_id",     null: false
    t.integer "entity_id",   null: false
    t.string  "entity_type", null: false
  end

  add_index "user_viewable_entities", ["user_id", "entity_id", "entity_type"], name: "one_entity_per_type_per_user", unique: true, using: :btree

  create_table "vispdats", force: :cascade do |t|
    t.integer  "client_id"
    t.string   "nickname"
    t.integer  "language_answer"
    t.boolean  "hiv_release"
    t.integer  "sleep_answer"
    t.string   "sleep_answer_other"
    t.integer  "homeless"
    t.boolean  "homeless_refused"
    t.integer  "episodes_homeless"
    t.boolean  "episodes_homeless_refused"
    t.integer  "emergency_healthcare"
    t.boolean  "emergency_healthcare_refused"
    t.integer  "ambulance"
    t.boolean  "ambulance_refused"
    t.integer  "inpatient"
    t.boolean  "inpatient_refused"
    t.integer  "crisis_service"
    t.boolean  "crisis_service_refused"
    t.integer  "talked_to_police"
    t.boolean  "talked_to_police_refused"
    t.integer  "jail"
    t.boolean  "jail_refused"
    t.integer  "attacked_answer"
    t.integer  "threatened_answer"
    t.integer  "legal_answer"
    t.integer  "tricked_answer"
    t.integer  "risky_answer"
    t.integer  "owe_money_answer"
    t.integer  "get_money_answer"
    t.integer  "activities_answer"
    t.integer  "basic_needs_answer"
    t.integer  "abusive_answer"
    t.integer  "leave_answer"
    t.integer  "chronic_answer"
    t.integer  "hiv_answer"
    t.integer  "disability_answer"
    t.integer  "avoid_help_answer"
    t.integer  "pregnant_answer"
    t.integer  "eviction_answer"
    t.integer  "drinking_answer"
    t.integer  "mental_answer"
    t.integer  "head_answer"
    t.integer  "learning_answer"
    t.integer  "brain_answer"
    t.integer  "medication_answer"
    t.integer  "sell_answer"
    t.integer  "trauma_answer"
    t.string   "find_location"
    t.string   "find_time"
    t.integer  "when_answer"
    t.string   "phone"
    t.string   "email"
    t.integer  "picture_answer"
    t.integer  "score"
    t.string   "recommendation"
    t.datetime "created_at",                                                                                         null: false
    t.datetime "updated_at",                                                                                         null: false
    t.datetime "submitted_at"
    t.integer  "homeless_period"
    t.date     "release_signed_on"
    t.boolean  "drug_release"
    t.string   "migrated_case_manager"
    t.string   "migrated_interviewer_name"
    t.string   "migrated_interviewer_email"
    t.string   "migrated_filed_by"
    t.boolean  "migrated",                                            default: false,                                null: false
    t.boolean  "housing_release_confirmed",                           default: false
    t.integer  "user_id"
    t.integer  "priority_score"
    t.boolean  "active",                                              default: false
    t.string   "type",                                                default: "GrdaWarehouse::Vispdat::Individual"
    t.integer  "marijuana_answer"
    t.integer  "incarcerated_before_18_answer"
    t.integer  "homeless_due_to_ran_away_answer"
    t.integer  "homeless_due_to_religions_beliefs_answer"
    t.integer  "homeless_due_to_family_answer"
    t.integer  "homeless_due_to_gender_identity_answer"
    t.integer  "violence_between_family_members_answer"
    t.boolean  "parent2_none",                                        default: false
    t.string   "parent2_first_name"
    t.string   "parent2_nickname"
    t.string   "parent2_last_name"
    t.string   "parent2_language_answer"
    t.date     "parent2_dob"
    t.string   "parent2_ssn"
    t.date     "parent2_release_signed_on"
    t.boolean  "parent2_drug_release",                                default: false
    t.boolean  "parent2_hiv_release",                                 default: false
    t.integer  "number_of_children_under_18_with_family"
    t.boolean  "number_of_children_under_18_with_family_refused",     default: false
    t.integer  "number_of_children_under_18_not_with_family"
    t.boolean  "number_of_children_under_18_not_with_family_refused", default: false
    t.integer  "any_member_pregnant_answer"
    t.integer  "family_member_tri_morbidity_answer"
    t.integer  "any_children_removed_answer"
    t.integer  "any_family_legal_issues_answer"
    t.integer  "any_children_lived_with_family_answer"
    t.integer  "any_child_abuse_answer"
    t.integer  "children_attend_school_answer"
    t.integer  "family_members_changed_answer"
    t.integer  "other_family_members_answer"
    t.integer  "planned_family_activities_answer"
    t.integer  "time_spent_alone_13_answer"
    t.integer  "time_spent_alone_12_answer"
    t.integer  "time_spent_helping_siblings_answer"
    t.integer  "number_of_bedrooms",                                  default: 0
  end

  add_index "vispdats", ["client_id"], name: "index_vispdats_on_client_id", using: :btree
  add_index "vispdats", ["user_id"], name: "index_vispdats_on_user_id", using: :btree

  create_table "warehouse_client_service_history", force: :cascade do |t|
    t.integer "client_id",                                                   null: false
    t.integer "data_source_id"
    t.date    "date",                                                        null: false
    t.date    "first_date_in_program",                                       null: false
    t.date    "last_date_in_program"
    t.string  "enrollment_group_id",             limit: 50
    t.integer "age"
    t.integer "destination"
    t.string  "head_of_household_id",            limit: 50
    t.string  "household_id",                    limit: 50
    t.string  "project_name",                    limit: 150
    t.integer "project_type"
    t.integer "project_tracking_method"
    t.string  "organization_id",                 limit: 50
    t.string  "record_type",                     limit: 50,                  null: false
    t.integer "housing_status_at_entry"
    t.integer "housing_status_at_exit"
    t.integer "service_type"
    t.integer "computed_project_type"
    t.boolean "presented_as_individual"
    t.integer "other_clients_over_25",                       default: 0,     null: false
    t.integer "other_clients_under_18",                      default: 0,     null: false
    t.integer "other_clients_between_18_and_25",             default: 0,     null: false
    t.boolean "unaccompanied_youth",                         default: false, null: false
    t.boolean "parenting_youth",                             default: false, null: false
    t.boolean "parenting_juvenile",                          default: false, null: false
    t.boolean "children_only",                               default: false, null: false
    t.boolean "individual_adult",                            default: false, null: false
    t.boolean "individual_elder",                            default: false, null: false
    t.boolean "head_of_household",                           default: false, null: false
    t.string  "project_id",                      limit: 50
  end

  add_index "warehouse_client_service_history", ["client_id", "record_type"], name: "index_sh_on_client_id", using: :btree
  add_index "warehouse_client_service_history", ["computed_project_type", "record_type", "client_id"], name: "index_sh_on_computed_project_type", using: :btree
  add_index "warehouse_client_service_history", ["data_source_id", "project_id", "organization_id", "record_type"], name: "index_sh_ds_proj_org_r_type", using: :btree
  add_index "warehouse_client_service_history", ["date", "household_id", "record_type"], name: "index_sh_on_household_id", using: :btree
  add_index "warehouse_client_service_history", ["date", "record_type", "presented_as_individual"], name: "index_sh_date_r_type_indiv", using: :btree
  add_index "warehouse_client_service_history", ["enrollment_group_id", "project_tracking_method"], name: "index_sh__enrollment_id_track_meth", using: :btree
  add_index "warehouse_client_service_history", ["first_date_in_program", "last_date_in_program", "record_type", "date"], name: "index_wsh_on_last_date_in_program", using: :btree
  add_index "warehouse_client_service_history", ["first_date_in_program"], name: "index_warehouse_client_service_history_on_first_date_in_program", using: :brin
  add_index "warehouse_client_service_history", ["record_type", "date", "data_source_id", "organization_id", "project_id", "project_type", "project_tracking_method"], name: "index_sh_date_ds_org_proj_proj_type", using: :btree

  create_table "warehouse_clients", force: :cascade do |t|
    t.string   "id_in_source",    null: false
    t.integer  "data_source_id"
    t.datetime "proposed_at"
    t.datetime "reviewed_at"
    t.string   "reviewd_by"
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.datetime "deleted_at"
    t.integer  "source_id"
    t.integer  "destination_id"
    t.integer  "client_match_id"
  end

  add_index "warehouse_clients", ["deleted_at"], name: "index_warehouse_clients_on_deleted_at", using: :btree
  add_index "warehouse_clients", ["destination_id"], name: "index_warehouse_clients_on_destination_id", using: :btree
  add_index "warehouse_clients", ["id_in_source"], name: "index_warehouse_clients_on_id_in_source", using: :btree
  add_index "warehouse_clients", ["source_id"], name: "index_warehouse_clients_on_source_id", unique: true, using: :btree

  create_table "warehouse_clients_processed", force: :cascade do |t|
    t.integer  "client_id"
    t.string   "routine"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.datetime "last_service_updated_at"
    t.integer  "days_served"
    t.date     "first_date_served"
    t.date     "last_date_served"
    t.date     "first_homeless_date"
    t.date     "last_homeless_date"
    t.integer  "homeless_days"
    t.date     "first_chronic_date"
    t.date     "last_chronic_date"
    t.integer  "chronic_days"
    t.integer  "days_homeless_last_three_years"
    t.integer  "literally_homeless_last_three_years"
  end

  add_index "warehouse_clients_processed", ["chronic_days"], name: "index_warehouse_clients_processed_on_chronic_days", using: :btree
  add_index "warehouse_clients_processed", ["days_served"], name: "index_warehouse_clients_processed_on_days_served", using: :btree
  add_index "warehouse_clients_processed", ["homeless_days"], name: "index_warehouse_clients_processed_on_homeless_days", using: :btree
  add_index "warehouse_clients_processed", ["routine"], name: "index_warehouse_clients_processed_on_routine", using: :btree

  create_table "warehouse_reports", force: :cascade do |t|
    t.json     "parameters"
    t.json     "data"
    t.string   "type"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "client_count"
    t.json     "support"
    t.string   "token"
  end

  create_table "weather", force: :cascade do |t|
    t.string   "url",        null: false
    t.text     "body",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "weather", ["url"], name: "index_weather_on_url", using: :btree

  add_foreign_key "Affiliation", "data_sources"
  add_foreign_key "Client", "data_sources"
  add_foreign_key "Disabilities", "data_sources"
  add_foreign_key "EmploymentEducation", "data_sources"
  add_foreign_key "Enrollment", "data_sources"
  add_foreign_key "EnrollmentCoC", "data_sources"
  add_foreign_key "Exit", "data_sources"
  add_foreign_key "Funder", "data_sources"
  add_foreign_key "HealthAndDV", "data_sources"
  add_foreign_key "IncomeBenefits", "data_sources"
  add_foreign_key "Inventory", "data_sources"
  add_foreign_key "Organization", "data_sources"
  add_foreign_key "Project", "data_sources"
  add_foreign_key "ProjectCoC", "data_sources"
  add_foreign_key "Services", "data_sources"
  add_foreign_key "Site", "data_sources"
  add_foreign_key "files", "vispdats"
  add_foreign_key "import_logs", "data_sources"
  add_foreign_key "service_history_services", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2000", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2001", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2002", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2003", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2004", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2005", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2006", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2007", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2008", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2009", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2010", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2011", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2012", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2013", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2014", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2015", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2016", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2017", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2018", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2019", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2020", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2021", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2022", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2023", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2024", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2025", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2026", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2027", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2028", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2029", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2030", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2031", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2032", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2033", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2034", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2035", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2036", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2037", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2038", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2039", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2040", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2041", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2042", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2043", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2044", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2045", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2046", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2047", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2048", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2049", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_2050", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "service_history_services_remainder", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "warehouse_clients", "\"Client\"", column: "destination_id"
  add_foreign_key "warehouse_clients", "\"Client\"", column: "source_id"
  add_foreign_key "warehouse_clients", "data_sources"
  add_foreign_key "warehouse_clients_processed", "\"Client\"", column: "client_id"

  create_view "report_clients",  sql_definition: <<-SQL
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
  SQL

  create_view "report_demographics",  sql_definition: <<-SQL
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
  SQL

  create_view "report_disabilities",  sql_definition: <<-SQL
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
      "Enrollment".id AS enrollment_id,
      source_clients.id AS demographic_id,
      destination_clients.id AS client_id
     FROM (((("Disabilities"
       JOIN "Client" source_clients ON ((("Disabilities".data_source_id = source_clients.data_source_id) AND (("Disabilities"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("Disabilities".data_source_id = "Enrollment".data_source_id) AND (("Disabilities"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("Disabilities"."ProjectEntryID")::text = ("Enrollment"."ProjectEntryID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("Disabilities"."DateDeleted" IS NULL);
  SQL

  create_view "report_employment_educations",  sql_definition: <<-SQL
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
      "Enrollment".id AS enrollment_id,
      source_clients.id AS demographic_id,
      destination_clients.id AS client_id
     FROM (((("EmploymentEducation"
       JOIN "Client" source_clients ON ((("EmploymentEducation".data_source_id = source_clients.data_source_id) AND (("EmploymentEducation"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("EmploymentEducation".data_source_id = "Enrollment".data_source_id) AND (("EmploymentEducation"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("EmploymentEducation"."ProjectEntryID")::text = ("Enrollment"."ProjectEntryID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("EmploymentEducation"."DateDeleted" IS NULL);
  SQL

  create_view "report_enrollments",  sql_definition: <<-SQL
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
      "Enrollment"."RunawayYouth",
      "Enrollment".processed_hash,
      source_clients.id AS demographic_id,
      destination_clients.id AS client_id
     FROM ((("Enrollment"
       JOIN "Client" source_clients ON ((("Enrollment".data_source_id = source_clients.data_source_id) AND (("Enrollment"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
    WHERE ("Enrollment"."DateDeleted" IS NULL);
  SQL

  create_view "report_exits",  sql_definition: <<-SQL
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
     FROM (((("Exit"
       JOIN "Client" source_clients ON ((("Exit".data_source_id = source_clients.data_source_id) AND (("Exit"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("Exit".data_source_id = "Enrollment".data_source_id) AND (("Exit"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("Exit"."ProjectEntryID")::text = ("Enrollment"."ProjectEntryID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("Exit"."DateDeleted" IS NULL);
  SQL

  create_view "report_health_and_dvs",  sql_definition: <<-SQL
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
      "Enrollment".id AS enrollment_id,
      source_clients.id AS demographic_id,
      destination_clients.id AS client_id
     FROM (((("HealthAndDV"
       JOIN "Client" source_clients ON ((("HealthAndDV".data_source_id = source_clients.data_source_id) AND (("HealthAndDV"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("HealthAndDV".data_source_id = "Enrollment".data_source_id) AND (("HealthAndDV"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("HealthAndDV"."ProjectEntryID")::text = ("Enrollment"."ProjectEntryID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("HealthAndDV"."DateDeleted" IS NULL);
  SQL

  create_view "report_income_benefits",  sql_definition: <<-SQL
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
      "IncomeBenefits"."ConnectionWithSOAR",
      "Enrollment".id AS enrollment_id,
      source_clients.id AS demographic_id,
      destination_clients.id AS client_id
     FROM (((("IncomeBenefits"
       JOIN "Client" source_clients ON ((("IncomeBenefits".data_source_id = source_clients.data_source_id) AND (("IncomeBenefits"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("IncomeBenefits".data_source_id = "Enrollment".data_source_id) AND (("IncomeBenefits"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("IncomeBenefits"."ProjectEntryID")::text = ("Enrollment"."ProjectEntryID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("IncomeBenefits"."DateDeleted" IS NULL);
  SQL

  create_view "report_services",  sql_definition: <<-SQL
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
      "Enrollment".id AS enrollment_id,
      source_clients.id AS demographic_id,
      destination_clients.id AS client_id
     FROM (((("Services"
       JOIN "Client" source_clients ON ((("Services".data_source_id = source_clients.data_source_id) AND (("Services"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("Services".data_source_id = "Enrollment".data_source_id) AND (("Services"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("Services"."ProjectEntryID")::text = ("Enrollment"."ProjectEntryID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("Services"."DateDeleted" IS NULL);
  SQL

  create_view "service_history",  sql_definition: <<-SQL
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
     FROM (service_history_services
       JOIN service_history_enrollments ON ((service_history_services.service_history_enrollment_id = service_history_enrollments.id)))
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
     FROM service_history_enrollments;
  SQL

  create_view "service_history_services_materialized", materialized: true,  sql_definition: <<-SQL
      SELECT service_history_services.id,
      service_history_services.service_history_enrollment_id,
      service_history_services.record_type,
      service_history_services.date,
      service_history_services.age,
      service_history_services.service_type,
      service_history_services.client_id,
      service_history_services.project_type
     FROM service_history_services;
  SQL

  add_index "service_history_services_materialized", ["client_id", "project_type", "record_type"], name: "index_shsm_c_id_p_type_r_type", using: :btree
  add_index "service_history_services_materialized", ["id"], name: "index_service_history_services_materialized_on_id", unique: true, using: :btree
  add_index "service_history_services_materialized", ["project_type", "record_type"], name: "index_shsm_p_type_r_type", using: :btree

end
