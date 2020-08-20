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

ActiveRecord::Schema.define(version: 2020_08_14_173200) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "hstore"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "postgis"

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
    t.string "SSN"
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
    t.boolean "income_maximization_assistance_requested", default: false, null: false
    t.integer "income_total_monthly"
    t.boolean "pending_subsidized_housing_placement", default: false, null: false
    t.boolean "pathways_domestic_violence", default: false, null: false
    t.boolean "rrh_th_desired", default: false, null: false
    t.boolean "sro_ok", default: false, null: false
    t.boolean "pathways_other_accessibility", default: false, null: false
    t.boolean "pathways_disabled_housing", default: false, null: false
    t.boolean "evicted", default: false, null: false
    t.boolean "dv_rrh_desired", default: false
    t.string "health_prioritized"
    t.boolean "demographic_dirty", default: true
    t.string "encrypted_FirstName"
    t.string "encrypted_FirstName_iv"
    t.string "encrypted_MiddleName"
    t.string "encrypted_MiddleName_iv"
    t.string "encrypted_LastName"
    t.string "encrypted_LastName_iv"
    t.string "encrypted_SSN"
    t.string "encrypted_SSN_iv"
    t.string "encrypted_NameSuffix"
    t.string "encrypted_NameSuffix_iv"
    t.string "soundex_first"
    t.string "soundex_last"
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

  create_table "ClientUnencrypted", id: :integer, default: -> { "nextval('\"Client_id_seq\"'::regclass)" }, force: :cascade do |t|
    t.string "PersonalID"
    t.string "FirstName", limit: 150
    t.string "MiddleName", limit: 150
    t.string "LastName", limit: 150
    t.string "NameSuffix", limit: 50
    t.integer "NameDataQuality"
    t.string "SSN"
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
    t.boolean "income_maximization_assistance_requested", default: false, null: false
    t.integer "income_total_monthly"
    t.boolean "pending_subsidized_housing_placement", default: false, null: false
    t.boolean "pathways_domestic_violence", default: false, null: false
    t.boolean "rrh_th_desired", default: false, null: false
    t.boolean "sro_ok", default: false, null: false
    t.boolean "pathways_other_accessibility", default: false, null: false
    t.boolean "pathways_disabled_housing", default: false, null: false
    t.boolean "evicted", default: false, null: false
    t.boolean "dv_rrh_desired", default: false
    t.string "health_prioritized"
    t.boolean "demographic_dirty", default: true
    t.string "encrypted_FirstName"
    t.string "encrypted_FirstName_iv"
    t.string "encrypted_MiddleName"
    t.string "encrypted_MiddleName_iv"
    t.string "encrypted_LastName"
    t.string "encrypted_LastName_iv"
    t.string "encrypted_SSN"
    t.string "encrypted_SSN_iv"
    t.string "encrypted_NameSuffix"
    t.string "encrypted_NameSuffix_iv"
    t.string "soundex_first"
    t.string "soundex_last"
    t.index ["DateCreated"], name: "ClientUnencrypted_DateCreated_idx"
    t.index ["DateDeleted", "data_source_id"], name: "ClientUnencrypted_DateDeleted_data_source_id_idx"
    t.index ["DateUpdated"], name: "ClientUnencrypted_DateUpdated_idx"
    t.index ["ExportID"], name: "ClientUnencrypted_ExportID_idx"
    t.index ["FirstName"], name: "ClientUnencrypted_FirstName_idx"
    t.index ["LastName"], name: "ClientUnencrypted_LastName_idx"
    t.index ["PersonalID"], name: "ClientUnencrypted_PersonalID_idx"
    t.index ["creator_id"], name: "ClientUnencrypted_creator_id_idx"
    t.index ["data_source_id"], name: "ClientUnencrypted_data_source_id_idx"
    t.index ["pending_date_deleted"], name: "ClientUnencrypted_pending_date_deleted_idx"
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
    t.index ["ProjectID", "Funder"], name: "index_Funder_on_ProjectID_and_Funder"
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
    t.string "coc_code_override"
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
    t.boolean "extrapolate_contacts", default: false, null: false
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
    t.string "zip_override"
    t.index ["DateCreated"], name: "project_coc_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_ProjectCoC_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "project_coc_date_updated"
    t.index ["ExportID"], name: "project_coc_export_id"
    t.index ["data_source_id", "ProjectCoCID"], name: "unk_ProjectCoC", unique: true
    t.index ["data_source_id", "ProjectID", "CoCCode"], name: "index_ProjectCoC_on_data_source_id_and_ProjectID_and_CoCCode"
    t.index ["data_source_id"], name: "index_ProjectCoC_on_data_source_id"
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
    t.boolean "ineligible_in_warehouse", default: false, null: false
    t.string "actor_type"
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
    t.integer "vulnerability_score"
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
    t.boolean "alert_active", default: true, null: false
    t.bigint "service_id"
    t.bigint "project_id"
    t.index ["client_id"], name: "index_client_notes_on_client_id"
    t.index ["project_id"], name: "index_client_notes_on_project_id"
    t.index ["service_id"], name: "index_client_notes_on_service_id"
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

  create_table "coc_codes", force: :cascade do |t|
    t.string "coc_code", null: false
    t.string "official_name", null: false
    t.string "preferred_name"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coc_code"], name: "index_coc_codes_on_coc_code"
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
    t.integer "threshold_row_1"
    t.string "threshold_color_1"
    t.string "threshold_label_1"
    t.integer "threshold_row_2"
    t.string "threshold_color_2"
    t.string "threshold_label_2"
    t.integer "threshold_row_3"
    t.string "threshold_color_3"
    t.string "threshold_label_3"
    t.integer "threshold_row_4"
    t.string "threshold_color_4"
    t.string "threshold_label_4"
    t.integer "threshold_row_5"
    t.string "threshold_color_5"
    t.string "threshold_label_5"
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
    t.boolean "expose_coc_code", default: false, null: false
    t.boolean "auto_confirm_consent", default: false, null: false
    t.string "health_emergency"
    t.string "health_emergency_tracing"
    t.integer "health_priority_age"
    t.boolean "multi_coc_installation", default: false, null: false
    t.float "auto_de_duplication_accept_threshold"
    t.float "auto_de_duplication_reject_threshold"
    t.string "pii_encryption_type", default: "none"
    t.boolean "auto_de_duplication_enabled", default: false, null: false
    t.boolean "request_account_available", default: false, null: false
    t.date "dashboard_lookback", default: "2014-07-01"
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
    t.datetime "deleted_at"
    t.boolean "service_scannable", default: false, null: false
  end

  create_table "direct_financial_assistances", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.integer "user_id"
    t.date "provided_on"
    t.string "type_provided"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "imported", default: false
    t.integer "amount"
    t.index ["deleted_at"], name: "index_direct_financial_assistances_on_deleted_at"
  end

  create_table "document_exports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type", null: false
    t.bigint "user_id", null: false
    t.string "version", null: false
    t.string "status", null: false
    t.string "query_string"
    t.binary "file_data"
    t.string "filename"
    t.string "mime_type"
    t.index ["type"], name: "index_document_exports_on_type"
    t.index ["user_id"], name: "index_document_exports_on_user_id"
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
    t.string "identifier"
    t.string "email"
    t.string "encrypted_password"
    t.string "encrypted_password_iv"
    t.string "enterprise"
    t.string "hud_touch_point_id"
    t.boolean "active", default: false
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

  create_table "exports_ad_hoc_anons", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "options"
    t.jsonb "headers"
    t.jsonb "rows"
    t.integer "client_count"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_exports_ad_hoc_anons_on_created_at"
    t.index ["updated_at"], name: "index_exports_ad_hoc_anons_on_updated_at"
    t.index ["user_id"], name: "index_exports_ad_hoc_anons_on_user_id"
  end

  create_table "exports_ad_hocs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "options"
    t.jsonb "headers"
    t.jsonb "rows"
    t.integer "client_count"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_exports_ad_hocs_on_created_at"
    t.index ["updated_at"], name: "index_exports_ad_hocs_on_updated_at"
    t.index ["user_id"], name: "index_exports_ad_hocs_on_user_id"
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

  create_table "health_emergency_ama_restrictions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "client_id", null: false
    t.integer "agency_id"
    t.string "restricted"
    t.string "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.text "notes"
    t.string "emergency_type"
    t.datetime "notification_at"
    t.integer "notification_batch_id"
    t.index ["agency_id"], name: "index_health_emergency_ama_restrictions_on_agency_id"
    t.index ["client_id"], name: "index_health_emergency_ama_restrictions_on_client_id"
    t.index ["created_at"], name: "index_health_emergency_ama_restrictions_on_created_at"
    t.index ["updated_at"], name: "index_health_emergency_ama_restrictions_on_updated_at"
    t.index ["user_id"], name: "index_health_emergency_ama_restrictions_on_user_id"
  end

  create_table "health_emergency_clinical_triages", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "client_id", null: false
    t.integer "agency_id"
    t.string "test_requested"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.text "notes"
    t.string "emergency_type"
    t.index ["agency_id"], name: "index_health_emergency_clinical_triages_on_agency_id"
    t.index ["client_id"], name: "index_health_emergency_clinical_triages_on_client_id"
    t.index ["created_at"], name: "index_health_emergency_clinical_triages_on_created_at"
    t.index ["updated_at"], name: "index_health_emergency_clinical_triages_on_updated_at"
    t.index ["user_id"], name: "index_health_emergency_clinical_triages_on_user_id"
  end

  create_table "health_emergency_isolations", force: :cascade do |t|
    t.string "type", null: false
    t.integer "user_id", null: false
    t.integer "client_id", null: false
    t.integer "agency_id"
    t.datetime "isolation_requested_at"
    t.string "location"
    t.date "started_on"
    t.date "scheduled_to_end_on"
    t.date "ended_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.text "notes"
    t.string "emergency_type"
    t.index ["agency_id"], name: "index_health_emergency_isolations_on_agency_id"
    t.index ["client_id"], name: "index_health_emergency_isolations_on_client_id"
    t.index ["created_at"], name: "index_health_emergency_isolations_on_created_at"
    t.index ["location"], name: "index_health_emergency_isolations_on_location"
    t.index ["updated_at"], name: "index_health_emergency_isolations_on_updated_at"
    t.index ["user_id"], name: "index_health_emergency_isolations_on_user_id"
  end

  create_table "health_emergency_test_batches", force: :cascade do |t|
    t.bigint "user_id"
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
    t.index ["created_at"], name: "index_health_emergency_test_batches_on_created_at"
    t.index ["deleted_at"], name: "index_health_emergency_test_batches_on_deleted_at"
    t.index ["updated_at"], name: "index_health_emergency_test_batches_on_updated_at"
    t.index ["user_id"], name: "index_health_emergency_test_batches_on_user_id"
  end

  create_table "health_emergency_tests", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "client_id", null: false
    t.integer "agency_id"
    t.string "test_requested"
    t.string "location"
    t.date "tested_on"
    t.string "result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.text "notes"
    t.string "emergency_type"
    t.datetime "notification_at"
    t.integer "notification_batch_id"
    t.index ["agency_id"], name: "index_health_emergency_tests_on_agency_id"
    t.index ["client_id"], name: "index_health_emergency_tests_on_client_id"
    t.index ["created_at"], name: "index_health_emergency_tests_on_created_at"
    t.index ["updated_at"], name: "index_health_emergency_tests_on_updated_at"
    t.index ["user_id"], name: "index_health_emergency_tests_on_user_id"
  end

  create_table "health_emergency_triages", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "client_id", null: false
    t.integer "agency_id"
    t.string "location"
    t.string "exposure"
    t.string "symptoms"
    t.date "first_symptoms_on"
    t.date "referred_on"
    t.string "referred_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.text "notes"
    t.string "emergency_type"
    t.index ["agency_id"], name: "index_health_emergency_triages_on_agency_id"
    t.index ["client_id"], name: "index_health_emergency_triages_on_client_id"
    t.index ["created_at"], name: "index_health_emergency_triages_on_created_at"
    t.index ["updated_at"], name: "index_health_emergency_triages_on_updated_at"
    t.index ["user_id"], name: "index_health_emergency_triages_on_user_id"
  end

  create_table "health_emergency_uploaded_tests", force: :cascade do |t|
    t.bigint "batch_id"
    t.integer "client_id"
    t.integer "test_id"
    t.string "first_name"
    t.string "last_name"
    t.date "dob"
    t.string "gender"
    t.string "ssn"
    t.date "tested_on"
    t.string "test_location"
    t.string "test_result"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["batch_id"], name: "index_health_emergency_uploaded_tests_on_batch_id"
    t.index ["created_at"], name: "index_health_emergency_uploaded_tests_on_created_at"
    t.index ["deleted_at"], name: "index_health_emergency_uploaded_tests_on_deleted_at"
    t.index ["updated_at"], name: "index_health_emergency_uploaded_tests_on_updated_at"
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

  create_table "hmis_2020_affiliations", force: :cascade do |t|
    t.string "AffiliationID"
    t.string "ProjectID"
    t.string "ResProjectID"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["AffiliationID", "data_source_id"], name: "hmis_2020_affiliations-lZaj"
    t.index ["ExportID"], name: "hmis_2020_affiliations-qycr"
    t.index ["source_type", "source_id"], name: "hmis_2020_affiliations-jXFa"
  end

  create_table "hmis_2020_assessment_questions", force: :cascade do |t|
    t.string "AssessmentQuestionID"
    t.string "AssessmentID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "AssessmentQuestionGroup"
    t.integer "AssessmentQuestionOrder"
    t.string "AssessmentQuestion"
    t.string "AssessmentAnswer"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["AssessmentID"], name: "hmis_2020_assessment_questions-fD1j"
    t.index ["AssessmentQuestionID", "data_source_id"], name: "hmis_2020_assessment_questions-0oMf"
    t.index ["ExportID"], name: "hmis_2020_assessment_questions-sDob"
    t.index ["source_type", "source_id"], name: "hmis_2020_assessment_questions-gVG2"
  end

  create_table "hmis_2020_assessment_results", force: :cascade do |t|
    t.string "AssessmentResultID"
    t.string "AssessmentID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "AssessmentResultType"
    t.string "AssessmentResult"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["AssessmentID"], name: "hmis_2020_assessment_results-AnQd"
    t.index ["AssessmentResultID", "data_source_id"], name: "hmis_2020_assessment_results-rawc"
    t.index ["ExportID"], name: "hmis_2020_assessment_results-2kxY"
    t.index ["source_type", "source_id"], name: "hmis_2020_assessment_results-CKgC"
  end

  create_table "hmis_2020_assessments", force: :cascade do |t|
    t.string "AssessmentID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "AssessmentDate"
    t.string "AssessmentLocation"
    t.integer "AssessmentType"
    t.integer "AssessmentLevel"
    t.integer "PrioritizationStatus"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["AssessmentDate"], name: "hmis_2020_assessments-YW8L"
    t.index ["AssessmentID", "data_source_id"], name: "hmis_2020_assessments-3sM0"
    t.index ["AssessmentID"], name: "hmis_2020_assessments-kqMe"
    t.index ["EnrollmentID"], name: "hmis_2020_assessments-gMUw"
    t.index ["ExportID"], name: "hmis_2020_assessments-u0eq"
    t.index ["PersonalID"], name: "hmis_2020_assessments-kdgA"
    t.index ["source_type", "source_id"], name: "hmis_2020_assessments-B1tS"
  end

  create_table "hmis_2020_clients", force: :cascade do |t|
    t.string "PersonalID"
    t.string "FirstName"
    t.string "MiddleName"
    t.string "LastName"
    t.string "NameSuffix"
    t.integer "NameDataQuality"
    t.string "SSN"
    t.string "SSNDataQuality"
    t.date "DOB"
    t.string "DOBDataQuality"
    t.integer "AmIndAKNative"
    t.integer "Asian"
    t.integer "BlackAfAmerican"
    t.integer "NativeHIOtherPacific"
    t.integer "White"
    t.integer "RaceNone"
    t.integer "Ethnicity"
    t.integer "Gender"
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
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["DOB"], name: "hmis_2020_clients-qUjP"
    t.index ["DateCreated"], name: "hmis_2020_clients-rrgI"
    t.index ["DateUpdated"], name: "hmis_2020_clients-jdcP"
    t.index ["ExportID"], name: "hmis_2020_clients-gmgS"
    t.index ["FirstName"], name: "hmis_2020_clients-48Qj"
    t.index ["LastName"], name: "hmis_2020_clients-3vTw"
    t.index ["PersonalID", "data_source_id"], name: "hmis_2020_clients-t6qe"
    t.index ["PersonalID"], name: "hmis_2020_clients-qK9d"
    t.index ["VeteranStatus"], name: "hmis_2020_clients-z1iL"
    t.index ["source_type", "source_id"], name: "hmis_2020_clients-VRsB"
  end

  create_table "hmis_2020_current_living_situations", force: :cascade do |t|
    t.string "CurrentLivingSitID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "InformationDate"
    t.integer "CurrentLivingSituation"
    t.string "VerifiedBy"
    t.integer "LeaveSituation14Days"
    t.integer "SubsequentResidence"
    t.integer "ResourcesToObtain"
    t.integer "LeaseOwn60Day"
    t.integer "MovedTwoOrMore"
    t.string "LocationDetails"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["CurrentLivingSitID", "data_source_id"], name: "hmis_2020_current_living_situations-cLpS"
    t.index ["CurrentLivingSitID"], name: "hmis_2020_current_living_situations-DXZ0"
    t.index ["CurrentLivingSituation"], name: "hmis_2020_current_living_situations-WmJZ"
    t.index ["EnrollmentID"], name: "hmis_2020_current_living_situations-jG8y"
    t.index ["ExportID"], name: "hmis_2020_current_living_situations-hGfj"
    t.index ["InformationDate"], name: "hmis_2020_current_living_situations-4v4L"
    t.index ["PersonalID"], name: "hmis_2020_current_living_situations-vWt4"
    t.index ["source_type", "source_id"], name: "hmis_2020_current_living_situations-qbbx"
  end

  create_table "hmis_2020_disabilities", force: :cascade do |t|
    t.string "DisabilitiesID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "InformationDate"
    t.integer "DisabilityType"
    t.integer "DisabilityResponse"
    t.integer "IndefiniteAndImpairs"
    t.integer "TCellCountAvailable"
    t.integer "TCellCount"
    t.integer "TCellSource"
    t.integer "ViralLoadAvailable"
    t.integer "ViralLoad"
    t.integer "ViralLoadSource"
    t.integer "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["DateCreated"], name: "hmis_2020_disabilities-p0j2"
    t.index ["DateUpdated"], name: "hmis_2020_disabilities-oxMH"
    t.index ["DisabilitiesID", "data_source_id"], name: "hmis_2020_disabilities-DA3C"
    t.index ["DisabilitiesID"], name: "hmis_2020_disabilities-8DFL"
    t.index ["EnrollmentID"], name: "hmis_2020_disabilities-1JPN"
    t.index ["ExportID"], name: "hmis_2020_disabilities-G1Z0"
    t.index ["PersonalID"], name: "hmis_2020_disabilities-2lYA"
    t.index ["source_type", "source_id"], name: "hmis_2020_disabilities-zFRZ"
  end

  create_table "hmis_2020_employment_educations", force: :cascade do |t|
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
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["DateCreated"], name: "hmis_2020_employment_educations-oPbl"
    t.index ["DateUpdated"], name: "hmis_2020_employment_educations-rTDS"
    t.index ["EmploymentEducationID", "data_source_id"], name: "hmis_2020_employment_educations-zM3A"
    t.index ["EmploymentEducationID"], name: "hmis_2020_employment_educations-Hv6e"
    t.index ["EnrollmentID"], name: "hmis_2020_employment_educations-mSvG"
    t.index ["ExportID"], name: "hmis_2020_employment_educations-uCTm"
    t.index ["PersonalID"], name: "hmis_2020_employment_educations-EPrc"
    t.index ["source_type", "source_id"], name: "hmis_2020_employment_educations-rxeE"
  end

  create_table "hmis_2020_enrollment_cocs", force: :cascade do |t|
    t.string "EnrollmentCoCID"
    t.string "EnrollmentID"
    t.string "HouseholdID"
    t.string "ProjectID"
    t.string "PersonalID"
    t.date "InformationDate"
    t.string "CoCCode"
    t.integer "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["CoCCode"], name: "hmis_2020_enrollment_cocs-5ROz"
    t.index ["DateCreated"], name: "hmis_2020_enrollment_cocs-zikd"
    t.index ["DateDeleted"], name: "hmis_2020_enrollment_cocs-GUQA"
    t.index ["DateUpdated"], name: "hmis_2020_enrollment_cocs-6Mre"
    t.index ["EnrollmentCoCID", "data_source_id"], name: "hmis_2020_enrollment_cocs-LilW"
    t.index ["EnrollmentCoCID"], name: "hmis_2020_enrollment_cocs-6ENr"
    t.index ["EnrollmentID"], name: "hmis_2020_enrollment_cocs-gQJA"
    t.index ["ExportID"], name: "hmis_2020_enrollment_cocs-sVGW"
    t.index ["PersonalID"], name: "hmis_2020_enrollment_cocs-5FMZ"
    t.index ["source_type", "source_id"], name: "hmis_2020_enrollment_cocs-Se2O"
  end

  create_table "hmis_2020_enrollments", force: :cascade do |t|
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "ProjectID"
    t.date "EntryDate"
    t.string "HouseholdID"
    t.integer "RelationshipToHoH"
    t.integer "LivingSituation"
    t.integer "LengthOfStay"
    t.integer "LOSUnderThreshold"
    t.integer "PreviousStreetESSH"
    t.date "DateToStreetESSH"
    t.integer "TimesHomelessPastThreeYears"
    t.integer "MonthsHomelessPastThreeYears"
    t.integer "DisablingCondition"
    t.date "DateOfEngagement"
    t.date "MoveInDate"
    t.date "DateOfPATHStatus"
    t.integer "ClientEnrolledInPATH"
    t.integer "ReasonNotEnrolled"
    t.integer "WorstHousingSituation"
    t.integer "PercentAMI"
    t.string "LastPermanentStreet"
    t.string "LastPermanentCity"
    t.string "LastPermanentState"
    t.string "LastPermanentZIP"
    t.integer "AddressDataQuality"
    t.date "DateOfBCPStatus"
    t.integer "EligibleForRHY"
    t.integer "ReasonNoServices"
    t.integer "RunawayYouth"
    t.integer "SexualOrientation"
    t.string "SexualOrientationOther"
    t.integer "FormerWardChildWelfare"
    t.integer "ChildWelfareYears"
    t.integer "ChildWelfareMonths"
    t.integer "FormerWardJuvenileJustice"
    t.integer "JuvenileJusticeYears"
    t.integer "JuvenileJusticeMonths"
    t.integer "UnemploymentFam"
    t.integer "MentalHealthIssuesFam"
    t.integer "PhysicalDisabilityFam"
    t.integer "AlcoholDrugAbuseFam"
    t.integer "InsufficientIncome"
    t.integer "IncarceratedParent"
    t.integer "ReferralSource"
    t.integer "CountOutreachReferralApproaches"
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
    t.integer "HPScreeningScore"
    t.integer "ThresholdScore"
    t.string "VAMCStation"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["DateCreated"], name: "hmis_2020_enrollments-ZK9t"
    t.index ["DateDeleted"], name: "hmis_2020_enrollments-WHri"
    t.index ["DateUpdated"], name: "hmis_2020_enrollments-hQVn"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis_2020_enrollments-xB0L"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmis_2020_enrollments-Qd6d"
    t.index ["EnrollmentID", "data_source_id"], name: "hmis_2020_enrollments-dRUc"
    t.index ["EnrollmentID"], name: "hmis_2020_enrollments-UrCS"
    t.index ["EntryDate"], name: "hmis_2020_enrollments-6ZYF"
    t.index ["ExportID"], name: "hmis_2020_enrollments-kzx7"
    t.index ["HouseholdID"], name: "hmis_2020_enrollments-xiJ6"
    t.index ["LivingSituation"], name: "hmis_2020_enrollments-Io4W"
    t.index ["PersonalID"], name: "hmis_2020_enrollments-UM6y"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmis_2020_enrollments-kIRP"
    t.index ["ProjectID", "HouseholdID"], name: "hmis_2020_enrollments-8tOj"
    t.index ["ProjectID", "RelationshipToHoH"], name: "hmis_2020_enrollments-HNd8"
    t.index ["ProjectID"], name: "hmis_2020_enrollments-dn8l"
    t.index ["RelationshipToHoH"], name: "hmis_2020_enrollments-y1wr"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears"], name: "hmis_2020_enrollments-9mEF"
    t.index ["source_type", "source_id"], name: "hmis_2020_enrollments-3NkS"
  end

  create_table "hmis_2020_events", force: :cascade do |t|
    t.string "EventID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "EventDate"
    t.integer "Event"
    t.integer "ProbSolDivRRResult"
    t.integer "ReferralCaseManageAfter"
    t.string "LocationCrisisorPHHousing"
    t.integer "ReferralResult"
    t.date "ResultDate"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["EnrollmentID"], name: "hmis_2020_events-ej4z"
    t.index ["EventDate"], name: "hmis_2020_events-SY9T"
    t.index ["EventID", "data_source_id"], name: "hmis_2020_events-5Ulw"
    t.index ["EventID"], name: "hmis_2020_events-h86C"
    t.index ["ExportID"], name: "hmis_2020_events-chRs"
    t.index ["PersonalID"], name: "hmis_2020_events-sFna"
    t.index ["source_type", "source_id"], name: "hmis_2020_events-ztpH"
  end

  create_table "hmis_2020_exits", force: :cascade do |t|
    t.string "ExitID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "ExitDate"
    t.integer "Destination"
    t.string "OtherDestination"
    t.integer "HousingAssessment"
    t.integer "SubsidyInformation"
    t.integer "ProjectCompletionStatus"
    t.integer "EarlyExitReason"
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
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["DateCreated"], name: "hmis_2020_exits-F305"
    t.index ["DateDeleted"], name: "hmis_2020_exits-s54g"
    t.index ["DateUpdated"], name: "hmis_2020_exits-Crsu"
    t.index ["EnrollmentID"], name: "hmis_2020_exits-Z3F6"
    t.index ["ExitDate"], name: "hmis_2020_exits-nEjV"
    t.index ["ExitID", "data_source_id"], name: "hmis_2020_exits-S9yO"
    t.index ["ExitID"], name: "hmis_2020_exits-4DnO"
    t.index ["ExportID"], name: "hmis_2020_exits-c4Un"
    t.index ["PersonalID"], name: "hmis_2020_exits-QkLT"
    t.index ["source_type", "source_id"], name: "hmis_2020_exits-dozv"
  end

  create_table "hmis_2020_exports", force: :cascade do |t|
    t.string "ExportID"
    t.integer "SourceType"
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
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["ExportID", "data_source_id"], name: "hmis_2020_exports-YcvP"
    t.index ["ExportID"], name: "hmis_2020_exports-awLV"
    t.index ["source_type", "source_id"], name: "hmis_2020_exports-5gdY"
  end

  create_table "hmis_2020_funders", force: :cascade do |t|
    t.string "FunderID"
    t.string "ProjectID"
    t.integer "Funder"
    t.string "OtherFunder"
    t.string "GrantID"
    t.date "StartDate"
    t.date "EndDate"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["DateCreated"], name: "hmis_2020_funders-CQE4"
    t.index ["DateUpdated"], name: "hmis_2020_funders-yKF3"
    t.index ["ExportID"], name: "hmis_2020_funders-qRxb"
    t.index ["FunderID", "data_source_id"], name: "hmis_2020_funders-XiWW"
    t.index ["FunderID"], name: "hmis_2020_funders-P3hw"
    t.index ["source_type", "source_id"], name: "hmis_2020_funders-Srvd"
  end

  create_table "hmis_2020_health_and_dvs", force: :cascade do |t|
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
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["DateCreated"], name: "hmis_2020_health_and_dvs-85bD"
    t.index ["DateUpdated"], name: "hmis_2020_health_and_dvs-TUTe"
    t.index ["EnrollmentID"], name: "hmis_2020_health_and_dvs-SbP4"
    t.index ["ExportID"], name: "hmis_2020_health_and_dvs-w4jj"
    t.index ["HealthAndDVID", "data_source_id"], name: "hmis_2020_health_and_dvs-zonF"
    t.index ["HealthAndDVID"], name: "hmis_2020_health_and_dvs-zE81"
    t.index ["PersonalID"], name: "hmis_2020_health_and_dvs-Kqiz"
    t.index ["source_type", "source_id"], name: "hmis_2020_health_and_dvs-Ha57"
  end

  create_table "hmis_2020_income_benefits", force: :cascade do |t|
    t.string "IncomeBenefitsID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "InformationDate"
    t.integer "IncomeFromAnySource"
    t.string "TotalMonthlyIncome"
    t.integer "Earned"
    t.string "EarnedAmount"
    t.integer "Unemployment"
    t.string "UnemploymentAmount"
    t.integer "SSI"
    t.string "SSIAmount"
    t.integer "SSDI"
    t.string "SSDIAmount"
    t.integer "VADisabilityService"
    t.string "VADisabilityServiceAmount"
    t.integer "VADisabilityNonService"
    t.string "VADisabilityNonServiceAmount"
    t.integer "PrivateDisability"
    t.string "PrivateDisabilityAmount"
    t.integer "WorkersComp"
    t.string "WorkersCompAmount"
    t.integer "TANF"
    t.string "TANFAmount"
    t.integer "GA"
    t.string "GAAmount"
    t.integer "SocSecRetirement"
    t.string "SocSecRetirementAmount"
    t.integer "Pension"
    t.string "PensionAmount"
    t.integer "ChildSupport"
    t.string "ChildSupportAmount"
    t.integer "Alimony"
    t.string "AlimonyAmount"
    t.integer "OtherIncomeSource"
    t.string "OtherIncomeAmount"
    t.string "OtherIncomeSourceIdentify"
    t.integer "BenefitsFromAnySource"
    t.integer "SNAP"
    t.integer "WIC"
    t.integer "TANFChildCare"
    t.integer "TANFTransportation"
    t.integer "OtherTANF"
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
    t.integer "IndianHealthServices"
    t.integer "NoIndianHealthServicesReason"
    t.integer "OtherInsurance"
    t.string "OtherInsuranceIdentify"
    t.integer "HIVAIDSAssistance"
    t.integer "NoHIVAIDSAssistanceReason"
    t.integer "ADAP"
    t.integer "NoADAPReason"
    t.integer "ConnectionWithSOAR"
    t.integer "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["DateCreated"], name: "hmis_2020_income_benefits-JwPq"
    t.index ["DateUpdated"], name: "hmis_2020_income_benefits-aphJ"
    t.index ["EnrollmentID"], name: "hmis_2020_income_benefits-AUwp"
    t.index ["ExportID"], name: "hmis_2020_income_benefits-BE9p"
    t.index ["IncomeBenefitsID", "data_source_id"], name: "hmis_2020_income_benefits-tBcJ"
    t.index ["IncomeBenefitsID"], name: "hmis_2020_income_benefits-pfYl"
    t.index ["PersonalID"], name: "hmis_2020_income_benefits-NcHX"
    t.index ["source_type", "source_id"], name: "hmis_2020_income_benefits-LCKi"
  end

  create_table "hmis_2020_inventories", force: :cascade do |t|
    t.string "InventoryID"
    t.string "ProjectID"
    t.string "CoCCode"
    t.integer "HouseholdType"
    t.integer "Availability"
    t.integer "UnitInventory"
    t.integer "BedInventory"
    t.integer "CHVetBedInventory"
    t.integer "YouthVetBedInventory"
    t.integer "VetBedInventory"
    t.integer "CHYouthBedInventory"
    t.integer "YouthBedInventory"
    t.integer "CHBedInventory"
    t.integer "OtherBedInventory"
    t.integer "ESBedType"
    t.date "InventoryStartDate"
    t.date "InventoryEndDate"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["DateCreated"], name: "hmis_2020_inventories-J6na"
    t.index ["DateUpdated"], name: "hmis_2020_inventories-0TGU"
    t.index ["ExportID"], name: "hmis_2020_inventories-whCo"
    t.index ["InventoryID", "data_source_id"], name: "hmis_2020_inventories-LNwI"
    t.index ["InventoryID"], name: "hmis_2020_inventories-fun6"
    t.index ["ProjectID", "CoCCode"], name: "hmis_2020_inventories-yV3L"
    t.index ["source_type", "source_id"], name: "hmis_2020_inventories-DTHt"
  end

  create_table "hmis_2020_organizations", force: :cascade do |t|
    t.string "OrganizationID"
    t.string "OrganizationName"
    t.integer "VictimServicesProvider"
    t.string "OrganizationCommonName"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["ExportID"], name: "hmis_2020_organizations-VQWo"
    t.index ["OrganizationID", "data_source_id"], name: "hmis_2020_organizations-MfSb"
    t.index ["OrganizationID"], name: "hmis_2020_organizations-Prts"
    t.index ["source_type", "source_id"], name: "hmis_2020_organizations-SWg3"
  end

  create_table "hmis_2020_project_cocs", force: :cascade do |t|
    t.string "ProjectCoCID"
    t.string "ProjectID"
    t.string "CoCCode"
    t.string "Geocode"
    t.string "Address1"
    t.string "Address2"
    t.string "City"
    t.string "State"
    t.string "Zip"
    t.integer "GeographyType"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["DateCreated"], name: "hmis_2020_project_cocs-Tmf3"
    t.index ["DateUpdated"], name: "hmis_2020_project_cocs-OI4Q"
    t.index ["ExportID"], name: "hmis_2020_project_cocs-GTs4"
    t.index ["ProjectCoCID", "data_source_id"], name: "hmis_2020_project_cocs-JAwb"
    t.index ["ProjectCoCID"], name: "hmis_2020_project_cocs-iuZj"
    t.index ["ProjectID", "CoCCode"], name: "hmis_2020_project_cocs-K8nw"
    t.index ["source_type", "source_id"], name: "hmis_2020_project_cocs-icQq"
  end

  create_table "hmis_2020_projects", force: :cascade do |t|
    t.string "ProjectID"
    t.string "OrganizationID"
    t.string "ProjectName"
    t.string "ProjectCommonName"
    t.date "OperatingStartDate"
    t.date "OperatingEndDate"
    t.integer "ContinuumProject"
    t.integer "ProjectType"
    t.integer "HousingType"
    t.integer "ResidentialAffiliation"
    t.integer "TrackingMethod"
    t.integer "HMISParticipatingProject"
    t.integer "TargetPopulation"
    t.integer "PITCount"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["DateCreated"], name: "hmis_2020_projects-ctk2"
    t.index ["DateUpdated"], name: "hmis_2020_projects-zcbu"
    t.index ["ExportID"], name: "hmis_2020_projects-fqB3"
    t.index ["ProjectID", "data_source_id"], name: "hmis_2020_projects-oxQa"
    t.index ["ProjectID"], name: "hmis_2020_projects-nhkJ"
    t.index ["ProjectType"], name: "hmis_2020_projects-xkUs"
    t.index ["source_type", "source_id"], name: "hmis_2020_projects-5SSM"
  end

  create_table "hmis_2020_services", force: :cascade do |t|
    t.string "ServicesID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "DateProvided"
    t.integer "RecordType"
    t.integer "TypeProvided"
    t.string "OtherTypeProvided"
    t.integer "SubTypeProvided"
    t.string "FAAmount"
    t.integer "ReferralOutcome"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["DateCreated"], name: "hmis_2020_services-eNab"
    t.index ["DateDeleted"], name: "hmis_2020_services-WGtP"
    t.index ["DateProvided"], name: "hmis_2020_services-8nZj"
    t.index ["DateUpdated"], name: "hmis_2020_services-VJ0s"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis_2020_services-m63x"
    t.index ["EnrollmentID", "RecordType", "DateDeleted", "DateProvided"], name: "hmis_2020_services-LqGx"
    t.index ["EnrollmentID"], name: "hmis_2020_services-wXdL"
    t.index ["ExportID"], name: "hmis_2020_services-Y8F7"
    t.index ["PersonalID", "RecordType", "EnrollmentID", "DateProvided"], name: "hmis_2020_services-ggIO"
    t.index ["PersonalID"], name: "hmis_2020_services-Rwkq"
    t.index ["RecordType", "DateDeleted"], name: "hmis_2020_services-WrTZ"
    t.index ["RecordType", "DateProvided"], name: "hmis_2020_services-ApuA"
    t.index ["RecordType"], name: "hmis_2020_services-mIRP"
    t.index ["ServicesID", "data_source_id"], name: "hmis_2020_services-3lC5"
    t.index ["ServicesID"], name: "hmis_2020_services-QkXD"
    t.index ["source_type", "source_id"], name: "hmis_2020_services-4CG1"
  end

  create_table "hmis_2020_users", force: :cascade do |t|
    t.string "UserID"
    t.string "UserFirstName"
    t.string "UserLastName"
    t.string "UserPhone"
    t.string "UserExtension"
    t.string "UserEmail"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at"
    t.datetime "clean_at"
    t.index ["ExportID"], name: "hmis_2020_users-Ls1u"
    t.index ["UserID", "data_source_id"], name: "hmis_2020_users-DmeI"
    t.index ["UserID"], name: "hmis_2020_users-74tq"
    t.index ["source_type", "source_id"], name: "hmis_2020_users-ZfY6"
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
    t.boolean "vispdat", default: false
    t.boolean "pathways", default: false
    t.boolean "ssm", default: false
    t.boolean "health_case_note", default: false
    t.boolean "health_has_qualifying_activities", default: false
    t.boolean "hud_assessment", default: false
    t.boolean "triage_assessment", default: false
    t.boolean "rrh_assessment", default: false
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

  create_table "hmis_csv_2020_affiliations", force: :cascade do |t|
    t.string "AffiliationID"
    t.string "ProjectID"
    t.string "ResProjectID"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["AffiliationID", "data_source_id"], name: "hmis_csv_2020_affiliations-F2ar"
    t.index ["ExportID"], name: "hmis_csv_2020_affiliations-ofln"
  end

  create_table "hmis_csv_2020_assessment_questions", force: :cascade do |t|
    t.string "AssessmentQuestionID"
    t.string "AssessmentID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "AssessmentQuestionGroup"
    t.string "AssessmentQuestionOrder"
    t.string "AssessmentQuestion"
    t.string "AssessmentAnswer"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["AssessmentID"], name: "hmis_csv_2020_assessment_questions-U6Dk"
    t.index ["AssessmentQuestionID", "data_source_id"], name: "hmis_csv_2020_assessment_questions-ZGxE"
    t.index ["ExportID"], name: "hmis_csv_2020_assessment_questions-Xt6t"
  end

  create_table "hmis_csv_2020_assessment_results", force: :cascade do |t|
    t.string "AssessmentResultID"
    t.string "AssessmentID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "AssessmentResultType"
    t.string "AssessmentResult"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["AssessmentID"], name: "hmis_csv_2020_assessment_results-NEN7"
    t.index ["AssessmentResultID", "data_source_id"], name: "hmis_csv_2020_assessment_results-Rkod"
    t.index ["ExportID"], name: "hmis_csv_2020_assessment_results-NLC4"
  end

  create_table "hmis_csv_2020_assessments", force: :cascade do |t|
    t.string "AssessmentID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "AssessmentDate"
    t.string "AssessmentLocation"
    t.string "AssessmentType"
    t.string "AssessmentLevel"
    t.string "PrioritizationStatus"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["AssessmentDate"], name: "hmis_csv_2020_assessments-GRoC"
    t.index ["AssessmentID", "data_source_id"], name: "hmis_csv_2020_assessments-y7s0"
    t.index ["AssessmentID"], name: "hmis_csv_2020_assessments-W4vL"
    t.index ["EnrollmentID"], name: "hmis_csv_2020_assessments-EZd7"
    t.index ["ExportID"], name: "hmis_csv_2020_assessments-MoqJ"
    t.index ["PersonalID"], name: "hmis_csv_2020_assessments-nFH4"
  end

  create_table "hmis_csv_2020_clients", force: :cascade do |t|
    t.string "PersonalID"
    t.string "FirstName"
    t.string "MiddleName"
    t.string "LastName"
    t.string "NameSuffix"
    t.string "NameDataQuality"
    t.string "SSN"
    t.string "SSNDataQuality"
    t.string "DOB"
    t.string "DOBDataQuality"
    t.string "AmIndAKNative"
    t.string "Asian"
    t.string "BlackAfAmerican"
    t.string "NativeHIOtherPacific"
    t.string "White"
    t.string "RaceNone"
    t.string "Ethnicity"
    t.string "Gender"
    t.string "VeteranStatus"
    t.string "YearEnteredService"
    t.string "YearSeparated"
    t.string "WorldWarII"
    t.string "KoreanWar"
    t.string "VietnamWar"
    t.string "DesertStorm"
    t.string "AfghanistanOEF"
    t.string "IraqOIF"
    t.string "IraqOND"
    t.string "OtherTheater"
    t.string "MilitaryBranch"
    t.string "DischargeStatus"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["DOB"], name: "hmis_csv_2020_clients-FQ7O"
    t.index ["DateCreated"], name: "hmis_csv_2020_clients-2cnC"
    t.index ["DateUpdated"], name: "hmis_csv_2020_clients-wlPc"
    t.index ["ExportID"], name: "hmis_csv_2020_clients-20vV"
    t.index ["FirstName"], name: "hmis_csv_2020_clients-Q0u6"
    t.index ["LastName"], name: "hmis_csv_2020_clients-85Ap"
    t.index ["PersonalID", "data_source_id"], name: "hmis_csv_2020_clients-qppE"
    t.index ["PersonalID"], name: "hmis_csv_2020_clients-moFz"
    t.index ["VeteranStatus"], name: "hmis_csv_2020_clients-kRKs"
  end

  create_table "hmis_csv_2020_current_living_situations", force: :cascade do |t|
    t.string "CurrentLivingSitID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "InformationDate"
    t.string "CurrentLivingSituation"
    t.string "VerifiedBy"
    t.string "LeaveSituation14Days"
    t.string "SubsequentResidence"
    t.string "ResourcesToObtain"
    t.string "LeaseOwn60Day"
    t.string "MovedTwoOrMore"
    t.string "LocationDetails"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["CurrentLivingSitID", "data_source_id"], name: "hmis_csv_2020_current_living_situations-jzq2"
    t.index ["CurrentLivingSitID"], name: "hmis_csv_2020_current_living_situations-EGfX"
    t.index ["CurrentLivingSituation"], name: "hmis_csv_2020_current_living_situations-Vh4Y"
    t.index ["EnrollmentID"], name: "hmis_csv_2020_current_living_situations-ScsR"
    t.index ["ExportID"], name: "hmis_csv_2020_current_living_situations-KGuH"
    t.index ["InformationDate"], name: "hmis_csv_2020_current_living_situations-VCsb"
    t.index ["PersonalID"], name: "hmis_csv_2020_current_living_situations-3hVq"
  end

  create_table "hmis_csv_2020_disabilities", force: :cascade do |t|
    t.string "DisabilitiesID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "InformationDate"
    t.string "DisabilityType"
    t.string "DisabilityResponse"
    t.string "IndefiniteAndImpairs"
    t.string "TCellCountAvailable"
    t.string "TCellCount"
    t.string "TCellSource"
    t.string "ViralLoadAvailable"
    t.string "ViralLoad"
    t.string "ViralLoadSource"
    t.string "DataCollectionStage"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_disabilities-ohpt"
    t.index ["DateUpdated"], name: "hmis_csv_2020_disabilities-4Nml"
    t.index ["DisabilitiesID", "data_source_id"], name: "hmis_csv_2020_disabilities-anqe"
    t.index ["DisabilitiesID"], name: "hmis_csv_2020_disabilities-toFu"
    t.index ["EnrollmentID"], name: "hmis_csv_2020_disabilities-9jL3"
    t.index ["ExportID"], name: "hmis_csv_2020_disabilities-Sp4k"
    t.index ["PersonalID"], name: "hmis_csv_2020_disabilities-xa8A"
  end

  create_table "hmis_csv_2020_employment_educations", force: :cascade do |t|
    t.string "EmploymentEducationID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "InformationDate"
    t.string "LastGradeCompleted"
    t.string "SchoolStatus"
    t.string "Employed"
    t.string "EmploymentType"
    t.string "NotEmployedReason"
    t.string "DataCollectionStage"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_employment_educations-bTVG"
    t.index ["DateUpdated"], name: "hmis_csv_2020_employment_educations-4yxa"
    t.index ["EmploymentEducationID", "data_source_id"], name: "hmis_csv_2020_employment_educations-3UVX"
    t.index ["EmploymentEducationID"], name: "hmis_csv_2020_employment_educations-U3yq"
    t.index ["EnrollmentID"], name: "hmis_csv_2020_employment_educations-JTgH"
    t.index ["ExportID"], name: "hmis_csv_2020_employment_educations-8u1c"
    t.index ["PersonalID"], name: "hmis_csv_2020_employment_educations-ffjb"
  end

  create_table "hmis_csv_2020_enrollment_cocs", force: :cascade do |t|
    t.string "EnrollmentCoCID"
    t.string "EnrollmentID"
    t.string "HouseholdID"
    t.string "ProjectID"
    t.string "PersonalID"
    t.string "InformationDate"
    t.string "CoCCode"
    t.string "DataCollectionStage"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["CoCCode"], name: "hmis_csv_2020_enrollment_cocs-RyqL"
    t.index ["DateCreated"], name: "hmis_csv_2020_enrollment_cocs-dizj"
    t.index ["DateDeleted"], name: "hmis_csv_2020_enrollment_cocs-ManB"
    t.index ["DateUpdated"], name: "hmis_csv_2020_enrollment_cocs-myvn"
    t.index ["EnrollmentCoCID", "data_source_id"], name: "hmis_csv_2020_enrollment_cocs-MhSp"
    t.index ["EnrollmentCoCID"], name: "hmis_csv_2020_enrollment_cocs-zRK2"
    t.index ["EnrollmentID"], name: "hmis_csv_2020_enrollment_cocs-phxe"
    t.index ["ExportID"], name: "hmis_csv_2020_enrollment_cocs-AFlL"
    t.index ["PersonalID"], name: "hmis_csv_2020_enrollment_cocs-GYSJ"
  end

  create_table "hmis_csv_2020_enrollments", force: :cascade do |t|
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "ProjectID"
    t.string "EntryDate"
    t.string "HouseholdID"
    t.string "RelationshipToHoH"
    t.string "LivingSituation"
    t.string "LengthOfStay"
    t.string "LOSUnderThreshold"
    t.string "PreviousStreetESSH"
    t.string "DateToStreetESSH"
    t.string "TimesHomelessPastThreeYears"
    t.string "MonthsHomelessPastThreeYears"
    t.string "DisablingCondition"
    t.string "DateOfEngagement"
    t.string "MoveInDate"
    t.string "DateOfPATHStatus"
    t.string "ClientEnrolledInPATH"
    t.string "ReasonNotEnrolled"
    t.string "WorstHousingSituation"
    t.string "PercentAMI"
    t.string "LastPermanentStreet"
    t.string "LastPermanentCity"
    t.string "LastPermanentState"
    t.string "LastPermanentZIP"
    t.string "AddressDataQuality"
    t.string "DateOfBCPStatus"
    t.string "EligibleForRHY"
    t.string "ReasonNoServices"
    t.string "RunawayYouth"
    t.string "SexualOrientation"
    t.string "SexualOrientationOther"
    t.string "FormerWardChildWelfare"
    t.string "ChildWelfareYears"
    t.string "ChildWelfareMonths"
    t.string "FormerWardJuvenileJustice"
    t.string "JuvenileJusticeYears"
    t.string "JuvenileJusticeMonths"
    t.string "UnemploymentFam"
    t.string "MentalHealthIssuesFam"
    t.string "PhysicalDisabilityFam"
    t.string "AlcoholDrugAbuseFam"
    t.string "InsufficientIncome"
    t.string "IncarceratedParent"
    t.string "ReferralSource"
    t.string "CountOutreachReferralApproaches"
    t.string "UrgentReferral"
    t.string "TimeToHousingLoss"
    t.string "ZeroIncome"
    t.string "AnnualPercentAMI"
    t.string "FinancialChange"
    t.string "HouseholdChange"
    t.string "EvictionHistory"
    t.string "SubsidyAtRisk"
    t.string "LiteralHomelessHistory"
    t.string "DisabledHoH"
    t.string "CriminalRecord"
    t.string "SexOffender"
    t.string "DependentUnder6"
    t.string "SingleParent"
    t.string "HH5Plus"
    t.string "IraqAfghanistan"
    t.string "FemVet"
    t.string "HPScreeningScore"
    t.string "ThresholdScore"
    t.string "VAMCStation"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_enrollments-djbw"
    t.index ["DateDeleted"], name: "hmis_csv_2020_enrollments-B4uX"
    t.index ["DateUpdated"], name: "hmis_csv_2020_enrollments-qD0O"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis_csv_2020_enrollments-8UEw"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmis_csv_2020_enrollments-LQ7R"
    t.index ["EnrollmentID", "data_source_id"], name: "hmis_csv_2020_enrollments-2DM8"
    t.index ["EnrollmentID"], name: "hmis_csv_2020_enrollments-XI6S"
    t.index ["EntryDate"], name: "hmis_csv_2020_enrollments-l0fG"
    t.index ["ExportID"], name: "hmis_csv_2020_enrollments-1CJ3"
    t.index ["HouseholdID"], name: "hmis_csv_2020_enrollments-1ErZ"
    t.index ["LivingSituation"], name: "hmis_csv_2020_enrollments-Leaw"
    t.index ["PersonalID"], name: "hmis_csv_2020_enrollments-7ZVi"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmis_csv_2020_enrollments-CxJA"
    t.index ["ProjectID", "HouseholdID"], name: "hmis_csv_2020_enrollments-gF7Z"
    t.index ["ProjectID", "RelationshipToHoH"], name: "hmis_csv_2020_enrollments-KtXA"
    t.index ["ProjectID"], name: "hmis_csv_2020_enrollments-CKRZ"
    t.index ["RelationshipToHoH"], name: "hmis_csv_2020_enrollments-GH0S"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears"], name: "hmis_csv_2020_enrollments-bpsk"
  end

  create_table "hmis_csv_2020_events", force: :cascade do |t|
    t.string "EventID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "EventDate"
    t.string "Event"
    t.string "ProbSolDivRRResult"
    t.string "ReferralCaseManageAfter"
    t.string "LocationCrisisorPHHousing"
    t.string "ReferralResult"
    t.string "ResultDate"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["EnrollmentID"], name: "hmis_csv_2020_events-niJ9"
    t.index ["EventDate"], name: "hmis_csv_2020_events-G60G"
    t.index ["EventID", "data_source_id"], name: "hmis_csv_2020_events-BBvn"
    t.index ["EventID"], name: "hmis_csv_2020_events-HCAc"
    t.index ["ExportID"], name: "hmis_csv_2020_events-lkZq"
    t.index ["PersonalID"], name: "hmis_csv_2020_events-7ZMP"
  end

  create_table "hmis_csv_2020_exits", force: :cascade do |t|
    t.string "ExitID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "ExitDate"
    t.string "Destination"
    t.string "OtherDestination"
    t.string "HousingAssessment"
    t.string "SubsidyInformation"
    t.string "ProjectCompletionStatus"
    t.string "EarlyExitReason"
    t.string "ExchangeForSex"
    t.string "ExchangeForSexPastThreeMonths"
    t.string "CountOfExchangeForSex"
    t.string "AskedOrForcedToExchangeForSex"
    t.string "AskedOrForcedToExchangeForSexPastThreeMonths"
    t.string "WorkPlaceViolenceThreats"
    t.string "WorkplacePromiseDifference"
    t.string "CoercedToContinueWork"
    t.string "LaborExploitPastThreeMonths"
    t.string "CounselingReceived"
    t.string "IndividualCounseling"
    t.string "FamilyCounseling"
    t.string "GroupCounseling"
    t.string "SessionCountAtExit"
    t.string "PostExitCounselingPlan"
    t.string "SessionsInPlan"
    t.string "DestinationSafeClient"
    t.string "DestinationSafeWorker"
    t.string "PosAdultConnections"
    t.string "PosPeerConnections"
    t.string "PosCommunityConnections"
    t.string "AftercareDate"
    t.string "AftercareProvided"
    t.string "EmailSocialMedia"
    t.string "Telephone"
    t.string "InPersonIndividual"
    t.string "InPersonGroup"
    t.string "CMExitReason"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_exits-B03u"
    t.index ["DateDeleted"], name: "hmis_csv_2020_exits-9oMc"
    t.index ["DateUpdated"], name: "hmis_csv_2020_exits-u5YR"
    t.index ["EnrollmentID"], name: "hmis_csv_2020_exits-lfLn"
    t.index ["ExitDate"], name: "hmis_csv_2020_exits-wXSx"
    t.index ["ExitID", "data_source_id"], name: "hmis_csv_2020_exits-m68a"
    t.index ["ExitID"], name: "hmis_csv_2020_exits-yZ3j"
    t.index ["ExportID"], name: "hmis_csv_2020_exits-xc6a"
    t.index ["PersonalID"], name: "hmis_csv_2020_exits-86BM"
  end

  create_table "hmis_csv_2020_exports", force: :cascade do |t|
    t.string "ExportID"
    t.string "SourceType"
    t.string "SourceID"
    t.string "SourceName"
    t.string "SourceContactFirst"
    t.string "SourceContactLast"
    t.string "SourceContactPhone"
    t.string "SourceContactExtension"
    t.string "SourceContactEmail"
    t.string "ExportDate"
    t.string "ExportStartDate"
    t.string "ExportEndDate"
    t.string "SoftwareName"
    t.string "SoftwareVersion"
    t.string "ExportPeriodType"
    t.string "ExportDirective"
    t.string "HashStatus"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["ExportID", "data_source_id"], name: "hmis_csv_2020_exports-K9wp"
    t.index ["ExportID"], name: "hmis_csv_2020_exports-iweG"
  end

  create_table "hmis_csv_2020_funders", force: :cascade do |t|
    t.string "FunderID"
    t.string "ProjectID"
    t.string "Funder"
    t.string "OtherFunder"
    t.string "GrantID"
    t.string "StartDate"
    t.string "EndDate"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_funders-IC4k"
    t.index ["DateUpdated"], name: "hmis_csv_2020_funders-Ix1m"
    t.index ["ExportID"], name: "hmis_csv_2020_funders-PEzG"
    t.index ["FunderID", "data_source_id"], name: "hmis_csv_2020_funders-BLkd"
    t.index ["FunderID"], name: "hmis_csv_2020_funders-1HLT"
  end

  create_table "hmis_csv_2020_health_and_dvs", force: :cascade do |t|
    t.string "HealthAndDVID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "InformationDate"
    t.string "DomesticViolenceVictim"
    t.string "WhenOccurred"
    t.string "CurrentlyFleeing"
    t.string "GeneralHealthStatus"
    t.string "DentalHealthStatus"
    t.string "MentalHealthStatus"
    t.string "PregnancyStatus"
    t.string "DueDate"
    t.string "DataCollectionStage"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_health_and_dvs-TUWh"
    t.index ["DateUpdated"], name: "hmis_csv_2020_health_and_dvs-y2fn"
    t.index ["EnrollmentID"], name: "hmis_csv_2020_health_and_dvs-zvlJ"
    t.index ["ExportID"], name: "hmis_csv_2020_health_and_dvs-lO76"
    t.index ["HealthAndDVID", "data_source_id"], name: "hmis_csv_2020_health_and_dvs-6zDo"
    t.index ["HealthAndDVID"], name: "hmis_csv_2020_health_and_dvs-2NoM"
    t.index ["PersonalID"], name: "hmis_csv_2020_health_and_dvs-xYMb"
  end

  create_table "hmis_csv_2020_income_benefits", force: :cascade do |t|
    t.string "IncomeBenefitsID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "InformationDate"
    t.string "IncomeFromAnySource"
    t.string "TotalMonthlyIncome"
    t.string "Earned"
    t.string "EarnedAmount"
    t.string "Unemployment"
    t.string "UnemploymentAmount"
    t.string "SSI"
    t.string "SSIAmount"
    t.string "SSDI"
    t.string "SSDIAmount"
    t.string "VADisabilityService"
    t.string "VADisabilityServiceAmount"
    t.string "VADisabilityNonService"
    t.string "VADisabilityNonServiceAmount"
    t.string "PrivateDisability"
    t.string "PrivateDisabilityAmount"
    t.string "WorkersComp"
    t.string "WorkersCompAmount"
    t.string "TANF"
    t.string "TANFAmount"
    t.string "GA"
    t.string "GAAmount"
    t.string "SocSecRetirement"
    t.string "SocSecRetirementAmount"
    t.string "Pension"
    t.string "PensionAmount"
    t.string "ChildSupport"
    t.string "ChildSupportAmount"
    t.string "Alimony"
    t.string "AlimonyAmount"
    t.string "OtherIncomeSource"
    t.string "OtherIncomeAmount"
    t.string "OtherIncomeSourceIdentify"
    t.string "BenefitsFromAnySource"
    t.string "SNAP"
    t.string "WIC"
    t.string "TANFChildCare"
    t.string "TANFTransportation"
    t.string "OtherTANF"
    t.string "OtherBenefitsSource"
    t.string "OtherBenefitsSourceIdentify"
    t.string "InsuranceFromAnySource"
    t.string "Medicaid"
    t.string "NoMedicaidReason"
    t.string "Medicare"
    t.string "NoMedicareReason"
    t.string "SCHIP"
    t.string "NoSCHIPReason"
    t.string "VAMedicalServices"
    t.string "NoVAMedReason"
    t.string "EmployerProvided"
    t.string "NoEmployerProvidedReason"
    t.string "COBRA"
    t.string "NoCOBRAReason"
    t.string "PrivatePay"
    t.string "NoPrivatePayReason"
    t.string "StateHealthIns"
    t.string "NoStateHealthInsReason"
    t.string "IndianHealthServices"
    t.string "NoIndianHealthServicesReason"
    t.string "OtherInsurance"
    t.string "OtherInsuranceIdentify"
    t.string "HIVAIDSAssistance"
    t.string "NoHIVAIDSAssistanceReason"
    t.string "ADAP"
    t.string "NoADAPReason"
    t.string "ConnectionWithSOAR"
    t.string "DataCollectionStage"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_income_benefits-lVjn"
    t.index ["DateUpdated"], name: "hmis_csv_2020_income_benefits-YyfJ"
    t.index ["EnrollmentID"], name: "hmis_csv_2020_income_benefits-6HMy"
    t.index ["ExportID"], name: "hmis_csv_2020_income_benefits-SEnq"
    t.index ["IncomeBenefitsID", "data_source_id"], name: "hmis_csv_2020_income_benefits-O58u"
    t.index ["IncomeBenefitsID"], name: "hmis_csv_2020_income_benefits-KXp0"
    t.index ["PersonalID"], name: "hmis_csv_2020_income_benefits-Qf5l"
  end

  create_table "hmis_csv_2020_inventories", force: :cascade do |t|
    t.string "InventoryID"
    t.string "ProjectID"
    t.string "CoCCode"
    t.string "HouseholdType"
    t.string "Availability"
    t.string "UnitInventory"
    t.string "BedInventory"
    t.string "CHVetBedInventory"
    t.string "YouthVetBedInventory"
    t.string "VetBedInventory"
    t.string "CHYouthBedInventory"
    t.string "YouthBedInventory"
    t.string "CHBedInventory"
    t.string "OtherBedInventory"
    t.string "ESBedType"
    t.string "InventoryStartDate"
    t.string "InventoryEndDate"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_inventories-eYpq"
    t.index ["DateUpdated"], name: "hmis_csv_2020_inventories-NeSc"
    t.index ["ExportID"], name: "hmis_csv_2020_inventories-wdcK"
    t.index ["InventoryID", "data_source_id"], name: "hmis_csv_2020_inventories-sfWI"
    t.index ["InventoryID"], name: "hmis_csv_2020_inventories-RGrg"
    t.index ["ProjectID", "CoCCode"], name: "hmis_csv_2020_inventories-BTZq"
  end

  create_table "hmis_csv_2020_organizations", force: :cascade do |t|
    t.string "OrganizationID"
    t.string "OrganizationName"
    t.string "VictimServicesProvider"
    t.string "OrganizationCommonName"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmis_csv_2020_organizations-LqQF"
    t.index ["OrganizationID", "data_source_id"], name: "hmis_csv_2020_organizations-cRJF"
    t.index ["OrganizationID"], name: "hmis_csv_2020_organizations-tyIy"
  end

  create_table "hmis_csv_2020_project_cocs", force: :cascade do |t|
    t.string "ProjectCoCID"
    t.string "ProjectID"
    t.string "CoCCode"
    t.string "Geocode"
    t.string "Address1"
    t.string "Address2"
    t.string "City"
    t.string "State"
    t.string "Zip"
    t.string "GeographyType"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_project_cocs-fRQZ"
    t.index ["DateUpdated"], name: "hmis_csv_2020_project_cocs-wP5S"
    t.index ["ExportID"], name: "hmis_csv_2020_project_cocs-336L"
    t.index ["ProjectCoCID", "data_source_id"], name: "hmis_csv_2020_project_cocs-K765"
    t.index ["ProjectCoCID"], name: "hmis_csv_2020_project_cocs-5NHP"
    t.index ["ProjectID", "CoCCode"], name: "hmis_csv_2020_project_cocs-G4ij"
  end

  create_table "hmis_csv_2020_projects", force: :cascade do |t|
    t.string "ProjectID"
    t.string "OrganizationID"
    t.string "ProjectName"
    t.string "ProjectCommonName"
    t.string "OperatingStartDate"
    t.string "OperatingEndDate"
    t.string "ContinuumProject"
    t.string "ProjectType"
    t.string "HousingType"
    t.string "ResidentialAffiliation"
    t.string "TrackingMethod"
    t.string "HMISParticipatingProject"
    t.string "TargetPopulation"
    t.string "PITCount"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_projects-m4tQ"
    t.index ["DateUpdated"], name: "hmis_csv_2020_projects-MNAC"
    t.index ["ExportID"], name: "hmis_csv_2020_projects-f4DP"
    t.index ["ProjectID", "data_source_id"], name: "hmis_csv_2020_projects-StS2"
    t.index ["ProjectID"], name: "hmis_csv_2020_projects-I9LN"
    t.index ["ProjectType"], name: "hmis_csv_2020_projects-gAEK"
  end

  create_table "hmis_csv_2020_services", force: :cascade do |t|
    t.string "ServicesID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "DateProvided"
    t.string "RecordType"
    t.string "TypeProvided"
    t.string "OtherTypeProvided"
    t.string "SubTypeProvided"
    t.string "FAAmount"
    t.string "ReferralOutcome"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_services-Nlyp"
    t.index ["DateDeleted"], name: "hmis_csv_2020_services-5b2P"
    t.index ["DateProvided"], name: "hmis_csv_2020_services-i7KB"
    t.index ["DateUpdated"], name: "hmis_csv_2020_services-MSYV"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis_csv_2020_services-7Ekp"
    t.index ["EnrollmentID", "RecordType", "DateDeleted", "DateProvided"], name: "hmis_csv_2020_services-1ggS"
    t.index ["EnrollmentID"], name: "hmis_csv_2020_services-mvqR"
    t.index ["ExportID"], name: "hmis_csv_2020_services-b6iK"
    t.index ["PersonalID", "RecordType", "EnrollmentID", "DateProvided"], name: "hmis_csv_2020_services-lVDS"
    t.index ["PersonalID"], name: "hmis_csv_2020_services-ZiEF"
    t.index ["RecordType", "DateDeleted"], name: "hmis_csv_2020_services-VRZ7"
    t.index ["RecordType", "DateProvided"], name: "hmis_csv_2020_services-8SnT"
    t.index ["RecordType"], name: "hmis_csv_2020_services-feYP"
    t.index ["ServicesID", "data_source_id"], name: "hmis_csv_2020_services-dacu"
    t.index ["ServicesID"], name: "hmis_csv_2020_services-4Q3B"
  end

  create_table "hmis_csv_2020_users", force: :cascade do |t|
    t.string "UserID"
    t.string "UserFirstName"
    t.string "UserLastName"
    t.string "UserPhone"
    t.string "UserExtension"
    t.string "UserEmail"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmis_csv_2020_users-Vflk"
    t.index ["UserID", "data_source_id"], name: "hmis_csv_2020_users-Y4OW"
    t.index ["UserID"], name: "hmis_csv_2020_users-3tXl"
  end

  create_table "hmis_csv_import_errors", force: :cascade do |t|
    t.integer "importer_log_id", null: false
    t.string "message"
    t.string "details"
    t.string "source_type", null: false
    t.string "source_id", null: false
    t.index ["importer_log_id"], name: "index_hmis_csv_import_errors_on_importer_log_id"
    t.index ["source_type", "source_id"], name: "hmis_csv_import_errors-wgH3"
  end

  create_table "hmis_csv_import_validations", force: :cascade do |t|
    t.integer "importer_log_id", null: false
    t.string "type", null: false
    t.string "source_id", null: false
    t.string "source_type", null: false
    t.string "status"
    t.index ["importer_log_id"], name: "index_hmis_csv_import_validations_on_importer_log_id"
    t.index ["source_type", "source_id"], name: "hmis_csv_validations-ONiu"
    t.index ["type"], name: "index_hmis_csv_import_validations_on_type"
  end

  create_table "hmis_csv_importer_logs", force: :cascade do |t|
    t.integer "data_source_id", null: false
    t.jsonb "summary"
    t.string "status"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "upload_id"
    t.index ["created_at"], name: "index_hmis_csv_importer_logs_on_created_at"
    t.index ["data_source_id"], name: "index_hmis_csv_importer_logs_on_data_source_id"
    t.index ["updated_at"], name: "index_hmis_csv_importer_logs_on_updated_at"
  end

  create_table "hmis_csv_load_errors", force: :cascade do |t|
    t.integer "loader_log_id", null: false
    t.string "file_name", null: false
    t.string "message"
    t.string "details"
    t.string "source"
    t.index ["loader_log_id"], name: "index_hmis_csv_load_errors_on_loader_log_id"
  end

  create_table "hmis_csv_loader_logs", force: :cascade do |t|
    t.integer "data_source_id", null: false
    t.integer "importer_log_id"
    t.jsonb "summary"
    t.string "status"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "upload_id"
    t.index ["created_at"], name: "index_hmis_csv_loader_logs_on_created_at"
    t.index ["data_source_id"], name: "index_hmis_csv_loader_logs_on_data_source_id"
    t.index ["importer_log_id"], name: "index_hmis_csv_loader_logs_on_importer_log_id"
    t.index ["updated_at"], name: "index_hmis_csv_loader_logs_on_updated_at"
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
    t.datetime "housing_status_updated_at"
    t.datetime "pathways_updated_at"
    t.date "assessment_completed_on"
    t.integer "assessment_score"
    t.boolean "rrh_desired", default: false, null: false
    t.boolean "youth_rrh_desired", default: false, null: false
    t.string "rrh_assessment_contact_info"
    t.boolean "adult_rrh_desired", default: false, null: false
    t.boolean "rrh_th_desired", default: false, null: false
    t.boolean "income_maximization_assistance_requested", default: false, null: false
    t.integer "income_total_annual"
    t.boolean "pending_subsidized_housing_placement", default: false, null: false
    t.boolean "domestic_violence", default: false, null: false
    t.boolean "interested_in_set_asides", default: false, null: false
    t.integer "required_number_of_bedrooms"
    t.integer "required_minimum_occupancy"
    t.boolean "requires_wheelchair_accessibility", default: false, null: false
    t.boolean "requires_elevator_access", default: false, null: false
    t.string "youth_rrh_aggregate"
    t.string "dv_rrh_aggregate"
    t.boolean "veteran_rrh_desired", default: false, null: false
    t.boolean "sro_ok", default: false, null: false
    t.boolean "other_accessibility", default: false, null: false
    t.boolean "disabled_housing", default: false, null: false
    t.boolean "evicted", default: false, null: false
    t.jsonb "neighborhood_interests", default: []
    t.string "client_phones"
    t.string "client_emails"
    t.string "client_shelters"
    t.string "client_case_managers"
    t.string "client_day_shelters"
    t.string "client_night_shelters"
    t.boolean "ssvf_eligible", default: false
    t.string "vispdat_physical_disability_answer"
    t.datetime "vispdat_physical_disability_updated_at"
    t.index ["assessment_id"], name: "index_hmis_forms_on_assessment_id"
    t.index ["client_id"], name: "index_hmis_forms_on_client_id"
    t.index ["collected_at"], name: "index_hmis_forms_on_collected_at"
    t.index ["name"], name: "index_hmis_forms_on_name"
  end

  create_table "hmis_import_configs", force: :cascade do |t|
    t.bigint "data_source_id", null: false
    t.boolean "active", default: false
    t.string "s3_access_key_id", null: false
    t.string "encrypted_s3_secret_access_key", null: false
    t.string "encrypted_s3_secret_access_key_iv"
    t.string "s3_region"
    t.string "s3_bucket_name"
    t.string "s3_path"
    t.string "encrypted_zip_file_password"
    t.string "encrypted_zip_file_password_iv"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["data_source_id"], name: "index_hmis_import_configs_on_data_source_id"
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
    t.text "encrypted_import_errors"
    t.string "encrypted_import_errors_iv"
    t.index ["completed_at"], name: "index_import_logs_on_completed_at"
    t.index ["created_at"], name: "index_import_logs_on_created_at"
    t.index ["data_source_id"], name: "index_import_logs_on_data_source_id"
    t.index ["updated_at"], name: "index_import_logs_on_updated_at"
  end

  create_table "lftp_s3_syncs", force: :cascade do |t|
    t.bigint "data_source_id", null: false
    t.string "ftp_host", null: false
    t.string "ftp_user", null: false
    t.string "encrypted_ftp_pass", null: false
    t.string "encrypted_ftp_pass_iv", null: false
    t.string "ftp_path", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_lftp_s3_syncs_on_created_at"
    t.index ["data_source_id"], name: "index_lftp_s3_syncs_on_data_source_id"
    t.index ["updated_at"], name: "index_lftp_s3_syncs_on_updated_at"
  end

  create_table "lookups_ethnicities", force: :cascade do |t|
    t.integer "value", null: false
    t.string "text", null: false
    t.index ["value"], name: "index_lookups_ethnicities_on_value"
  end

  create_table "lookups_funding_sources", force: :cascade do |t|
    t.integer "value", null: false
    t.string "text", null: false
    t.index ["value"], name: "index_lookups_funding_sources_on_value"
  end

  create_table "lookups_genders", force: :cascade do |t|
    t.integer "value", null: false
    t.string "text", null: false
    t.index ["value"], name: "index_lookups_genders_on_value"
  end

  create_table "lookups_living_situations", force: :cascade do |t|
    t.integer "value", null: false
    t.string "text", null: false
    t.index ["value"], name: "index_lookups_living_situations_on_value"
  end

  create_table "lookups_project_types", force: :cascade do |t|
    t.integer "value", null: false
    t.string "text", null: false
    t.index ["value"], name: "index_lookups_project_types_on_value"
  end

  create_table "lookups_relationships", force: :cascade do |t|
    t.integer "value", null: false
    t.string "text", null: false
    t.index ["value"], name: "index_lookups_relationships_on_value"
  end

  create_table "lookups_tracking_methods", force: :cascade do |t|
    t.integer "value"
    t.string "text", null: false
    t.index ["value"], name: "index_lookups_tracking_methods_on_value"
  end

  create_table "lookups_yes_no_etcs", force: :cascade do |t|
    t.integer "value", null: false
    t.string "text", null: false
    t.index ["value"], name: "index_lookups_yes_no_etcs_on_value"
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
    t.jsonb "youth_families", default: []
    t.jsonb "family_parents", default: []
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
    t.jsonb "literally_homeless_youth_families", default: []
    t.jsonb "system_youth_families", default: []
    t.jsonb "homeless_youth_families", default: []
    t.jsonb "ph_youth_families", default: []
    t.jsonb "es_youth_families", default: []
    t.jsonb "th_youth_families", default: []
    t.jsonb "so_youth_families", default: []
    t.jsonb "sh_youth_families", default: []
    t.jsonb "literally_homeless_family_parents", default: []
    t.jsonb "system_family_parents", default: []
    t.jsonb "homeless_family_parents", default: []
    t.jsonb "ph_family_parents", default: []
    t.jsonb "es_family_parents", default: []
    t.jsonb "th_family_parents", default: []
    t.jsonb "so_family_parents", default: []
    t.jsonb "sh_family_parents", default: []
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
    t.integer "literally_homeless_youth_families", default: 0
    t.integer "system_youth_families", default: 0
    t.integer "homeless_youth_families", default: 0
    t.integer "ph_youth_families", default: 0
    t.integer "es_youth_families", default: 0
    t.integer "th_youth_families", default: 0
    t.integer "so_youth_families", default: 0
    t.integer "sh_youth_families", default: 0
    t.integer "literally_homeless_family_parents", default: 0
    t.integer "system_family_parents", default: 0
    t.integer "homeless_family_parents", default: 0
    t.integer "ph_family_parents", default: 0
    t.integer "es_family_parents", default: 0
    t.integer "th_family_parents", default: 0
    t.integer "so_family_parents", default: 0
    t.integer "sh_family_parents", default: 0
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
    t.integer "youth_families", default: 0
    t.integer "family_parents", default: 0
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
    t.index ["age"], name: "index_service_history_enrollments_on_age"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2000_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2000_client_id_only"
    t.index ["date"], name: "index_shs_2000_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2000_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2000_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2000_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2000_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2001_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2001_client_id_only"
    t.index ["date"], name: "index_shs_2001_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2001_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2001_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2001_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2001_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2002_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2002_client_id_only"
    t.index ["date"], name: "index_shs_2002_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2002_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2002_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2002_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2002_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2003_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2003_client_id_only"
    t.index ["date"], name: "index_shs_2003_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2003_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2003_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2003_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2003_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2004_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2004_client_id_only"
    t.index ["date"], name: "index_shs_2004_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2004_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2004_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2004_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2004_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2005_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2005_client_id_only"
    t.index ["date"], name: "index_shs_2005_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2005_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2005_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2005_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2005_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2006_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2006_client_id_only"
    t.index ["date"], name: "index_shs_2006_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2006_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2006_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2006_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2006_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2007_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2007_client_id_only"
    t.index ["date"], name: "index_shs_2007_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2007_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2007_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2007_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2007_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2008_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2008_client_id_only"
    t.index ["date"], name: "index_shs_2008_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2008_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2008_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2008_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2008_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2009_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2009_client_id_only"
    t.index ["date"], name: "index_shs_2009_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2009_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2009_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2009_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2009_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2010_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2010_client_id_only"
    t.index ["date"], name: "index_shs_2010_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2010_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2010_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2010_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2010_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2011_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2011_client_id_only"
    t.index ["date"], name: "index_shs_2011_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2011_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2011_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2011_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2011_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2012_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2012_client_id_only"
    t.index ["date"], name: "index_shs_2012_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2012_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2012_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2012_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2012_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2013_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2013_client_id_only"
    t.index ["date"], name: "index_shs_2013_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2013_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2013_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2013_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2013_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2014_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2014_client_id_only"
    t.index ["date"], name: "index_shs_2014_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2014_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2014_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2014_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2014_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2015_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2015_client_id_only"
    t.index ["date"], name: "index_shs_2015_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2015_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2015_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2015_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2015_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2016_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2016_client_id_only"
    t.index ["date"], name: "index_shs_2016_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2016_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2016_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2016_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2016_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2017_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2017_client_id_only"
    t.index ["date"], name: "index_shs_2017_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2017_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2017_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2017_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2017_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2018_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2018_client_id_only"
    t.index ["date"], name: "index_shs_2018_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2018_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2018_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2018_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2018_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2019_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2019_client_id_only"
    t.index ["date"], name: "index_shs_2019_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2019_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2019_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2019_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2019_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2020_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2020_client_id_only"
    t.index ["date"], name: "index_shs_2020_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2020_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2020_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2020_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2020_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2021_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2021_client_id_only"
    t.index ["date"], name: "index_shs_2021_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2021_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2021_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2021_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2021_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2022_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2022_client_id_only"
    t.index ["date"], name: "index_shs_2022_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2022_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2022_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2022_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2022_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2023_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2023_client_id_only"
    t.index ["date"], name: "index_shs_2023_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2023_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2023_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2023_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2023_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2024_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2024_client_id_only"
    t.index ["date"], name: "index_shs_2024_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2024_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2024_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2024_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2024_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2025_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2025_client_id_only"
    t.index ["date"], name: "index_shs_2025_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2025_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2025_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2025_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2025_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2026_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2026_client_id_only"
    t.index ["date"], name: "index_shs_2026_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2026_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2026_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2026_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2026_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2027_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2027_client_id_only"
    t.index ["date"], name: "index_shs_2027_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2027_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2027_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2027_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2027_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2028_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2028_client_id_only"
    t.index ["date"], name: "index_shs_2028_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2028_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2028_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2028_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2028_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2029_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2029_client_id_only"
    t.index ["date"], name: "index_shs_2029_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2029_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2029_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2029_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2029_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2030_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2030_client_id_only"
    t.index ["date"], name: "index_shs_2030_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2030_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2030_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2030_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2030_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2031_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2031_client_id_only"
    t.index ["date"], name: "index_shs_2031_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2031_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2031_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2031_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2031_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2032_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2032_client_id_only"
    t.index ["date"], name: "index_shs_2032_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2032_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2032_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2032_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2032_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2033_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2033_client_id_only"
    t.index ["date"], name: "index_shs_2033_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2033_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2033_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2033_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2033_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2034_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2034_client_id_only"
    t.index ["date"], name: "index_shs_2034_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2034_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2034_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2034_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2034_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2035_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2035_client_id_only"
    t.index ["date"], name: "index_shs_2035_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2035_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2035_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2035_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2035_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2036_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2036_client_id_only"
    t.index ["date"], name: "index_shs_2036_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2036_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2036_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2036_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2036_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2037_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2037_client_id_only"
    t.index ["date"], name: "index_shs_2037_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2037_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2037_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2037_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2037_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2038_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2038_client_id_only"
    t.index ["date"], name: "index_shs_2038_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2038_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2038_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2038_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2038_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2039_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2039_client_id_only"
    t.index ["date"], name: "index_shs_2039_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2039_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2039_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2039_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2039_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2040_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2040_client_id_only"
    t.index ["date"], name: "index_shs_2040_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2040_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2040_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2040_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2040_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2041_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2041_client_id_only"
    t.index ["date"], name: "index_shs_2041_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2041_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2041_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2041_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2041_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2042_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2042_client_id_only"
    t.index ["date"], name: "index_shs_2042_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2042_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2042_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2042_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2042_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2043_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2043_client_id_only"
    t.index ["date"], name: "index_shs_2043_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2043_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2043_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2043_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2043_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2044_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2044_client_id_only"
    t.index ["date"], name: "index_shs_2044_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2044_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2044_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2044_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2044_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2045_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2045_client_id_only"
    t.index ["date"], name: "index_shs_2045_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2045_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2045_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2045_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2045_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2046_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2046_client_id_only"
    t.index ["date"], name: "index_shs_2046_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2046_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2046_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2046_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2046_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2047_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2047_client_id_only"
    t.index ["date"], name: "index_shs_2047_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2047_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2047_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2047_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2047_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2048_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2048_client_id_only"
    t.index ["date"], name: "index_shs_2048_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2048_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2048_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2048_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2048_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2049_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2049_client_id_only"
    t.index ["date"], name: "index_shs_2049_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2049_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2049_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2049_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2049_en_id_only"
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
    t.index ["client_id", "service_history_enrollment_id"], name: "index_shs_2050_c_id_en_id"
    t.index ["client_id"], name: "index_shs_2050_client_id_only"
    t.index ["date"], name: "index_shs_2050_date_brin", using: :brin
    t.index ["id"], name: "index_service_history_services_2050_on_id", unique: true
    t.index ["project_type", "date", "record_type"], name: "index_shs_2050_date_project_type"
    t.index ["service_history_enrollment_id", "date", "record_type"], name: "index_shs_2050_date_en_id"
    t.index ["service_history_enrollment_id"], name: "index_shs_2050_en_id_only"
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

  create_table "service_scanning_scanner_ids", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.string "source_type", null: false
    t.string "scanned_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["client_id"], name: "index_service_scanning_scanner_ids_on_client_id"
    t.index ["created_at"], name: "index_service_scanning_scanner_ids_on_created_at"
    t.index ["scanned_id"], name: "index_service_scanning_scanner_ids_on_scanned_id"
    t.index ["source_type"], name: "index_service_scanning_scanner_ids_on_source_type"
    t.index ["updated_at"], name: "index_service_scanning_scanner_ids_on_updated_at"
  end

  create_table "service_scanning_services", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "project_id", null: false
    t.bigint "user_id", null: false
    t.string "type", null: false
    t.string "other_type"
    t.datetime "provided_at"
    t.string "note"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.index ["client_id"], name: "index_service_scanning_services_on_client_id"
    t.index ["created_at"], name: "index_service_scanning_services_on_created_at"
    t.index ["project_id"], name: "index_service_scanning_services_on_project_id"
    t.index ["type"], name: "index_service_scanning_services_on_type"
    t.index ["updated_at"], name: "index_service_scanning_services_on_updated_at"
    t.index ["user_id"], name: "index_service_scanning_services_on_user_id"
  end

  create_table "shape_cocs", force: :cascade do |t|
    t.string "st"
    t.string "state_name"
    t.string "cocnum"
    t.string "cocname"
    t.decimal "ard"
    t.decimal "pprn"
    t.decimal "fprn"
    t.string "fprn_statu"
    t.decimal "es_c_hwac"
    t.decimal "es_c_hwoa_"
    t.decimal "es_c_hwoc"
    t.decimal "es_vso_tot"
    t.decimal "th_c_hwac_"
    t.decimal "th_c_hwoa"
    t.decimal "th_c_hwoc"
    t.decimal "th_c_vet"
    t.decimal "rrh_c_hwac"
    t.decimal "rrh_c_hwoa"
    t.decimal "rrh_c_hwoc"
    t.decimal "rrh_c_vet"
    t.decimal "psh_c_hwac"
    t.decimal "psh_c_hwoa"
    t.decimal "psh_c_hwoc"
    t.decimal "psh_c_vet"
    t.decimal "psh_c_ch"
    t.string "psh_u_hwac"
    t.string "psh_u_hwoa"
    t.string "psh_u_hwoc"
    t.string "psh_u_vet"
    t.string "psh_u_ch"
    t.decimal "sh_c_hwoa"
    t.decimal "sh_c_vet"
    t.decimal "sh_pers_hw"
    t.decimal "unsh_pers_"
    t.decimal "sh_pers__1"
    t.decimal "unsh_pers1"
    t.decimal "sh_pers__2"
    t.decimal "unsh_per_1"
    t.decimal "sh_ch"
    t.decimal "unsh_ch"
    t.decimal "sh_youth_u"
    t.decimal "unsh_youth"
    t.decimal "sh_vets"
    t.decimal "unsh_vets"
    t.decimal "shape_leng"
    t.decimal "shape_area"
    t.geometry "orig_geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.geometry "geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.index ["cocname"], name: "index_shape_cocs_on_cocname"
    t.index ["geom"], name: "index_shape_cocs_on_geom", using: :gist
    t.index ["orig_geom"], name: "index_shape_cocs_on_orig_geom", using: :gist
    t.index ["st"], name: "index_shape_cocs_on_st"
  end

  create_table "shape_zip_codes", force: :cascade do |t|
    t.string "zcta5ce10", limit: 5
    t.string "geoid10", limit: 5
    t.string "classfp10", limit: 2
    t.string "mtfcc10", limit: 5
    t.string "funcstat10", limit: 1
    t.float "aland10"
    t.float "awater10"
    t.string "intptlat10", limit: 11
    t.string "intptlon10", limit: 12
    t.geometry "orig_geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.geometry "geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.index ["geom"], name: "index_shape_zip_codes_on_geom", using: :gist
    t.index ["orig_geom"], name: "index_shape_zip_codes_on_orig_geom", using: :gist
    t.index ["zcta5ce10"], name: "index_shape_zip_codes_on_zcta5ce10", unique: true
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

  create_table "talentlms_configs", force: :cascade do |t|
    t.string "subdomain"
    t.string "encrypted_api_key"
    t.string "encrypted_api_key_iv"
    t.integer "courseid"
  end

  create_table "talentlms_logins", force: :cascade do |t|
    t.bigint "user_id"
    t.string "login"
    t.string "encrypted_password"
    t.string "encrypted_password_iv"
    t.integer "lms_user_id"
    t.index ["user_id"], name: "index_talentlms_logins_on_user_id"
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
    t.text "encrypted_content"
    t.string "encrypted_content_iv"
    t.index ["deleted_at"], name: "index_uploads_on_deleted_at"
  end

  create_table "user_client_permissions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "client_id", null: false
    t.boolean "viewable", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_user_client_permissions_on_client_id"
    t.index ["user_id"], name: "index_user_client_permissions_on_user_id"
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
    t.index ["data_source_id"], name: "index_warehouse_clients_on_data_source_id"
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
    t.index ["client_id"], name: "index_warehouse_clients_processed_on_client_id"
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
    t.datetime "deleted_at"
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
    t.boolean "imported", default: false
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
    t.string "other_agency_involvement"
    t.string "owns_cell_phone"
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
    t.boolean "imported", default: false
    t.string "first_name"
    t.string "last_name"
    t.string "ssn"
    t.json "other_agency_involvements", default: []
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
    t.boolean "imported", default: false
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

  create_view "bi_Organization", sql_definition: <<-SQL
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
     FROM "Organization"
    WHERE ("Organization"."DateDeleted" IS NULL);
  SQL
  create_view "bi_Project", sql_definition: <<-SQL
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
     FROM ("Project"
       JOIN "Organization" ON ((("Project".data_source_id = "Organization".data_source_id) AND (("Project"."OrganizationID")::text = ("Organization"."OrganizationID")::text) AND ("Organization"."DateDeleted" IS NULL))))
    WHERE ("Project"."DateDeleted" IS NULL);
  SQL
  create_view "bi_ProjectCoC", sql_definition: <<-SQL
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
     FROM ("ProjectCoC"
       JOIN "Project" ON ((("ProjectCoC".data_source_id = "Project".data_source_id) AND (("ProjectCoC"."ProjectID")::text = ("Project"."ProjectID")::text) AND ("Project"."DateDeleted" IS NULL))))
    WHERE ("ProjectCoC"."DateDeleted" IS NULL);
  SQL
  create_view "bi_Affiliation", sql_definition: <<-SQL
      SELECT "Affiliation".id AS "AffiliationID",
      "Project".id AS "ProjectID",
      "Affiliation"."ResProjectID",
      "Affiliation"."DateCreated",
      "Affiliation"."DateUpdated",
      "Affiliation"."UserID",
      "Affiliation"."DateDeleted",
      "Affiliation"."ExportID",
      "Affiliation".data_source_id
     FROM ("Affiliation"
       JOIN "Project" ON ((("Affiliation".data_source_id = "Project".data_source_id) AND (("Affiliation"."ProjectID")::text = ("Project"."ProjectID")::text) AND ("Project"."DateDeleted" IS NULL))))
    WHERE ("Affiliation"."DateDeleted" IS NULL);
  SQL
  create_view "bi_Export", sql_definition: <<-SQL
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
     FROM "Export";
  SQL
  create_view "bi_Inventory", sql_definition: <<-SQL
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
     FROM ("Inventory"
       JOIN "Project" ON ((("Inventory".data_source_id = "Project".data_source_id) AND (("Inventory"."ProjectID")::text = ("Project"."ProjectID")::text) AND ("Project"."DateDeleted" IS NULL))))
    WHERE ("Inventory"."DateDeleted" IS NULL);
  SQL
  create_view "bi_Funder", sql_definition: <<-SQL
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
     FROM ("Funder"
       JOIN "Project" ON ((("Funder".data_source_id = "Project".data_source_id) AND (("Funder"."ProjectID")::text = ("Project"."ProjectID")::text) AND ("Project"."DateDeleted" IS NULL))))
    WHERE ("Funder"."DateDeleted" IS NULL);
  SQL
  create_view "bi_Services", sql_definition: <<-SQL
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
     FROM ((((("Services"
       JOIN "Enrollment" ON ((("Services".data_source_id = "Enrollment".data_source_id) AND (("Services"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
       LEFT JOIN "Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
       JOIN "Client" source_clients ON ((("Services".data_source_id = source_clients.data_source_id) AND (("Services"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
    WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("Services"."DateProvided" >= (CURRENT_DATE - '5 years'::interval)) AND ("Services"."DateDeleted" IS NULL)));
  SQL
  create_view "bi_Exit", sql_definition: <<-SQL
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
     FROM (((("Exit"
       JOIN "Enrollment" ON ((("Exit".data_source_id = "Enrollment".data_source_id) AND (("Exit"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
       JOIN "Client" source_clients ON ((("Exit".data_source_id = source_clients.data_source_id) AND (("Exit"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
    WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("Exit"."DateDeleted" IS NULL)));
  SQL
  create_view "bi_EnrollmentCoC", sql_definition: <<-SQL
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
     FROM (((((("EnrollmentCoC"
       JOIN "Project" ON ((("EnrollmentCoC".data_source_id = "Project".data_source_id) AND (("EnrollmentCoC"."ProjectID")::text = ("Project"."ProjectID")::text) AND ("Project"."DateDeleted" IS NULL))))
       JOIN "Enrollment" ON ((("EnrollmentCoC".data_source_id = "Enrollment".data_source_id) AND (("EnrollmentCoC"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
       LEFT JOIN "Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
       JOIN "Client" source_clients ON ((("EnrollmentCoC".data_source_id = source_clients.data_source_id) AND (("EnrollmentCoC"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
    WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("EnrollmentCoC"."DateDeleted" IS NULL)));
  SQL
  create_view "bi_Disabilities", sql_definition: <<-SQL
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
     FROM ((((("Disabilities"
       JOIN "Enrollment" ON ((("Disabilities".data_source_id = "Enrollment".data_source_id) AND (("Disabilities"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
       LEFT JOIN "Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
       JOIN "Client" source_clients ON ((("Disabilities".data_source_id = source_clients.data_source_id) AND (("Disabilities"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
    WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("Disabilities"."DateDeleted" IS NULL)));
  SQL
  create_view "bi_HealthAndDV", sql_definition: <<-SQL
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
     FROM ((((("HealthAndDV"
       JOIN "Enrollment" ON ((("HealthAndDV".data_source_id = "Enrollment".data_source_id) AND (("HealthAndDV"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
       LEFT JOIN "Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
       JOIN "Client" source_clients ON ((("HealthAndDV".data_source_id = source_clients.data_source_id) AND (("HealthAndDV"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
    WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("HealthAndDV"."DateDeleted" IS NULL)));
  SQL
  create_view "bi_IncomeBenefits", sql_definition: <<-SQL
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
     FROM ((((("IncomeBenefits"
       JOIN "Enrollment" ON ((("IncomeBenefits".data_source_id = "Enrollment".data_source_id) AND (("IncomeBenefits"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
       LEFT JOIN "Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
       JOIN "Client" source_clients ON ((("IncomeBenefits".data_source_id = source_clients.data_source_id) AND (("IncomeBenefits"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
    WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("IncomeBenefits"."DateDeleted" IS NULL)));
  SQL
  create_view "bi_EmploymentEducation", sql_definition: <<-SQL
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
     FROM ((((("EmploymentEducation"
       JOIN "Enrollment" ON ((("EmploymentEducation".data_source_id = "Enrollment".data_source_id) AND (("EmploymentEducation"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
       LEFT JOIN "Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
       JOIN "Client" source_clients ON ((("EmploymentEducation".data_source_id = source_clients.data_source_id) AND (("EmploymentEducation"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
    WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("EmploymentEducation"."DateDeleted" IS NULL)));
  SQL
  create_view "bi_CurrentLivingSituation", sql_definition: <<-SQL
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
     FROM ((((("CurrentLivingSituation"
       JOIN "Enrollment" ON ((("CurrentLivingSituation".data_source_id = "Enrollment".data_source_id) AND (("CurrentLivingSituation"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
       LEFT JOIN "Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
       JOIN "Client" source_clients ON ((("CurrentLivingSituation".data_source_id = source_clients.data_source_id) AND (("CurrentLivingSituation"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
    WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("CurrentLivingSituation"."DateDeleted" IS NULL)));
  SQL
  create_view "bi_Event", sql_definition: <<-SQL
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
     FROM ((((("Event"
       JOIN "Enrollment" ON ((("Event".data_source_id = "Enrollment".data_source_id) AND (("Event"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
       LEFT JOIN "Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
       JOIN "Client" source_clients ON ((("Event".data_source_id = source_clients.data_source_id) AND (("Event"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
    WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("Event"."DateDeleted" IS NULL)));
  SQL
  create_view "bi_Assessment", sql_definition: <<-SQL
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
     FROM ((((("Assessment"
       JOIN "Enrollment" ON ((("Assessment".data_source_id = "Enrollment".data_source_id) AND (("Assessment"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
       LEFT JOIN "Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
       JOIN "Client" source_clients ON ((("Assessment".data_source_id = source_clients.data_source_id) AND (("Assessment"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
    WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("Assessment"."DateDeleted" IS NULL)));
  SQL
  create_view "bi_AssessmentQuestions", sql_definition: <<-SQL
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
     FROM (((((("AssessmentQuestions"
       JOIN "Enrollment" ON ((("AssessmentQuestions".data_source_id = "Enrollment".data_source_id) AND (("AssessmentQuestions"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
       LEFT JOIN "Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
       JOIN "Client" source_clients ON ((("AssessmentQuestions".data_source_id = source_clients.data_source_id) AND (("AssessmentQuestions"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Assessment" ON ((("AssessmentQuestions".data_source_id = "Assessment".data_source_id) AND (("AssessmentQuestions"."AssessmentID")::text = ("Assessment"."AssessmentID")::text) AND ("Assessment"."DateDeleted" IS NULL))))
    WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("AssessmentQuestions"."DateDeleted" IS NULL)));
  SQL
  create_view "bi_AssessmentResults", sql_definition: <<-SQL
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
     FROM (((((("AssessmentResults"
       JOIN "Enrollment" ON ((("AssessmentResults".data_source_id = "Enrollment".data_source_id) AND (("AssessmentResults"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Enrollment"."DateDeleted" IS NULL))))
       LEFT JOIN "Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
       JOIN "Client" source_clients ON ((("AssessmentResults".data_source_id = source_clients.data_source_id) AND (("AssessmentResults"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
       JOIN "Assessment" ON ((("AssessmentResults".data_source_id = "Assessment".data_source_id) AND (("AssessmentResults"."AssessmentID")::text = ("Assessment"."AssessmentID")::text) AND ("Assessment"."DateDeleted" IS NULL))))
    WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("AssessmentResults"."DateDeleted" IS NULL)));
  SQL
  create_view "bi_Client", sql_definition: <<-SQL
      SELECT "Client".id AS personalid,
      4 AS "HashStatus",
      encode(sha256((soundex(upper(btrim(("Client"."FirstName")::text))))::bytea), 'hex'::text) AS "FirstName",
      encode(sha256((soundex(upper(btrim(("Client"."MiddleName")::text))))::bytea), 'hex'::text) AS "MiddleName",
      encode(sha256((soundex(upper(btrim(("Client"."LastName")::text))))::bytea), 'hex'::text) AS "LastName",
      encode(sha256((soundex(upper(btrim(("Client"."NameSuffix")::text))))::bytea), 'hex'::text) AS "NameSuffix",
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
     FROM "Client"
    WHERE (("Client"."DateDeleted" IS NULL) AND ("Client".data_source_id IN ( SELECT data_sources.id
             FROM data_sources
            WHERE ((data_sources.deleted_at IS NULL) AND (data_sources.source_type IS NULL) AND (data_sources.authoritative = false)))));
  SQL
  create_view "bi_Demographics", sql_definition: <<-SQL
      SELECT "Client".id AS personalid,
      4 AS "HashStatus",
      encode(sha256((soundex(upper(btrim(("Client"."FirstName")::text))))::bytea), 'hex'::text) AS "FirstName",
      encode(sha256((soundex(upper(btrim(("Client"."MiddleName")::text))))::bytea), 'hex'::text) AS "MiddleName",
      encode(sha256((soundex(upper(btrim(("Client"."LastName")::text))))::bytea), 'hex'::text) AS "LastName",
      encode(sha256((soundex(upper(btrim(("Client"."NameSuffix")::text))))::bytea), 'hex'::text) AS "NameSuffix",
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
     FROM ("Client"
       JOIN warehouse_clients ON ((warehouse_clients.source_id = "Client".id)))
    WHERE (("Client"."DateDeleted" IS NULL) AND ("Client".data_source_id IN ( SELECT data_sources.id
             FROM data_sources
            WHERE ((data_sources.deleted_at IS NULL) AND ((data_sources.source_type IS NOT NULL) OR (data_sources.authoritative = true))))));
  SQL
  create_view "bi_Enrollment", sql_definition: <<-SQL
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
     FROM ((((("Enrollment"
       JOIN "Project" ON ((("Enrollment".data_source_id = "Project".data_source_id) AND (("Enrollment"."ProjectID")::text = ("Project"."ProjectID")::text) AND ("Project"."DateDeleted" IS NULL))))
       JOIN "Exit" ON ((("Enrollment".data_source_id = "Exit".data_source_id) AND (("Enrollment"."EnrollmentID")::text = ("Exit"."EnrollmentID")::text) AND ("Exit"."DateDeleted" IS NULL))))
       JOIN "Client" source_clients ON ((("Enrollment".data_source_id = source_clients.data_source_id) AND (("Enrollment"."PersonalID")::text = (source_clients."PersonalID")::text) AND (source_clients."DateDeleted" IS NULL))))
       JOIN warehouse_clients ON ((source_clients.id = warehouse_clients.source_id)))
       JOIN "Client" destination_clients ON (((destination_clients.id = warehouse_clients.destination_id) AND (destination_clients."DateDeleted" IS NULL))))
    WHERE (("Exit"."ExitDate" IS NULL) OR (("Exit"."ExitDate" >= (CURRENT_DATE - '5 years'::interval)) AND ("Enrollment"."DateDeleted" IS NULL)));
  SQL
  create_view "bi_service_history_services", sql_definition: <<-SQL
      SELECT service_history_services.id,
      service_history_services.service_history_enrollment_id,
      service_history_services.record_type,
      service_history_services.date,
      service_history_services.age,
      service_history_services.client_id,
      service_history_services.project_type
     FROM (service_history_services
       JOIN "Client" ON ((("Client"."DateDeleted" IS NULL) AND ("Client".id = service_history_services.client_id))))
    WHERE (service_history_services.date >= (CURRENT_DATE - '5 years'::interval));
  SQL
  create_view "bi_service_history_enrollments", sql_definition: <<-SQL
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
     FROM (((service_history_enrollments
       JOIN "Client" ON ((("Client"."DateDeleted" IS NULL) AND ("Client".id = service_history_enrollments.client_id))))
       JOIN "Project" ON ((("Project"."DateDeleted" IS NULL) AND ("Project".data_source_id = service_history_enrollments.data_source_id) AND (("Project"."ProjectID")::text = (service_history_enrollments.project_id)::text) AND (("Project"."OrganizationID")::text = (service_history_enrollments.organization_id)::text))))
       JOIN "Enrollment" ON ((("Enrollment"."DateDeleted" IS NULL) AND ("Enrollment".data_source_id = service_history_enrollments.data_source_id) AND (("Enrollment"."EnrollmentID")::text = (service_history_enrollments.enrollment_group_id)::text) AND (("Enrollment"."ProjectID")::text = (service_history_enrollments.project_id)::text))))
    WHERE (((service_history_enrollments.record_type)::text = 'entry'::text) AND ((service_history_enrollments.last_date_in_program IS NULL) OR (service_history_enrollments.last_date_in_program >= (CURRENT_DATE - '5 years'::interval))));
  SQL
  create_view "bi_data_sources", sql_definition: <<-SQL
      SELECT data_sources.id,
      data_sources.name,
      data_sources.short_name
     FROM data_sources
    WHERE ((data_sources.deleted_at IS NULL) AND (data_sources.deleted_at IS NULL));
  SQL
  create_view "bi_lookups_ethnicities", sql_definition: <<-SQL
      SELECT lookups_ethnicities.id,
      lookups_ethnicities.value,
      lookups_ethnicities.text
     FROM lookups_ethnicities;
  SQL
  create_view "bi_lookups_funding_sources", sql_definition: <<-SQL
      SELECT lookups_funding_sources.id,
      lookups_funding_sources.value,
      lookups_funding_sources.text
     FROM lookups_funding_sources;
  SQL
  create_view "bi_lookups_genders", sql_definition: <<-SQL
      SELECT lookups_genders.id,
      lookups_genders.value,
      lookups_genders.text
     FROM lookups_genders;
  SQL
  create_view "bi_lookups_living_situations", sql_definition: <<-SQL
      SELECT lookups_living_situations.id,
      lookups_living_situations.value,
      lookups_living_situations.text
     FROM lookups_living_situations;
  SQL
  create_view "bi_lookups_project_types", sql_definition: <<-SQL
      SELECT lookups_project_types.id,
      lookups_project_types.value,
      lookups_project_types.text
     FROM lookups_project_types;
  SQL
  create_view "bi_lookups_relationships", sql_definition: <<-SQL
      SELECT lookups_relationships.id,
      lookups_relationships.value,
      lookups_relationships.text
     FROM lookups_relationships;
  SQL
  create_view "bi_lookups_tracking_methods", sql_definition: <<-SQL
      SELECT lookups_tracking_methods.id,
      lookups_tracking_methods.value,
      lookups_tracking_methods.text
     FROM lookups_tracking_methods;
  SQL
  create_view "bi_lookups_yes_no_etcs", sql_definition: <<-SQL
      SELECT lookups_yes_no_etcs.id,
      lookups_yes_no_etcs.value,
      lookups_yes_no_etcs.text
     FROM lookups_yes_no_etcs;
  SQL
  create_view "bi_nightly_census_by_projects", sql_definition: <<-SQL
      SELECT nightly_census_by_projects.id,
      nightly_census_by_projects.date,
      nightly_census_by_projects.project_id,
      nightly_census_by_projects.veterans,
      nightly_census_by_projects.non_veterans,
      nightly_census_by_projects.children,
      nightly_census_by_projects.adults,
      nightly_census_by_projects.all_clients,
      nightly_census_by_projects.beds
     FROM nightly_census_by_projects;
  SQL
end
