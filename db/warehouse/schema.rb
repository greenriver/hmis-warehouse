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

ActiveRecord::Schema.define(version: 2020_01_10_150204) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "hstore"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "Affiliation", id: :serial, force: :cascade do |t|
    t.string "AffiliationID"
    t.string "ProjectID"
    t.string "ResProjectID"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "source_hash"
    t.datetime "pending_date_deleted"
    t.index ["DateCreated"], name: "affiliation_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Affiliation_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "affiliation_date_updated"
    t.index ["ExportID"], name: "affiliation_export_id"
    t.index ["data_source_id", "AffiliationID"], name: "unk_Affiliation", unique: true
    t.index ["data_source_id"], name: "index_Affiliation_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_Affiliation_on_pending_date_deleted"
  end

  create_table "Assessment", id: :serial, force: :cascade do |t|
    t.string "AssessmentID", limit: 32, null: false
    t.string "EnrollmentID", null: false
    t.string "PersonalID", null: false
    t.date "AssessmentDate", null: false
    t.string "AssessmentLocation", null: false
    t.integer "AssessmentType", null: false
    t.integer "AssessmentLevel", null: false
    t.integer "PrioritizationStatus", null: false
    t.datetime "DateCreated", null: false
    t.datetime "DateUpdated", null: false
    t.string "UserID", limit: 32, null: false
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.datetime "pending_date_deleted"
    t.string "source_hash"
    t.index ["AssessmentID", "data_source_id"], name: "assessment_a_id_ds_id"
    t.index ["PersonalID", "EnrollmentID", "data_source_id", "AssessmentID"], name: "assessment_p_id_en_id_ds_id_a_id"
    t.index ["pending_date_deleted"], name: "index_Assessment_on_pending_date_deleted"
  end

  create_table "AssessmentQuestions", id: :serial, force: :cascade do |t|
    t.string "AssessmentQuestionID", limit: 32, null: false
    t.string "AssessmentID", limit: 32, null: false
    t.string "EnrollmentID", null: false
    t.string "PersonalID", null: false
    t.string "AssessmentQuestionGroup"
    t.integer "AssessmentQuestionOrder"
    t.string "AssessmentQuestion"
    t.string "AssessmentAnswer"
    t.datetime "DateCreated", null: false
    t.datetime "DateUpdated", null: false
    t.string "UserID", limit: 32, null: false
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.datetime "pending_date_deleted"
    t.string "source_hash"
    t.index ["AssessmentID", "data_source_id", "PersonalID", "EnrollmentID", "AssessmentQuestionID"], name: "assessment_q_a_id_ds_id_p_id_en_id_aq_id"
    t.index ["AssessmentQuestionID", "data_source_id"], name: "assessment_q_aq_id_ds_id"
    t.index ["pending_date_deleted"], name: "index_AssessmentQuestions_on_pending_date_deleted"
  end

  create_table "AssessmentResults", id: :serial, force: :cascade do |t|
    t.string "AssessmentResultID", limit: 32, null: false
    t.string "AssessmentID", limit: 32, null: false
    t.string "EnrollmentID", null: false
    t.string "PersonalID", null: false
    t.string "AssessmentResultType"
    t.string "AssessmentResult"
    t.datetime "DateCreated", null: false
    t.datetime "DateUpdated", null: false
    t.string "UserID", limit: 32, null: false
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.datetime "pending_date_deleted"
    t.string "source_hash"
    t.index ["AssessmentID", "data_source_id", "PersonalID", "EnrollmentID", "AssessmentResultID"], name: "assessment_r_a_id_ds_id_p_id_en_id_ar_id"
    t.index ["AssessmentResultID", "data_source_id"], name: "assessment_r_ar_id_ds_id"
    t.index ["pending_date_deleted"], name: "index_AssessmentResults_on_pending_date_deleted"
  end

  create_table "Client", id: :serial, force: :cascade do |t|
    t.string "PersonalID"
    t.string "FirstName", limit: 150
    t.string "MiddleName", limit: 150
    t.string "LastName", limit: 150
    t.string "NameSuffix", limit: 50
    t.integer "NameDataQuality"
    t.string "SSN", limit: 9
    t.integer "SSNDataQuality"
    t.date "DOB"
    t.integer "DOBDataQuality"
    t.integer "AmIndAKNative"
    t.integer "Asian"
    t.integer "BlackAfAmerican"
    t.integer "NativeHIOtherPacific"
    t.integer "White"
    t.integer "RaceNone"
    t.integer "Ethnicity"
    t.integer "Gender"
    t.string "OtherGender", limit: 50
    t.integer "VeteranStatus"
    t.integer "YearEnteredService"
    t.integer "YearSeparated"
    t.integer "WorldWarII"
    t.integer "KoreanWar"
    t.integer "VietnamWar"
    t.integer "DesertStorm"
    t.integer "AfghanistanOEF"
    t.integer "IraqOIF"
    t.integer "IraqOND"
    t.integer "OtherTheater"
    t.integer "MilitaryBranch"
    t.integer "DischargeStatus"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.datetime "disability_verified_on"
    t.datetime "housing_assistance_network_released_on"
    t.boolean "sync_with_cas", default: false, null: false
    t.boolean "dmh_eligible", default: false, null: false
    t.boolean "va_eligible", default: false, null: false
    t.boolean "hues_eligible", default: false, null: false
    t.boolean "hiv_positive", default: false, null: false
    t.string "housing_release_status"
    t.boolean "chronically_homeless_for_cas", default: false, null: false
    t.boolean "us_citizen", default: false, null: false
    t.boolean "asylee", default: false, null: false
    t.boolean "ineligible_immigrant", default: false, null: false
    t.boolean "lifetime_sex_offender", default: false, null: false
    t.boolean "meth_production_conviction", default: false, null: false
    t.boolean "family_member", default: false, null: false
    t.boolean "child_in_household", default: false, null: false
    t.boolean "ha_eligible", default: false, null: false
    t.boolean "api_update_in_process", default: false, null: false
    t.datetime "api_update_started_at"
    t.datetime "api_last_updated_at"
    t.integer "creator_id"
    t.boolean "cspech_eligible", default: false
    t.date "consent_form_signed_on"
    t.integer "vispdat_prioritization_days_homeless"
    t.boolean "generate_history_pdf", default: false
    t.boolean "congregate_housing", default: false
    t.boolean "sober_housing", default: false
    t.integer "consent_form_id"
    t.integer "rrh_assessment_score"
    t.boolean "ssvf_eligible", default: false, null: false
    t.boolean "rrh_desired", default: false, null: false
    t.boolean "youth_rrh_desired", default: false, null: false
    t.string "rrh_assessment_contact_info"
    t.datetime "rrh_assessment_collected_at"
    t.string "source_hash"
    t.boolean "generate_manual_history_pdf", default: false, null: false
    t.boolean "requires_wheelchair_accessibility", default: false
    t.integer "required_number_of_bedrooms", default: 1
    t.integer "required_minimum_occupancy", default: 1
    t.boolean "requires_elevator_access", default: false
    t.jsonb "neighborhood_interests", default: [], null: false
    t.string "verified_veteran_status"
    t.boolean "interested_in_set_asides", default: false
    t.date "consent_expires_on"
    t.datetime "pending_date_deleted"
    t.date "cas_match_override"
    t.boolean "vash_eligible", default: false
    t.jsonb "consented_coc_codes", default: []
    t.index ["DateCreated"], name: "client_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Client_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "client_date_updated"
    t.index ["ExportID"], name: "client_export_id"
    t.index ["FirstName"], name: "client_first_name"
    t.index ["LastName"], name: "client_last_name"
    t.index ["PersonalID"], name: "client_personal_id"
    t.index ["creator_id"], name: "index_Client_on_creator_id"
    t.index ["data_source_id"], name: "index_Client_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_Client_on_pending_date_deleted"
  end

  create_table "CurrentLivingSituation", id: :serial, force: :cascade do |t|
    t.string "CurrentLivingSitID", limit: 32, null: false
    t.string "EnrollmentID", null: false
    t.string "PersonalID", null: false
    t.date "InformationDate", null: false
    t.integer "CurrentLivingSituation", null: false
    t.string "VerifiedBy"
    t.integer "LeaveSituation14Days"
    t.integer "SubsequentResidence"
    t.integer "ResourcesToObtain"
    t.integer "LeaseOwn60Day"
    t.integer "MovedTwoOrMore"
    t.string "LocationDetails"
    t.datetime "DateCreated", null: false
    t.datetime "DateUpdated", null: false
    t.string "UserID", limit: 32, null: false
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.datetime "pending_date_deleted"
    t.string "source_hash"
    t.index ["CurrentLivingSitID", "data_source_id"], name: "cur_liv_sit_cur_id_ds_id"
    t.index ["PersonalID", "EnrollmentID", "data_source_id", "CurrentLivingSitID"], name: "cur_liv_sit_p_id_en_id_ds_id_cur_id"
    t.index ["pending_date_deleted"], name: "index_CurrentLivingSituation_on_pending_date_deleted"
  end

  create_table "Disabilities", id: :serial, force: :cascade do |t|
    t.string "DisabilitiesID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "InformationDate"
    t.integer "DisabilityType"
    t.integer "DisabilityResponse"
    t.integer "IndefiniteAndImpairs"
    t.integer "DocumentationOnFile"
    t.integer "ReceivingServices"
    t.integer "PATHHowConfirmed"
    t.integer "PATHSMIInformation"
    t.integer "TCellCountAvailable"
    t.integer "TCellCount"
    t.integer "TCellSource"
    t.integer "ViralLoadAvailable"
    t.integer "ViralLoad"
    t.integer "ViralLoadSource"
    t.integer "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "source_hash"
    t.datetime "pending_date_deleted"
    t.index ["DateCreated"], name: "disabilities_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "Disabilities_DateDeleted_data_source_id_idx", where: "(\"DateDeleted\" IS NULL)"
    t.index ["DateDeleted", "data_source_id"], name: "Disabilities_DateDeleted_data_source_id_idx1", where: "(\"DateDeleted\" IS NULL)"
    t.index ["DateDeleted", "data_source_id"], name: "index_Disabilities_on_DateDeleted_and_data_source_id"
    t.index ["DateDeleted"], name: "Disabilities_DateDeleted_idx", where: "(\"DateDeleted\" IS NULL)"
    t.index ["DateUpdated"], name: "disabilities_date_updated"
    t.index ["DisabilityType", "DisabilityResponse", "InformationDate", "PersonalID", "EnrollmentID", "DateDeleted"], name: "disabilities_disability_type_response_idx"
    t.index ["EnrollmentID"], name: "index_Disabilities_on_EnrollmentID"
    t.index ["ExportID"], name: "disabilities_export_id"
    t.index ["PersonalID"], name: "index_Disabilities_on_PersonalID"
    t.index ["data_source_id", "DisabilitiesID"], name: "unk_Disabilities", unique: true
    t.index ["data_source_id", "PersonalID"], name: "index_Disabilities_on_data_source_id_and_PersonalID"
    t.index ["data_source_id"], name: "index_Disabilities_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_Disabilities_on_pending_date_deleted"
  end

  create_table "EmploymentEducation", id: :serial, force: :cascade do |t|
    t.string "EmploymentEducationID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "InformationDate"
    t.integer "LastGradeCompleted"
    t.integer "SchoolStatus"
    t.integer "Employed"
    t.integer "EmploymentType"
    t.integer "NotEmployedReason"
    t.integer "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "source_hash"
    t.datetime "pending_date_deleted"
    t.index ["DateCreated"], name: "employment_education_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_EmploymentEducation_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "employment_education_date_updated"
    t.index ["EnrollmentID"], name: "index_EmploymentEducation_on_EnrollmentID"
    t.index ["ExportID"], name: "employment_education_export_id"
    t.index ["PersonalID"], name: "index_EmploymentEducation_on_PersonalID"
    t.index ["data_source_id", "EmploymentEducationID"], name: "unk_EmploymentEducation", unique: true
    t.index ["data_source_id", "PersonalID"], name: "index_EmploymentEducation_on_data_source_id_and_PersonalID"
    t.index ["data_source_id"], name: "index_EmploymentEducation_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_EmploymentEducation_on_pending_date_deleted"
  end

  create_table "Enrollment", id: :serial, force: :cascade do |t|
    t.string "EnrollmentID", limit: 50
    t.string "PersonalID"
    t.string "ProjectID", limit: 50
    t.date "EntryDate"
    t.string "HouseholdID"
    t.integer "RelationshipToHoH"
    t.integer "LivingSituation"
    t.string "OtherResidencePrior"
    t.integer "LengthOfStay"
    t.integer "DisablingCondition"
    t.integer "EntryFromStreetESSH"
    t.date "DateToStreetESSH"
    t.integer "ContinuouslyHomelessOneYear"
    t.integer "TimesHomelessPastThreeYears"
    t.integer "MonthsHomelessPastThreeYears"
    t.integer "MonthsHomelessThisTime"
    t.integer "StatusDocumented"
    t.integer "HousingStatus"
    t.date "DateOfEngagement"
    t.integer "InPermanentHousing"
    t.date "MoveInDate"
    t.date "DateOfPATHStatus"
    t.integer "ClientEnrolledInPATH"
    t.integer "ReasonNotEnrolled"
    t.integer "WorstHousingSituation"
    t.integer "PercentAMI"
    t.string "LastPermanentStreet"
    t.string "LastPermanentCity", limit: 50
    t.string "LastPermanentState", limit: 2
    t.string "LastPermanentZIP", limit: 10
    t.integer "AddressDataQuality"
    t.date "DateOfBCPStatus"
    t.integer "EligibleForRHY"
    t.integer "ReasonNoServices"
    t.integer "SexualOrientation"
    t.integer "FormerWardChildWelfare"
    t.integer "ChildWelfareYears"
    t.integer "ChildWelfareMonths"
    t.integer "FormerWardJuvenileJustice"
    t.integer "JuvenileJusticeYears"
    t.integer "JuvenileJusticeMonths"
    t.integer "HouseholdDynamics"
    t.integer "SexualOrientationGenderIDYouth"
    t.integer "SexualOrientationGenderIDFam"
    t.integer "HousingIssuesYouth"
    t.integer "HousingIssuesFam"
    t.integer "SchoolEducationalIssuesYouth"
    t.integer "SchoolEducationalIssuesFam"
    t.integer "UnemploymentYouth"
    t.integer "UnemploymentFam"
    t.integer "MentalHealthIssuesYouth"
    t.integer "MentalHealthIssuesFam"
    t.integer "HealthIssuesYouth"
    t.integer "HealthIssuesFam"
    t.integer "PhysicalDisabilityYouth"
    t.integer "PhysicalDisabilityFam"
    t.integer "MentalDisabilityYouth"
    t.integer "MentalDisabilityFam"
    t.integer "AbuseAndNeglectYouth"
    t.integer "AbuseAndNeglectFam"
    t.integer "AlcoholDrugAbuseYouth"
    t.integer "AlcoholDrugAbuseFam"
    t.integer "InsufficientIncome"
    t.integer "ActiveMilitaryParent"
    t.integer "IncarceratedParent"
    t.integer "IncarceratedParentStatus"
    t.integer "ReferralSource"
    t.integer "CountOutreachReferralApproaches"
    t.integer "ExchangeForSex"
    t.integer "ExchangeForSexPastThreeMonths"
    t.integer "CountOfExchangeForSex"
    t.integer "AskedOrForcedToExchangeForSex"
    t.integer "AskedOrForcedToExchangeForSexPastThreeMonths"
    t.integer "WorkPlaceViolenceThreats"
    t.integer "WorkplacePromiseDifference"
    t.integer "CoercedToContinueWork"
    t.integer "LaborExploitPastThreeMonths"
    t.integer "HPScreeningScore"
    t.integer "VAMCStation"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.integer "LOSUnderThreshold"
    t.integer "PreviousStreetESSH"
    t.integer "UrgentReferral"
    t.integer "TimeToHousingLoss"
    t.integer "ZeroIncome"
    t.integer "AnnualPercentAMI"
    t.integer "FinancialChange"
    t.integer "HouseholdChange"
    t.integer "EvictionHistory"
    t.integer "SubsidyAtRisk"
    t.integer "LiteralHomelessHistory"
    t.integer "DisabledHoH"
    t.integer "CriminalRecord"
    t.integer "SexOffender"
    t.integer "DependentUnder6"
    t.integer "SingleParent"
    t.integer "HH5Plus"
    t.integer "IraqAfghanistan"
    t.integer "FemVet"
    t.integer "ThresholdScore"
    t.integer "ERVisits"
    t.integer "JailNights"
    t.integer "HospitalNights"
    t.integer "RunawayYouth"
    t.string "processed_hash"
    t.string "processed_as"
    t.boolean "roi_permission"
    t.string "last_locality"
    t.string "last_zipcode"
    t.string "source_hash"
    t.datetime "pending_date_deleted"
    t.string "SexualOrientationOther", limit: 100
    t.index ["DateCreated"], name: "enrollment_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Enrollment_on_DateDeleted_and_data_source_id"
    t.index ["DateDeleted"], name: "index_Enrollment_on_DateDeleted"
    t.index ["DateUpdated"], name: "enrollment_date_updated"
    t.index ["EnrollmentID"], name: "index_Enrollment_on_EnrollmentID"
    t.index ["EntryDate"], name: "index_Enrollment_on_EntryDate"
    t.index ["ExportID"], name: "enrollment_export_id"
    t.index ["MoveInDate"], name: "index_Enrollment_on_MoveInDate"
    t.index ["PersonalID"], name: "index_Enrollment_on_PersonalID"
    t.index ["ProjectID"], name: "index_Enrollment_on_ProjectID"
    t.index ["data_source_id", "EnrollmentID", "PersonalID"], name: "unk_Enrollment", unique: true
    t.index ["data_source_id", "HouseholdID", "ProjectID"], name: "idx_enrollment_ds_id_hh_id_p_id"
    t.index ["data_source_id", "PersonalID"], name: "index_Enrollment_on_data_source_id_and_PersonalID"
    t.index ["data_source_id"], name: "index_Enrollment_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_Enrollment_on_pending_date_deleted"
  end

  create_table "EnrollmentCoC", id: :serial, force: :cascade do |t|
    t.string "EnrollmentCoCID"
    t.string "EnrollmentID"
    t.string "ProjectID"
    t.string "PersonalID"
    t.date "InformationDate"
    t.string "CoCCode", limit: 50
    t.integer "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "HouseholdID", limit: 32
    t.string "source_hash"
    t.datetime "pending_date_deleted"
    t.index ["DateCreated"], name: "enrollment_coc_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_EnrollmentCoC_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "enrollment_coc_date_updated"
    t.index ["EnrollmentCoCID"], name: "index_EnrollmentCoC_on_EnrollmentCoCID"
    t.index ["ExportID"], name: "enrollment_coc_export_id"
    t.index ["data_source_id", "EnrollmentCoCID"], name: "unk_EnrollmentCoC", unique: true
    t.index ["data_source_id", "PersonalID"], name: "index_EnrollmentCoC_on_data_source_id_and_PersonalID"
    t.index ["data_source_id"], name: "index_EnrollmentCoC_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_EnrollmentCoC_on_pending_date_deleted"
  end

  create_table "Event", id: :serial, force: :cascade do |t|
    t.string "EventID", limit: 32, null: false
    t.string "EnrollmentID", null: false
    t.string "PersonalID", null: false
    t.date "EventDate", null: false
    t.integer "Event", null: false
    t.integer "ProbSolDivRRResult"
    t.integer "ReferralCaseManageAfter"
    t.string "LocationCrisisorPHHousing"
    t.integer "ReferralResult"
    t.date "ResultDate"
    t.datetime "DateCreated", null: false
    t.datetime "DateUpdated", null: false
    t.string "UserID", limit: 32, null: false
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.datetime "pending_date_deleted"
    t.string "source_hash"
    t.index ["EventID", "data_source_id"], name: "event_ev_id_ds_id"
    t.index ["data_source_id", "PersonalID", "EnrollmentID", "EventID"], name: "event_ds_id_p_id_en_id_ev_id"
    t.index ["pending_date_deleted"], name: "index_Event_on_pending_date_deleted"
  end

  create_table "Exit", id: :serial, force: :cascade do |t|
    t.string "ExitID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "ExitDate"
    t.integer "Destination"
    t.string "OtherDestination"
    t.integer "AssessmentDisposition"
    t.string "OtherDisposition"
    t.integer "HousingAssessment"
    t.integer "SubsidyInformation"
    t.integer "ConnectionWithSOAR"
    t.integer "WrittenAftercarePlan"
    t.integer "AssistanceMainstreamBenefits"
    t.integer "PermanentHousingPlacement"
    t.integer "TemporaryShelterPlacement"
    t.integer "ExitCounseling"
    t.integer "FurtherFollowUpServices"
    t.integer "ScheduledFollowUpContacts"
    t.integer "ResourcePackage"
    t.integer "OtherAftercarePlanOrAction"
    t.integer "ProjectCompletionStatus"
    t.integer "EarlyExitReason"
    t.integer "FamilyReunificationAchieved"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.integer "ExchangeForSex"
    t.integer "ExchangeForSexPastThreeMonths"
    t.integer "CountOfExchangeForSex"
    t.integer "AskedOrForcedToExchangeForSex"
    t.integer "AskedOrForcedToExchangeForSexPastThreeMonths"
    t.integer "WorkPlaceViolenceThreats"
    t.integer "WorkplacePromiseDifference"
    t.integer "CoercedToContinueWork"
    t.integer "LaborExploitPastThreeMonths"
    t.integer "CounselingReceived"
    t.integer "IndividualCounseling"
    t.integer "FamilyCounseling"
    t.integer "GroupCounseling"
    t.integer "SessionCountAtExit"
    t.integer "PostExitCounselingPlan"
    t.integer "SessionsInPlan"
    t.integer "DestinationSafeClient"
    t.integer "DestinationSafeWorker"
    t.integer "PosAdultConnections"
    t.integer "PosPeerConnections"
    t.integer "PosCommunityConnections"
    t.date "AftercareDate"
    t.integer "AftercareProvided"
    t.integer "EmailSocialMedia"
    t.integer "Telephone"
    t.integer "InPersonIndividual"
    t.integer "InPersonGroup"
    t.integer "CMExitReason"
    t.string "source_hash"
    t.datetime "pending_date_deleted"
    t.index ["DateCreated"], name: "exit_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Exit_on_DateDeleted_and_data_source_id"
    t.index ["DateDeleted"], name: "index_Exit_on_DateDeleted"
    t.index ["DateUpdated"], name: "exit_date_updated"
    t.index ["EnrollmentID"], name: "index_Exit_on_EnrollmentID"
    t.index ["ExitDate"], name: "index_Exit_on_ExitDate"
    t.index ["ExportID"], name: "exit_export_id"
    t.index ["PersonalID"], name: "index_Exit_on_PersonalID"
    t.index ["data_source_id", "ExitID"], name: "unk_Exit", unique: true
    t.index ["data_source_id", "PersonalID"], name: "index_Exit_on_data_source_id_and_PersonalID"
    t.index ["data_source_id"], name: "index_Exit_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_Exit_on_pending_date_deleted"
  end

  create_table "Export", id: :serial, force: :cascade do |t|
    t.string "ExportID"
    t.string "SourceID"
    t.string "SourceName"
    t.string "SourceContactFirst"
    t.string "SourceContactLast"
    t.string "SourceContactPhone"
    t.string "SourceContactExtension"
    t.string "SourceContactEmail"
    t.datetime "ExportDate"
    t.date "ExportStartDate"
    t.date "ExportEndDate"
    t.string "SoftwareName"
    t.string "SoftwareVersion"
    t.integer "ExportPeriodType"
    t.integer "ExportDirective"
    t.integer "HashStatus"
    t.integer "data_source_id"
    t.integer "SourceType"
    t.date "effective_export_end_date"
    t.string "source_hash"
    t.index ["ExportID"], name: "export_export_id"
    t.index ["data_source_id", "ExportID"], name: "unk_Export", unique: true
    t.index ["data_source_id"], name: "index_Export_on_data_source_id"
  end

  create_table "Funder", id: :serial, force: :cascade do |t|
    t.string "FunderID"
    t.string "ProjectID"
    t.string "Funder"
    t.string "GrantID"
    t.date "StartDate"
    t.date "EndDate"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "source_hash"
    t.datetime "pending_date_deleted"
    t.string "OtherFunder"
    t.index ["DateCreated"], name: "funder_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Funder_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "funder_date_updated"
    t.index ["ExportID"], name: "funder_export_id"
    t.index ["data_source_id", "FunderID"], name: "unk_Funder", unique: true
    t.index ["data_source_id"], name: "index_Funder_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_Funder_on_pending_date_deleted"
  end

  create_table "Geography", id: :serial, force: :cascade do |t|
    t.string "GeographyID"
    t.string "ProjectID"
    t.string "CoCCode", limit: 50
    t.integer "PrincipalSite"
    t.string "Geocode", limit: 50
    t.string "Address1"
    t.string "City"
    t.string "State", limit: 2
    t.string "ZIP", limit: 10
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.date "InformationDate"
    t.string "Address2"
    t.integer "GeographyType"
    t.string "source_hash"
    t.string "geocode_override", limit: 6
    t.integer "geography_type_override"
    t.date "information_date_override"
    t.datetime "pending_date_deleted"
    t.index ["DateCreated"], name: "site_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Geography_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "site_date_updated"
    t.index ["ExportID"], name: "site_export_id"
    t.index ["data_source_id", "GeographyID"], name: "unk_Geography", unique: true
    t.index ["data_source_id", "GeographyID"], name: "unk_Site", unique: true
    t.index ["data_source_id"], name: "index_Geography_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_Geography_on_pending_date_deleted"
  end

  create_table "HealthAndDV", id: :serial, force: :cascade do |t|
    t.string "HealthAndDVID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "InformationDate"
    t.integer "DomesticViolenceVictim"
    t.integer "WhenOccurred"
    t.integer "CurrentlyFleeing"
    t.integer "GeneralHealthStatus"
    t.integer "DentalHealthStatus"
    t.integer "MentalHealthStatus"
    t.integer "PregnancyStatus"
    t.date "DueDate"
    t.integer "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "source_hash"
    t.datetime "pending_date_deleted"
    t.index ["DateCreated"], name: "health_and_dv_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_HealthAndDV_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "health_and_dv_date_updated"
    t.index ["EnrollmentID"], name: "index_HealthAndDV_on_EnrollmentID"
    t.index ["ExportID"], name: "health_and_dv_export_id"
    t.index ["PersonalID"], name: "index_HealthAndDV_on_PersonalID"
    t.index ["data_source_id", "HealthAndDVID"], name: "unk_HealthAndDV", unique: true
    t.index ["data_source_id", "PersonalID"], name: "index_HealthAndDV_on_data_source_id_and_PersonalID"
    t.index ["data_source_id"], name: "index_HealthAndDV_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_HealthAndDV_on_pending_date_deleted"
  end

  create_table "IncomeBenefits", id: :serial, force: :cascade do |t|
    t.string "IncomeBenefitsID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "InformationDate"
    t.integer "IncomeFromAnySource"
    t.decimal "TotalMonthlyIncome"
    t.integer "Earned"
    t.decimal "EarnedAmount"
    t.integer "Unemployment"
    t.decimal "UnemploymentAmount"
    t.integer "SSI"
    t.decimal "SSIAmount"
    t.integer "SSDI"
    t.decimal "SSDIAmount"
    t.integer "VADisabilityService"
    t.decimal "VADisabilityServiceAmount"
    t.integer "VADisabilityNonService"
    t.decimal "VADisabilityNonServiceAmount"
    t.integer "PrivateDisability"
    t.decimal "PrivateDisabilityAmount"
    t.integer "WorkersComp"
    t.decimal "WorkersCompAmount"
    t.integer "TANF"
    t.decimal "TANFAmount"
    t.integer "GA"
    t.decimal "GAAmount"
    t.integer "SocSecRetirement"
    t.decimal "SocSecRetirementAmount"
    t.integer "Pension"
    t.decimal "PensionAmount"
    t.integer "ChildSupport"
    t.decimal "ChildSupportAmount"
    t.integer "Alimony"
    t.decimal "AlimonyAmount"
    t.integer "OtherIncomeSource"
    t.decimal "OtherIncomeAmount"
    t.string "OtherIncomeSourceIdentify"
    t.integer "BenefitsFromAnySource"
    t.integer "SNAP"
    t.integer "WIC"
    t.integer "TANFChildCare"
    t.integer "TANFTransportation"
    t.integer "OtherTANF"
    t.integer "RentalAssistanceOngoing"
    t.integer "RentalAssistanceTemp"
    t.integer "OtherBenefitsSource"
    t.string "OtherBenefitsSourceIdentify"
    t.integer "InsuranceFromAnySource"
    t.integer "Medicaid"
    t.integer "NoMedicaidReason"
    t.integer "Medicare"
    t.integer "NoMedicareReason"
    t.integer "SCHIP"
    t.integer "NoSCHIPReason"
    t.integer "VAMedicalServices"
    t.integer "NoVAMedReason"
    t.integer "EmployerProvided"
    t.integer "NoEmployerProvidedReason"
    t.integer "COBRA"
    t.integer "NoCOBRAReason"
    t.integer "PrivatePay"
    t.integer "NoPrivatePayReason"
    t.integer "StateHealthIns"
    t.integer "NoStateHealthInsReason"
    t.integer "HIVAIDSAssistance"
    t.integer "NoHIVAIDSAssistanceReason"
    t.integer "ADAP"
    t.integer "NoADAPReason"
    t.integer "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.integer "IndianHealthServices"
    t.integer "NoIndianHealthServicesReason"
    t.integer "OtherInsurance"
    t.string "OtherInsuranceIdentify", limit: 50
    t.integer "ConnectionWithSOAR"
    t.string "source_hash"
    t.datetime "pending_date_deleted"
    t.index ["DateCreated"], name: "income_benefits_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "IncomeBenefits_DateDeleted_data_source_id_idx", where: "(\"DateDeleted\" IS NULL)"
    t.index ["DateDeleted", "data_source_id"], name: "index_IncomeBenefits_on_DateDeleted_and_data_source_id"
    t.index ["DateDeleted"], name: "IncomeBenefits_DateDeleted_idx", where: "(\"DateDeleted\" IS NULL)"
    t.index ["DateUpdated"], name: "income_benefits_date_updated"
    t.index ["EnrollmentID"], name: "index_IncomeBenefits_on_EnrollmentID"
    t.index ["ExportID"], name: "income_benefits_export_id"
    t.index ["PersonalID"], name: "index_IncomeBenefits_on_PersonalID"
    t.index ["data_source_id", "DateDeleted"], name: "IncomeBenefits_data_source_id_DateDeleted_idx", where: "(\"DateDeleted\" IS NULL)"
    t.index ["data_source_id", "IncomeBenefitsID"], name: "unk_IncomeBenefits", unique: true
    t.index ["data_source_id", "PersonalID"], name: "index_IncomeBenefits_on_data_source_id_and_PersonalID"
    t.index ["data_source_id"], name: "index_IncomeBenefits_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_IncomeBenefits_on_pending_date_deleted"
  end

  create_table "Inventory", id: :serial, force: :cascade do |t|
    t.string "InventoryID"
    t.string "ProjectID"
    t.string "CoCCode", limit: 50
    t.date "InformationDate"
    t.integer "HouseholdType"
    t.integer "BedType"
    t.integer "Availability"
    t.integer "UnitInventory"
    t.integer "BedInventory"
    t.integer "CHBedInventory"
    t.integer "VetBedInventory"
    t.integer "YouthBedInventory"
    t.integer "YouthAgeGroup"
    t.date "InventoryStartDate"
    t.date "InventoryEndDate"
    t.integer "HMISParticipatingBeds"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "source_hash"
    t.datetime "pending_date_deleted"
    t.integer "CHVetBedInventory"
    t.integer "YouthVetBedInventory"
    t.integer "CHYouthBedInventory"
    t.integer "OtherBedInventory"
    t.integer "TargetPopulation"
    t.integer "ESBedType"
    t.index ["DateCreated"], name: "inventory_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Inventory_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "inventory_date_updated"
    t.index ["ExportID"], name: "inventory_export_id"
    t.index ["ProjectID", "CoCCode", "data_source_id"], name: "index_Inventory_on_ProjectID_and_CoCCode_and_data_source_id"
    t.index ["data_source_id", "InventoryID"], name: "unk_Inventory", unique: true
    t.index ["data_source_id"], name: "index_Inventory_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_Inventory_on_pending_date_deleted"
  end

  create_table "Organization", id: :serial, force: :cascade do |t|
    t.string "OrganizationID", limit: 50
    t.string "OrganizationName"
    t.string "OrganizationCommonName"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.boolean "dmh", default: false, null: false
    t.string "source_hash"
    t.datetime "pending_date_deleted"
    t.integer "VictimServicesProvider"
    t.index ["DateDeleted", "data_source_id"], name: "index_Organization_on_DateDeleted_and_data_source_id"
    t.index ["ExportID"], name: "organization_export_id"
    t.index ["data_source_id", "OrganizationID"], name: "unk_Organization", unique: true
    t.index ["data_source_id"], name: "index_Organization_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_Organization_on_pending_date_deleted"
  end

  create_table "Project", id: :serial, force: :cascade do |t|
    t.string "ProjectID", limit: 50
    t.string "OrganizationID", limit: 50
    t.string "ProjectName"
    t.string "ProjectCommonName"
    t.integer "ContinuumProject"
    t.integer "ProjectType"
    t.integer "ResidentialAffiliation"
    t.integer "TrackingMethod"
    t.integer "TargetPopulation"
    t.integer "PITCount"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.integer "act_as_project_type"
    t.boolean "hud_continuum_funded"
    t.boolean "confidential", default: false, null: false
    t.integer "computed_project_type"
    t.date "OperatingStartDate"
    t.date "OperatingEndDate"
    t.integer "VictimServicesProvider"
    t.integer "HousingType"
    t.string "local_planning_group"
    t.string "source_hash"
    t.integer "housing_type_override"
    t.boolean "uses_move_in_date", default: false, null: false
    t.date "operating_start_date_override"
    t.datetime "pending_date_deleted"
    t.integer "HMISParticipatingProject"
    t.boolean "active_homeless_status_override", default: false
    t.boolean "include_in_days_homeless_override", default: false
    t.index "COALESCE(act_as_project_type, \"ProjectType\")", name: "project_project_override_index"
    t.index ["DateCreated"], name: "project_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Project_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "project_date_updated"
    t.index ["ExportID"], name: "project_export_id"
    t.index ["ProjectID", "data_source_id", "OrganizationID"], name: "index_proj_proj_id_org_id_ds_id"
    t.index ["ProjectType"], name: "index_Project_on_ProjectType"
    t.index ["computed_project_type"], name: "index_Project_on_computed_project_type"
    t.index ["data_source_id", "ProjectID"], name: "unk_Project", unique: true
    t.index ["data_source_id"], name: "index_Project_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_Project_on_pending_date_deleted"
  end

  create_table "ProjectCoC", id: :serial, force: :cascade do |t|
    t.string "ProjectCoCID", limit: 50
    t.string "ProjectID"
    t.string "CoCCode", limit: 50
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "hud_coc_code"
    t.string "source_hash"
    t.datetime "pending_date_deleted"
    t.string "Geocode", limit: 6
    t.integer "GeographyType"
    t.string "Address1"
    t.string "Address2"
    t.string "City"
    t.string "State", limit: 2
    t.string "Zip", limit: 5
    t.integer "geography_type_override"
    t.string "geocode_override", limit: 6
    t.index ["DateCreated"], name: "project_coc_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_ProjectCoC_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "project_coc_date_updated"
    t.index ["ExportID"], name: "project_coc_export_id"
    t.index ["data_source_id", "ProjectCoCID"], name: "unk_ProjectCoC", unique: true
    t.index ["data_source_id", "ProjectID", "CoCCode"], name: "index_ProjectCoC_on_data_source_id_and_ProjectID_and_CoCCode"
    t.index ["pending_date_deleted"], name: "index_ProjectCoC_on_pending_date_deleted"
  end

  create_table "Services", id: :serial, force: :cascade do |t|
    t.string "ServicesID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "DateProvided"
    t.integer "RecordType"
    t.integer "TypeProvided"
    t.string "OtherTypeProvided"
    t.integer "SubTypeProvided"
    t.decimal "FAAmount"
    t.integer "ReferralOutcome"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "source_hash"
    t.datetime "pending_date_deleted"
    t.index ["DateCreated"], name: "services_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Services_on_DateDeleted_and_data_source_id"
    t.index ["DateDeleted"], name: "index_Services_on_DateDeleted"
    t.index ["DateProvided"], name: "index_Services_on_DateProvided"
    t.index ["DateUpdated"], name: "services_date_updated"
    t.index ["EnrollmentID", "PersonalID", "data_source_id"], name: "index_serv_on_proj_entry_per_id_ds_id"
    t.index ["ExportID"], name: "services_export_id"
    t.index ["PersonalID"], name: "index_Services_on_PersonalID"
    t.index ["data_source_id", "PersonalID", "RecordType", "EnrollmentID", "DateProvided"], name: "index_services_ds_id_p_id_type_entry_id_date"
    t.index ["data_source_id", "ServicesID"], name: "unk_Services", unique: true
    t.index ["data_source_id"], name: "index_Services_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_Services_on_pending_date_deleted"
  end

  create_table "User", id: :serial, force: :cascade do |t|
    t.string "UserID", limit: 32, null: false
    t.string "UserFirstName"
    t.string "UserLastName"
    t.string "UserPhone", limit: 10
    t.string "UserExtension", limit: 5
    t.string "UserEmail"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.datetime "pending_date_deleted"
    t.string "source_hash"
    t.index ["UserID", "data_source_id"], name: "index_User_on_UserID_and_data_source_id"
    t.index ["pending_date_deleted"], name: "index_User_on_pending_date_deleted"
  end

  create_table "ad_hoc_batches", id: :serial, force: :cascade do |t|
    t.integer "ad_hoc_data_source_id"
    t.string "description", null: false
    t.integer "uploaded_count"
    t.integer "matched_count"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "import_errors"
    t.string "file"
    t.string "name"
    t.string "size"
    t.string "content_type"
    t.binary "content"
    t.integer "user_id"
    t.index ["created_at"], name: "index_ad_hoc_batches_on_created_at"
    t.index ["deleted_at"], name: "index_ad_hoc_batches_on_deleted_at"
    t.index ["updated_at"], name: "index_ad_hoc_batches_on_updated_at"
  end

  create_table "ad_hoc_clients", id: :serial, force: :cascade do |t|
    t.integer "ad_hoc_data_source_id"
    t.integer "client_id"
    t.jsonb "matching_client_ids"
    t.integer "batch_id"
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "ssn"
    t.date "dob"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_ad_hoc_clients_on_created_at"
    t.index ["deleted_at"], name: "index_ad_hoc_clients_on_deleted_at"
    t.index ["updated_at"], name: "index_ad_hoc_clients_on_updated_at"
  end

  create_table "ad_hoc_data_sources", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name"
    t.string "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_ad_hoc_data_sources_on_created_at"
    t.index ["deleted_at"], name: "index_ad_hoc_data_sources_on_deleted_at"
    t.index ["updated_at"], name: "index_ad_hoc_data_sources_on_updated_at"
  end

  create_table "administrative_events", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.date "date", null: false
    t.string "title", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_administrative_events_on_deleted_at"
  end

  create_table "anomalies", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.integer "submitted_by"
    t.string "description"
    t.string "status", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["client_id"], name: "index_anomalies_on_client_id"
    t.index ["status"], name: "index_anomalies_on_status"
  end

  create_table "api_client_data_source_ids", id: :serial, force: :cascade do |t|
    t.string "warehouse_id"
    t.string "id_in_data_source"
    t.integer "site_id_in_data_source"
    t.integer "data_source_id"
    t.integer "client_id"
    t.date "last_contact"
    t.boolean "temporary_high_priority", default: false, null: false
    t.index ["client_id"], name: "index_api_client_data_source_ids_on_client_id"
    t.index ["data_source_id"], name: "index_api_client_data_source_ids_on_data_source_id"
    t.index ["warehouse_id"], name: "index_api_client_data_source_ids_on_warehouse_id"
  end

  create_table "available_file_tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "group"
    t.string "included_info"
    t.integer "weight", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "document_ready", default: false
    t.boolean "notification_trigger", default: false
    t.boolean "consent_form", default: false
    t.string "note"
    t.boolean "full_release", default: false, null: false
    t.boolean "requires_effective_date", default: false, null: false
    t.boolean "requires_expiration_date", default: false, null: false
    t.string "required_for"
    t.boolean "coc_available", default: false, null: false
    t.boolean "verified_homeless_history", default: false, null: false
  end

  create_table "bo_configs", id: :serial, force: :cascade do |t|
    t.integer "data_source_id"
    t.string "user"
    t.string "encrypted_pass"
    t.string "encrypted_pass_iv"
    t.string "url"
    t.string "server"
    t.string "client_lookup_cuid"
    t.string "touch_point_lookup_cuid"
    t.string "subject_response_lookup_cuid"
    t.string "site_touch_point_map_cuid"
    t.string "disability_verification_cuid"
    t.integer "disability_touch_point_id"
    t.integer "disability_touch_point_question_id"
  end

  create_table "cas_availabilities", id: :serial, force: :cascade do |t|
    t.integer "client_id", null: false
    t.datetime "available_at", null: false
    t.datetime "unavailable_at"
    t.boolean "part_of_a_family", default: false, null: false
    t.integer "age_at_available_at"
    t.index ["available_at"], name: "index_cas_availabilities_on_available_at"
    t.index ["client_id"], name: "index_cas_availabilities_on_client_id"
    t.index ["unavailable_at"], name: "index_cas_availabilities_on_unavailable_at"
  end

  create_table "cas_enrollments", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.integer "enrollment_id"
    t.date "entry_date"
    t.date "exit_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "history"
    t.index ["client_id"], name: "index_cas_enrollments_on_client_id"
    t.index ["enrollment_id"], name: "index_cas_enrollments_on_enrollment_id"
  end

  create_table "cas_houseds", id: :serial, force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "cas_client_id", null: false
    t.integer "match_id", null: false
    t.date "housed_on", null: false
    t.boolean "inactivated", default: false
    t.index ["client_id"], name: "index_cas_houseds_on_client_id"
  end

  create_table "cas_non_hmis_client_histories", id: :serial, force: :cascade do |t|
    t.integer "cas_client_id", null: false
    t.date "available_on", null: false
    t.date "unavailable_on"
    t.boolean "part_of_a_family", default: false, null: false
    t.integer "age_at_available_on"
    t.index ["cas_client_id"], name: "index_cas_non_hmis_client_histories_on_cas_client_id"
  end

  create_table "cas_reports", id: :serial, force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "match_id", null: false
    t.integer "decision_id", null: false
    t.integer "decision_order", null: false
    t.string "match_step", null: false
    t.string "decision_status", null: false
    t.boolean "current_step", default: false, null: false
    t.boolean "active_match", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "elapsed_days", default: 0, null: false
    t.datetime "client_last_seen_date"
    t.datetime "criminal_hearing_date"
    t.string "decline_reason"
    t.string "not_working_with_client_reason"
    t.string "administrative_cancel_reason"
    t.boolean "client_spoken_with_services_agency"
    t.boolean "cori_release_form_submitted"
    t.datetime "match_started_at"
    t.string "program_type"
    t.json "shelter_agency_contacts"
    t.json "hsa_contacts"
    t.json "ssp_contacts"
    t.json "admin_contacts"
    t.json "clent_contacts"
    t.json "hsp_contacts"
    t.string "program_name"
    t.string "sub_program_name"
    t.string "terminal_status"
    t.string "match_route"
    t.integer "cas_client_id"
    t.date "client_move_in_date"
    t.string "source_data_source"
    t.string "event_contact"
    t.string "event_contact_agency"
    t.integer "vacancy_id"
    t.string "housing_type"
    t.index ["client_id", "match_id", "decision_id"], name: "index_cas_reports_on_client_id_and_match_id_and_decision_id", unique: true
  end

  create_table "cas_vacancies", id: :serial, force: :cascade do |t|
    t.integer "program_id", null: false
    t.integer "sub_program_id", null: false
    t.string "program_name"
    t.string "sub_program_name"
    t.string "program_type"
    t.string "route_name", null: false
    t.datetime "vacancy_created_at", null: false
    t.datetime "vacancy_made_available_at"
    t.datetime "first_matched_at"
    t.index ["program_id"], name: "index_cas_vacancies_on_program_id"
    t.index ["sub_program_id"], name: "index_cas_vacancies_on_sub_program_id"
  end

  create_table "ce_assessments", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "client_id", null: false
    t.string "type", null: false
    t.datetime "submitted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "active", default: true
    t.integer "score", default: 0
    t.integer "priority_score", default: 0
    t.integer "assessor_id", null: false
    t.string "location"
    t.string "client_email"
    t.boolean "military_duty", default: false
    t.boolean "under_25", default: false
    t.boolean "over_60", default: false
    t.boolean "lgbtq", default: false
    t.boolean "children_under_18", default: false
    t.boolean "fleeing_dv", default: false
    t.boolean "living_outdoors", default: false
    t.boolean "urgent_health_issue", default: false
    t.boolean "location_option_1", default: false
    t.boolean "location_option_2", default: false
    t.boolean "location_option_3", default: false
    t.boolean "location_option_4", default: false
    t.boolean "location_option_5", default: false
    t.boolean "location_option_6", default: false
    t.string "location_option_other"
    t.string "location_option_no"
    t.integer "homelessness"
    t.integer "substance_use"
    t.integer "mental_health"
    t.integer "health_care"
    t.integer "legal_issues"
    t.integer "income"
    t.integer "work"
    t.integer "independent_living"
    t.integer "community_involvement"
    t.integer "survival_skills"
    t.boolean "barrier_no_rental_history", default: false
    t.boolean "barrier_no_income", default: false
    t.boolean "barrier_poor_credit", default: false
    t.boolean "barrier_eviction_history", default: false
    t.boolean "barrier_eviction_from_public_housing", default: false
    t.boolean "barrier_bedrooms_3", default: false
    t.boolean "barrier_service_animal", default: false
    t.boolean "barrier_cori_issues", default: false
    t.boolean "barrier_registered_sex_offender", default: false
    t.string "barrier_other"
    t.boolean "preferences_studio", default: false
    t.boolean "preferences_roomate", default: false
    t.boolean "preferences_pets", default: false
    t.boolean "preferences_accessible", default: false
    t.boolean "preferences_quiet", default: false
    t.boolean "preferences_public_transport", default: false
    t.boolean "preferences_parks", default: false
    t.string "preferences_other"
    t.integer "assessor_rating"
    t.boolean "homeless_six_months", default: false
    t.boolean "mortality_hospitilization_3", default: false
    t.boolean "mortality_emergency_room_3", default: false
    t.boolean "mortality_over_60", default: false
    t.boolean "mortality_cirrhosis", default: false
    t.boolean "mortality_renal_disease", default: false
    t.boolean "mortality_frostbite", default: false
    t.boolean "mortality_hiv", default: false
    t.boolean "mortality_tri_morbid", default: false
    t.boolean "lacks_access_to_shelter", default: false
    t.boolean "high_potential_for_vicitimization", default: false
    t.boolean "danger_of_harm", default: false
    t.boolean "acute_medical_condition", default: false
    t.boolean "acute_psychiatric_condition", default: false
    t.boolean "acute_substance_abuse", default: false
    t.boolean "location_no_preference"
    t.index ["assessor_id"], name: "index_ce_assessments_on_assessor_id"
    t.index ["client_id"], name: "index_ce_assessments_on_client_id"
    t.index ["deleted_at"], name: "index_ce_assessments_on_deleted_at"
    t.index ["type"], name: "index_ce_assessments_on_type"
    t.index ["user_id"], name: "index_ce_assessments_on_user_id"
  end

  create_table "census_by_project_types", id: :serial, force: :cascade do |t|
    t.integer "ProjectType", null: false
    t.date "date", null: false
    t.boolean "veteran", default: false, null: false
    t.integer "gender", default: 99, null: false
    t.integer "client_count", default: 0, null: false
  end

  create_table "censuses", id: :serial, force: :cascade do |t|
    t.integer "data_source_id", null: false
    t.integer "ProjectType", null: false
    t.string "OrganizationID", null: false
    t.string "ProjectID", null: false
    t.date "date", null: false
    t.boolean "veteran", default: false, null: false
    t.integer "gender", default: 99, null: false
    t.integer "client_count", default: 0, null: false
    t.integer "bed_inventory", default: 0, null: false
    t.index ["data_source_id", "ProjectType", "OrganizationID", "ProjectID"], name: "index_censuses_ds_id_proj_type_org_id_proj_id"
    t.index ["date", "ProjectType"], name: "index_censuses_on_date_and_ProjectType"
    t.index ["date"], name: "index_censuses_on_date"
  end

  create_table "censuses_averaged_by_year", id: :serial, force: :cascade do |t|
    t.integer "year", null: false
    t.integer "data_source_id"
    t.string "OrganizationID"
    t.string "ProjectID"
    t.integer "ProjectType", null: false
    t.integer "client_count", default: 0, null: false
    t.integer "bed_inventory", default: 0, null: false
    t.integer "seasonal_inventory", default: 0, null: false
    t.integer "overflow_inventory", default: 0, null: false
    t.integer "days_of_service", default: 0, null: false
    t.index ["year", "data_source_id", "ProjectType", "OrganizationID", "ProjectID"], name: "index_censuses_ave_year_ds_id_proj_type_org_id_proj_id"
  end

  create_table "children", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.date "dob"
    t.integer "family_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_children_on_family_id"
  end

  create_table "chronics", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.integer "client_id", null: false
    t.integer "days_in_last_three_years"
    t.integer "months_in_last_three_years"
    t.boolean "individual"
    t.integer "age"
    t.date "homeless_since"
    t.boolean "dmh", default: false
    t.string "trigger"
    t.string "project_names"
    t.index ["client_id"], name: "index_chronics_on_client_id"
    t.index ["date"], name: "index_chronics_on_date"
  end

  create_table "client_matches", id: :serial, force: :cascade do |t|
    t.integer "source_client_id", null: false
    t.integer "destination_client_id", null: false
    t.integer "updated_by_id"
    t.integer "lock_version"
    t.integer "defer_count"
    t.string "status", null: false
    t.float "score"
    t.text "score_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_client_id"], name: "index_client_matches_on_destination_client_id"
    t.index ["source_client_id"], name: "index_client_matches_on_source_client_id"
    t.index ["updated_by_id"], name: "index_client_matches_on_updated_by_id"
  end

  create_table "client_merge_histories", id: :serial, force: :cascade do |t|
    t.integer "merged_into", null: false
    t.integer "merged_from", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_client_merge_histories_on_created_at"
    t.index ["merged_from"], name: "index_client_merge_histories_on_merged_from"
    t.index ["updated_at"], name: "index_client_merge_histories_on_updated_at"
  end

  create_table "client_notes", id: :serial, force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "user_id", null: false
    t.string "type", null: false
    t.text "note"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string "migrated_username"
    t.jsonb "recipients"
    t.datetime "sent_at"
    t.index ["client_id"], name: "index_client_notes_on_client_id"
    t.index ["user_id"], name: "index_client_notes_on_user_id"
  end

  create_table "client_split_histories", id: :serial, force: :cascade do |t|
    t.integer "split_into", null: false
    t.integer "split_from", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "receive_hmis"
    t.boolean "receive_health"
    t.index ["created_at"], name: "index_client_split_histories_on_created_at"
    t.index ["split_from"], name: "index_client_split_histories_on_split_from"
    t.index ["updated_at"], name: "index_client_split_histories_on_updated_at"
  end

  create_table "cohort_client_changes", id: :serial, force: :cascade do |t|
    t.integer "cohort_client_id", null: false
    t.integer "cohort_id", null: false
    t.integer "user_id", null: false
    t.string "change"
    t.datetime "changed_at", null: false
    t.string "reason"
    t.index ["change"], name: "index_cohort_client_changes_on_change"
    t.index ["changed_at"], name: "index_cohort_client_changes_on_changed_at"
  end

  create_table "cohort_client_notes", id: :serial, force: :cascade do |t|
    t.integer "cohort_client_id", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.integer "user_id", null: false
    t.index ["cohort_client_id"], name: "index_cohort_client_notes_on_cohort_client_id"
    t.index ["deleted_at"], name: "index_cohort_client_notes_on_deleted_at"
  end

  create_table "cohort_clients", id: :serial, force: :cascade do |t|
    t.integer "cohort_id", null: false
    t.integer "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "agency"
    t.string "case_manager"
    t.string "housing_manager"
    t.string "housing_search_agency"
    t.string "housing_opportunity"
    t.string "legal_barriers"
    t.string "criminal_record_status"
    t.string "document_ready"
    t.boolean "sif_eligible", default: false
    t.string "sensory_impaired"
    t.date "housed_date"
    t.string "destination"
    t.string "sub_population"
    t.integer "rank"
    t.string "st_francis_house"
    t.date "last_group_review_date"
    t.date "pre_contemplative_last_date_approached"
    t.string "va_eligible"
    t.boolean "vash_eligible", default: false
    t.string "chapter_115"
    t.date "first_date_homeless"
    t.date "last_date_approached"
    t.boolean "chronic", default: false
    t.string "dnd_rank"
    t.boolean "veteran", default: false
    t.string "housing_track_suggested"
    t.string "housing_track_enrolled"
    t.integer "adjusted_days_homeless"
    t.string "housing_navigator"
    t.string "status"
    t.string "ssvf_eligible"
    t.string "location"
    t.string "location_type"
    t.string "vet_squares_confirmed"
    t.boolean "active", default: true, null: false
    t.string "provider"
    t.string "next_step"
    t.text "housing_plan"
    t.date "document_ready_on"
    t.string "new_lease_referral"
    t.string "vulnerability_rank"
    t.boolean "ineligible", default: false, null: false
    t.integer "adjusted_days_homeless_last_three_years", default: 0, null: false
    t.boolean "original_chronic", default: false, null: false
    t.string "not_a_vet"
    t.string "primary_housing_track_suggested"
    t.integer "minimum_bedroom_size"
    t.string "special_needs"
    t.integer "adjusted_days_literally_homeless_last_three_years"
    t.boolean "reported"
    t.integer "calculated_days_homeless_on_effective_date"
    t.integer "days_homeless_last_three_years_on_effective_date"
    t.integer "days_literally_homeless_last_three_years_on_effective_date"
    t.string "destination_from_homelessness"
    t.string "related_users"
    t.date "disability_verification_date"
    t.string "missing_documents"
    t.string "sleeping_location"
    t.string "exit_destination"
    t.string "lgbtq"
    t.string "school_district"
    t.string "user_string_1"
    t.string "user_string_2"
    t.string "user_string_3"
    t.string "user_string_4"
    t.boolean "user_boolean_1"
    t.boolean "user_boolean_2"
    t.boolean "user_boolean_3"
    t.boolean "user_boolean_4"
    t.string "user_select_1"
    t.string "user_select_2"
    t.string "user_select_3"
    t.string "user_select_4"
    t.string "user_date_1"
    t.string "user_date_2"
    t.string "user_date_3"
    t.string "user_date_4"
    t.integer "assessment_score"
    t.integer "vispdat_score_manual"
    t.integer "user_numeric_1"
    t.integer "user_numeric_2"
    t.integer "user_numeric_3"
    t.integer "user_numeric_4"
    t.string "user_string_5"
    t.string "user_string_6"
    t.string "user_string_7"
    t.string "user_string_8"
    t.string "hmis_destination"
    t.boolean "user_boolean_5"
    t.boolean "user_boolean_6"
    t.boolean "user_boolean_7"
    t.boolean "user_boolean_8"
    t.boolean "user_boolean_9"
    t.boolean "user_boolean_10"
    t.boolean "user_boolean_11"
    t.boolean "user_boolean_12"
    t.boolean "user_boolean_13"
    t.boolean "user_boolean_14"
    t.boolean "user_boolean_15"
    t.string "lgbtq_from_hmis"
    t.integer "days_homeless_plus_overrides"
    t.integer "user_numeric_5"
    t.integer "user_numeric_6"
    t.integer "user_numeric_7"
    t.integer "user_numeric_8"
    t.integer "user_numeric_9"
    t.integer "user_numeric_10"
    t.string "user_select_5"
    t.string "user_select_6"
    t.string "user_select_7"
    t.string "user_select_8"
    t.string "user_select_9"
    t.string "user_select_10"
    t.string "user_date_5"
    t.string "user_date_6"
    t.string "user_date_7"
    t.string "user_date_8"
    t.string "user_date_9"
    t.string "user_date_10"
    t.index ["client_id"], name: "index_cohort_clients_on_client_id"
    t.index ["cohort_id"], name: "index_cohort_clients_on_cohort_id"
    t.index ["deleted_at"], name: "index_cohort_clients_on_deleted_at"
  end

  create_table "cohort_column_options", id: :serial, force: :cascade do |t|
    t.string "cohort_column", null: false
    t.integer "weight"
    t.string "value"
    t.boolean "active", default: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cohorts", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.date "effective_date"
    t.text "column_state"
    t.string "default_sort_direction", default: "desc"
    t.boolean "only_window", default: true, null: false
    t.boolean "active_cohort", default: true, null: false
    t.integer "static_column_count", default: 3, null: false
    t.string "short_name"
    t.integer "days_of_inactivity", default: 90
    t.boolean "show_on_client_dashboard", default: true, null: false
    t.boolean "visible_in_cas", default: true, null: false
    t.string "assessment_trigger"
    t.integer "tag_id"
    t.index ["deleted_at"], name: "index_cohorts_on_deleted_at"
  end

  create_table "configs", id: :serial, force: :cascade do |t|
    t.boolean "project_type_override", default: true, null: false
    t.boolean "eto_api_available", default: false, null: false
    t.string "cas_available_method", default: "cas_flag", null: false
    t.boolean "healthcare_available", default: false, null: false
    t.string "family_calculation_method", default: "adult_child"
    t.string "site_coc_codes"
    t.string "default_coc_zipcodes"
    t.string "continuum_name"
    t.string "cas_url", default: "https://cas.boston.gov"
    t.string "release_duration", default: "Indefinite"
    t.boolean "allow_partial_release", default: true
    t.string "cas_flag_method", default: "manual"
    t.boolean "window_access_requires_release", default: false
    t.boolean "show_partial_ssn_in_window_search_results", default: false
    t.string "url_of_blank_consent_form"
    t.boolean "ahar_psh_includes_rrh", default: true
    t.boolean "so_day_as_month", default: true
    t.text "client_details"
    t.boolean "allow_multiple_file_tags", default: false, null: false
    t.boolean "infer_family_from_household_id", default: false, null: false
    t.string "chronic_definition", default: "chronics", null: false
    t.string "vispdat_prioritization_scheme", default: "length_of_time", null: false
    t.boolean "show_vispdats_on_dashboards", default: false
    t.boolean "rrh_cas_readiness", default: false
    t.string "cas_days_homeless_source", default: "days_homeless"
    t.boolean "consent_visible_to_all", default: false
    t.boolean "verified_homeless_history_visible_to_all", default: false, null: false
    t.boolean "only_most_recent_import", default: false
  end

  create_table "contacts", id: :serial, force: :cascade do |t|
    t.string "type", null: false
    t.integer "entity_id", null: false
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["entity_id"], name: "index_contacts_on_entity_id"
    t.index ["type"], name: "index_contacts_on_type"
  end

  create_table "dashboard_export_reports", id: :serial, force: :cascade do |t|
    t.integer "file_id"
    t.integer "user_id"
    t.integer "job_id"
    t.string "coc_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
  end

  create_table "data_monitorings", id: :serial, force: :cascade do |t|
    t.integer "resource_id", null: false
    t.date "census"
    t.date "calculated_on"
    t.date "calculate_after"
    t.float "value"
    t.float "change"
    t.integer "iteration"
    t.integer "of_iterations"
    t.string "type"
    t.index ["calculated_on"], name: "index_data_monitorings_on_calculated_on"
    t.index ["census"], name: "index_data_monitorings_on_census"
    t.index ["resource_id"], name: "index_data_monitorings_on_resource_id"
    t.index ["type"], name: "index_data_monitorings_on_type"
  end

  create_table "data_sources", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "file_path"
    t.datetime "last_imported_at"
    t.date "newest_updated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source_type"
    t.boolean "munged_personal_id", default: false, null: false
    t.string "short_name"
    t.boolean "visible_in_window", default: false, null: false
    t.boolean "authoritative", default: false
    t.string "after_create_path"
    t.boolean "import_paused", default: false, null: false
    t.string "authoritative_type"
    t.string "source_id"
  end

  create_table "direct_financial_assistances", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.integer "user_id"
    t.date "provided_on"
    t.string "type_provided"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_direct_financial_assistances_on_deleted_at"
  end

  create_table "enrollment_change_histories", id: :serial, force: :cascade do |t|
    t.integer "client_id", null: false
    t.date "on", null: false
    t.jsonb "residential"
    t.jsonb "other"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "version", default: 1, null: false
    t.integer "days_homeless"
    t.index ["client_id"], name: "index_enrollment_change_histories_on_client_id"
  end

  create_table "enrollment_extras", id: :serial, force: :cascade do |t|
    t.integer "enrollment_id", null: false
    t.integer "vispdat_grand_total"
    t.date "vispdat_added_at"
    t.date "vispdat_started_at"
    t.date "vispdat_ended_at"
    t.string "source_tab"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "eto_api_configs", id: :serial, force: :cascade do |t|
    t.integer "data_source_id", null: false
    t.jsonb "touchpoint_fields"
    t.jsonb "demographic_fields"
    t.jsonb "demographic_fields_with_attributes"
    t.jsonb "additional_fields"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["data_source_id"], name: "index_eto_api_configs_on_data_source_id"
  end

  create_table "eto_client_lookups", id: :serial, force: :cascade do |t|
    t.integer "data_source_id", null: false
    t.integer "client_id", null: false
    t.string "enterprise_guid", null: false
    t.integer "site_id", null: false
    t.integer "subject_id", null: false
    t.datetime "last_updated"
    t.integer "participant_site_identifier"
    t.index ["client_id"], name: "index_eto_client_lookups_on_client_id"
    t.index ["data_source_id"], name: "index_eto_client_lookups_on_data_source_id"
  end

  create_table "eto_subject_response_lookups", id: :serial, force: :cascade do |t|
    t.integer "data_source_id", null: false
    t.integer "subject_id", null: false
    t.integer "response_id", null: false
    t.index ["subject_id"], name: "index_eto_subject_response_lookups_on_subject_id"
  end

  create_table "eto_touch_point_lookups", id: :serial, force: :cascade do |t|
    t.integer "data_source_id", null: false
    t.integer "client_id", null: false
    t.integer "subject_id", null: false
    t.integer "assessment_id", null: false
    t.integer "response_id", null: false
    t.datetime "last_updated"
    t.integer "site_id"
    t.index ["client_id"], name: "index_eto_touch_point_lookups_on_client_id"
    t.index ["data_source_id"], name: "index_eto_touch_point_lookups_on_data_source_id"
  end

  create_table "eto_touch_point_response_times", id: :serial, force: :cascade do |t|
    t.integer "touch_point_unique_identifier", null: false
    t.integer "response_unique_identifier", null: false
    t.datetime "response_last_updated", null: false
    t.integer "subject_unique_identifier", null: false
  end

  create_table "exports", id: :serial, force: :cascade do |t|
    t.string "export_id"
    t.integer "user_id"
    t.date "start_date"
    t.date "end_date"
    t.integer "period_type"
    t.integer "directive"
    t.integer "hash_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "faked_pii", default: false
    t.jsonb "project_ids"
    t.boolean "include_deleted", default: false
    t.string "content_type"
    t.binary "content"
    t.string "file"
    t.integer "delayed_job_id"
    t.index ["deleted_at"], name: "index_exports_on_deleted_at"
    t.index ["export_id"], name: "index_exports_on_export_id"
  end

  create_table "fake_data", id: :serial, force: :cascade do |t|
    t.string "environment", null: false
    t.text "map"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "client_ids"
  end

  create_table "files", id: :serial, force: :cascade do |t|
    t.string "type", null: false
    t.string "file"
    t.string "content_type"
    t.binary "content"
    t.integer "client_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string "note"
    t.string "name"
    t.boolean "visible_in_window"
    t.string "migrated_username"
    t.integer "vispdat_id"
    t.date "consent_form_signed_on"
    t.boolean "consent_form_confirmed"
    t.float "size"
    t.date "effective_date"
    t.date "expiration_date"
    t.integer "delete_reason"
    t.string "delete_detail"
    t.datetime "consent_revoked_at"
    t.jsonb "coc_codes", default: []
    t.index ["type"], name: "index_files_on_type"
    t.index ["vispdat_id"], name: "index_files_on_vispdat_id"
  end

  create_table "generate_service_history_batch_logs", id: :serial, force: :cascade do |t|
    t.integer "generate_service_history_log_id"
    t.integer "to_process"
    t.integer "updated"
    t.integer "patched"
    t.integer "delayed_job_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "generate_service_history_log", id: :serial, force: :cascade do |t|
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "to_delete"
    t.integer "to_add"
    t.integer "to_update"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "batches"
  end

  create_table "grades", id: :serial, force: :cascade do |t|
    t.string "type", null: false
    t.string "grade", null: false
    t.integer "percentage_low"
    t.integer "percentage_high"
    t.integer "percentage_under_low"
    t.integer "percentage_under_high"
    t.integer "percentage_over_low"
    t.integer "percentage_over_high"
    t.string "color", default: "#000000"
    t.integer "weight", default: 0, null: false
    t.index ["type"], name: "index_grades_on_type"
  end

  create_table "group_viewable_entities", id: :serial, force: :cascade do |t|
    t.integer "access_group_id", null: false
    t.integer "entity_id", null: false
    t.string "entity_type", null: false
    t.datetime "deleted_at"
    t.index ["access_group_id", "entity_id", "entity_type"], name: "one_entity_per_type_per_group", unique: true
  end

  create_table "helps", id: :serial, force: :cascade do |t|
    t.string "controller_path", null: false
    t.string "action_name", null: false
    t.string "external_url"
    t.string "title", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location", default: "internal", null: false
    t.index ["controller_path", "action_name"], name: "index_helps_on_controller_path_and_action_name", unique: true
    t.index ["created_at"], name: "index_helps_on_created_at"
    t.index ["updated_at"], name: "index_helps_on_updated_at"
  end

  create_table "hmis_assessments", id: :serial, force: :cascade do |t|
    t.integer "assessment_id", null: false
    t.integer "site_id", null: false
    t.string "site_name"
    t.string "name", null: false
    t.boolean "fetch", default: false, null: false
    t.boolean "active", default: true, null: false
    t.datetime "last_fetched_at"
    t.integer "data_source_id", null: false
    t.boolean "confidential", default: false, null: false
    t.boolean "exclude_from_window", default: false, null: false
    t.boolean "details_in_window_with_release", default: false, null: false
    t.boolean "health", default: false, null: false
    t.index ["assessment_id"], name: "index_hmis_assessments_on_assessment_id"
    t.index ["data_source_id"], name: "index_hmis_assessments_on_data_source_id"
    t.index ["site_id"], name: "index_hmis_assessments_on_site_id"
  end

  create_table "hmis_client_attributes_defined_text", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.integer "data_source_id"
    t.string "consent_form_status"
    t.datetime "consent_form_updated_at"
    t.string "source_id"
    t.string "source_class"
    t.index ["client_id"], name: "index_hmis_client_attributes_defined_text_on_client_id"
    t.index ["data_source_id"], name: "index_hmis_client_attributes_defined_text_on_data_source_id"
  end

  create_table "hmis_clients", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.text "response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "consent_form_status"
    t.string "case_manager_name"
    t.text "case_manager_attributes"
    t.string "assigned_staff_name"
    t.text "assigned_staff_attributes"
    t.string "counselor_name"
    t.text "counselor_attributes"
    t.string "outreach_counselor_name"
    t.integer "subject_id"
    t.jsonb "processed_fields"
    t.date "consent_confirmed_on"
    t.date "consent_expires_on"
    t.datetime "eto_last_updated"
    t.string "sexual_orientation"
    t.index ["client_id"], name: "index_hmis_clients_on_client_id"
  end

  create_table "hmis_forms", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.text "api_response"
    t.string "name"
    t.text "answers"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "response_id"
    t.integer "subject_id"
    t.datetime "collected_at"
    t.string "staff"
    t.string "assessment_type"
    t.string "collection_location"
    t.integer "assessment_id"
    t.integer "data_source_id", null: false
    t.integer "site_id"
    t.datetime "vispdat_score_updated_at"
    t.float "vispdat_total_score"
    t.float "vispdat_youth_score"
    t.float "vispdat_family_score"
    t.float "vispdat_months_homeless"
    t.float "vispdat_times_homeless"
    t.string "staff_email"
    t.datetime "eto_last_updated"
    t.string "housing_status"
    t.string "vispdat_pregnant"
    t.date "vispdat_pregnant_updated_at"
    t.index ["assessment_id"], name: "index_hmis_forms_on_assessment_id"
    t.index ["client_id"], name: "index_hmis_forms_on_client_id"
    t.index ["collected_at"], name: "index_hmis_forms_on_collected_at"
    t.index ["name"], name: "index_hmis_forms_on_name"
  end

  create_table "hmis_staff", id: :serial, force: :cascade do |t|
    t.integer "site_id"
    t.string "first_name"
    t.string "last_name"
    t.string "middle_initial"
    t.string "work_phone"
    t.string "cell_phone"
    t.string "email"
    t.string "ssn"
    t.string "source_class"
    t.string "source_id"
    t.integer "data_source_id"
  end

  create_table "hmis_staff_x_clients", id: :serial, force: :cascade do |t|
    t.integer "staff_id"
    t.integer "client_id"
    t.integer "relationship_id"
    t.string "source_class"
    t.string "source_id"
    t.index ["staff_id", "client_id", "relationship_id"], name: "index_staff_x_client_s_id_c_id_r_id", unique: true
  end

  create_table "hud_chronics", id: :serial, force: :cascade do |t|
    t.date "date"
    t.integer "client_id"
    t.integer "months_in_last_three_years"
    t.boolean "individual"
    t.integer "age"
    t.date "homeless_since"
    t.boolean "dmh"
    t.string "trigger"
    t.string "project_names"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "days_in_last_three_years"
    t.index ["client_id"], name: "index_hud_chronics_on_client_id"
  end

  create_table "hud_create_logs", id: :serial, force: :cascade do |t|
    t.string "hud_key", null: false
    t.string "personal_id", null: false
    t.string "type", null: false
    t.datetime "imported_at", null: false
    t.date "effective_date", null: false
    t.integer "data_source_id", null: false
    t.index ["effective_date"], name: "index_hud_create_logs_on_effective_date"
    t.index ["imported_at"], name: "index_hud_create_logs_on_imported_at"
  end

  create_table "identify_duplicates_log", id: :serial, force: :cascade do |t|
    t.datetime "started_at"
    t.datetime "completed_at"
    t.integer "to_match"
    t.integer "matched"
    t.integer "new_created"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "import_logs", id: :serial, force: :cascade do |t|
    t.integer "data_source_id"
    t.string "files"
    t.text "import_errors"
    t.string "summary"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "zip"
    t.integer "upload_id"
    t.index ["completed_at"], name: "index_import_logs_on_completed_at"
    t.index ["created_at"], name: "index_import_logs_on_created_at"
    t.index ["data_source_id"], name: "index_import_logs_on_data_source_id"
    t.index ["updated_at"], name: "index_import_logs_on_updated_at"
  end

  create_table "new_service_history", id: :serial, force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "data_source_id"
    t.date "date", null: false
    t.date "first_date_in_program", null: false
    t.date "last_date_in_program"
    t.string "enrollment_group_id", limit: 50
    t.integer "age", limit: 2
    t.integer "destination"
    t.string "head_of_household_id", limit: 50
    t.string "household_id", limit: 50
    t.string "project_id", limit: 50
    t.string "project_name", limit: 150
    t.integer "project_type", limit: 2
    t.integer "project_tracking_method"
    t.string "organization_id", limit: 50
    t.string "record_type", limit: 50, null: false
    t.integer "housing_status_at_entry"
    t.integer "housing_status_at_exit"
    t.integer "service_type", limit: 2
    t.integer "computed_project_type", limit: 2
    t.boolean "presented_as_individual"
    t.integer "other_clients_over_25", limit: 2, default: 0, null: false
    t.integer "other_clients_under_18", limit: 2, default: 0, null: false
    t.integer "other_clients_between_18_and_25", limit: 2, default: 0, null: false
    t.boolean "unaccompanied_youth", default: false, null: false
    t.boolean "parenting_youth", default: false, null: false
    t.boolean "parenting_juvenile", default: false, null: false
    t.boolean "children_only", default: false, null: false
    t.boolean "individual_adult", default: false, null: false
    t.boolean "individual_elder", default: false, null: false
    t.boolean "head_of_household", default: false, null: false
    t.index ["client_id", "record_type"], name: "index_sh_on_client_id"
    t.index ["computed_project_type", "record_type", "client_id"], name: "index_sh_on_computed_project_type"
    t.index ["data_source_id", "project_id", "organization_id", "record_type"], name: "index_sh_ds_proj_org_r_type"
    t.index ["date", "household_id", "record_type"], name: "index_sh_on_household_id"
    t.index ["enrollment_group_id", "project_tracking_method"], name: "index_sh__enrollment_id_track_meth"
    t.index ["first_date_in_program", "last_date_in_program", "record_type", "date"], name: "index_wsh_on_last_date_in_program"
    t.index ["first_date_in_program"], name: "index_new_service_history_on_first_date_in_program", using: :brin
    t.index ["record_type", "date", "data_source_id", "organization_id", "project_id", "project_type", "project_tracking_method"], name: "index_sh_date_ds_org_proj_proj_type"
  end

  create_table "nightly_census_by_project_clients", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.integer "project_id", null: false
    t.jsonb "veterans", default: []
    t.jsonb "non_veterans", default: []
    t.jsonb "children", default: []
    t.jsonb "adults", default: []
    t.jsonb "youth", default: []
    t.jsonb "families", default: []
    t.jsonb "individuals", default: []
    t.jsonb "parenting_youth", default: []
    t.jsonb "parenting_juveniles", default: []
    t.jsonb "all_clients", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "juveniles", default: []
    t.jsonb "unaccompanied_minors", default: []
  end

  create_table "nightly_census_by_project_type_clients", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.jsonb "literally_homeless_veterans", default: []
    t.jsonb "literally_homeless_non_veterans", default: []
    t.jsonb "literally_homeless_children", default: []
    t.jsonb "literally_homeless_adults", default: []
    t.jsonb "literally_homeless_youth", default: []
    t.jsonb "literally_homeless_families", default: []
    t.jsonb "literally_homeless_individuals", default: []
    t.jsonb "literally_homeless_parenting_youth", default: []
    t.jsonb "literally_homeless_parenting_juveniles", default: []
    t.jsonb "literally_homeless_all_clients", default: []
    t.jsonb "system_veterans", default: []
    t.jsonb "system_non_veterans", default: []
    t.jsonb "system_children", default: []
    t.jsonb "system_adults", default: []
    t.jsonb "system_youth", default: []
    t.jsonb "system_families", default: []
    t.jsonb "system_individuals", default: []
    t.jsonb "system_parenting_youth", default: []
    t.jsonb "system_parenting_juveniles", default: []
    t.jsonb "system_all_clients", default: []
    t.jsonb "homeless_veterans", default: []
    t.jsonb "homeless_non_veterans", default: []
    t.jsonb "homeless_children", default: []
    t.jsonb "homeless_adults", default: []
    t.jsonb "homeless_youth", default: []
    t.jsonb "homeless_families", default: []
    t.jsonb "homeless_individuals", default: []
    t.jsonb "homeless_parenting_youth", default: []
    t.jsonb "homeless_parenting_juveniles", default: []
    t.jsonb "homeless_all_clients", default: []
    t.jsonb "ph_veterans", default: []
    t.jsonb "ph_non_veterans", default: []
    t.jsonb "ph_children", default: []
    t.jsonb "ph_adults", default: []
    t.jsonb "ph_youth", default: []
    t.jsonb "ph_families", default: []
    t.jsonb "ph_individuals", default: []
    t.jsonb "ph_parenting_youth", default: []
    t.jsonb "ph_parenting_juveniles", default: []
    t.jsonb "ph_all_clients", default: []
    t.jsonb "es_veterans", default: []
    t.jsonb "es_non_veterans", default: []
    t.jsonb "es_children", default: []
    t.jsonb "es_adults", default: []
    t.jsonb "es_youth", default: []
    t.jsonb "es_families", default: []
    t.jsonb "es_individuals", default: []
    t.jsonb "es_parenting_youth", default: []
    t.jsonb "es_parenting_juveniles", default: []
    t.jsonb "es_all_clients", default: []
    t.jsonb "th_veterans", default: []
    t.jsonb "th_non_veterans", default: []
    t.jsonb "th_children", default: []
    t.jsonb "th_adults", default: []
    t.jsonb "th_youth", default: []
    t.jsonb "th_families", default: []
    t.jsonb "th_individuals", default: []
    t.jsonb "th_parenting_youth", default: []
    t.jsonb "th_parenting_juveniles", default: []
    t.jsonb "th_all_clients", default: []
    t.jsonb "so_veterans", default: []
    t.jsonb "so_non_veterans", default: []
    t.jsonb "so_children", default: []
    t.jsonb "so_adults", default: []
    t.jsonb "so_youth", default: []
    t.jsonb "so_families", default: []
    t.jsonb "so_individuals", default: []
    t.jsonb "so_parenting_youth", default: []
    t.jsonb "so_parenting_juveniles", default: []
    t.jsonb "so_all_clients", default: []
    t.jsonb "sh_veterans", default: []
    t.jsonb "sh_non_veterans", default: []
    t.jsonb "sh_children", default: []
    t.jsonb "sh_adults", default: []
    t.jsonb "sh_youth", default: []
    t.jsonb "sh_families", default: []
    t.jsonb "sh_individuals", default: []
    t.jsonb "sh_parenting_youth", default: []
    t.jsonb "sh_parenting_juveniles", default: []
    t.jsonb "sh_all_clients", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "literally_homeless_juveniles", default: []
    t.jsonb "system_juveniles", default: []
    t.jsonb "homeless_juveniles", default: []
    t.jsonb "ph_juveniles", default: []
    t.jsonb "es_juveniles", default: []
    t.jsonb "th__juveniles", default: []
    t.jsonb "so_juveniles", default: []
    t.jsonb "sh_juveniles", default: []
    t.jsonb "literally_homeless_unaccompanied_minors", default: []
    t.jsonb "system_unaccompanied_minors", default: []
    t.jsonb "homeless_unaccompanied_minors", default: []
    t.jsonb "ph_unaccompanied_minors", default: []
    t.jsonb "es_unaccompanied_minors", default: []
    t.jsonb "th_unaccompanied_minors", default: []
    t.jsonb "so_unaccompanied_minors", default: []
    t.jsonb "sh_unaccompanied_minors", default: []
  end

  create_table "nightly_census_by_project_types", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.integer "literally_homeless_veterans", default: 0
    t.integer "literally_homeless_non_veterans", default: 0
    t.integer "literally_homeless_children", default: 0
    t.integer "literally_homeless_adults", default: 0
    t.integer "literally_homeless_youth", default: 0
    t.integer "literally_homeless_families", default: 0
    t.integer "literally_homeless_individuals", default: 0
    t.integer "literally_homeless_parenting_youth", default: 0
    t.integer "literally_homeless_parenting_juveniles", default: 0
    t.integer "literally_homeless_all_clients", default: 0
    t.integer "system_veterans", default: 0
    t.integer "system_non_veterans", default: 0
    t.integer "system_children", default: 0
    t.integer "system_adults", default: 0
    t.integer "system_youth", default: 0
    t.integer "system_families", default: 0
    t.integer "system_individuals", default: 0
    t.integer "system_parenting_youth", default: 0
    t.integer "system_parenting_juveniles", default: 0
    t.integer "system_all_clients", default: 0
    t.integer "homeless_veterans", default: 0
    t.integer "homeless_non_veterans", default: 0
    t.integer "homeless_children", default: 0
    t.integer "homeless_adults", default: 0
    t.integer "homeless_youth", default: 0
    t.integer "homeless_families", default: 0
    t.integer "homeless_individuals", default: 0
    t.integer "homeless_parenting_youth", default: 0
    t.integer "homeless_parenting_juveniles", default: 0
    t.integer "homeless_all_clients", default: 0
    t.integer "ph_veterans", default: 0
    t.integer "ph_non_veterans", default: 0
    t.integer "ph_children", default: 0
    t.integer "ph_adults", default: 0
    t.integer "ph_youth", default: 0
    t.integer "ph_families", default: 0
    t.integer "ph_individuals", default: 0
    t.integer "ph_parenting_youth", default: 0
    t.integer "ph_parenting_juveniles", default: 0
    t.integer "ph_all_clients", default: 0
    t.integer "es_veterans", default: 0
    t.integer "es_non_veterans", default: 0
    t.integer "es_children", default: 0
    t.integer "es_adults", default: 0
    t.integer "es_youth", default: 0
    t.integer "es_families", default: 0
    t.integer "es_individuals", default: 0
    t.integer "es_parenting_youth", default: 0
    t.integer "es_parenting_juveniles", default: 0
    t.integer "es_all_clients", default: 0
    t.integer "th_veterans", default: 0
    t.integer "th_non_veterans", default: 0
    t.integer "th_children", default: 0
    t.integer "th_adults", default: 0
    t.integer "th_youth", default: 0
    t.integer "th_families", default: 0
    t.integer "th_individuals", default: 0
    t.integer "th_parenting_youth", default: 0
    t.integer "th_parenting_juveniles", default: 0
    t.integer "th_all_clients", default: 0
    t.integer "so_veterans", default: 0
    t.integer "so_non_veterans", default: 0
    t.integer "so_children", default: 0
    t.integer "so_adults", default: 0
    t.integer "so_youth", default: 0
    t.integer "so_families", default: 0
    t.integer "so_individuals", default: 0
    t.integer "so_parenting_youth", default: 0
    t.integer "so_parenting_juveniles", default: 0
    t.integer "so_all_clients", default: 0
    t.integer "sh_veterans", default: 0
    t.integer "sh_non_veterans", default: 0
    t.integer "sh_children", default: 0
    t.integer "sh_adults", default: 0
    t.integer "sh_youth", default: 0
    t.integer "sh_families", default: 0
    t.integer "sh_individuals", default: 0
    t.integer "sh_parenting_youth", default: 0
    t.integer "sh_parenting_juveniles", default: 0
    t.integer "sh_all_clients", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ph_beds", default: 0
    t.integer "es_beds", default: 0
    t.integer "th_beds", default: 0
    t.integer "so_beds", default: 0
    t.integer "sh_beds", default: 0
    t.integer "literally_homeless_juveniles", default: 0
    t.integer "system_juveniles", default: 0
    t.integer "homeless_juveniles", default: 0
    t.integer "ph_juveniles", default: 0
    t.integer "es_juveniles", default: 0
    t.integer "th_juveniles", default: 0
    t.integer "so_juveniles", default: 0
    t.integer "sh_juveniles", default: 0
    t.integer "literally_homeless_unaccompanied_minors", default: 0
    t.integer "system_unaccompanied_minors", default: 0
    t.integer "homeless_unaccompanied_minors", default: 0
    t.integer "ph_unaccompanied_minors", default: 0
    t.integer "es_unaccompanied_minors", default: 0
    t.integer "th_unaccompanied_minors", default: 0
    t.integer "so_unaccompanied_minors", default: 0
    t.integer "sh_unaccompanied_minors", default: 0
  end

  create_table "nightly_census_by_projects", id: :serial, force: :cascade do |t|
    t.date "date", null: false
    t.integer "project_id", null: false
    t.integer "veterans", default: 0
    t.integer "non_veterans", default: 0
    t.integer "children", default: 0
    t.integer "adults", default: 0
    t.integer "youth", default: 0
    t.integer "families", default: 0
    t.integer "individuals", default: 0
    t.integer "parenting_youth", default: 0
    t.integer "parenting_juveniles", default: 0
    t.integer "all_clients", default: 0
    t.integer "beds", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "juveniles", default: 0
    t.integer "unaccompanied_minors", default: 0
  end

  create_table "non_hmis_uploads", id: :serial, force: :cascade do |t|
    t.integer "data_source_id"
    t.integer "user_id"
    t.integer "delayed_job_id"
    t.string "file", null: false
    t.float "percent_complete"
    t.json "import_errors"
    t.string "content_type"
    t.binary "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_non_hmis_uploads_on_deleted_at"
  end

  create_table "project_data_quality", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.string "type"
    t.date "start"
    t.date "end"
    t.json "report"
    t.datetime "sent_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "processing_errors"
    t.integer "project_group_id"
    t.json "support"
    t.integer "requestor_id"
    t.index ["project_id"], name: "index_project_data_quality_on_project_id"
  end

  create_table "project_groups", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "project_project_groups", id: :serial, force: :cascade do |t|
    t.integer "project_group_id"
    t.integer "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "recent_report_enrollments", id: false, force: :cascade do |t|
    t.string "EnrollmentID", limit: 50
    t.string "PersonalID"
    t.string "ProjectID", limit: 50
    t.date "EntryDate"
    t.string "HouseholdID"
    t.integer "RelationshipToHoH"
    t.integer "LivingSituation"
    t.string "OtherResidencePrior"
    t.integer "LengthOfStay"
    t.integer "DisablingCondition"
    t.integer "EntryFromStreetESSH"
    t.date "DateToStreetESSH"
    t.integer "ContinuouslyHomelessOneYear"
    t.integer "TimesHomelessPastThreeYears"
    t.integer "MonthsHomelessPastThreeYears"
    t.integer "MonthsHomelessThisTime"
    t.integer "StatusDocumented"
    t.integer "HousingStatus"
    t.date "DateOfEngagement"
    t.integer "InPermanentHousing"
    t.date "MoveInDate"
    t.date "DateOfPATHStatus"
    t.integer "ClientEnrolledInPATH"
    t.integer "ReasonNotEnrolled"
    t.integer "WorstHousingSituation"
    t.integer "PercentAMI"
    t.string "LastPermanentStreet"
    t.string "LastPermanentCity", limit: 50
    t.string "LastPermanentState", limit: 2
    t.string "LastPermanentZIP", limit: 10
    t.integer "AddressDataQuality"
    t.date "DateOfBCPStatus"
    t.integer "EligibleForRHY"
    t.integer "ReasonNoServices"
    t.integer "SexualOrientation"
    t.integer "FormerWardChildWelfare"
    t.integer "ChildWelfareYears"
    t.integer "ChildWelfareMonths"
    t.integer "FormerWardJuvenileJustice"
    t.integer "JuvenileJusticeYears"
    t.integer "JuvenileJusticeMonths"
    t.integer "HouseholdDynamics"
    t.integer "SexualOrientationGenderIDYouth"
    t.integer "SexualOrientationGenderIDFam"
    t.integer "HousingIssuesYouth"
    t.integer "HousingIssuesFam"
    t.integer "SchoolEducationalIssuesYouth"
    t.integer "SchoolEducationalIssuesFam"
    t.integer "UnemploymentYouth"
    t.integer "UnemploymentFam"
    t.integer "MentalHealthIssuesYouth"
    t.integer "MentalHealthIssuesFam"
    t.integer "HealthIssuesYouth"
    t.integer "HealthIssuesFam"
    t.integer "PhysicalDisabilityYouth"
    t.integer "PhysicalDisabilityFam"
    t.integer "MentalDisabilityYouth"
    t.integer "MentalDisabilityFam"
    t.integer "AbuseAndNeglectYouth"
    t.integer "AbuseAndNeglectFam"
    t.integer "AlcoholDrugAbuseYouth"
    t.integer "AlcoholDrugAbuseFam"
    t.integer "InsufficientIncome"
    t.integer "ActiveMilitaryParent"
    t.integer "IncarceratedParent"
    t.integer "IncarceratedParentStatus"
    t.integer "ReferralSource"
    t.integer "CountOutreachReferralApproaches"
    t.integer "ExchangeForSex"
    t.integer "ExchangeForSexPastThreeMonths"
    t.integer "CountOfExchangeForSex"
    t.integer "AskedOrForcedToExchangeForSex"
    t.integer "AskedOrForcedToExchangeForSexPastThreeMonths"
    t.integer "WorkPlaceViolenceThreats"
    t.integer "WorkplacePromiseDifference"
    t.integer "CoercedToContinueWork"
    t.integer "LaborExploitPastThreeMonths"
    t.integer "HPScreeningScore"
    t.integer "VAMCStation"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID", limit: 100
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id"
    t.integer "id"
    t.integer "LOSUnderThreshold"
    t.integer "PreviousStreetESSH"
    t.integer "UrgentReferral"
    t.integer "TimeToHousingLoss"
    t.integer "ZeroIncome"
    t.integer "AnnualPercentAMI"
    t.integer "FinancialChange"
    t.integer "HouseholdChange"
    t.integer "EvictionHistory"
    t.integer "SubsidyAtRisk"
    t.integer "LiteralHomelessHistory"
    t.integer "DisabledHoH"
    t.integer "CriminalRecord"
    t.integer "SexOffender"
    t.integer "DependentUnder6"
    t.integer "SingleParent"
    t.integer "HH5Plus"
    t.integer "IraqAfghanistan"
    t.integer "FemVet"
    t.integer "ThresholdScore"
    t.integer "ERVisits"
    t.integer "JailNights"
    t.integer "HospitalNights"
    t.integer "RunawayYouth"
    t.string "processed_hash"
    t.string "processed_as"
    t.boolean "roi_permission"
    t.string "last_locality"
    t.string "last_zipcode"
    t.string "source_hash"
    t.datetime "pending_date_deleted"
    t.string "SexualOrientationOther", limit: 100
    t.integer "demographic_id"
    t.integer "client_id"
    t.index ["EntryDate"], name: "entrydate_ret_index"
    t.index ["client_id"], name: "client_id_ret_index"
    t.index ["id"], name: "id_ret_index", unique: true
  end

  create_table "recent_service_history", id: false, force: :cascade do |t|
    t.integer "id"
    t.integer "client_id"
    t.integer "data_source_id"
    t.date "date"
    t.date "first_date_in_program"
    t.date "last_date_in_program"
    t.string "enrollment_group_id", limit: 50
    t.integer "age", limit: 2
    t.integer "destination"
    t.string "head_of_household_id", limit: 50
    t.string "household_id", limit: 50
    t.integer "project_id"
    t.integer "project_type", limit: 2
    t.integer "project_tracking_method"
    t.integer "organization_id"
    t.integer "housing_status_at_entry"
    t.integer "housing_status_at_exit"
    t.integer "service_type", limit: 2
    t.integer "computed_project_type", limit: 2
    t.boolean "presented_as_individual"
    t.index ["client_id"], name: "client_id_rsh_index"
    t.index ["computed_project_type"], name: "computed_project_type_rsh_index"
    t.index ["date"], name: "date_rsh_index"
    t.index ["household_id"], name: "household_id_rsh_index"
    t.index ["id"], name: "id_rsh_index", unique: true
    t.index ["project_tracking_method"], name: "project_tracking_method_rsh_index"
    t.index ["project_type"], name: "project_type_rsh_index"
  end

  create_table "recurring_hmis_export_links", id: :serial, force: :cascade do |t|
    t.integer "hmis_export_id"
    t.integer "recurring_hmis_export_id"
    t.date "exported_at"
  end

  create_table "recurring_hmis_exports", id: :serial, force: :cascade do |t|
    t.integer "every_n_days"
    t.string "reporting_range"
    t.integer "reporting_range_days"
    t.date "start_date"
    t.date "end_date"
    t.integer "hash_status"
    t.integer "period_type"
    t.integer "directive"
    t.boolean "include_deleted"
    t.integer "user_id"
    t.boolean "faked_pii"
    t.string "project_ids"
    t.string "project_group_ids"
    t.string "organization_ids"
    t.string "data_source_ids"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "s3_region"
    t.string "s3_bucket"
    t.string "s3_prefix"
    t.string "encrypted_s3_access_key_id"
    t.string "encrypted_s3_access_key_id_iv"
    t.string "encrypted_s3_secret"
    t.string "encrypted_s3_secret_iv"
    t.datetime "deleted_at"
    t.index ["encrypted_s3_access_key_id_iv"], name: "index_recurring_hmis_exports_on_encrypted_s3_access_key_id_iv", unique: true
    t.index ["encrypted_s3_secret_iv"], name: "index_recurring_hmis_exports_on_encrypted_s3_secret_iv", unique: true
  end

  create_table "report_definitions", id: :serial, force: :cascade do |t|
    t.string "report_group"
    t.text "url"
    t.text "name"
    t.text "description"
    t.integer "weight", default: 0, null: false
    t.boolean "enabled", default: true, null: false
    t.boolean "limitable", default: true, null: false
  end

  create_table "report_tokens", id: :serial, force: :cascade do |t|
    t.integer "report_id", null: false
    t.integer "contact_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", null: false
    t.datetime "accessed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["contact_id"], name: "index_report_tokens_on_contact_id"
    t.index ["report_id"], name: "index_report_tokens_on_report_id"
  end

  create_table "secure_files", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "file"
    t.string "content_type"
    t.binary "content"
    t.integer "size"
    t.integer "sender_id"
    t.integer "recipient_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "service_history_enrollments", id: :serial, force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "data_source_id"
    t.date "date", null: false
    t.date "first_date_in_program", null: false
    t.date "last_date_in_program"
    t.string "enrollment_group_id", limit: 50
    t.string "project_id", limit: 50
    t.integer "age", limit: 2
    t.integer "destination"
    t.string "head_of_household_id", limit: 50
    t.string "household_id", limit: 50
    t.string "project_name", limit: 150
    t.integer "project_type", limit: 2
    t.integer "project_tracking_method"
    t.string "organization_id", limit: 50
    t.string "record_type", limit: 50, null: false
    t.integer "housing_status_at_entry"
    t.integer "housing_status_at_exit"
    t.integer "service_type", limit: 2
    t.integer "computed_project_type", limit: 2
    t.boolean "presented_as_individual"
    t.integer "other_clients_over_25", limit: 2, default: 0, null: false
    t.integer "other_clients_under_18", limit: 2, default: 0, null: false
    t.integer "other_clients_between_18_and_25", limit: 2, default: 0, null: false
    t.boolean "unaccompanied_youth", default: false, null: false
    t.boolean "parenting_youth", default: false, null: false
    t.boolean "parenting_juvenile", default: false, null: false
    t.boolean "children_only", default: false, null: false
    t.boolean "individual_adult", default: false, null: false
    t.boolean "individual_elder", default: false, null: false
    t.boolean "head_of_household", default: false, null: false
    t.date "move_in_date"
    t.boolean "unaccompanied_minor", default: false
    t.index ["client_id", "record_type"], name: "index_she_on_client_id"
    t.index ["computed_project_type", "record_type", "client_id"], name: "index_she_on_computed_project_type"
    t.index ["data_source_id", "project_id", "organization_id", "record_type"], name: "index_she_ds_proj_org_r_type"
    t.index ["date", "household_id", "record_type"], name: "index_she_on_household_id"
    t.index ["date", "record_type", "presented_as_individual"], name: "index_she_date_r_type_indiv"
    t.index ["enrollment_group_id", "project_tracking_method"], name: "index_she__enrollment_id_track_meth"
    t.index ["first_date_in_program", "last_date_in_program", "record_type", "date"], name: "index_she_on_last_date_in_program"
    t.index ["first_date_in_program"], name: "index_she_on_first_date_in_program", using: :brin
    t.index ["record_type", "date", "data_source_id", "organization_id", "project_id", "project_type", "project_tracking_method"], name: "index_she_date_ds_org_proj_proj_type"
  end

  create_table "service_history_services", id: :serial, force: :cascade do |t|
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
  end

  create_table "service_history_services_2000", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2000_date_client_id"
    t.index ["date"], name: "index_shs_2000_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2000_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2000_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2000_date_en_id"
  end

  create_table "service_history_services_2001", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2001_date_client_id"
    t.index ["date"], name: "index_shs_2001_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2001_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2001_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2001_date_en_id"
  end

  create_table "service_history_services_2002", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2002_date_client_id"
    t.index ["date"], name: "index_shs_2002_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2002_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2002_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2002_date_en_id"
  end

  create_table "service_history_services_2003", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2003_date_client_id"
    t.index ["date"], name: "index_shs_2003_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2003_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2003_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2003_date_en_id"
  end

  create_table "service_history_services_2004", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2004_date_client_id"
    t.index ["date"], name: "index_shs_2004_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2004_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2004_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2004_date_en_id"
  end

  create_table "service_history_services_2005", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2005_date_client_id"
    t.index ["date"], name: "index_shs_2005_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2005_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2005_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2005_date_en_id"
  end

  create_table "service_history_services_2006", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2006_date_client_id"
    t.index ["date"], name: "index_shs_2006_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2006_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2006_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2006_date_en_id"
  end

  create_table "service_history_services_2007", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2007_date_client_id"
    t.index ["date"], name: "index_shs_2007_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2007_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2007_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2007_date_en_id"
  end

  create_table "service_history_services_2008", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2008_date_client_id"
    t.index ["date"], name: "index_shs_2008_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2008_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2008_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2008_date_en_id"
  end

  create_table "service_history_services_2009", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2009_date_client_id"
    t.index ["date"], name: "index_shs_2009_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2009_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2009_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2009_date_en_id"
  end

  create_table "service_history_services_2010", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2010_date_client_id"
    t.index ["date"], name: "index_shs_2010_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2010_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2010_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2010_date_en_id"
  end

  create_table "service_history_services_2011", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2011_date_client_id"
    t.index ["date"], name: "index_shs_2011_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2011_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2011_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2011_date_en_id"
  end

  create_table "service_history_services_2012", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2012_date_client_id"
    t.index ["date"], name: "index_shs_2012_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2012_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2012_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2012_date_en_id"
  end

  create_table "service_history_services_2013", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2013_date_client_id"
    t.index ["date"], name: "index_shs_2013_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2013_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2013_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2013_date_en_id"
  end

  create_table "service_history_services_2014", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2014_date_client_id"
    t.index ["date"], name: "index_shs_2014_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2014_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2014_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2014_date_en_id"
  end

  create_table "service_history_services_2015", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2015_date_client_id"
    t.index ["date"], name: "index_shs_2015_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2015_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2015_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2015_date_en_id"
  end

  create_table "service_history_services_2016", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2016_date_client_id"
    t.index ["date"], name: "index_shs_2016_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2016_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2016_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2016_date_en_id"
  end

  create_table "service_history_services_2017", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2017_date_client_id"
    t.index ["date"], name: "index_shs_2017_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2017_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2017_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2017_date_en_id"
  end

  create_table "service_history_services_2018", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2018_date_client_id"
    t.index ["date"], name: "index_shs_2018_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2018_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2018_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2018_date_en_id"
  end

  create_table "service_history_services_2019", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2019_date_client_id"
    t.index ["date"], name: "index_shs_2019_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2019_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2019_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2019_date_en_id"
  end

  create_table "service_history_services_2020", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2020_date_client_id"
    t.index ["date"], name: "index_shs_2020_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2020_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2020_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2020_date_en_id"
  end

  create_table "service_history_services_2021", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2021_date_client_id"
    t.index ["date"], name: "index_shs_2021_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2021_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2021_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2021_date_en_id"
  end

  create_table "service_history_services_2022", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2022_date_client_id"
    t.index ["date"], name: "index_shs_2022_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2022_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2022_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2022_date_en_id"
  end

  create_table "service_history_services_2023", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2023_date_client_id"
    t.index ["date"], name: "index_shs_2023_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2023_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2023_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2023_date_en_id"
  end

  create_table "service_history_services_2024", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2024_date_client_id"
    t.index ["date"], name: "index_shs_2024_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2024_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2024_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2024_date_en_id"
  end

  create_table "service_history_services_2025", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2025_date_client_id"
    t.index ["date"], name: "index_shs_2025_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2025_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2025_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2025_date_en_id"
  end

  create_table "service_history_services_2026", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2026_date_client_id"
    t.index ["date"], name: "index_shs_2026_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2026_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2026_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2026_date_en_id"
  end

  create_table "service_history_services_2027", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2027_date_client_id"
    t.index ["date"], name: "index_shs_2027_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2027_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2027_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2027_date_en_id"
  end

  create_table "service_history_services_2028", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2028_date_client_id"
    t.index ["date"], name: "index_shs_2028_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2028_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2028_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2028_date_en_id"
  end

  create_table "service_history_services_2029", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2029_date_client_id"
    t.index ["date"], name: "index_shs_2029_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2029_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2029_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2029_date_en_id"
  end

  create_table "service_history_services_2030", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2030_date_client_id"
    t.index ["date"], name: "index_shs_2030_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2030_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2030_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2030_date_en_id"
  end

  create_table "service_history_services_2031", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2031_date_client_id"
    t.index ["date"], name: "index_shs_2031_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2031_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2031_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2031_date_en_id"
  end

  create_table "service_history_services_2032", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2032_date_client_id"
    t.index ["date"], name: "index_shs_2032_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2032_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2032_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2032_date_en_id"
  end

  create_table "service_history_services_2033", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2033_date_client_id"
    t.index ["date"], name: "index_shs_2033_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2033_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2033_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2033_date_en_id"
  end

  create_table "service_history_services_2034", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2034_date_client_id"
    t.index ["date"], name: "index_shs_2034_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2034_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2034_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2034_date_en_id"
  end

  create_table "service_history_services_2035", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2035_date_client_id"
    t.index ["date"], name: "index_shs_2035_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2035_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2035_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2035_date_en_id"
  end

  create_table "service_history_services_2036", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2036_date_client_id"
    t.index ["date"], name: "index_shs_2036_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2036_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2036_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2036_date_en_id"
  end

  create_table "service_history_services_2037", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2037_date_client_id"
    t.index ["date"], name: "index_shs_2037_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2037_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2037_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2037_date_en_id"
  end

  create_table "service_history_services_2038", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2038_date_client_id"
    t.index ["date"], name: "index_shs_2038_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2038_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2038_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2038_date_en_id"
  end

  create_table "service_history_services_2039", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2039_date_client_id"
    t.index ["date"], name: "index_shs_2039_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2039_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2039_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2039_date_en_id"
  end

  create_table "service_history_services_2040", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2040_date_client_id"
    t.index ["date"], name: "index_shs_2040_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2040_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2040_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2040_date_en_id"
  end

  create_table "service_history_services_2041", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2041_date_client_id"
    t.index ["date"], name: "index_shs_2041_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2041_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2041_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2041_date_en_id"
  end

  create_table "service_history_services_2042", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2042_date_client_id"
    t.index ["date"], name: "index_shs_2042_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2042_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2042_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2042_date_en_id"
  end

  create_table "service_history_services_2043", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2043_date_client_id"
    t.index ["date"], name: "index_shs_2043_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2043_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2043_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2043_date_en_id"
  end

  create_table "service_history_services_2044", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2044_date_client_id"
    t.index ["date"], name: "index_shs_2044_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2044_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2044_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2044_date_en_id"
  end

  create_table "service_history_services_2045", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2045_date_client_id"
    t.index ["date"], name: "index_shs_2045_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2045_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2045_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2045_date_en_id"
  end

  create_table "service_history_services_2046", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2046_date_client_id"
    t.index ["date"], name: "index_shs_2046_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2046_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2046_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2046_date_en_id"
  end

  create_table "service_history_services_2047", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2047_date_client_id"
    t.index ["date"], name: "index_shs_2047_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2047_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2047_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2047_date_en_id"
  end

  create_table "service_history_services_2048", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2048_date_client_id"
    t.index ["date"], name: "index_shs_2048_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2048_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2048_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2048_date_en_id"
  end

  create_table "service_history_services_2049", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2049_date_client_id"
    t.index ["date"], name: "index_shs_2049_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2049_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2049_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2049_date_en_id"
  end

  create_table "service_history_services_2050", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["client_id", "date", "record_type"], name: "index_shs_2050_date_client_id"
    t.index ["date"], name: "index_shs_2050_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2050_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2050_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2050_date_en_id"
  end

  create_table "service_history_services_remainder", id: false, force: :cascade do |t|
    t.integer "id", default: -> { "nextval('service_history_services_id_seq'::regclass)" }, null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["date", "client_id"], name: "index_shs_1900_date_client_id"
    t.index ["date", "project_type"], name: "index_shs_1900_date_project_type"
    t.index ["date", "service_history_enrollment_id"], name: "index_shs_1900_date_en_id"
    t.index ["date"], name: "index_shs_1900_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_remainder_on_id", unique: true
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.integer "tagger_id"
    t.string "tagger_type"
    t.string "context", limit: 128
    t.datetime "created_at"
    t.index ["context"], name: "index_taggings_on_context"
    t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
    t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
    t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
    t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
    t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
    t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "taggings_count", default: 0
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "uploads", id: :serial, force: :cascade do |t|
    t.integer "data_source_id"
    t.integer "user_id"
    t.string "file", null: false
    t.float "percent_complete"
    t.string "unzipped_path"
    t.json "unzipped_files"
    t.json "summary"
    t.json "import_errors"
    t.string "content_type"
    t.binary "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "deleted_at"
    t.integer "delayed_job_id"
    t.boolean "deidentified", default: false
    t.boolean "project_whitelist", default: false
    t.index ["deleted_at"], name: "index_uploads_on_deleted_at"
  end

  create_table "user_clients", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "client_id", null: false
    t.boolean "confidential", default: false, null: false
    t.string "relationship"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.date "start_date"
    t.date "end_date"
    t.boolean "client_notifications", default: false
    t.index ["client_id"], name: "index_user_clients_on_client_id"
    t.index ["user_id"], name: "index_user_clients_on_user_id"
  end

  create_table "user_viewable_entities", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "entity_id", null: false
    t.string "entity_type", null: false
    t.datetime "deleted_at"
    t.index ["user_id", "entity_id", "entity_type", "deleted_at"], name: "one_entity_per_type_per_user_allows_delete", unique: true
  end

  create_table "verification_sources", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.string "location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "verified_at"
    t.string "type"
  end

  create_table "vispdats", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.string "nickname"
    t.integer "language_answer"
    t.boolean "hiv_release"
    t.integer "sleep_answer"
    t.string "sleep_answer_other"
    t.integer "homeless"
    t.boolean "homeless_refused"
    t.integer "episodes_homeless"
    t.boolean "episodes_homeless_refused"
    t.integer "emergency_healthcare"
    t.boolean "emergency_healthcare_refused"
    t.integer "ambulance"
    t.boolean "ambulance_refused"
    t.integer "inpatient"
    t.boolean "inpatient_refused"
    t.integer "crisis_service"
    t.boolean "crisis_service_refused"
    t.integer "talked_to_police"
    t.boolean "talked_to_police_refused"
    t.integer "jail"
    t.boolean "jail_refused"
    t.integer "attacked_answer"
    t.integer "threatened_answer"
    t.integer "legal_answer"
    t.integer "tricked_answer"
    t.integer "risky_answer"
    t.integer "owe_money_answer"
    t.integer "get_money_answer"
    t.integer "activities_answer"
    t.integer "basic_needs_answer"
    t.integer "abusive_answer"
    t.integer "leave_answer"
    t.integer "chronic_answer"
    t.integer "hiv_answer"
    t.integer "disability_answer"
    t.integer "avoid_help_answer"
    t.integer "pregnant_answer"
    t.integer "eviction_answer"
    t.integer "drinking_answer"
    t.integer "mental_answer"
    t.integer "head_answer"
    t.integer "learning_answer"
    t.integer "brain_answer"
    t.integer "medication_answer"
    t.integer "sell_answer"
    t.integer "trauma_answer"
    t.string "find_location"
    t.string "find_time"
    t.integer "when_answer"
    t.string "phone"
    t.string "email"
    t.integer "picture_answer"
    t.integer "score"
    t.string "recommendation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "submitted_at"
    t.integer "homeless_period"
    t.date "release_signed_on"
    t.boolean "drug_release"
    t.string "migrated_case_manager"
    t.string "migrated_interviewer_name"
    t.string "migrated_interviewer_email"
    t.string "migrated_filed_by"
    t.boolean "migrated", default: false, null: false
    t.boolean "housing_release_confirmed", default: false
    t.integer "user_id"
    t.integer "priority_score"
    t.boolean "active", default: false
    t.string "type", default: "GrdaWarehouse::Vispdat::Individual"
    t.integer "marijuana_answer"
    t.integer "incarcerated_before_18_answer"
    t.integer "homeless_due_to_ran_away_answer"
    t.integer "homeless_due_to_religions_beliefs_answer"
    t.integer "homeless_due_to_family_answer"
    t.integer "homeless_due_to_gender_identity_answer"
    t.integer "violence_between_family_members_answer"
    t.boolean "parent2_none", default: false
    t.string "parent2_first_name"
    t.string "parent2_nickname"
    t.string "parent2_last_name"
    t.string "parent2_language_answer"
    t.date "parent2_dob"
    t.string "parent2_ssn"
    t.date "parent2_release_signed_on"
    t.boolean "parent2_drug_release", default: false
    t.boolean "parent2_hiv_release", default: false
    t.integer "number_of_children_under_18_with_family"
    t.boolean "number_of_children_under_18_with_family_refused", default: false
    t.integer "number_of_children_under_18_not_with_family"
    t.boolean "number_of_children_under_18_not_with_family_refused", default: false
    t.integer "any_member_pregnant_answer"
    t.integer "family_member_tri_morbidity_answer"
    t.integer "any_children_removed_answer"
    t.integer "any_family_legal_issues_answer"
    t.integer "any_children_lived_with_family_answer"
    t.integer "any_child_abuse_answer"
    t.integer "children_attend_school_answer"
    t.integer "family_members_changed_answer"
    t.integer "other_family_members_answer"
    t.integer "planned_family_activities_answer"
    t.integer "time_spent_alone_13_answer"
    t.integer "time_spent_alone_12_answer"
    t.integer "time_spent_helping_siblings_answer"
    t.integer "number_of_bedrooms", default: 0
    t.index ["client_id"], name: "index_vispdats_on_client_id"
    t.index ["user_id"], name: "index_vispdats_on_user_id"
  end

  create_table "warehouse_client_service_history", id: :serial, force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "data_source_id"
    t.date "date", null: false
    t.date "first_date_in_program", null: false
    t.date "last_date_in_program"
    t.string "enrollment_group_id", limit: 50
    t.integer "age"
    t.integer "destination"
    t.string "head_of_household_id", limit: 50
    t.string "household_id", limit: 50
    t.string "project_id", limit: 50
    t.string "project_name", limit: 150
    t.integer "project_type"
    t.integer "project_tracking_method"
    t.string "organization_id", limit: 50
    t.string "record_type", limit: 50, null: false
    t.integer "housing_status_at_entry"
    t.integer "housing_status_at_exit"
    t.integer "service_type"
    t.integer "computed_project_type"
    t.boolean "presented_as_individual"
    t.integer "other_clients_over_25", default: 0, null: false
    t.integer "other_clients_under_18", default: 0, null: false
    t.integer "other_clients_between_18_and_25", default: 0, null: false
    t.boolean "unaccompanied_youth", default: false, null: false
    t.boolean "parenting_youth", default: false, null: false
    t.boolean "parenting_juvenile", default: false, null: false
    t.boolean "children_only", default: false, null: false
    t.boolean "individual_adult", default: false, null: false
    t.boolean "individual_elder", default: false, null: false
    t.boolean "head_of_household", default: false, null: false
    t.index ["client_id"], name: "index_service_history_on_client_id"
    t.index ["computed_project_type"], name: "index_warehouse_client_service_history_on_computed_project_type"
    t.index ["data_source_id", "organization_id", "project_id", "record_type"], name: "index_sh_ds_id_org_id_proj_id_r_type"
    t.index ["data_source_id"], name: "index_warehouse_client_service_history_on_data_source_id"
    t.index ["date", "data_source_id", "organization_id", "project_id", "project_type"], name: "sh_date_ds_id_org_id_proj_id_proj_type"
    t.index ["date", "record_type", "presented_as_individual"], name: "index_sh_date_r_type_indiv"
    t.index ["enrollment_group_id"], name: "index_warehouse_client_service_history_on_enrollment_group_id"
    t.index ["first_date_in_program"], name: "index_warehouse_client_service_history_on_first_date_in_program"
    t.index ["household_id"], name: "index_warehouse_client_service_history_on_household_id"
    t.index ["last_date_in_program"], name: "index_warehouse_client_service_history_on_last_date_in_program"
    t.index ["project_tracking_method"], name: "index_sh_tracking_method"
    t.index ["project_type"], name: "index_warehouse_client_service_history_on_project_type"
    t.index ["record_type"], name: "index_warehouse_client_service_history_on_record_type"
  end

  create_table "warehouse_clients", id: :serial, force: :cascade do |t|
    t.string "id_in_source", null: false
    t.integer "data_source_id"
    t.datetime "proposed_at"
    t.datetime "reviewed_at"
    t.string "reviewd_by"
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.integer "source_id"
    t.integer "destination_id"
    t.integer "client_match_id"
    t.index ["deleted_at"], name: "index_warehouse_clients_on_deleted_at"
    t.index ["destination_id"], name: "index_warehouse_clients_on_destination_id"
    t.index ["id_in_source"], name: "index_warehouse_clients_on_id_in_source"
    t.index ["source_id"], name: "index_warehouse_clients_on_source_id", unique: true
  end

  create_table "warehouse_clients_processed", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.string "routine"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "last_service_updated_at"
    t.integer "days_served"
    t.date "first_date_served"
    t.date "last_date_served"
    t.date "first_homeless_date"
    t.date "last_homeless_date"
    t.integer "homeless_days"
    t.date "first_chronic_date"
    t.date "last_chronic_date"
    t.integer "chronic_days"
    t.integer "days_homeless_last_three_years"
    t.integer "literally_homeless_last_three_years"
    t.boolean "enrolled_homeless_shelter"
    t.boolean "enrolled_homeless_unsheltered"
    t.boolean "enrolled_permanent_housing"
    t.integer "eto_coordinated_entry_assessment_score"
    t.string "household_members"
    t.string "last_homeless_visit"
    t.jsonb "open_enrollments"
    t.boolean "rrh_desired"
    t.integer "vispdat_priority_score"
    t.integer "vispdat_score"
    t.boolean "active_in_cas_match", default: false
    t.string "last_exit_destination"
    t.datetime "last_cas_match_date"
    t.string "lgbtq_from_hmis"
    t.integer "days_homeless_plus_overrides"
    t.index ["chronic_days"], name: "index_warehouse_clients_processed_on_chronic_days"
    t.index ["days_served"], name: "index_warehouse_clients_processed_on_days_served"
    t.index ["homeless_days"], name: "index_warehouse_clients_processed_on_homeless_days"
    t.index ["routine"], name: "index_warehouse_clients_processed_on_routine"
  end

  create_table "warehouse_reports", id: :serial, force: :cascade do |t|
    t.json "parameters"
    t.json "data"
    t.string "type"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "client_count"
    t.json "support"
    t.string "token"
    t.integer "user_id"
  end

  create_table "weather", id: :serial, force: :cascade do |t|
    t.string "url", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url"], name: "index_weather_on_url"
  end

  create_table "whitelisted_projects_for_clients", id: :serial, force: :cascade do |t|
    t.integer "data_source_id", null: false
    t.string "ProjectID", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "youth_case_managements", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.integer "user_id"
    t.date "engaged_on"
    t.text "activity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "housing_status"
    t.string "other_housing_status"
    t.index ["deleted_at"], name: "index_youth_case_managements_on_deleted_at"
  end

  create_table "youth_exports", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.jsonb "options"
    t.jsonb "headers"
    t.jsonb "rows"
    t.integer "client_count"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_youth_exports_on_created_at"
    t.index ["updated_at"], name: "index_youth_exports_on_updated_at"
    t.index ["user_id"], name: "index_youth_exports_on_user_id"
  end

  create_table "youth_follow_ups", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.integer "user_id"
    t.date "contacted_on"
    t.string "housing_status"
    t.string "zip_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_youth_follow_ups_on_deleted_at"
  end

  create_table "youth_intakes", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.integer "user_id"
    t.string "type"
    t.boolean "other_staff_completed_intake", default: false, null: false
    t.date "client_dob"
    t.string "staff_name"
    t.string "staff_email"
    t.date "engagement_date", null: false
    t.date "exit_date"
    t.string "unaccompanied", null: false
    t.string "street_outreach_contact", null: false
    t.string "housing_status", null: false
    t.string "other_agency_involvement", null: false
    t.string "owns_cell_phone", null: false
    t.string "secondary_education", null: false
    t.string "attending_college", null: false
    t.string "health_insurance", null: false
    t.string "requesting_financial_assistance", null: false
    t.string "staff_believes_youth_under_24", null: false
    t.integer "client_gender", null: false
    t.string "client_lgbtq", null: false
    t.jsonb "client_race", null: false
    t.integer "client_ethnicity", null: false
    t.string "client_primary_language", null: false
    t.string "pregnant_or_parenting", null: false
    t.jsonb "disabilities", null: false
    t.string "how_hear"
    t.string "needs_shelter", null: false
    t.string "referred_to_shelter", default: "f", null: false
    t.string "in_stable_housing", null: false
    t.string "stable_housing_zipcode"
    t.string "youth_experiencing_homelessness_at_start"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "turned_away", default: false, null: false
    t.string "college_pilot", default: "No", null: false
    t.string "graduating_college", default: "No", null: false
    t.index ["created_at"], name: "index_youth_intakes_on_created_at"
    t.index ["deleted_at"], name: "index_youth_intakes_on_deleted_at"
    t.index ["updated_at"], name: "index_youth_intakes_on_updated_at"
  end

  create_table "youth_referrals", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.integer "user_id"
    t.date "referred_on"
    t.string "referred_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_youth_referrals_on_deleted_at"
  end

  add_foreign_key "Affiliation", "data_sources"
  add_foreign_key "Client", "data_sources"
  add_foreign_key "Disabilities", "data_sources"
  add_foreign_key "EmploymentEducation", "data_sources"
  add_foreign_key "Enrollment", "data_sources"
  add_foreign_key "EnrollmentCoC", "data_sources"
  add_foreign_key "Exit", "data_sources"
  add_foreign_key "Funder", "data_sources"
  add_foreign_key "Geography", "data_sources"
  add_foreign_key "HealthAndDV", "data_sources"
  add_foreign_key "IncomeBenefits", "data_sources"
  add_foreign_key "Inventory", "data_sources"
  add_foreign_key "Organization", "data_sources"
  add_foreign_key "Project", "data_sources"
  add_foreign_key "ProjectCoC", "data_sources"
  add_foreign_key "Services", "data_sources"
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

  create_view "Site", sql_definition: <<-SQL
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
     FROM "Geography";
  SQL
  create_view "combined_cohort_client_changes", sql_definition: <<-SQL
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
             FROM cohort_client_changes
            WHERE ((cohort_client_changes.change)::text = ANY (ARRAY[('create'::character varying)::text, ('activate'::character varying)::text]))) cc
       LEFT JOIN LATERAL ( SELECT cohort_client_changes.id,
              cohort_client_changes.cohort_client_id,
              cohort_client_changes.cohort_id,
              cohort_client_changes.user_id,
              cohort_client_changes.change,
              cohort_client_changes.changed_at,
              cohort_client_changes.reason
             FROM cohort_client_changes
            WHERE (((cohort_client_changes.change)::text = ANY (ARRAY[('destroy'::character varying)::text, ('deactivate'::character varying)::text])) AND (cc.cohort_client_id = cohort_client_changes.cohort_client_id) AND (cc.cohort_id = cohort_client_changes.cohort_id) AND (cc.changed_at < cohort_client_changes.changed_at))
            ORDER BY cohort_client_changes.changed_at
           LIMIT 1) cc_ex ON (true))
       JOIN cohort_clients ON ((cc.cohort_client_id = cohort_clients.id)))
       JOIN "Client" ON (((cohort_clients.client_id = "Client".id) AND ("Client"."DateDeleted" IS NULL))))
    WHERE ((cc_ex.reason IS NULL) OR ((cc_ex.reason)::text <> 'Mistake'::text))
    ORDER BY cc.id;
  SQL
  create_view "index_stats", sql_definition: <<-SQL
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
  SQL
  create_view "report_clients", sql_definition: <<-SQL
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
  create_view "report_demographics", sql_definition: <<-SQL
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
  create_view "report_disabilities", sql_definition: <<-SQL
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
     FROM (((("Disabilities"
       JOIN "Client" source_clients ON ((("Disabilities".data_source_id = source_clients.data_source_id) AND (("Disabilities"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("Disabilities".data_source_id = "Enrollment".data_source_id) AND (("Disabilities"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("Disabilities"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("Disabilities"."DateDeleted" IS NULL);
  SQL
  create_view "report_employment_educations", sql_definition: <<-SQL
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
     FROM (((("EmploymentEducation"
       JOIN "Client" source_clients ON ((("EmploymentEducation".data_source_id = source_clients.data_source_id) AND (("EmploymentEducation"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("EmploymentEducation".data_source_id = "Enrollment".data_source_id) AND (("EmploymentEducation"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("EmploymentEducation"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("EmploymentEducation"."DateDeleted" IS NULL);
  SQL
  create_view "report_enrollments", sql_definition: <<-SQL
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
     FROM ((("Enrollment"
       JOIN "Client" source_clients ON ((("Enrollment".data_source_id = source_clients.data_source_id) AND (("Enrollment"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
    WHERE ("Enrollment"."DateDeleted" IS NULL);
  SQL
  create_view "report_exits", sql_definition: <<-SQL
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
     FROM (((("Exit"
       JOIN "Client" source_clients ON ((("Exit".data_source_id = source_clients.data_source_id) AND (("Exit"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("Exit".data_source_id = "Enrollment".data_source_id) AND (("Exit"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("Exit"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("Exit"."DateDeleted" IS NULL);
  SQL
  create_view "report_health_and_dvs", sql_definition: <<-SQL
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
     FROM (((("HealthAndDV"
       JOIN "Client" source_clients ON ((("HealthAndDV".data_source_id = source_clients.data_source_id) AND (("HealthAndDV"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("HealthAndDV".data_source_id = "Enrollment".data_source_id) AND (("HealthAndDV"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("HealthAndDV"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("HealthAndDV"."DateDeleted" IS NULL);
  SQL
  create_view "report_income_benefits", sql_definition: <<-SQL
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
     FROM (((("IncomeBenefits"
       JOIN "Client" source_clients ON ((("IncomeBenefits".data_source_id = source_clients.data_source_id) AND (("IncomeBenefits"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("IncomeBenefits".data_source_id = "Enrollment".data_source_id) AND (("IncomeBenefits"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("IncomeBenefits"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("IncomeBenefits"."DateDeleted" IS NULL);
  SQL
  create_view "report_services", sql_definition: <<-SQL
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
     FROM (((("Services"
       JOIN "Client" source_clients ON ((("Services".data_source_id = source_clients.data_source_id) AND (("Services"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("Services".data_source_id = "Enrollment".data_source_id) AND (("Services"."PersonalID")::text = ("Enrollment"."PersonalID")::text) AND (("Services"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
    WHERE ("Services"."DateDeleted" IS NULL);
  SQL
  create_view "service_history", sql_definition: <<-SQL
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
  create_view "todd_stats", sql_definition: <<-SQL
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
  SQL
  create_view "service_history_services_materialized", materialized: true, sql_definition: <<-SQL
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
     FROM service_history_services;
  SQL
  add_index "service_history_services_materialized", ["client_id", "date"], name: "index_shsm_c_id_date"
  add_index "service_history_services_materialized", ["client_id", "project_type", "record_type"], name: "index_shsm_c_id_p_type_r_type"
  add_index "service_history_services_materialized", ["homeless", "project_type", "client_id"], name: "index_shsm_homeless_p_type_c_id"
  add_index "service_history_services_materialized", ["id"], name: "index_service_history_services_materialized_on_id", unique: true
  add_index "service_history_services_materialized", ["literally_homeless", "project_type", "client_id"], name: "index_shsm_literally_homeless_p_type_c_id"
  add_index "service_history_services_materialized", ["service_history_enrollment_id"], name: "index_shsm_shse_id"

end
