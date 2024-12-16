# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2024_12_03_154146) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "hstore"
  enable_extension "pg_trgm"
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "postgis"
  enable_extension "unaccent"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "census_levels", ["STATE", "COUNTY", "PLACE", "SLDU", "SLDL", "ZCTA5", "TRACT", "BG", "TABBLOCK", "CUSTOM", "CUSTOMTOWN"]
  create_enum "record_action", ["added", "updated", "unchanged", "removed"]
  create_enum "record_type", ["first", "entry", "exit", "service", "extrapolated"]

  create_function :f_unaccent, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.f_unaccent(text)
       RETURNS text
       LANGUAGE sql
       IMMUTABLE PARALLEL SAFE STRICT
      AS $function$
      SELECT public.unaccent('public.unaccent', $1)  -- schema-qualify function and dictionary
      $function$
  SQL
  create_function :service_history_service_insert_trigger, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.service_history_service_insert_trigger()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
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
          $function$
  SQL

  create_table "Affiliation", id: :serial, force: :cascade do |t|
    t.string "AffiliationID"
    t.string "ProjectID"
    t.string "ResProjectID"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "source_hash"
    t.datetime "pending_date_deleted", precision: nil
    t.index ["AffiliationID", "data_source_id"], name: "index_Affiliation_on_AffiliationID_and_data_source_id", unique: true
    t.index ["DateCreated"], name: "affiliation_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Affiliation_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "affiliation_date_updated"
    t.index ["ExportID"], name: "affiliation_export_id"
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
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.string "UserID", limit: 32, null: false
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.datetime "pending_date_deleted", precision: nil
    t.string "source_hash"
    t.boolean "synthetic", default: false
    t.index ["AssessmentID", "data_source_id"], name: "index_Assessment_on_AssessmentID_and_data_source_id", unique: true
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
    t.string "AssessmentAnswer", limit: 500
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.string "UserID", limit: 32, null: false
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.datetime "pending_date_deleted", precision: nil
    t.string "source_hash"
    t.index ["AssessmentID", "data_source_id", "PersonalID", "EnrollmentID", "AssessmentQuestionID"], name: "assessment_q_a_id_ds_id_p_id_en_id_aq_id"
    t.index ["AssessmentQuestionID", "data_source_id"], name: "aq_aq_id_ds_id", unique: true
    t.index ["pending_date_deleted"], name: "index_AssessmentQuestions_on_pending_date_deleted"
  end

  create_table "AssessmentResults", id: :serial, force: :cascade do |t|
    t.string "AssessmentResultID", limit: 32, null: false
    t.string "AssessmentID", limit: 32, null: false
    t.string "EnrollmentID", null: false
    t.string "PersonalID", null: false
    t.string "AssessmentResultType"
    t.string "AssessmentResult"
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.string "UserID", limit: 32, null: false
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.datetime "pending_date_deleted", precision: nil
    t.string "source_hash"
    t.index ["AssessmentID", "data_source_id", "PersonalID", "EnrollmentID", "AssessmentResultID"], name: "assessment_r_a_id_ds_id_p_id_en_id_ar_id"
    t.index ["AssessmentResultID", "data_source_id"], name: "ar_ar_id_ds_id", unique: true
    t.index ["pending_date_deleted"], name: "index_AssessmentResults_on_pending_date_deleted"
  end

  create_table "CEParticipation", force: :cascade do |t|
    t.string "CEParticipationID", null: false
    t.string "ProjectID", null: false
    t.integer "AccessPoint"
    t.integer "PreventionAssessment"
    t.integer "CrisisAssessment"
    t.integer "HousingAssessment"
    t.integer "DirectServices"
    t.integer "ReceivesReferrals"
    t.date "CEParticipationStatusStartDate"
    t.date "CEParticipationStatusEndDate"
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.datetime "DateDeleted", precision: nil
    t.string "UserID"
    t.string "ExportID"
    t.integer "data_source_id"
    t.date "pending_date_deleted"
    t.string "source_hash"
    t.index ["CEParticipationID"], name: "index_CEParticipation_on_CEParticipationID"
    t.index ["ProjectID"], name: "index_CEParticipation_on_ProjectID"
    t.index ["data_source_id", "CEParticipationID"], name: "ds_ceparticipation_idx", unique: true
  end

  create_table "Client", id: :serial, force: :cascade do |t|
    t.string "PersonalID", null: false
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "disability_verified_on", precision: nil
    t.datetime "housing_assistance_network_released_on", precision: nil
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
    t.datetime "api_update_started_at", precision: nil
    t.datetime "api_last_updated_at", precision: nil
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
    t.datetime "rrh_assessment_collected_at", precision: nil
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
    t.datetime "pending_date_deleted", precision: nil
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
    t.integer "Female"
    t.integer "Male"
    t.integer "GenderOther"
    t.integer "Transgender"
    t.integer "Questioning"
    t.integer "GenderNone"
    t.integer "NativeHIPacific"
    t.integer "NoSingleGender"
    t.integer "tc_hat_additional_days_homeless", default: 0
    t.string "pronouns"
    t.string "sexual_orientation"
    t.bigint "health_housing_navigator_id"
    t.boolean "encampment_decomissioned", default: false, null: false
    t.boolean "va_verified_veteran", default: false
    t.integer "HispanicLatinaeo"
    t.integer "MidEastNAfrican"
    t.string "AdditionalRaceEthnicity"
    t.integer "Woman"
    t.integer "Man"
    t.integer "NonBinary"
    t.integer "CulturallySpecific"
    t.integer "DifferentIdentity"
    t.string "DifferentIdentityText"
    t.virtual "search_name_full", type: :string, as: "f_unaccent((((((COALESCE(\"FirstName\", ''::character varying))::text || ' '::text) || (COALESCE(\"MiddleName\", ''::character varying))::text) || ' '::text) || (COALESCE(\"LastName\", ''::character varying))::text))", stored: true
    t.virtual "search_name_last", type: :string, as: "f_unaccent((\"LastName\")::text)", stored: true
    t.integer "lock_version", default: 0, null: false
    t.index ["AmIndAKNative"], name: "index_Client_on_AmIndAKNative"
    t.index ["Asian"], name: "index_Client_on_Asian"
    t.index ["BlackAfAmerican"], name: "index_Client_on_BlackAfAmerican"
    t.index ["DateCreated"], name: "client_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Client_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "client_date_updated"
    t.index ["ExportID"], name: "client_export_id"
    t.index ["Female"], name: "index_Client_on_Female"
    t.index ["FirstName"], name: "client_first_name"
    t.index ["GenderNone"], name: "index_Client_on_GenderNone"
    t.index ["LastName"], name: "client_last_name"
    t.index ["Male"], name: "index_Client_on_Male"
    t.index ["NativeHIOtherPacific"], name: "index_Client_on_NativeHIOtherPacific"
    t.index ["NativeHIPacific"], name: "index_Client_on_NativeHIPacific"
    t.index ["NoSingleGender"], name: "index_Client_on_NoSingleGender"
    t.index ["PersonalID"], name: "client_personal_id"
    t.index ["Questioning"], name: "index_Client_on_Questioning"
    t.index ["RaceNone"], name: "index_Client_on_RaceNone"
    t.index ["Transgender"], name: "index_Client_on_Transgender"
    t.index ["White"], name: "index_Client_on_White"
    t.index ["creator_id"], name: "index_Client_on_creator_id"
    t.index ["data_source_id"], name: "index_Client_on_data_source_id"
    t.index ["health_housing_navigator_id"], name: "index_Client_on_health_housing_navigator_id"
    t.index ["pending_date_deleted"], name: "index_Client_on_pending_date_deleted"
    t.index ["search_name_full"], name: "idx_client_name_full_gin", opclass: :gin_trgm_ops, using: :gin
    t.index ["search_name_last"], name: "idx_client_name_last_gin", opclass: :gin_trgm_ops, using: :gin
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.datetime "disability_verified_on", precision: nil
    t.datetime "housing_assistance_network_released_on", precision: nil
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
    t.datetime "api_update_started_at", precision: nil
    t.datetime "api_last_updated_at", precision: nil
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
    t.datetime "rrh_assessment_collected_at", precision: nil
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
    t.datetime "pending_date_deleted", precision: nil
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
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.string "UserID", limit: 32, null: false
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.datetime "pending_date_deleted", precision: nil
    t.string "source_hash"
    t.integer "CLSSubsidyType"
    t.bigint "verified_by_project_id"
    t.index ["CurrentLivingSitID", "data_source_id"], name: "cur_liv_sit_cur_id_ds_id"
    t.index ["CurrentLivingSitID", "data_source_id"], name: "cur_liv_sit_sit_id_ds_id", unique: true
    t.index ["PersonalID", "EnrollmentID", "data_source_id", "CurrentLivingSitID"], name: "cur_liv_sit_p_id_en_id_ds_id_cur_id"
    t.index ["pending_date_deleted"], name: "index_CurrentLivingSituation_on_pending_date_deleted"
    t.index ["verified_by_project_id"], name: "index_CurrentLivingSituation_on_verified_by_project_id"
  end

  create_table "CustomAssessments", force: :cascade do |t|
    t.string "CustomAssessmentID", null: false
    t.string "EnrollmentID", null: false
    t.string "PersonalID", null: false
    t.string "UserID", limit: 32, null: false
    t.date "AssessmentDate", null: false
    t.integer "DataCollectionStage", null: false, comment: "One of the HMIS 5.03.1, or 99 for local use"
    t.integer "data_source_id"
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.datetime "DateDeleted", precision: nil
    t.boolean "wip", default: false, null: false
    t.integer "lock_version", default: 0, null: false
    t.bigint "created_by_hud_user_id"
    t.bigint "updated_by_hud_user_id"
    t.index ["created_by_hud_user_id"], name: "index_CustomAssessments_on_created_by_hud_user_id"
    t.index ["updated_by_hud_user_id"], name: "index_CustomAssessments_on_updated_by_hud_user_id"
  end

  create_table "CustomCaseNote", force: :cascade do |t|
    t.string "CustomCaseNoteID", null: false
    t.string "PersonalID", null: false
    t.string "EnrollmentID"
    t.bigint "data_source_id", null: false
    t.text "content", null: false
    t.string "UserID"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.datetime "DateDeleted", precision: nil
    t.date "information_date"
    t.index ["EnrollmentID"], name: "index_CustomCaseNote_on_EnrollmentID"
    t.index ["PersonalID"], name: "index_CustomCaseNote_on_PersonalID"
    t.index ["UserID"], name: "index_CustomCaseNote_on_UserID"
    t.index ["data_source_id", "CustomCaseNoteID"], name: "idxCustomCaseNoteOnID", unique: true
  end

  create_table "CustomClientAddress", force: :cascade do |t|
    t.string "use"
    t.string "address_type"
    t.string "line1"
    t.string "line2"
    t.string "city"
    t.string "state"
    t.string "district"
    t.string "country"
    t.string "postal_code"
    t.string "notes"
    t.string "AddressID", null: false
    t.string "PersonalID", null: false
    t.string "UserID", limit: 32, null: false
    t.integer "data_source_id"
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.datetime "DateDeleted", precision: nil
    t.string "EnrollmentID"
    t.string "enrollment_address_type"
    t.index ["data_source_id", "EnrollmentID"], name: "index_CustomClientAddress_on_data_source_id_and_EnrollmentID", unique: true, where: "(((enrollment_address_type)::text = 'move_in'::text) AND (\"DateDeleted\" IS NULL))"
  end

  create_table "CustomClientAssessments", force: :cascade do |t|
    t.string "CustomClientAssessmentID", null: false
    t.string "PersonalID", null: false
    t.string "UserID", limit: 32, null: false
    t.date "InformationDate", null: false
    t.integer "data_source_id"
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.datetime "DateDeleted", precision: nil
  end

  create_table "CustomClientContactPoint", force: :cascade do |t|
    t.string "use"
    t.string "system"
    t.string "value"
    t.string "notes"
    t.string "ContactPointID", null: false
    t.string "PersonalID", null: false
    t.string "UserID", limit: 32, null: false
    t.integer "data_source_id"
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.datetime "DateDeleted", precision: nil
  end

  create_table "CustomClientName", force: :cascade do |t|
    t.string "first"
    t.string "middle"
    t.string "last"
    t.string "suffix"
    t.string "use"
    t.text "notes"
    t.boolean "primary"
    t.integer "NameDataQuality"
    t.string "CustomClientNameID", null: false
    t.string "PersonalID", null: false
    t.string "UserID", limit: 32, null: false
    t.integer "data_source_id"
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.datetime "DateDeleted", precision: nil
    t.virtual "search_name_full", type: :string, as: "f_unaccent((((((COALESCE(first, ''::character varying))::text || ' '::text) || (COALESCE(middle, ''::character varying))::text) || ' '::text) || (COALESCE(last, ''::character varying))::text))", stored: true
    t.virtual "search_name_last", type: :string, as: "f_unaccent((last)::text)", stored: true
    t.index ["search_name_full"], name: "idx_client_custom_names_full_idx", opclass: :gin_trgm_ops, using: :gin
    t.index ["search_name_last"], name: "idx_client_custom_names_last_idx", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "CustomDataElementDefinitions", force: :cascade do |t|
    t.string "owner_type", null: false, comment: "Record that this type of data element must be associated with"
    t.bigint "custom_service_type_id", comment: "Service type that this type of data element must be associated with"
    t.string "field_type", null: false, comment: "Type of element (string, integer, etc)"
    t.string "key", null: false, comment: "Machine-readable key for this type of data element. Will be used by the FormDefinition that collects/displays it."
    t.string "label", null: false, comment: "Human-readable label to use when displaying this type of data element."
    t.boolean "repeats", default: false, null: false, comment: "Whether multiple values are allowed per record."
    t.integer "data_source_id"
    t.string "UserID", limit: 32, null: false
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.datetime "DateDeleted", precision: nil
    t.boolean "show_in_summary", default: false, null: false, comment: "Whether to show this custom field in summary views such as in a table row when viewing a Service/CLS/Note"
    t.string "form_definition_identifier"
    t.index ["custom_service_type_id"], name: "index_CustomDataElementDefinitions_on_custom_service_type_id"
    t.index ["form_definition_identifier"], name: "idx_CustomDataElementDefinitions_1"
    t.index ["key"], name: "index_CustomDataElementDefinitions_on_key"
    t.index ["owner_type", "key"], name: "unique_index_ensuring_one_key_per_record_type", unique: true
    t.index ["owner_type"], name: "index_CustomDataElementDefinitions_on_owner_type"
  end

  create_table "CustomDataElements", force: :cascade do |t|
    t.bigint "data_element_definition_id", null: false, comment: "Definition for this data element"
    t.string "owner_type", null: false
    t.bigint "owner_id", null: false, comment: "Record that this data element belongs to (Client, Project, CustomAssessment, etc)"
    t.float "value_float"
    t.integer "value_integer"
    t.boolean "value_boolean"
    t.string "value_string"
    t.text "value_text"
    t.date "value_date"
    t.jsonb "value_json"
    t.integer "data_source_id"
    t.string "UserID", limit: 32, null: false
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.datetime "DateDeleted", precision: nil
    t.index ["data_element_definition_id"], name: "index_CustomDataElements_on_data_element_definition_id"
    t.index ["owner_type", "owner_id"], name: "index_CustomDataElements_on_owner"
  end

  create_table "CustomProjectAssessments", force: :cascade do |t|
    t.string "CustomProjectAssessmentID", null: false
    t.string "ProjectID", null: false
    t.string "UserID", limit: 32, null: false
    t.date "InformationDate", null: false
    t.integer "data_source_id"
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.datetime "DateDeleted", precision: nil
  end

  create_table "CustomServiceCategories", force: :cascade do |t|
    t.string "name", null: false, comment: "Name of service category (eg Financial Assistance)"
    t.string "UserID", limit: 32, null: false
    t.integer "data_source_id"
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.datetime "DateDeleted", precision: nil
  end

  create_table "CustomServiceTypes", force: :cascade do |t|
    t.string "name", null: false, comment: "Name of this service (eg HAP Rental Assistance)"
    t.bigint "custom_service_category_id", comment: "Category that this service belongs to"
    t.integer "hud_record_type", comment: "Only applicable if this is a HUD service"
    t.integer "hud_type_provided", comment: "Only applicable if this is a HUD service"
    t.string "UserID", limit: 32, null: false
    t.integer "data_source_id"
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.datetime "DateDeleted", precision: nil
    t.boolean "supports_bulk_assignment", default: false, null: false, comment: "whether to support bulk service assignment for this type in the hmis application"
    t.index ["custom_service_category_id"], name: "index_CustomServiceTypes_on_custom_service_category_id"
  end

  create_table "CustomServices", force: :cascade do |t|
    t.string "CustomServiceID", null: false
    t.string "EnrollmentID", null: false
    t.string "PersonalID", null: false
    t.string "UserID", limit: 32, null: false
    t.date "DateProvided", null: false
    t.integer "data_source_id"
    t.bigint "custom_service_type_id", comment: "Reference to the type of service rendered"
    t.string "service_name", comment: "Name of service rendered (for export)"
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.datetime "DateDeleted", precision: nil
    t.float "FAAmount"
    t.date "FAStartDate"
    t.date "FAEndDate"
    t.index ["DateProvided"], name: "index_CustomServices_on_DateProvided"
    t.index ["EnrollmentID"], name: "index_CustomServices_on_EnrollmentID"
    t.index ["PersonalID"], name: "index_CustomServices_on_PersonalID"
    t.index ["custom_service_type_id"], name: "index_CustomServices_on_custom_service_type_id"
    t.index ["data_source_id"], name: "index_CustomServices_on_data_source_id"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "source_hash"
    t.datetime "pending_date_deleted", precision: nil
    t.integer "AntiRetroviral"
    t.index ["DateCreated"], name: "disabilities_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "Disabilities_DateDeleted_data_source_id_idx", where: "(\"DateDeleted\" IS NULL)"
    t.index ["DateDeleted", "data_source_id"], name: "Disabilities_DateDeleted_data_source_id_idx1", where: "(\"DateDeleted\" IS NULL)"
    t.index ["DateDeleted", "data_source_id"], name: "index_Disabilities_on_DateDeleted_and_data_source_id"
    t.index ["DateDeleted"], name: "Disabilities_DateDeleted_idx", where: "(\"DateDeleted\" IS NULL)"
    t.index ["DateUpdated"], name: "disabilities_date_updated"
    t.index ["DisabilitiesID", "data_source_id"], name: "index_Disabilities_on_DisabilitiesID_and_data_source_id", unique: true
    t.index ["DisabilityType", "DisabilityResponse", "InformationDate", "PersonalID", "EnrollmentID", "DateDeleted"], name: "disabilities_disability_type_response_idx"
    t.index ["EnrollmentID", "PersonalID", "DateDeleted", "data_source_id"], name: "idx_dis_p_id_e_id_del_ds_id", where: "(\"IndefiniteAndImpairs\" = 1)"
    t.index ["EnrollmentID"], name: "index_Disabilities_on_EnrollmentID"
    t.index ["ExportID"], name: "disabilities_export_id"
    t.index ["PersonalID"], name: "index_Disabilities_on_PersonalID"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "source_hash"
    t.datetime "pending_date_deleted", precision: nil
    t.index ["DateCreated"], name: "employment_education_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_EmploymentEducation_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "employment_education_date_updated"
    t.index ["EmploymentEducationID", "data_source_id"], name: "ee_ee_id_ds_id", unique: true
    t.index ["EnrollmentID"], name: "index_EmploymentEducation_on_EnrollmentID"
    t.index ["ExportID"], name: "employment_education_export_id"
    t.index ["PersonalID"], name: "index_EmploymentEducation_on_PersonalID"
    t.index ["data_source_id", "PersonalID"], name: "index_EmploymentEducation_on_data_source_id_and_PersonalID"
    t.index ["data_source_id"], name: "index_EmploymentEducation_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_EmploymentEducation_on_pending_date_deleted"
  end

  create_table "Enrollment", id: :serial, force: :cascade do |t|
    t.string "EnrollmentID", limit: 50, null: false
    t.string "PersonalID", null: false
    t.string "ProjectID", limit: 50
    t.date "EntryDate", null: false
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
    t.integer "VAMCStation_deleted"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
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
    t.datetime "pending_date_deleted", precision: nil
    t.string "SexualOrientationOther", limit: 100
    t.date "history_generated_on"
    t.string "original_household_id"
    t.bigint "service_history_processing_job_id"
    t.integer "MentalHealthDisorderFam"
    t.integer "AlcoholDrugUseDisorderFam"
    t.integer "ClientLeaseholder"
    t.integer "HOHLeasesholder"
    t.integer "IncarceratedAdult"
    t.integer "PrisonDischarge"
    t.integer "CurrentPregnant"
    t.integer "CoCPrioritized"
    t.integer "TargetScreenReqd"
    t.integer "HOHLeaseholder"
    t.string "EnrollmentCoC"
    t.integer "RentalSubsidyType"
    t.integer "TranslationNeeded"
    t.integer "PreferredLanguage"
    t.string "PreferredLanguageDifferent"
    t.string "VAMCStation"
    t.integer "lock_version", default: 0, null: false
    t.bigint "project_pk"
    t.index ["DateCreated"], name: "Enrollment_d381"
    t.index ["DateCreated"], name: "enrollment_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Enrollment_on_DateDeleted_and_data_source_id"
    t.index ["DateDeleted"], name: "Enrollment_f3a2"
    t.index ["DateDeleted"], name: "index_Enrollment_on_DateDeleted"
    t.index ["DateUpdated"], name: "Enrollment_42d5"
    t.index ["DateUpdated"], name: "enrollment_date_updated"
    t.index ["EnrollmentID", "PersonalID", "data_source_id"], name: "en_en_id_p_id_ds_id", unique: true
    t.index ["EnrollmentID", "PersonalID"], name: "Enrollment_c548"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "Enrollment_34e3"
    t.index ["EnrollmentID"], name: "Enrollment_4337"
    t.index ["EnrollmentID"], name: "index_Enrollment_on_EnrollmentID"
    t.index ["EntryDate"], name: "index_Enrollment_on_EntryDate"
    t.index ["ExportID"], name: "Enrollment_634d"
    t.index ["ExportID"], name: "enrollment_export_id"
    t.index ["HouseholdID"], name: "Enrollment_5328"
    t.index ["MoveInDate"], name: "index_Enrollment_on_MoveInDate"
    t.index ["PersonalID"], name: "Enrollment_603f"
    t.index ["PersonalID"], name: "index_Enrollment_on_PersonalID"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "Enrollment_3085"
    t.index ["ProjectID", "HouseholdID"], name: "Enrollment_2735"
    t.index ["ProjectID", "data_source_id"], name: "index_Enrollment_on_ProjectID_and_data_source_id", where: "(\"DateDeleted\" IS NULL)"
    t.index ["ProjectID"], name: "Enrollment_42af"
    t.index ["ProjectID"], name: "index_Enrollment_on_ProjectID"
    t.index ["data_source_id", "HouseholdID", "ProjectID"], name: "idx_enrollment_ds_id_hh_id_p_id"
    t.index ["data_source_id", "PersonalID"], name: "index_Enrollment_on_data_source_id_and_PersonalID"
    t.index ["data_source_id"], name: "index_Enrollment_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_Enrollment_on_pending_date_deleted"
    t.index ["project_pk"], name: "index_Enrollment_on_project_pk"
    t.index ["service_history_processing_job_id"], name: "index_Enrollment_on_service_history_processing_job_id"
  end

  create_table "EnrollmentCoC", id: :serial, force: :cascade do |t|
    t.string "EnrollmentCoCID"
    t.string "EnrollmentID"
    t.string "ProjectID"
    t.string "PersonalID"
    t.date "InformationDate"
    t.string "CoCCode", limit: 50
    t.integer "DataCollectionStage"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "HouseholdID", limit: 32
    t.string "source_hash"
    t.datetime "pending_date_deleted", precision: nil
    t.index ["CoCCode"], name: "coc_code_test"
    t.index ["DateCreated"], name: "enrollment_coc_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_EnrollmentCoC_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "enrollment_coc_date_updated"
    t.index ["EnrollmentCoCID", "data_source_id"], name: "index_EnrollmentCoC_on_EnrollmentCoCID_and_data_source_id", unique: true
    t.index ["EnrollmentCoCID"], name: "index_EnrollmentCoC_on_EnrollmentCoCID"
    t.index ["ExportID"], name: "enrollment_coc_export_id"
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
    t.string "LocationCrisisOrPHHousing"
    t.integer "ReferralResult"
    t.date "ResultDate"
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.string "UserID", limit: 32, null: false
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.datetime "pending_date_deleted", precision: nil
    t.string "source_hash"
    t.boolean "synthetic", default: false
    t.index ["EventID", "data_source_id"], name: "ev_ev_id_ds_id", unique: true
    t.index ["data_source_id", "PersonalID", "EnrollmentID", "EventID"], name: "event_ds_id_p_id_en_id_ev_id"
    t.index ["pending_date_deleted"], name: "index_Event_on_pending_date_deleted"
  end

  create_table "Exit", id: :serial, force: :cascade do |t|
    t.string "ExitID", null: false
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "ExitDate", null: false
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
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
    t.datetime "pending_date_deleted", precision: nil
    t.integer "DestinationSubsidyType"
    t.datetime "auto_exited", precision: nil
    t.index ["DateCreated"], name: "exit_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Exit_on_DateDeleted_and_data_source_id"
    t.index ["DateDeleted"], name: "index_Exit_on_DateDeleted"
    t.index ["DateUpdated"], name: "exit_date_updated"
    t.index ["EnrollmentID", "PersonalID", "data_source_id", "ExitDate"], name: "exit_en_id_p_id_ds_id_ex_d"
    t.index ["EnrollmentID", "PersonalID", "data_source_id", "ExitDate"], name: "exit_en_id_p_id_ds_id_ex_d_undeleted", where: "(\"DateDeleted\" IS NULL)"
    t.index ["ExitDate"], name: "index_Exit_on_ExitDate"
    t.index ["ExitID", "data_source_id"], name: "index_Exit_on_ExitID_and_data_source_id", unique: true
    t.index ["ExportID"], name: "exit_export_id"
    t.index ["PersonalID", "data_source_id"], name: "exit_p_id_ds_id", where: "(\"DateDeleted\" IS NULL)"
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
    t.datetime "ExportDate", precision: nil
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
    t.string "CSVVersion"
    t.string "ImplementationID"
    t.index ["ExportID", "data_source_id"], name: "index_Export_on_ExportID_and_data_source_id", unique: true
    t.index ["ExportID"], name: "export_export_id"
    t.index ["data_source_id"], name: "index_Export_on_data_source_id"
  end

  create_table "Funder", id: :serial, force: :cascade do |t|
    t.string "FunderID"
    t.string "ProjectID"
    t.string "Funder"
    t.string "GrantID"
    t.date "StartDate"
    t.date "EndDate"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "source_hash"
    t.datetime "pending_date_deleted", precision: nil
    t.string "OtherFunder"
    t.boolean "manual_entry", default: false
    t.index ["DateCreated"], name: "funder_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Funder_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "funder_date_updated"
    t.index ["ExportID"], name: "funder_export_id"
    t.index ["FunderID", "data_source_id"], name: "index_Funder_on_FunderID_and_data_source_id", unique: true
    t.index ["ProjectID", "Funder"], name: "index_Funder_on_ProjectID_and_Funder"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.date "InformationDate"
    t.string "Address2"
    t.integer "GeographyType"
    t.string "source_hash"
    t.string "geocode_override", limit: 6
    t.integer "geography_type_override"
    t.date "information_date_override"
    t.datetime "pending_date_deleted", precision: nil
    t.index ["DateCreated"], name: "site_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Geography_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "site_date_updated"
    t.index ["ExportID"], name: "site_export_id"
    t.index ["data_source_id", "GeographyID"], name: "unk_Geography", unique: true
    t.index ["data_source_id", "GeographyID"], name: "unk_Site", unique: true
    t.index ["data_source_id"], name: "index_Geography_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_Geography_on_pending_date_deleted"
  end

  create_table "HMISParticipation", force: :cascade do |t|
    t.string "HMISParticipationID", null: false
    t.string "ProjectID", null: false
    t.integer "HMISParticipationType"
    t.date "HMISParticipationStatusStartDate"
    t.date "HMISParticipationStatusEndDate"
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.datetime "DateDeleted", precision: nil
    t.string "UserID"
    t.string "ExportID"
    t.integer "data_source_id"
    t.date "pending_date_deleted"
    t.string "source_hash"
    t.index ["HMISParticipationID"], name: "index_HMISParticipation_on_HMISParticipationID"
    t.index ["ProjectID"], name: "index_HMISParticipation_on_ProjectID"
    t.index ["data_source_id", "HMISParticipationID"], name: "ds_hmisparticipation_idx", unique: true
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "source_hash"
    t.datetime "pending_date_deleted", precision: nil
    t.integer "LifeValue"
    t.integer "SupportFromOthers"
    t.integer "BounceBack"
    t.integer "FeelingFrequency"
    t.integer "DomesticViolenceSurvivor"
    t.index ["DateCreated"], name: "health_and_dv_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_HealthAndDV_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "health_and_dv_date_updated"
    t.index ["EnrollmentID"], name: "index_HealthAndDV_on_EnrollmentID"
    t.index ["ExportID"], name: "health_and_dv_export_id"
    t.index ["HealthAndDVID", "data_source_id"], name: "index_HealthAndDV_on_HealthAndDVID_and_data_source_id", unique: true
    t.index ["PersonalID"], name: "index_HealthAndDV_on_PersonalID"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.integer "IndianHealthServices"
    t.integer "NoIndianHealthServicesReason"
    t.integer "OtherInsurance"
    t.string "OtherInsuranceIdentify", limit: 50
    t.integer "ConnectionWithSOAR"
    t.string "source_hash"
    t.datetime "pending_date_deleted", precision: nil
    t.integer "RyanWhiteMedDent"
    t.integer "NoRyanWhiteReason"
    t.integer "VHAServices"
    t.string "NoVHAReason"
    t.index ["DateCreated"], name: "income_benefits_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "IncomeBenefits_DateDeleted_data_source_id_idx", where: "(\"DateDeleted\" IS NULL)"
    t.index ["DateDeleted", "data_source_id"], name: "index_IncomeBenefits_on_DateDeleted_and_data_source_id"
    t.index ["DateDeleted"], name: "IncomeBenefits_DateDeleted_idx", where: "(\"DateDeleted\" IS NULL)"
    t.index ["DateUpdated"], name: "income_benefits_date_updated"
    t.index ["Earned", "DataCollectionStage"], name: "idx_earned_stage"
    t.index ["EnrollmentID"], name: "index_IncomeBenefits_on_EnrollmentID"
    t.index ["ExportID"], name: "income_benefits_export_id"
    t.index ["IncomeBenefitsID", "data_source_id"], name: "index_IncomeBenefits_on_IncomeBenefitsID_and_data_source_id", unique: true
    t.index ["IncomeFromAnySource", "DataCollectionStage"], name: "idx_any_stage"
    t.index ["InformationDate"], name: "index_IncomeBenefits_on_InformationDate"
    t.index ["PersonalID"], name: "index_IncomeBenefits_on_PersonalID"
    t.index ["data_source_id", "DateDeleted"], name: "IncomeBenefits_data_source_id_DateDeleted_idx", where: "(\"DateDeleted\" IS NULL)"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "source_hash"
    t.datetime "pending_date_deleted", precision: nil
    t.integer "CHVetBedInventory"
    t.integer "YouthVetBedInventory"
    t.integer "CHYouthBedInventory"
    t.integer "OtherBedInventory"
    t.integer "TargetPopulation"
    t.integer "ESBedType"
    t.boolean "manual_entry", default: false
    t.index ["DateCreated"], name: "inventory_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Inventory_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "inventory_date_updated"
    t.index ["ExportID"], name: "inventory_export_id"
    t.index ["InventoryID", "data_source_id"], name: "index_Inventory_on_InventoryID_and_data_source_id", unique: true
    t.index ["ProjectID", "CoCCode", "data_source_id"], name: "index_Inventory_on_ProjectID_and_CoCCode_and_data_source_id"
    t.index ["data_source_id"], name: "index_Inventory_on_data_source_id"
    t.index ["pending_date_deleted"], name: "index_Inventory_on_pending_date_deleted"
  end

  create_table "Organization", id: :serial, force: :cascade do |t|
    t.string "OrganizationID", limit: 50
    t.string "OrganizationName"
    t.string "OrganizationCommonName"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.boolean "dmh", default: false, null: false
    t.string "source_hash"
    t.datetime "pending_date_deleted", precision: nil
    t.integer "VictimServicesProvider"
    t.integer "VictimServiceProvider"
    t.boolean "confidential", default: false, null: false
    t.string "description"
    t.string "contact_information"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
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
    t.datetime "pending_date_deleted", precision: nil
    t.integer "HMISParticipatingProject"
    t.boolean "active_homeless_status_override", default: false
    t.boolean "include_in_days_homeless_override", default: false
    t.boolean "extrapolate_contacts", default: false, null: false
    t.boolean "combine_enrollments", default: false
    t.integer "HOPWAMedAssistedLivingFac"
    t.string "description"
    t.string "contact_information"
    t.integer "RRHSubType"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "source_hash"
    t.datetime "pending_date_deleted", precision: nil
    t.string "Geocode", limit: 6
    t.integer "GeographyType"
    t.string "Address1"
    t.string "Address2"
    t.string "City"
    t.string "State", limit: 2
    t.string "Zip", limit: 5
    t.boolean "manual_entry", default: false
    t.index "lower((\"City\")::text)", name: "project_cocs_city_lower"
    t.index ["DateCreated"], name: "project_coc_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_ProjectCoC_on_DateDeleted_and_data_source_id"
    t.index ["DateUpdated"], name: "project_coc_date_updated"
    t.index ["ExportID"], name: "project_coc_export_id"
    t.index ["ProjectCoCID", "data_source_id"], name: "index_ProjectCoC_on_ProjectCoCID_and_data_source_id", unique: true
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.string "source_hash"
    t.datetime "pending_date_deleted", precision: nil
    t.string "MovingOnOtherType"
    t.date "FAStartDate"
    t.date "FAEndDate"
    t.index ["DateCreated"], name: "services_date_created"
    t.index ["DateDeleted", "data_source_id"], name: "index_Services_on_DateDeleted_and_data_source_id"
    t.index ["DateDeleted"], name: "index_Services_on_DateDeleted"
    t.index ["DateProvided"], name: "index_Services_on_DateProvided"
    t.index ["DateUpdated"], name: "services_date_updated"
    t.index ["EnrollmentID", "PersonalID", "data_source_id"], name: "index_serv_on_proj_entry_per_id_ds_id"
    t.index ["ExportID"], name: "services_export_id"
    t.index ["PersonalID"], name: "index_Services_on_PersonalID"
    t.index ["RecordType", "TypeProvided"], name: "idx_services_hud_types"
    t.index ["ServicesID", "data_source_id"], name: "index_Services_on_ServicesID_and_data_source_id", unique: true
    t.index ["data_source_id", "PersonalID", "RecordType", "EnrollmentID", "DateProvided"], name: "index_services_ds_id_p_id_type_entry_id_date"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id"
    t.datetime "pending_date_deleted", precision: nil
    t.string "source_hash"
    t.index ["UserEmail", "data_source_id"], name: "users_ds_email_idx"
    t.index ["UserID", "data_source_id"], name: "index_User_on_UserID_and_data_source_id", unique: true
    t.index ["pending_date_deleted"], name: "index_User_on_pending_date_deleted"
  end

  create_table "YouthEducationStatus", force: :cascade do |t|
    t.string "YouthEducationStatusID", limit: 32, null: false
    t.string "EnrollmentID", limit: 32, null: false
    t.string "PersonalID", limit: 32, null: false
    t.date "InformationDate", null: false
    t.integer "CurrentSchoolAttend"
    t.integer "MostRecentEdStatus"
    t.integer "CurrentEdStatus"
    t.integer "DataCollectionStage", null: false
    t.datetime "DateCreated", precision: nil, null: false
    t.datetime "DateUpdated", precision: nil, null: false
    t.string "UserID", limit: 32, null: false
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID", limit: 32
    t.integer "data_source_id"
    t.date "pending_date_deleted"
    t.string "source_hash"
    t.boolean "synthetic", default: false
    t.index ["YouthEducationStatusID", "EnrollmentID", "PersonalID", "data_source_id"], name: "youth_eds_id_e_id_p_id_ds_id"
    t.index ["YouthEducationStatusID", "data_source_id"], name: "youth_ed_ev_id_ds_id", unique: true
  end

  create_table "ac_hmis_projects_import_attempts", force: :cascade do |t|
    t.string "status", default: "init", null: false
    t.string "etag", null: false, comment: "fingerprint of the file"
    t.text "key", null: false, comment: "path in an s3 bucket to the file"
    t.jsonb "result", default: {}, null: false
    t.datetime "attempted_at", precision: nil, null: false, comment: "last time an import was attempted"
    t.index ["etag"], name: "index_ac_hmis_projects_import_attempts_on_etag"
    t.index ["key", "etag"], name: "index_ac_hmis_projects_import_attempts_on_key_and_etag", unique: true
  end

  create_table "ad_hoc_batches", id: :serial, force: :cascade do |t|
    t.integer "ad_hoc_data_source_id"
    t.string "description", null: false
    t.integer "uploaded_count"
    t.integer "matched_count"
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["created_at"], name: "index_ad_hoc_clients_on_created_at"
    t.index ["deleted_at"], name: "index_ad_hoc_clients_on_deleted_at"
    t.index ["updated_at"], name: "index_ad_hoc_clients_on_updated_at"
  end

  create_table "ad_hoc_data_sources", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "short_name"
    t.string "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.bigint "user_id"
    t.index ["created_at"], name: "index_ad_hoc_data_sources_on_created_at"
    t.index ["deleted_at"], name: "index_ad_hoc_data_sources_on_deleted_at"
    t.index ["updated_at"], name: "index_ad_hoc_data_sources_on_updated_at"
    t.index ["user_id"], name: "index_ad_hoc_data_sources_on_user_id"
  end

  create_table "administrative_events", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.date "date", null: false
    t.string "title", null: false
    t.string "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_administrative_events_on_deleted_at"
  end

  create_table "anomalies", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.integer "submitted_by"
    t.string "description"
    t.string "status", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["client_id"], name: "index_anomalies_on_client_id"
    t.index ["status"], name: "index_anomalies_on_status"
  end

  create_table "ansd_enrollments", force: :cascade do |t|
    t.bigint "report_id"
    t.bigint "enrollment_id"
    t.string "project_name"
    t.integer "project_type"
    t.string "household_id"
    t.string "household_type"
    t.string "prior_living_situation_category"
    t.date "entry_date"
    t.date "move_in_date"
    t.date "exit_date"
    t.date "adjusted_exit_date"
    t.string "exit_type"
    t.integer "destination"
    t.string "destination_text"
    t.string "relationship"
    t.string "personal_id"
    t.integer "age"
    t.string "gender"
    t.string "primary_race"
    t.string "race_list"
    t.string "ethnicity"
    t.date "ce_entry_date"
    t.date "ce_referral_date"
    t.string "ce_referral_id"
    t.date "return_date"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "destination_client_id"
    t.integer "relationship_to_hoh"
    t.date "placed_date"
    t.bigint "project_id"
    t.index ["enrollment_id"], name: "index_ansd_enrollments_on_enrollment_id"
    t.index ["report_id"], name: "index_ansd_enrollments_on_report_id"
  end

  create_table "ansd_events", force: :cascade do |t|
    t.bigint "enrollment_id"
    t.string "event_id"
    t.date "event_date"
    t.string "event"
    t.string "location"
    t.string "project_name"
    t.string "project_type"
    t.integer "referral_result"
    t.date "result_date"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "personal_id"
    t.string "source_enrollment_id"
    t.index ["enrollment_id"], name: "index_ansd_events_on_enrollment_id"
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

  create_table "assessment_answer_lookups", force: :cascade do |t|
    t.string "assessment_question"
    t.string "response_code"
    t.string "response_text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "data_source_id"
    t.index ["response_code"], name: "index_assessment_answer_lookups_on_response_code"
  end

  create_table "available_file_tags", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "group"
    t.string "included_info"
    t.integer "weight", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.boolean "ce_self_report_certification", default: false, null: false
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

  create_table "boston_project_scorecard_reports", force: :cascade do |t|
    t.bigint "project_id"
    t.bigint "project_group_id"
    t.string "status", default: "pending"
    t.bigint "user_id"
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.bigint "apr_id"
    t.integer "project_type"
    t.date "period_start_date"
    t.date "period_end_date"
    t.bigint "secondary_reviewer_id"
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "sent_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "initial_goals_pass"
    t.string "initial_goals_notes"
    t.boolean "timeliness_pass"
    t.string "timeliness_notes"
    t.boolean "independent_living_pass"
    t.string "independent_living_notes"
    t.boolean "management_oversight_pass"
    t.string "management_oversight_notes"
    t.boolean "prioritization_pass"
    t.string "prioritization_notes"
    t.float "rrh_exits_to_ph"
    t.float "psh_stayers_or_to_ph"
    t.float "increased_stayer_employment_income"
    t.float "increased_stayer_other_income"
    t.float "increased_leaver_employment_income"
    t.float "increased_leaver_other_income"
    t.integer "days_to_lease_up"
    t.float "pii_error_rate"
    t.float "ude_error_rate"
    t.float "income_and_housing_error_rate"
    t.integer "invoicing"
    t.integer "actual_households_served"
    t.float "amount_agency_spent"
    t.float "returned_funds"
    t.float "average_utilization_rate"
    t.jsonb "subpopulations_served"
    t.boolean "practices_housing_first"
    t.jsonb "vulnerable_subpopulations_served"
    t.boolean "barrier_id_process"
    t.boolean "plan_to_address_barriers"
    t.float "contracted_budget"
    t.string "archive"
    t.boolean "required_match_percent_met"
    t.float "increased_employment_income"
    t.float "increased_other_income"
    t.integer "invoicing_timeliness"
    t.integer "invoicing_accuracy"
    t.integer "no_concern"
    t.integer "materials_concern"
    t.boolean "lms_completed"
    t.boolean "self_certified"
    t.integer "days_to_lease_up_comparison"
    t.bigint "comparison_apr_id"
    t.index ["apr_id"], name: "index_boston_project_scorecard_reports_on_apr_id"
    t.index ["comparison_apr_id"], name: "index_boston_project_scorecard_reports_on_comparison_apr_id"
    t.index ["project_group_id"], name: "index_boston_project_scorecard_reports_on_project_group_id"
    t.index ["project_id"], name: "index_boston_project_scorecard_reports_on_project_id"
    t.index ["secondary_reviewer_id"], name: "index_boston_project_scorecard_reports_on_secondary_reviewer_id"
    t.index ["user_id"], name: "index_boston_project_scorecard_reports_on_user_id"
  end

  create_table "boston_report_configs", force: :cascade do |t|
    t.string "total_color"
    t.string "breakdown_1_color_0"
    t.string "breakdown_2_color_0"
    t.string "breakdown_3_color_0"
    t.string "breakdown_4_color_0"
    t.string "breakdown_1_color_1"
    t.string "breakdown_2_color_1"
    t.string "breakdown_3_color_1"
    t.string "breakdown_4_color_1"
    t.string "breakdown_1_color_2"
    t.string "breakdown_2_color_2"
    t.string "breakdown_3_color_2"
    t.string "breakdown_4_color_2"
    t.string "breakdown_1_color_3"
    t.string "breakdown_2_color_3"
    t.string "breakdown_3_color_3"
    t.string "breakdown_4_color_3"
    t.string "breakdown_1_color_4"
    t.string "breakdown_2_color_4"
    t.string "breakdown_3_color_4"
    t.string "breakdown_4_color_4"
    t.string "breakdown_1_color_5"
    t.string "breakdown_2_color_5"
    t.string "breakdown_3_color_5"
    t.string "breakdown_4_color_5"
    t.string "breakdown_1_color_6"
    t.string "breakdown_2_color_6"
    t.string "breakdown_3_color_6"
    t.string "breakdown_4_color_6"
    t.string "breakdown_1_color_7"
    t.string "breakdown_2_color_7"
    t.string "breakdown_3_color_7"
    t.string "breakdown_4_color_7"
    t.string "breakdown_1_color_8"
    t.string "breakdown_2_color_8"
    t.string "breakdown_3_color_8"
    t.string "breakdown_4_color_8"
    t.string "breakdown_1_color_9"
    t.string "breakdown_2_color_9"
    t.string "breakdown_3_color_9"
    t.string "breakdown_4_color_9"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cas_availabilities", id: :serial, force: :cascade do |t|
    t.integer "client_id", null: false
    t.datetime "available_at", precision: nil, null: false
    t.datetime "unavailable_at", precision: nil
    t.boolean "part_of_a_family", default: false, null: false
    t.integer "age_at_available_at"
    t.index ["available_at"], name: "index_cas_availabilities_on_available_at"
    t.index ["client_id"], name: "index_cas_availabilities_on_client_id"
    t.index ["unavailable_at"], name: "index_cas_availabilities_on_unavailable_at"
  end

  create_table "cas_ce_assessments", force: :cascade do |t|
    t.bigint "cas_client_id"
    t.bigint "cas_non_hmis_assessment_id"
    t.bigint "hmis_client_id"
    t.bigint "program_id"
    t.date "assessment_date"
    t.string "assessment_location"
    t.integer "assessment_type"
    t.integer "assessment_level"
    t.integer "assessment_status"
    t.datetime "assessment_created_at", precision: nil
    t.datetime "assessment_updated_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["cas_client_id"], name: "index_cas_ce_assessments_on_cas_client_id"
    t.index ["cas_non_hmis_assessment_id"], name: "index_cas_ce_assessments_on_cas_non_hmis_assessment_id", unique: true
    t.index ["hmis_client_id"], name: "index_cas_ce_assessments_on_hmis_client_id"
    t.index ["program_id"], name: "index_cas_ce_assessments_on_program_id"
  end

  create_table "cas_enrollments", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.integer "enrollment_id"
    t.date "entry_date"
    t.date "exit_date"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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

  create_table "cas_programs_to_projects", force: :cascade do |t|
    t.bigint "program_id"
    t.bigint "project_id"
    t.index ["program_id"], name: "index_cas_programs_to_projects_on_program_id"
    t.index ["project_id"], name: "index_cas_programs_to_projects_on_project_id"
  end

  create_table "cas_referral_events", force: :cascade do |t|
    t.bigint "cas_client_id"
    t.bigint "hmis_client_id"
    t.bigint "program_id"
    t.bigint "client_opportunity_match_id"
    t.date "referral_date"
    t.integer "referral_result"
    t.date "referral_result_date"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "event"
    t.index ["cas_client_id"], name: "index_cas_referral_events_on_cas_client_id"
    t.index ["client_opportunity_match_id"], name: "index_cas_referral_events_on_client_opportunity_match_id"
    t.index ["hmis_client_id"], name: "index_cas_referral_events_on_hmis_client_id"
    t.index ["program_id"], name: "index_cas_referral_events_on_program_id"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "elapsed_days", default: 0, null: false
    t.datetime "client_last_seen_date", precision: nil
    t.datetime "criminal_hearing_date", precision: nil
    t.string "decline_reason"
    t.string "not_working_with_client_reason"
    t.string "administrative_cancel_reason"
    t.boolean "client_spoken_with_services_agency"
    t.boolean "cori_release_form_submitted"
    t.datetime "match_started_at", precision: nil
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
    t.boolean "confidential", default: false
    t.index ["client_id", "match_id", "decision_id"], name: "index_cas_reports_on_client_id_and_match_id_and_decision_id", unique: true
  end

  create_table "cas_vacancies", id: :serial, force: :cascade do |t|
    t.integer "program_id", null: false
    t.integer "sub_program_id", null: false
    t.string "program_name"
    t.string "sub_program_name"
    t.string "program_type"
    t.string "route_name", null: false
    t.datetime "vacancy_created_at", precision: nil, null: false
    t.datetime "vacancy_made_available_at", precision: nil
    t.datetime "first_matched_at", precision: nil
    t.index ["program_id"], name: "index_cas_vacancies_on_program_id"
    t.index ["sub_program_id"], name: "index_cas_vacancies_on_sub_program_id"
  end

  create_table "ce_assessments", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "client_id", null: false
    t.string "type", null: false
    t.datetime "submitted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
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

  create_table "ce_performance_ce_aprs", force: :cascade do |t|
    t.bigint "report_id", null: false
    t.bigint "ce_apr_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["ce_apr_id"], name: "index_ce_performance_ce_aprs_on_ce_apr_id"
    t.index ["report_id"], name: "index_ce_performance_ce_aprs_on_report_id"
  end

  create_table "ce_performance_clients", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "report_id"
    t.bigint "ce_apr_id"
    t.string "first_name"
    t.string "last_name"
    t.integer "reporting_age"
    t.boolean "head_of_household"
    t.integer "prior_living_situation"
    t.integer "los_under_threshold"
    t.integer "previous_street_essh"
    t.integer "prevention_tool_score"
    t.integer "assessment_score"
    t.jsonb "events"
    t.jsonb "assessments"
    t.boolean "diversion_event"
    t.boolean "diversion_successful"
    t.boolean "veteran"
    t.integer "household_size"
    t.jsonb "household_ages"
    t.boolean "chronically_homeless_at_entry"
    t.date "entry_date"
    t.date "exit_date"
    t.date "initial_assessment_date"
    t.date "latest_assessment_date"
    t.date "initial_housing_referral_date"
    t.date "housing_enrollment_entry_date"
    t.date "housing_enrollment_move_in_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ce_apr_client_id"
    t.date "dob"
    t.date "move_in_date"
    t.string "period"
    t.string "household_type"
    t.integer "days_before_assessment"
    t.integer "days_on_list"
    t.integer "days_in_project"
    t.integer "days_between_referral_and_housing"
    t.boolean "q5a_b1", default: false
    t.datetime "deleted_at", precision: nil
    t.string "assessment_type"
    t.integer "days_between_entry_and_initial_referral"
    t.boolean "cls_literally_homeless", default: false, null: false
    t.string "vispdat_type"
    t.string "vispdat_range"
    t.string "prioritization_tool_type"
    t.integer "prioritization_tool_score"
    t.string "community"
    t.boolean "lgbtq_household_members", default: false, null: false
    t.boolean "client_lgbtq", default: false, null: false
    t.boolean "dv_survivor", default: false, null: false
    t.integer "destination_client_id"
    t.index ["ce_apr_id"], name: "index_ce_performance_clients_on_ce_apr_id"
    t.index ["client_id"], name: "index_ce_performance_clients_on_client_id"
    t.index ["report_id"], name: "index_ce_performance_clients_on_report_id"
  end

  create_table "ce_performance_goals", force: :cascade do |t|
    t.string "coc_code", null: false
    t.integer "screening", default: 100, null: false
    t.integer "diversion", default: 5, null: false
    t.integer "time_in_ce", default: 30, null: false
    t.integer "time_to_referral", default: 5, null: false
    t.integer "time_to_housing", default: 5, null: false
    t.integer "time_on_list", default: 30, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
  end

  create_table "ce_performance_results", force: :cascade do |t|
    t.bigint "report_id"
    t.float "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type"
    t.string "period"
    t.integer "numerator"
    t.integer "denominator"
    t.datetime "deleted_at", precision: nil
    t.integer "event_type"
    t.integer "goal"
    t.index ["report_id"], name: "index_ce_performance_results_on_report_id"
  end

  create_table "census_by_project_types", id: :serial, force: :cascade do |t|
    t.integer "ProjectType", null: false
    t.date "date", null: false
    t.boolean "veteran", default: false, null: false
    t.integer "gender", default: 99, null: false
    t.integer "client_count", default: 0, null: false
  end

  create_table "census_groups", force: :cascade do |t|
    t.integer "year", null: false
    t.string "dataset", null: false
    t.string "name", null: false
    t.text "description", null: false
    t.date "created_on"
    t.index ["year", "dataset", "name"], name: "index_census_groups_on_year_and_dataset_and_name", unique: true
  end

  create_table "census_values", force: :cascade do |t|
    t.bigint "census_variable_id", null: false
    t.decimal "value", null: false
    t.string "full_geoid", null: false
    t.date "created_on", null: false
    t.enum "census_level", null: false, enum_type: "census_levels"
    t.index ["census_level"], name: "index_census_values_on_census_level"
    t.index ["census_variable_id"], name: "index_census_values_on_census_variable_id"
    t.index ["full_geoid", "census_variable_id"], name: "index_census_values_on_full_geoid_and_census_variable_id", unique: true
    t.index ["full_geoid"], name: "index_census_values_on_full_geoid"
  end

  create_table "census_variables", force: :cascade do |t|
    t.integer "year", null: false
    t.boolean "downloaded", default: false, null: false
    t.string "dataset", null: false
    t.string "name", null: false
    t.text "label", null: false
    t.text "concept", null: false
    t.string "census_group", null: false
    t.string "census_attributes", null: false
    t.string "internal_name"
    t.date "created_on", null: false
    t.index ["dataset"], name: "index_census_variables_on_dataset"
    t.index ["internal_name", "year", "dataset"], name: "index_census_variables_on_internal_name_and_year_and_dataset", where: "(internal_name IS NOT NULL)"
    t.index ["year", "dataset", "name"], name: "index_census_variables_on_year_and_dataset_and_name", unique: true
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

  create_table "ch_enrollments", force: :cascade do |t|
    t.bigint "enrollment_id", null: false
    t.string "processed_as"
    t.boolean "chronically_homeless_at_entry", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["enrollment_id", "chronically_homeless_at_entry"], name: "ch_enrollments_e_id_ch"
    t.index ["enrollment_id", "processed_as"], name: "ch_enrollments_e_id_pro"
  end

  create_table "children", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.date "dob"
    t.integer "family_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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

  create_table "clh_locations", force: :cascade do |t|
    t.bigint "client_id"
    t.string "source_type"
    t.bigint "source_id"
    t.date "located_on"
    t.float "lat"
    t.float "lon"
    t.string "collected_by"
    t.datetime "processed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.bigint "enrollment_id"
    t.datetime "located_at"
    t.index ["client_id"], name: "index_clh_locations_on_client_id"
    t.index ["lat", "lon"], name: "index_clh_locations_on_lat_and_lon"
    t.index ["source_type", "source_id"], name: "index_clh_locations_on_source_type_and_source_id"
  end

  create_table "client_contacts", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.string "source_type", null: false
    t.bigint "source_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "full_name"
    t.string "contact_type"
    t.string "phone"
    t.string "phone_alternate"
    t.string "email"
    t.string "address"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "note"
    t.datetime "last_modified_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["client_id"], name: "index_client_contacts_on_client_id"
    t.index ["source_type", "source_id"], name: "index_client_contacts_on_source_type_and_source_id"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["destination_client_id"], name: "index_client_matches_on_destination_client_id"
    t.index ["source_client_id"], name: "index_client_matches_on_source_client_id"
    t.index ["updated_by_id"], name: "index_client_matches_on_updated_by_id"
  end

  create_table "client_merge_histories", id: :serial, force: :cascade do |t|
    t.integer "merged_into", null: false
    t.integer "merged_from", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["created_at"], name: "index_client_merge_histories_on_created_at"
    t.index ["merged_from"], name: "index_client_merge_histories_on_merged_from"
    t.index ["updated_at"], name: "index_client_merge_histories_on_updated_at"
  end

  create_table "client_notes", id: :serial, force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "user_id", null: false
    t.string "type", null: false
    t.text "note"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.string "migrated_username"
    t.jsonb "recipients"
    t.datetime "sent_at", precision: nil
    t.boolean "alert_active", default: true, null: false
    t.bigint "service_id"
    t.bigint "project_id"
    t.index ["client_id"], name: "index_client_notes_on_client_id"
    t.index ["project_id"], name: "index_client_notes_on_project_id"
    t.index ["service_id"], name: "index_client_notes_on_service_id"
    t.index ["user_id"], name: "index_client_notes_on_user_id"
  end

  create_table "client_roi_authorizations", force: :cascade do |t|
    t.bigint "destination_client_id", null: false
    t.string "status", null: false
    t.string "coc_codes", array: true
    t.date "starts_at"
    t.date "expires_at"
    t.index ["destination_client_id"], name: "index_client_roi_authorizations_on_destination_client_id", unique: true
  end

  create_table "client_split_histories", id: :serial, force: :cascade do |t|
    t.integer "split_into", null: false
    t.integer "split_from", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["coc_code"], name: "index_coc_codes_on_coc_code"
  end

  create_table "coc_pit_counts", force: :cascade do |t|
    t.bigint "goal_id"
    t.date "pit_date"
    t.integer "sheltered"
    t.integer "unsheltered"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["goal_id"], name: "index_coc_pit_counts_on_goal_id"
  end

  create_table "cohort_client_changes", id: :serial, force: :cascade do |t|
    t.integer "cohort_client_id", null: false
    t.integer "cohort_id", null: false
    t.integer "user_id", null: false
    t.string "change"
    t.datetime "changed_at", precision: nil, null: false
    t.string "reason"
    t.index ["change"], name: "index_cohort_client_changes_on_change"
    t.index ["changed_at"], name: "index_cohort_client_changes_on_changed_at"
  end

  create_table "cohort_client_notes", id: :serial, force: :cascade do |t|
    t.integer "cohort_client_id", null: false
    t.text "note"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "user_id", null: false
    t.jsonb "recipients", default: []
    t.index ["cohort_client_id"], name: "index_cohort_client_notes_on_cohort_client_id"
    t.index ["deleted_at"], name: "index_cohort_client_notes_on_deleted_at"
  end

  create_table "cohort_clients", id: :serial, force: :cascade do |t|
    t.integer "cohort_id", null: false
    t.integer "client_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
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
    t.string "user_select_11"
    t.string "user_select_12"
    t.string "user_select_13"
    t.string "user_select_14"
    t.string "user_select_15"
    t.string "user_select_16"
    t.string "user_select_17"
    t.string "user_select_18"
    t.string "user_select_19"
    t.string "user_select_20"
    t.string "user_select_21"
    t.string "user_select_22"
    t.string "user_select_23"
    t.string "user_select_24"
    t.string "user_select_25"
    t.string "user_select_26"
    t.string "user_select_27"
    t.string "user_select_28"
    t.string "user_select_29"
    t.string "user_select_30"
    t.boolean "user_boolean_16"
    t.boolean "user_boolean_17"
    t.boolean "user_boolean_18"
    t.boolean "user_boolean_19"
    t.boolean "user_boolean_20"
    t.boolean "user_boolean_21"
    t.boolean "user_boolean_22"
    t.boolean "user_boolean_23"
    t.boolean "user_boolean_24"
    t.boolean "user_boolean_25"
    t.boolean "user_boolean_26"
    t.boolean "user_boolean_27"
    t.boolean "user_boolean_28"
    t.boolean "user_boolean_29"
    t.boolean "user_boolean_30"
    t.date "date_added_to_cohort"
    t.boolean "individual_in_most_recent_homeless_enrollment"
    t.string "user_date_11"
    t.string "user_date_12"
    t.string "user_date_13"
    t.string "user_date_14"
    t.string "user_date_15"
    t.string "user_date_16"
    t.string "user_date_17"
    t.string "user_date_18"
    t.string "user_date_19"
    t.string "user_date_20"
    t.string "user_date_21"
    t.string "user_date_22"
    t.string "user_date_23"
    t.string "user_date_24"
    t.string "user_date_25"
    t.string "user_date_26"
    t.string "user_date_27"
    t.string "user_date_28"
    t.string "user_date_29"
    t.string "user_date_30"
    t.date "most_recent_date_to_street"
    t.boolean "user_boolean_31"
    t.boolean "user_boolean_32"
    t.boolean "user_boolean_33"
    t.boolean "user_boolean_34"
    t.boolean "user_boolean_35"
    t.boolean "user_boolean_36"
    t.boolean "user_boolean_37"
    t.boolean "user_boolean_38"
    t.boolean "user_boolean_39"
    t.boolean "user_boolean_40"
    t.boolean "user_boolean_41"
    t.boolean "user_boolean_42"
    t.boolean "user_boolean_43"
    t.boolean "user_boolean_44"
    t.boolean "user_boolean_45"
    t.boolean "user_boolean_46"
    t.boolean "user_boolean_47"
    t.boolean "user_boolean_48"
    t.boolean "user_boolean_49"
    t.integer "sheltered_days_homeless_last_three_years"
    t.integer "unsheltered_days_homeless_last_three_years"
    t.string "user_string_9"
    t.string "user_string_10"
    t.string "user_string_11"
    t.string "user_string_12"
    t.string "user_string_13"
    t.string "user_string_14"
    t.string "user_string_15"
    t.string "user_string_16"
    t.string "user_string_17"
    t.string "user_string_18"
    t.string "user_string_19"
    t.string "user_string_20"
    t.string "user_string_21"
    t.string "user_string_22"
    t.string "user_string_23"
    t.string "user_string_24"
    t.string "user_string_25"
    t.string "user_string_26"
    t.string "user_string_27"
    t.string "user_string_28"
    t.string "user_string_29"
    t.string "user_string_30"
    t.string "most_recent_cls"
    t.string "most_recent_prior_living_situation"
    t.string "most_recent_household_type"
    t.string "most_recent_self_report_months_homeless"
    t.string "most_recent_disabling_condition"
    t.index ["client_id"], name: "index_cohort_clients_on_client_id"
    t.index ["cohort_id"], name: "index_cohort_clients_on_cohort_id"
    t.index ["deleted_at"], name: "index_cohort_clients_on_deleted_at"
  end

  create_table "cohort_column_options", id: :serial, force: :cascade do |t|
    t.string "cohort_column", null: false
    t.integer "weight"
    t.string "value"
    t.boolean "active", default: true
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "cohort_tabs", force: :cascade do |t|
    t.bigint "cohort_id", null: false
    t.string "name"
    t.jsonb "rules"
    t.integer "order", default: 0, null: false
    t.jsonb "permissions", default: [], null: false
    t.string "base_scope", default: "current_scope"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["cohort_id"], name: "index_cohort_tabs_on_cohort_id"
  end

  create_table "cohorts", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
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
    t.boolean "system_cohort", default: false
    t.string "type", default: "GrdaWarehouse::Cohort"
    t.bigint "project_group_id"
    t.boolean "enforce_project_visibility_on_cells", default: true, null: false
    t.boolean "expose_inactive_on_client_dashboard", default: false
    t.index ["deleted_at"], name: "index_cohorts_on_deleted_at"
    t.index ["project_group_id"], name: "index_cohorts_on_project_group_id"
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
    t.integer "domestic_violence_lookback_days", default: 0, null: false
    t.string "support_contact_email"
    t.integer "completeness_goal", default: 90
    t.integer "excess_goal", default: 105
    t.integer "timeliness_goal", default: 14
    t.integer "income_increase_goal", default: 75
    t.integer "ph_destination_increase_goal", default: 60
    t.integer "move_in_date_threshold", default: 30
    t.integer "pf_universal_data_element_threshold", default: 2, null: false
    t.integer "pf_utilization_min", default: 66, null: false
    t.integer "pf_utilization_max", default: 104, null: false
    t.integer "pf_timeliness_threshold", default: 3, null: false
    t.boolean "pf_show_income", default: false, null: false
    t.boolean "pf_show_additional_timeliness", default: false, null: false
    t.integer "cas_sync_months", default: 3
    t.boolean "send_sms_for_covid_reminders", default: false, null: false
    t.integer "bypass_2fa_duration", default: 0, null: false
    t.string "health_claims_data_path"
    t.boolean "enable_youth_hrp", default: true, null: false
    t.boolean "enable_system_cohorts", default: false
    t.boolean "currently_homeless_cohort", default: false
    t.boolean "show_client_last_seen_info_in_client_details", default: true
    t.boolean "ineligible_uses_extrapolated_days", default: true, null: false
    t.string "warehouse_client_name_order", default: "earliest", null: false
    t.string "cas_calculator", default: "GrdaWarehouse::CasProjectClientCalculator::Default", null: false
    t.boolean "service_register_visible", default: false, null: false
    t.boolean "enable_youth_unstably_housed", default: true
    t.boolean "veteran_cohort", default: false, null: false
    t.boolean "youth_cohort", default: false, null: false
    t.boolean "chronic_cohort", default: false, null: false
    t.boolean "adult_and_child_cohort", default: false, null: false
    t.boolean "adult_only_cohort", default: false, null: false
    t.boolean "youth_no_child_cohort", default: false, null: false
    t.boolean "youth_and_child_cohort", default: false, null: false
    t.integer "cas_sync_project_group_id"
    t.string "majority_sheltered_calculation", default: "current_living_situation"
    t.date "system_cohort_processing_date"
    t.integer "system_cohort_date_window", default: 1
    t.string "roi_model", default: "explicit"
    t.string "client_dashboard", default: "default", null: false
    t.boolean "require_service_for_reporting_default", default: true, null: false
    t.string "supplemental_enrollment_importer", default: "GrdaWarehouse::Tasks::EnrollmentExtrasImport"
    t.string "verified_homeless_history_method", default: "visible_in_window"
    t.boolean "youth_hoh_cohort", default: false, null: false
    t.integer "youth_hoh_cohort_project_group_id"
    t.boolean "chronic_tab_justifications", default: true
    t.boolean "chronic_tab_roi"
    t.integer "filter_date_span_years", default: 1, null: false
    t.boolean "include_pii_in_detail_downloads", default: true
    t.date "self_report_start_date"
    t.boolean "chronic_adult_only_cohort", default: false
    t.boolean "enable_auto_deduplication", default: true
    t.integer "number_lms_courses_required", default: -1
    t.string "rds_s3_integration_role_arn"
  end

  create_table "contacts", id: :serial, force: :cascade do |t|
    t.string "type", null: false
    t.integer "entity_id", null: false
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["entity_id"], name: "index_contacts_on_entity_id"
    t.index ["type"], name: "index_contacts_on_type"
  end

  create_table "csg_engage_agencies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "csg_engage_agency_id"
  end

  create_table "csg_engage_program_mappings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "project_id"
    t.string "clarity_name"
    t.boolean "include_in_export", default: true, null: false
    t.bigint "program_id"
    t.index ["program_id"], name: "index_csg_engage_program_mappings_on_program_id"
    t.index ["project_id"], name: "index_csg_engage_program_mappings_on_project_id"
  end

  create_table "csg_engage_program_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "report_id"
    t.string "raw_result"
    t.jsonb "json_result"
    t.jsonb "error_data"
    t.jsonb "warning_data"
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "imported_program_name"
    t.string "imported_import_keyword"
    t.string "cleared_at"
    t.bigint "program_id"
    t.index ["program_id"], name: "index_csg_engage_program_reports_on_program_id"
    t.index ["report_id"], name: "index_csg_engage_program_reports_on_report_id"
  end

  create_table "csg_engage_programs", force: :cascade do |t|
    t.bigint "agency_id"
    t.string "csg_engage_name", null: false
    t.string "csg_engage_import_keyword", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_csg_engage_programs_on_agency_id"
  end

  create_table "csg_engage_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "project_ids", default: [], null: false, array: true
    t.bigint "agency_id"
    t.index ["agency_id"], name: "index_csg_engage_reports_on_agency_id"
  end

  create_table "custom_imports_b_al_rows", force: :cascade do |t|
    t.bigint "import_file_id"
    t.bigint "data_source_id"
    t.string "assessment_question"
    t.string "response_code"
    t.string "response_text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["created_at"], name: "index_custom_imports_b_al_rows_on_created_at"
    t.index ["data_source_id"], name: "index_custom_imports_b_al_rows_on_data_source_id"
    t.index ["import_file_id"], name: "index_custom_imports_b_al_rows_on_import_file_id"
    t.index ["updated_at"], name: "index_custom_imports_b_al_rows_on_updated_at"
  end

  create_table "custom_imports_b_contacts_rows", force: :cascade do |t|
    t.bigint "import_file_id"
    t.bigint "data_source_id"
    t.integer "row_number", null: false
    t.string "personal_id", null: false
    t.string "unique_id"
    t.string "agency_id", null: false
    t.string "contact_name"
    t.string "contact_type"
    t.string "phone"
    t.string "phone_alternate"
    t.string "email"
    t.string "note"
    t.string "private"
    t.datetime "contact_created_at", precision: nil
    t.datetime "contact_updated_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["created_at"], name: "index_custom_imports_b_contacts_rows_on_created_at"
    t.index ["data_source_id"], name: "index_custom_imports_b_contacts_rows_on_data_source_id"
    t.index ["import_file_id"], name: "index_custom_imports_b_contacts_rows_on_import_file_id"
    t.index ["updated_at"], name: "index_custom_imports_b_contacts_rows_on_updated_at"
  end

  create_table "custom_imports_b_coo_rows", force: :cascade do |t|
    t.string "unique_id", null: false
    t.string "personal_id"
    t.string "enrollment_id"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.string "length_of_time"
    t.string "geolocation_location"
    t.date "collected_on"
    t.bigint "import_file_id"
    t.bigint "data_source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "dirty", default: false
    t.index ["data_source_id"], name: "index_custom_imports_b_coo_rows_on_data_source_id"
    t.index ["import_file_id"], name: "index_custom_imports_b_coo_rows_on_import_file_id"
    t.index ["unique_id"], name: "index_custom_imports_b_coo_rows_on_unique_id", unique: true
  end

  create_table "custom_imports_b_services_rows", force: :cascade do |t|
    t.bigint "import_file_id"
    t.bigint "data_source_id"
    t.integer "row_number", null: false
    t.string "personal_id", null: false
    t.string "unique_id"
    t.string "agency_id", null: false
    t.string "enrollment_id"
    t.string "service_id"
    t.date "date"
    t.string "service_name"
    t.string "service_category"
    t.string "service_item"
    t.string "service_program_usage"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.date "reporting_period_started_on"
    t.date "reporting_period_ended_on"
    t.index ["created_at"], name: "index_custom_imports_b_services_rows_on_created_at"
    t.index ["data_source_id"], name: "index_custom_imports_b_services_rows_on_data_source_id"
    t.index ["import_file_id"], name: "index_custom_imports_b_services_rows_on_import_file_id"
    t.index ["personal_id", "data_source_id"], name: "idx_cibs_p_id_ds_id"
    t.index ["service_id"], name: "index_custom_imports_b_services_rows_on_service_id", unique: true
    t.index ["updated_at"], name: "index_custom_imports_b_services_rows_on_updated_at"
  end

  create_table "custom_imports_config", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "data_source_id"
    t.boolean "active", default: true, null: false
    t.string "description"
    t.integer "import_hour"
    t.string "import_type"
    t.string "s3_region"
    t.string "s3_bucket"
    t.string "s3_prefix"
    t.string "encrypted_s3_access_key_id"
    t.string "encrypted_s3_access_key_id_iv"
    t.string "encrypted_s3_secret"
    t.string "encrypted_s3_secret_iv"
    t.datetime "last_import_attempted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["created_at"], name: "index_custom_imports_config_on_created_at"
    t.index ["data_source_id"], name: "index_custom_imports_config_on_data_source_id"
    t.index ["updated_at"], name: "index_custom_imports_config_on_updated_at"
    t.index ["user_id"], name: "index_custom_imports_config_on_user_id"
  end

  create_table "custom_imports_files", force: :cascade do |t|
    t.string "type"
    t.bigint "config_id"
    t.bigint "data_source_id"
    t.string "file"
    t.string "status"
    t.jsonb "summary"
    t.jsonb "import_errors"
    t.string "content_type"
    t.binary "content"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.index ["config_id"], name: "index_custom_imports_files_on_config_id"
    t.index ["created_at"], name: "index_custom_imports_files_on_created_at"
    t.index ["data_source_id"], name: "index_custom_imports_files_on_data_source_id"
    t.index ["updated_at"], name: "index_custom_imports_files_on_updated_at"
  end

  create_table "dashboard_export_reports", id: :serial, force: :cascade do |t|
    t.integer "file_id"
    t.integer "user_id"
    t.integer "job_id"
    t.string "coc_code"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
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
    t.datetime "last_imported_at", precision: nil
    t.date "newest_updated_at"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "source_type"
    t.boolean "munged_personal_id", default: false, null: false
    t.string "short_name"
    t.boolean "visible_in_window", default: false, null: false
    t.boolean "authoritative", default: false
    t.string "after_create_path"
    t.boolean "import_paused", default: false, null: false
    t.string "authoritative_type"
    t.string "source_id"
    t.datetime "deleted_at", precision: nil
    t.boolean "service_scannable", default: false, null: false
    t.jsonb "import_aggregators", default: {}
    t.jsonb "import_cleanups", default: {}
    t.boolean "refuse_imports_with_errors", default: false
    t.string "hmis"
    t.boolean "obey_consent", default: true
  end

  create_table "datasets", force: :cascade do |t|
    t.string "source_type", null: false
    t.bigint "source_id", null: false
    t.string "identifier"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_type", "source_id"], name: "index_datasets_on_source"
  end

  create_table "direct_financial_assistances", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.integer "user_id"
    t.date "provided_on"
    t.string "type_provided"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "imported", default: false
    t.integer "amount"
    t.index ["deleted_at"], name: "index_direct_financial_assistances_on_deleted_at"
  end

  create_table "document_exports", force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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

  create_table "eccovia_assessments", force: :cascade do |t|
    t.string "client_id"
    t.bigint "data_source_id"
    t.string "assessment_id"
    t.integer "score"
    t.datetime "assessed_at", precision: nil
    t.string "assessor_id"
    t.string "assessor_name"
    t.string "assessor_email"
    t.datetime "last_fetched_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["client_id", "data_source_id", "assessment_id"], name: "e_a_c_d_a_idx", unique: true
    t.index ["data_source_id"], name: "index_eccovia_assessments_on_data_source_id"
  end

  create_table "eccovia_case_managers", force: :cascade do |t|
    t.string "client_id"
    t.bigint "data_source_id"
    t.string "case_manager_id"
    t.string "user_id"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.string "phone"
    t.string "cell"
    t.date "start_date"
    t.date "end_date"
    t.datetime "last_fetched_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["client_id", "data_source_id", "case_manager_id", "user_id"], name: "e_c_m_c_d_a_u_idx", unique: true
    t.index ["data_source_id"], name: "index_eccovia_case_managers_on_data_source_id"
  end

  create_table "eccovia_client_contacts", force: :cascade do |t|
    t.string "client_id"
    t.bigint "data_source_id"
    t.string "email"
    t.string "phone"
    t.string "cell"
    t.string "street"
    t.string "street2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.datetime "last_fetched_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["client_id", "data_source_id"], name: "e_c_C_c_d_a_idx", unique: true
    t.index ["data_source_id"], name: "index_eccovia_client_contacts_on_data_source_id"
  end

  create_table "eccovia_fetches", force: :cascade do |t|
    t.bigint "credentials_id"
    t.bigint "data_source_id"
    t.boolean "active", default: false, null: false
    t.datetime "last_fetched_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["credentials_id"], name: "index_eccovia_fetches_on_credentials_id"
    t.index ["data_source_id"], name: "index_eccovia_fetches_on_data_source_id"
  end

  create_table "enrollment_change_histories", id: :serial, force: :cascade do |t|
    t.integer "client_id", null: false
    t.date "on", null: false
    t.jsonb "residential"
    t.jsonb "other"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "version", default: 1, null: false
    t.integer "days_homeless"
    t.index ["client_id"], name: "index_enrollment_change_histories_on_client_id"
  end

  create_table "enrollment_extras", id: :serial, force: :cascade do |t|
    t.integer "enrollment_id"
    t.integer "vispdat_grand_total"
    t.date "vispdat_added_at"
    t.date "vispdat_started_at"
    t.date "vispdat_ended_at"
    t.string "source_tab"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.bigint "file_id"
    t.integer "data_source_id"
    t.string "client_id"
    t.string "client_uid"
    t.string "hud_enrollment_id"
    t.string "enrollment_group_id"
    t.string "project_name"
    t.date "entry_date"
    t.date "exit_date"
    t.string "vispdat_type"
    t.string "vispdat_range"
    t.string "prioritization_tool_type"
    t.integer "prioritization_tool_score"
    t.string "agency_name"
    t.string "community"
    t.boolean "lgbtq_household_members"
    t.boolean "client_lgbtq"
    t.boolean "dv_survivor"
    t.integer "prevention_tool_score"
    t.string "shelter_priority"
    t.string "permanent_housing_priority_group"
    t.index ["client_id", "data_source_id"], name: "index_enrollment_extras_on_client_id_and_data_source_id"
    t.index ["file_id"], name: "index_enrollment_extras_on_file_id"
    t.index ["hud_enrollment_id", "data_source_id"], name: "index_enrollment_extras_on_hud_enrollment_id_and_data_source_id"
    t.index ["hud_enrollment_id", "entry_date", "vispdat_ended_at", "project_name", "agency_name", "community", "data_source_id"], name: "idx_tpc_uniqueness", unique: true
  end

  create_table "eto_api_configs", id: :serial, force: :cascade do |t|
    t.integer "data_source_id", null: false
    t.jsonb "touchpoint_fields"
    t.jsonb "demographic_fields"
    t.jsonb "demographic_fields_with_attributes"
    t.jsonb "additional_fields"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
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
    t.datetime "last_updated", precision: nil
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
    t.datetime "last_updated", precision: nil
    t.integer "site_id"
    t.index ["client_id"], name: "index_eto_touch_point_lookups_on_client_id"
    t.index ["data_source_id"], name: "index_eto_touch_point_lookups_on_data_source_id"
  end

  create_table "eto_touch_point_response_times", id: :serial, force: :cascade do |t|
    t.integer "touch_point_unique_identifier", null: false
    t.integer "response_unique_identifier", null: false
    t.datetime "response_last_updated", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "faked_pii", default: false
    t.jsonb "project_ids"
    t.boolean "include_deleted", default: false
    t.string "content_type"
    t.binary "content"
    t.string "file"
    t.integer "delayed_job_id"
    t.string "version"
    t.boolean "confidential", default: false, null: false
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.jsonb "options"
    t.index ["deleted_at"], name: "index_exports_on_deleted_at"
    t.index ["export_id"], name: "index_exports_on_export_id"
  end

  create_table "exports_ad_hoc_anons", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "options"
    t.jsonb "headers"
    t.jsonb "rows"
    t.integer "client_count"
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
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
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["created_at"], name: "index_exports_ad_hocs_on_created_at"
    t.index ["updated_at"], name: "index_exports_ad_hocs_on_updated_at"
    t.index ["user_id"], name: "index_exports_ad_hocs_on_user_id"
  end

  create_table "external_ids", force: :cascade do |t|
    t.string "value", null: false
    t.string "source_type", null: false
    t.bigint "source_id", null: false
    t.bigint "remote_credential_id"
    t.bigint "external_request_log_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "namespace"
    t.index ["external_request_log_id"], name: "index_external_ids_on_external_request_log_id"
    t.index ["remote_credential_id"], name: "index_external_ids_on_remote_credential_id"
    t.index ["source_id", "source_type", "remote_credential_id"], name: "uidx_external_ids_source_value", unique: true, where: "(((namespace)::text <> 'ac_hmis_mci'::text) OR (namespace IS NULL))"
    t.index ["source_type", "namespace", "value"], name: "uidx_external_id_ns_value", unique: true, where: "((namespace)::text <> ALL (ARRAY[('ac_hmis_mci'::character varying)::text, ('ac_hmis_mci_unique_id'::character varying)::text]))"
    t.index ["value"], name: "index_external_ids_on_value"
  end

  create_table "external_reporting_cohort_permissions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "cohort_id", null: false
    t.string "permission", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.index ["cohort_id"], name: "index_external_reporting_cohort_permissions_on_cohort_id"
    t.index ["user_id"], name: "index_external_reporting_cohort_permissions_on_user_id"
  end

  create_table "external_reporting_project_permissions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "project_id", null: false
    t.string "permission", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.index ["project_id"], name: "index_external_reporting_project_permissions_on_project_id"
    t.index ["user_id"], name: "index_external_reporting_project_permissions_on_user_id"
  end

  create_table "external_request_logs", force: :cascade do |t|
    t.string "initiator_type"
    t.bigint "initiator_id"
    t.string "identifier"
    t.string "content_type"
    t.string "url", null: false
    t.string "http_method", default: "GET", null: false
    t.inet "ip"
    t.jsonb "request_headers", default: {}, null: false
    t.text "request", null: false
    t.text "response", null: false
    t.integer "http_status"
    t.datetime "requested_at", precision: nil, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["initiator_id", "initiator_type"], name: "index_external_request_logs_on_initiator_id_and_initiator_type"
    t.index ["initiator_type", "initiator_id"], name: "index_external_request_logs_on_initiator"
    t.index ["ip"], name: "index_external_request_logs_on_ip"
    t.index ["requested_at"], name: "index_external_request_logs_on_requested_at"
  end

  create_table "fake_data", id: :serial, force: :cascade do |t|
    t.string "environment", null: false
    t.text "map"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "client_ids"
  end

  create_table "favorites", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "entity_type", null: false
    t.bigint "entity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_favorites_on_created_at"
    t.index ["entity_type", "entity_id"], name: "index_favorites_on_entity"
    t.index ["updated_at"], name: "index_favorites_on_updated_at"
    t.index ["user_id", "entity_id", "entity_type"], name: "one_entity_per_type_per_id_per_user", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "federal_census_breakdowns", force: :cascade do |t|
    t.date "accurate_on", comment: "Most recent census date"
    t.string "type"
    t.string "geography_level", comment: "State, zip, CoC (or maybe 010, 040, 050)"
    t.string "geography", comment: "MA, 02101, MA-500"
    t.string "measure", comment: "Detail of race, age, etc. (Asian, 50-59...)"
    t.integer "value", comment: "count of population"
    t.string "geo_id"
    t.string "race"
    t.string "gender"
    t.integer "age_min"
    t.integer "age_max"
    t.string "source", comment: "Source of data"
    t.string "census_variable_name", comment: "For debugging, variable name used in source"
    t.index ["accurate_on", "geography", "geography_level", "measure"], name: "idx_fed_census_acc_on_geo_measure"
  end

  create_table "files", id: :serial, force: :cascade do |t|
    t.string "type", null: false
    t.string "file"
    t.string "content_type"
    t.binary "content"
    t.integer "client_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "deleted_at", precision: nil
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
    t.datetime "consent_revoked_at", precision: nil
    t.jsonb "coc_codes", default: []
    t.bigint "enrollment_id"
    t.boolean "confidential", default: false, null: false
    t.bigint "updated_by_id"
    t.bigint "data_source_id"
    t.integer "consent_revoked_by_user_id"
    t.index ["data_source_id"], name: "index_files_on_data_source_id"
    t.index ["enrollment_id"], name: "index_files_on_enrollment_id"
    t.index ["type"], name: "index_files_on_type"
    t.index ["updated_by_id"], name: "index_files_on_updated_by_id"
    t.index ["vispdat_id"], name: "index_files_on_vispdat_id"
  end

  create_table "financial_clients", force: :cascade do |t|
    t.integer "external_client_id", null: false
    t.integer "client_id", comment: "Reference to a destination client"
    t.integer "data_source_id", null: false
    t.string "client_first_name"
    t.string "client_last_name"
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.string "service_provder_company"
    t.integer "head_of_household"
    t.integer "deleted_was_the_client_screened_for_homelessness"
    t.integer "does_the_client_have_a_tenant_based_housing_voucher"
    t.string "if_yes_what_pha_issued_the_voucher"
    t.string "if_yes_what_type_of_voucher_was_issued"
    t.string "voucher_type_other"
    t.string "what_housing_program_is_the_client_in"
    t.string "housing_program_other"
    t.datetime "date_vouchered_if_applicable", precision: nil
    t.datetime "date_of_referral_to_agency", precision: nil
    t.datetime "lease_start_date", precision: nil
    t.string "city_of_unit"
    t.decimal "income"
    t.integer "household_members"
    t.integer "household_members_under_18"
    t.integer "household_members_over_62"
    t.datetime "client_birthdate", precision: nil
    t.integer "ada_needs"
    t.string "race"
    t.string "gender"
    t.string "ethnicity"
    t.string "cal_optima_client_id"
    t.integer "dv_survivor"
    t.string "most_recent_living_situation"
    t.string "most_recent_living_situation_other"
    t.datetime "date_of_referral_to_wit", precision: nil
    t.integer "delete_are_rental_arrears_owed"
    t.decimal "rent_owed_rental_arrears"
    t.integer "total_time_housed"
    t.string "hmis_id_if_applicable"
    t.integer "housed_after_18_months"
    t.integer "housed_after_24_months"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.string "was_the_client_screened_for_homelessness"
    t.string "are_rental_arrears_owed"
    t.index ["external_client_id", "data_source_id"], name: "ex_id_ds_id_fc_idx", unique: true
  end

  create_table "financial_providers", force: :cascade do |t|
    t.integer "provider_id", null: false
    t.integer "data_source_id", null: false
    t.string "agency_name", null: false
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.string "service_provider_area"
    t.string "service_provider_area_by_city"
    t.string "pha_contracts"
    t.string "client_referral_process"
    t.string "client_referral_process_other"
    t.string "voucher_types_for_client"
    t.string "housing_programs"
    t.string "housing_program_other"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["provider_id", "data_source_id"], name: "p_id_ds_id_fp_idx", unique: true
  end

  create_table "financial_transactions", force: :cascade do |t|
    t.integer "transaction_id", null: false
    t.integer "data_source_id", null: false
    t.string "transaction_status", null: false
    t.datetime "transaction_date", precision: nil, null: false
    t.datetime "paid_date", precision: nil
    t.integer "external_client_id", null: false
    t.integer "provider_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["transaction_id", "data_source_id"], name: "tx_id_ds_id_ft_idx", unique: true
  end

  create_table "generate_service_history_batch_logs", id: :serial, force: :cascade do |t|
    t.integer "generate_service_history_log_id"
    t.integer "to_process"
    t.integer "updated"
    t.integer "patched"
    t.integer "delayed_job_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "generate_service_history_log", id: :serial, force: :cascade do |t|
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.integer "to_delete"
    t.integer "to_add"
    t.integer "to_update"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "batches"
  end

  create_table "generic_services", force: :cascade do |t|
    t.bigint "client_id"
    t.string "source_type"
    t.bigint "source_id"
    t.date "date"
    t.string "title"
    t.integer "data_source_id"
    t.string "category"
    t.index ["client_id"], name: "index_generic_services_on_client_id"
    t.index ["source_id", "source_type"], name: "gs_source_id_source_type_uniq", unique: true
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
    t.datetime "deleted_at", precision: nil
    t.bigint "collection_id"
    t.index ["access_group_id", "entity_id", "entity_type"], name: "one_entity_per_type_per_group", unique: true, where: "(access_group_id <> 0)"
    t.index ["collection_id", "entity_id", "entity_type"], name: "one_entity_per_type_per_collection", unique: true, where: "(collection_id IS NOT NULL)"
    t.index ["collection_id"], name: "index_group_viewable_entities_on_collection_id"
  end

  create_table "hap_report_clients", force: :cascade do |t|
    t.bigint "client_id"
    t.integer "age"
    t.boolean "emancipated"
    t.boolean "head_of_household"
    t.string "household_ids", array: true
    t.integer "project_types", array: true
    t.boolean "veteran"
    t.boolean "mental_health"
    t.boolean "substance_use_disorder"
    t.boolean "domestic_violence"
    t.integer "income_at_start"
    t.integer "income_at_exit"
    t.boolean "homeless"
    t.integer "nights_in_shelter"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "head_of_household_for", array: true
    t.string "personal_id"
    t.string "mci_id"
    t.index ["client_id"], name: "index_hap_report_clients_on_client_id"
  end

  create_table "hap_report_eraps", force: :cascade do |t|
    t.bigint "hap_report_id"
    t.string "personal_id", null: false
    t.string "mci_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.integer "age"
    t.string "household_id"
    t.boolean "head_of_household"
    t.boolean "emancipated"
    t.integer "project_type"
    t.boolean "veteran"
    t.boolean "mental_health_disorder"
    t.boolean "substance_use_disorder"
    t.boolean "survivor_of_domestic_violence"
    t.integer "income_at_start"
    t.integer "income_at_exit"
    t.boolean "homeless"
    t.integer "nights_in_shelter"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hap_report_id"], name: "index_hap_report_eraps_on_hap_report_id"
  end

  create_table "health_emergency_ama_restrictions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "client_id", null: false
    t.integer "agency_id"
    t.string "restricted"
    t.string "note"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.text "notes"
    t.string "emergency_type"
    t.datetime "notification_at", precision: nil
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
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
    t.datetime "isolation_requested_at", precision: nil
    t.string "location"
    t.date "started_on"
    t.date "scheduled_to_end_on"
    t.date "ended_on"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
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
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.text "notes"
    t.string "emergency_type"
    t.datetime "notification_at", precision: nil
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.bigint "ama_restriction_id"
    t.index ["ama_restriction_id"], name: "index_health_emergency_uploaded_tests_on_ama_restriction_id"
    t.index ["batch_id"], name: "index_health_emergency_uploaded_tests_on_batch_id"
    t.index ["created_at"], name: "index_health_emergency_uploaded_tests_on_created_at"
    t.index ["deleted_at"], name: "index_health_emergency_uploaded_tests_on_deleted_at"
    t.index ["updated_at"], name: "index_health_emergency_uploaded_tests_on_updated_at"
  end

  create_table "health_emergency_vaccinations", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "client_id", null: false
    t.integer "agency_id"
    t.date "vaccinated_on", null: false
    t.string "vaccinated_at"
    t.date "follow_up_on"
    t.datetime "follow_up_notification_sent_at", precision: nil
    t.string "vaccination_type", null: false
    t.string "follow_up_cell_phone"
    t.string "emergency_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "health_vaccination_id"
    t.string "preferred_language", default: "en"
    t.text "notification_status"
    t.index ["agency_id"], name: "index_health_emergency_vaccinations_on_agency_id"
    t.index ["client_id"], name: "index_health_emergency_vaccinations_on_client_id"
    t.index ["created_at"], name: "index_health_emergency_vaccinations_on_created_at"
    t.index ["updated_at"], name: "index_health_emergency_vaccinations_on_updated_at"
    t.index ["user_id"], name: "index_health_emergency_vaccinations_on_user_id"
  end

  create_table "helps", id: :serial, force: :cascade do |t|
    t.string "controller_path", null: false
    t.string "action_name", null: false
    t.string "external_url"
    t.string "title", null: false
    t.text "content", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "location", default: "internal", null: false
    t.index ["controller_path", "action_name"], name: "index_helps_on_controller_path_and_action_name", unique: true
    t.index ["created_at"], name: "index_helps_on_created_at"
    t.index ["updated_at"], name: "index_helps_on_updated_at"
  end

  create_table "hmis_2020_affiliations", force: :cascade do |t|
    t.string "AffiliationID"
    t.string "ProjectID"
    t.string "ResProjectID"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["AffiliationID", "data_source_id"], name: "hmis_2020_affiliations-lZaj"
    t.index ["ExportID"], name: "hmis_2020_affiliations-qycr"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_affiliations_imid_du"
    t.index ["source_type", "source_id"], name: "hmis_2020_affiliations-jXFa"
  end

  create_table "hmis_2020_aggregated_enrollments", force: :cascade do |t|
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.index ["DateCreated"], name: "hmis_2020_aggregated_enrollments-Jmkq"
    t.index ["DateDeleted"], name: "hmis_2020_aggregated_enrollments-6wqk"
    t.index ["DateUpdated"], name: "hmis_2020_aggregated_enrollments-4L8g"
    t.index ["EnrollmentID", "PersonalID", "data_source_id"], name: "hmis_2020_aggregated_enrollments-0cTv", unique: true
    t.index ["EnrollmentID", "PersonalID", "importer_log_id", "data_source_id"], name: "hmis_2020_aggregated_enrollments-fSDc", unique: true
    t.index ["EnrollmentID", "PersonalID"], name: "hmis_2020_aggregated_enrollments-ocKA"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmis_2020_aggregated_enrollments-zNVo"
    t.index ["EnrollmentID"], name: "hmis_2020_aggregated_enrollments-RNSl"
    t.index ["EntryDate"], name: "hmis_2020_aggregated_enrollments-oiEU"
    t.index ["ExportID"], name: "hmis_2020_aggregated_enrollments-fXAB"
    t.index ["HouseholdID"], name: "hmis_2020_aggregated_enrollments-QV2G"
    t.index ["LivingSituation"], name: "hmis_2020_aggregated_enrollments-ysoO"
    t.index ["PersonalID"], name: "hmis_2020_aggregated_enrollments-wnDD"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmis_2020_aggregated_enrollments-Xqsk"
    t.index ["ProjectID", "HouseholdID"], name: "hmis_2020_aggregated_enrollments-BMfj"
    t.index ["ProjectID", "RelationshipToHoH"], name: "hmis_2020_aggregated_enrollments-RJNU"
    t.index ["ProjectID"], name: "hmis_2020_aggregated_enrollments-CpSq"
    t.index ["RelationshipToHoH"], name: "hmis_2020_aggregated_enrollments-E6ih"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears"], name: "hmis_2020_aggregated_enrollments-ZGm4"
    t.index ["source_type", "source_id"], name: "hmis_2020_aggregated_enrollments-G7U1"
  end

  create_table "hmis_2020_aggregated_exits", force: :cascade do |t|
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.index ["DateCreated"], name: "hmis_2020_aggregated_exits-2lOR"
    t.index ["DateDeleted"], name: "hmis_2020_aggregated_exits-cduB"
    t.index ["DateUpdated"], name: "hmis_2020_aggregated_exits-VRGa"
    t.index ["EnrollmentID"], name: "hmis_2020_aggregated_exits-BwSf"
    t.index ["ExitDate"], name: "hmis_2020_aggregated_exits-GBBG"
    t.index ["ExitID", "data_source_id"], name: "hmis_2020_aggregated_exits-UYdB", unique: true
    t.index ["ExitID", "importer_log_id", "data_source_id"], name: "hmis_2020_aggregated_exits-2mwI", unique: true
    t.index ["ExitID"], name: "hmis_2020_aggregated_exits-g6y1"
    t.index ["ExportID"], name: "hmis_2020_aggregated_exits-auds"
    t.index ["PersonalID"], name: "hmis_2020_aggregated_exits-EPOP"
    t.index ["source_type", "source_id"], name: "hmis_2020_aggregated_exits-SgMf"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["AssessmentID"], name: "hmis_2020_assessment_results-AnQd"
    t.index ["AssessmentResultID", "data_source_id"], name: "hmis_2020_assessment_results-rawc"
    t.index ["ExportID"], name: "hmis_2020_assessment_results-2kxY"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_assessment_results_imid_du"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["AssessmentDate"], name: "hmis_2020_assessments-YW8L"
    t.index ["AssessmentID", "data_source_id"], name: "hmis_2020_assessments-3sM0"
    t.index ["AssessmentID"], name: "hmis_2020_assessments-kqMe"
    t.index ["EnrollmentID"], name: "hmis_2020_assessments-gMUw"
    t.index ["ExportID"], name: "hmis_2020_assessments-u0eq"
    t.index ["PersonalID"], name: "hmis_2020_assessments-kdgA"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_assessments_imid_du"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DOB"], name: "hmis_2020_clients-qUjP"
    t.index ["DateCreated"], name: "hmis_2020_clients-rrgI"
    t.index ["DateUpdated"], name: "hmis_2020_clients-jdcP"
    t.index ["ExportID"], name: "hmis_2020_clients-gmgS"
    t.index ["FirstName"], name: "hmis_2020_clients-48Qj"
    t.index ["LastName"], name: "hmis_2020_clients-3vTw"
    t.index ["PersonalID", "data_source_id"], name: "hmis_2020_clients-t6qe"
    t.index ["PersonalID"], name: "hmis_2020_clients-qK9d"
    t.index ["VeteranStatus"], name: "hmis_2020_clients-z1iL"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_clients_imid_du"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["CurrentLivingSitID", "data_source_id"], name: "hmis_2020_current_living_situations-cLpS"
    t.index ["CurrentLivingSitID"], name: "hmis_2020_current_living_situations-DXZ0"
    t.index ["CurrentLivingSituation"], name: "hmis_2020_current_living_situations-WmJZ"
    t.index ["EnrollmentID"], name: "hmis_2020_current_living_situations-jG8y"
    t.index ["ExportID"], name: "hmis_2020_current_living_situations-hGfj"
    t.index ["InformationDate"], name: "hmis_2020_current_living_situations-4v4L"
    t.index ["PersonalID"], name: "hmis_2020_current_living_situations-vWt4"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_current_living_situations_imid_du"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis_2020_disabilities-p0j2"
    t.index ["DateUpdated"], name: "hmis_2020_disabilities-oxMH"
    t.index ["DisabilitiesID", "data_source_id"], name: "hmis_2020_disabilities-DA3C"
    t.index ["DisabilitiesID"], name: "hmis_2020_disabilities-8DFL"
    t.index ["EnrollmentID"], name: "hmis_2020_disabilities-1JPN"
    t.index ["ExportID"], name: "hmis_2020_disabilities-G1Z0"
    t.index ["PersonalID"], name: "hmis_2020_disabilities-2lYA"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_disabilities_imid_du"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis_2020_employment_educations-oPbl"
    t.index ["DateUpdated"], name: "hmis_2020_employment_educations-rTDS"
    t.index ["EmploymentEducationID", "data_source_id"], name: "hmis_2020_employment_educations-zM3A"
    t.index ["EmploymentEducationID"], name: "hmis_2020_employment_educations-Hv6e"
    t.index ["EnrollmentID"], name: "hmis_2020_employment_educations-mSvG"
    t.index ["ExportID"], name: "hmis_2020_employment_educations-uCTm"
    t.index ["PersonalID"], name: "hmis_2020_employment_educations-EPrc"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_employment_educations_imid_du"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["CoCCode"], name: "hmis_2020_enrollment_cocs-5ROz"
    t.index ["DateCreated"], name: "hmis_2020_enrollment_cocs-zikd"
    t.index ["DateDeleted"], name: "hmis_2020_enrollment_cocs-GUQA"
    t.index ["DateUpdated"], name: "hmis_2020_enrollment_cocs-6Mre"
    t.index ["EnrollmentCoCID", "data_source_id"], name: "hmis_2020_enrollment_cocs-LilW"
    t.index ["EnrollmentCoCID"], name: "hmis_2020_enrollment_cocs-6ENr"
    t.index ["EnrollmentID"], name: "hmis_2020_enrollment_cocs-gQJA"
    t.index ["ExportID"], name: "hmis_2020_enrollment_cocs-sVGW"
    t.index ["PersonalID"], name: "hmis_2020_enrollment_cocs-5FMZ"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_enrollment_cocs_imid_du"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis_2020_enrollments-ZK9t"
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
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_enrollments_imid_du"
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
    t.string "LocationCrisisOrPHHousing"
    t.integer "ReferralResult"
    t.date "ResultDate"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis_2020_exits-F305"
    t.index ["DateDeleted"], name: "hmis_2020_exits-s54g"
    t.index ["DateUpdated"], name: "hmis_2020_exits-Crsu"
    t.index ["EnrollmentID"], name: "hmis_2020_exits-Z3F6"
    t.index ["ExitDate"], name: "hmis_2020_exits-nEjV"
    t.index ["ExitID", "data_source_id"], name: "hmis_2020_exits-S9yO"
    t.index ["ExitID"], name: "hmis_2020_exits-4DnO"
    t.index ["ExportID"], name: "hmis_2020_exits-c4Un"
    t.index ["PersonalID"], name: "hmis_2020_exits-QkLT"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_exits_imid_du"
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
    t.datetime "ExportDate", precision: nil
    t.date "ExportStartDate"
    t.date "ExportEndDate"
    t.string "SoftwareName"
    t.string "SoftwareVersion"
    t.integer "ExportPeriodType"
    t.integer "ExportDirective"
    t.integer "HashStatus"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["ExportID", "data_source_id"], name: "hmis_2020_exports-YcvP"
    t.index ["ExportID"], name: "hmis_2020_exports-awLV"
    t.index ["importer_log_id"], name: "index_hmis_2020_exports_on_importer_log_id"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis_2020_funders-CQE4"
    t.index ["DateUpdated"], name: "hmis_2020_funders-yKF3"
    t.index ["ExportID"], name: "hmis_2020_funders-qRxb"
    t.index ["FunderID", "data_source_id"], name: "hmis_2020_funders-XiWW"
    t.index ["FunderID"], name: "hmis_2020_funders-P3hw"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_funders_imid_du"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis_2020_health_and_dvs-85bD"
    t.index ["DateUpdated"], name: "hmis_2020_health_and_dvs-TUTe"
    t.index ["EnrollmentID"], name: "hmis_2020_health_and_dvs-SbP4"
    t.index ["ExportID"], name: "hmis_2020_health_and_dvs-w4jj"
    t.index ["HealthAndDVID", "data_source_id"], name: "hmis_2020_health_and_dvs-zonF"
    t.index ["HealthAndDVID"], name: "hmis_2020_health_and_dvs-zE81"
    t.index ["PersonalID"], name: "hmis_2020_health_and_dvs-Kqiz"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_health_and_dvs_imid_du"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis_2020_income_benefits-JwPq"
    t.index ["DateUpdated"], name: "hmis_2020_income_benefits-aphJ"
    t.index ["EnrollmentID"], name: "hmis_2020_income_benefits-AUwp"
    t.index ["ExportID"], name: "hmis_2020_income_benefits-BE9p"
    t.index ["IncomeBenefitsID", "data_source_id"], name: "hmis_2020_income_benefits-tBcJ"
    t.index ["IncomeBenefitsID"], name: "hmis_2020_income_benefits-pfYl"
    t.index ["PersonalID"], name: "hmis_2020_income_benefits-NcHX"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_income_benefits_imid_du"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis_2020_inventories-J6na"
    t.index ["DateUpdated"], name: "hmis_2020_inventories-0TGU"
    t.index ["ExportID"], name: "hmis_2020_inventories-whCo"
    t.index ["InventoryID", "data_source_id"], name: "hmis_2020_inventories-LNwI"
    t.index ["InventoryID"], name: "hmis_2020_inventories-fun6"
    t.index ["ProjectID", "CoCCode"], name: "hmis_2020_inventories-yV3L"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_inventories_imid_du"
    t.index ["source_type", "source_id"], name: "hmis_2020_inventories-DTHt"
  end

  create_table "hmis_2020_organizations", force: :cascade do |t|
    t.string "OrganizationID"
    t.string "OrganizationName"
    t.integer "VictimServicesProvider"
    t.string "OrganizationCommonName"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["ExportID"], name: "hmis_2020_organizations-VQWo"
    t.index ["OrganizationID", "data_source_id"], name: "hmis_2020_organizations-MfSb"
    t.index ["OrganizationID"], name: "hmis_2020_organizations-Prts"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_organizations_imid_du"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis_2020_project_cocs-Tmf3"
    t.index ["DateUpdated"], name: "hmis_2020_project_cocs-OI4Q"
    t.index ["ExportID"], name: "hmis_2020_project_cocs-GTs4"
    t.index ["ProjectCoCID", "data_source_id"], name: "hmis_2020_project_cocs-JAwb"
    t.index ["ProjectCoCID"], name: "hmis_2020_project_cocs-iuZj"
    t.index ["ProjectID", "CoCCode"], name: "hmis_2020_project_cocs-K8nw"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_project_cocs_imid_du"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis_2020_projects-ctk2"
    t.index ["DateUpdated"], name: "hmis_2020_projects-zcbu"
    t.index ["ExportID"], name: "hmis_2020_projects-fqB3"
    t.index ["ProjectID", "data_source_id"], name: "hmis_2020_projects-oxQa"
    t.index ["ProjectID"], name: "hmis_2020_projects-nhkJ"
    t.index ["ProjectType"], name: "hmis_2020_projects-xkUs"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_projects_imid_du"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis_2020_services-eNab"
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
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_services_imid_du"
    t.index ["source_type", "source_id"], name: "hmis_2020_services-4CG1"
  end

  create_table "hmis_2020_users", force: :cascade do |t|
    t.string "UserID"
    t.string "UserFirstName"
    t.string "UserLastName"
    t.string "UserPhone"
    t.string "UserExtension"
    t.string "UserEmail"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["ExportID"], name: "hmis_2020_users-Ls1u"
    t.index ["UserID", "data_source_id"], name: "hmis_2020_users-DmeI"
    t.index ["UserID"], name: "hmis_2020_users-74tq"
    t.index ["importer_log_id", "DateUpdated"], name: "idx_hmis_2020_users_imid_du"
    t.index ["source_type", "source_id"], name: "hmis_2020_users-ZfY6"
  end

  create_table "hmis_2022_affiliations", force: :cascade do |t|
    t.string "AffiliationID"
    t.string "ProjectID"
    t.string "ResProjectID"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["AffiliationID", "data_source_id"], name: "hmis_2022_affiliations-6457"
    t.index ["ExportID"], name: "hmis2022affiliations_9Tjd"
    t.index ["ExportID"], name: "hmis2022affiliations_MCe3"
    t.index ["ExportID"], name: "hmis2022affiliations_lc0a"
    t.index ["ExportID"], name: "hmis2022affiliations_lt6c"
    t.index ["ExportID"], name: "hmis2022affiliations_otVM"
    t.index ["importer_log_id"], name: "index_hmis_2022_affiliations_on_importer_log_id"
  end

  create_table "hmis_2022_assessment_questions", force: :cascade do |t|
    t.string "AssessmentQuestionID"
    t.string "AssessmentID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "AssessmentQuestionGroup"
    t.integer "AssessmentQuestionOrder"
    t.string "AssessmentQuestion"
    t.string "AssessmentAnswer"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["AssessmentID"], name: "hmis2022assessmentquestions_67BE"
    t.index ["AssessmentID"], name: "hmis2022assessmentquestions_FW3S"
    t.index ["AssessmentID"], name: "hmis2022assessmentquestions_NcX9"
    t.index ["AssessmentID"], name: "hmis2022assessmentquestions_Y8GY"
    t.index ["AssessmentID"], name: "hmis2022assessmentquestions_jsNW"
    t.index ["AssessmentQuestionID", "data_source_id"], name: "hmis_2022_assessment_questions-0cd3"
    t.index ["ExportID"], name: "hmis2022assessmentquestions_66AG"
    t.index ["ExportID"], name: "hmis2022assessmentquestions_8Qlc"
    t.index ["ExportID"], name: "hmis2022assessmentquestions_U4bM"
    t.index ["ExportID"], name: "hmis2022assessmentquestions_cKeo"
    t.index ["ExportID"], name: "hmis2022assessmentquestions_mNPM"
    t.index ["importer_log_id"], name: "index_hmis_2022_assessment_questions_on_importer_log_id"
  end

  create_table "hmis_2022_assessment_results", force: :cascade do |t|
    t.string "AssessmentResultID"
    t.string "AssessmentID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "AssessmentResultType"
    t.string "AssessmentResult"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["AssessmentID"], name: "hmis2022assessmentresults_4YlO"
    t.index ["AssessmentID"], name: "hmis2022assessmentresults_A8se"
    t.index ["AssessmentID"], name: "hmis2022assessmentresults_BRi6"
    t.index ["AssessmentID"], name: "hmis2022assessmentresults_BgP9"
    t.index ["AssessmentID"], name: "hmis2022assessmentresults_l8P3"
    t.index ["AssessmentResultID", "data_source_id"], name: "hmis_2022_assessment_results-d6c9"
    t.index ["ExportID"], name: "hmis2022assessmentresults_QszM"
    t.index ["ExportID"], name: "hmis2022assessmentresults_j7wN"
    t.index ["ExportID"], name: "hmis2022assessmentresults_pBh1"
    t.index ["ExportID"], name: "hmis2022assessmentresults_qwBT"
    t.index ["ExportID"], name: "hmis2022assessmentresults_wvgD"
    t.index ["importer_log_id"], name: "index_hmis_2022_assessment_results_on_importer_log_id"
  end

  create_table "hmis_2022_assessments", force: :cascade do |t|
    t.string "AssessmentID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "AssessmentDate"
    t.string "AssessmentLocation"
    t.integer "AssessmentType"
    t.integer "AssessmentLevel"
    t.integer "PrioritizationStatus"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["AssessmentDate"], name: "hmis2022assessments_D5nN"
    t.index ["AssessmentDate"], name: "hmis2022assessments_LJiY"
    t.index ["AssessmentDate"], name: "hmis2022assessments_PKqe"
    t.index ["AssessmentDate"], name: "hmis2022assessments_lWWv"
    t.index ["AssessmentDate"], name: "hmis2022assessments_vHPu"
    t.index ["AssessmentID", "data_source_id"], name: "hmis_2022_assessments-df76"
    t.index ["AssessmentID"], name: "hmis2022assessments_1WRE"
    t.index ["AssessmentID"], name: "hmis2022assessments_ByZf"
    t.index ["AssessmentID"], name: "hmis2022assessments_PDLH"
    t.index ["AssessmentID"], name: "hmis2022assessments_qLFb"
    t.index ["AssessmentID"], name: "hmis2022assessments_t8k1"
    t.index ["EnrollmentID"], name: "hmis2022assessments_1xkk"
    t.index ["EnrollmentID"], name: "hmis2022assessments_ACmg"
    t.index ["EnrollmentID"], name: "hmis2022assessments_AlYO"
    t.index ["EnrollmentID"], name: "hmis2022assessments_sqjV"
    t.index ["EnrollmentID"], name: "hmis2022assessments_vTjw"
    t.index ["ExportID"], name: "hmis2022assessments_8G4O"
    t.index ["ExportID"], name: "hmis2022assessments_A3yK"
    t.index ["ExportID"], name: "hmis2022assessments_BXpI"
    t.index ["ExportID"], name: "hmis2022assessments_je8c"
    t.index ["ExportID"], name: "hmis2022assessments_r7np"
    t.index ["PersonalID"], name: "hmis2022assessments_KR2P"
    t.index ["PersonalID"], name: "hmis2022assessments_W410"
    t.index ["PersonalID"], name: "hmis2022assessments_bjSD"
    t.index ["PersonalID"], name: "hmis2022assessments_fvZW"
    t.index ["PersonalID"], name: "hmis2022assessments_lRgj"
    t.index ["importer_log_id"], name: "index_hmis_2022_assessments_on_importer_log_id"
  end

  create_table "hmis_2022_clients", force: :cascade do |t|
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
    t.integer "NativeHIPacific"
    t.integer "White"
    t.integer "RaceNone"
    t.integer "Ethnicity"
    t.integer "Female"
    t.integer "Male"
    t.integer "NoSingleGender"
    t.integer "Transgender"
    t.integer "Questioning"
    t.integer "GenderNone"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DOB"], name: "hmis2022clients_5PV0"
    t.index ["DOB"], name: "hmis2022clients_bgBr"
    t.index ["DOB"], name: "hmis2022clients_cWzB"
    t.index ["DOB"], name: "hmis2022clients_kPEm"
    t.index ["DOB"], name: "hmis2022clients_sjHR"
    t.index ["DateCreated"], name: "hmis2022clients_HLPo"
    t.index ["DateCreated"], name: "hmis2022clients_I9Fk"
    t.index ["DateCreated"], name: "hmis2022clients_fuco"
    t.index ["DateCreated"], name: "hmis2022clients_lUID"
    t.index ["DateCreated"], name: "hmis2022clients_rhmD"
    t.index ["DateUpdated"], name: "hmis2022clients_0nAI"
    t.index ["DateUpdated"], name: "hmis2022clients_Lowh"
    t.index ["DateUpdated"], name: "hmis2022clients_O4VV"
    t.index ["DateUpdated"], name: "hmis2022clients_fT7G"
    t.index ["DateUpdated"], name: "hmis2022clients_kDCg"
    t.index ["ExportID"], name: "hmis2022clients_8dIx"
    t.index ["ExportID"], name: "hmis2022clients_G2Er"
    t.index ["ExportID"], name: "hmis2022clients_NBVb"
    t.index ["ExportID"], name: "hmis2022clients_kXnX"
    t.index ["ExportID"], name: "hmis2022clients_nPqP"
    t.index ["FirstName"], name: "hmis2022clients_IHZO"
    t.index ["FirstName"], name: "hmis2022clients_WRGs"
    t.index ["FirstName"], name: "hmis2022clients_mwtf"
    t.index ["FirstName"], name: "hmis2022clients_o1zL"
    t.index ["FirstName"], name: "hmis2022clients_wPM4"
    t.index ["LastName"], name: "hmis2022clients_YO8w"
    t.index ["LastName"], name: "hmis2022clients_lDTO"
    t.index ["LastName"], name: "hmis2022clients_tAtk"
    t.index ["LastName"], name: "hmis2022clients_vm2H"
    t.index ["LastName"], name: "hmis2022clients_xavS"
    t.index ["PersonalID", "data_source_id"], name: "hmis_2022_clients-230f"
    t.index ["PersonalID"], name: "hmis2022clients_0K2Q"
    t.index ["PersonalID"], name: "hmis2022clients_H9sW"
    t.index ["PersonalID"], name: "hmis2022clients_I9Hf"
    t.index ["PersonalID"], name: "hmis2022clients_JCgD"
    t.index ["PersonalID"], name: "hmis2022clients_smwv"
    t.index ["VeteranStatus"], name: "hmis2022clients_1ZkA"
    t.index ["VeteranStatus"], name: "hmis2022clients_E1Fj"
    t.index ["VeteranStatus"], name: "hmis2022clients_EuyH"
    t.index ["VeteranStatus"], name: "hmis2022clients_V6Ey"
    t.index ["VeteranStatus"], name: "hmis2022clients_ctEI"
    t.index ["importer_log_id"], name: "index_hmis_2022_clients_on_importer_log_id"
  end

  create_table "hmis_2022_current_living_situations", force: :cascade do |t|
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["CurrentLivingSitID", "data_source_id"], name: "hmis_2022_current_living_situations-cf31"
    t.index ["CurrentLivingSitID"], name: "hmis2022currentlivingsituations_No3V"
    t.index ["CurrentLivingSitID"], name: "hmis2022currentlivingsituations_QXw2"
    t.index ["CurrentLivingSitID"], name: "hmis2022currentlivingsituations_S2Pz"
    t.index ["CurrentLivingSitID"], name: "hmis2022currentlivingsituations_dhqx"
    t.index ["CurrentLivingSitID"], name: "hmis2022currentlivingsituations_fcmV"
    t.index ["CurrentLivingSituation"], name: "hmis2022currentlivingsituations_ELrQ"
    t.index ["CurrentLivingSituation"], name: "hmis2022currentlivingsituations_YN5f"
    t.index ["CurrentLivingSituation"], name: "hmis2022currentlivingsituations_dREG"
    t.index ["CurrentLivingSituation"], name: "hmis2022currentlivingsituations_g26S"
    t.index ["CurrentLivingSituation"], name: "hmis2022currentlivingsituations_nYeO"
    t.index ["EnrollmentID"], name: "hmis2022currentlivingsituations_OUiJ"
    t.index ["EnrollmentID"], name: "hmis2022currentlivingsituations_Q6ST"
    t.index ["EnrollmentID"], name: "hmis2022currentlivingsituations_S7CL"
    t.index ["EnrollmentID"], name: "hmis2022currentlivingsituations_ZUJw"
    t.index ["EnrollmentID"], name: "hmis2022currentlivingsituations_jaT0"
    t.index ["ExportID"], name: "hmis2022currentlivingsituations_4lpH"
    t.index ["ExportID"], name: "hmis2022currentlivingsituations_D7JX"
    t.index ["ExportID"], name: "hmis2022currentlivingsituations_XjUe"
    t.index ["ExportID"], name: "hmis2022currentlivingsituations_bdhj"
    t.index ["ExportID"], name: "hmis2022currentlivingsituations_sxaI"
    t.index ["InformationDate"], name: "hmis2022currentlivingsituations_5TrW"
    t.index ["InformationDate"], name: "hmis2022currentlivingsituations_Jc9G"
    t.index ["InformationDate"], name: "hmis2022currentlivingsituations_Q9cW"
    t.index ["InformationDate"], name: "hmis2022currentlivingsituations_TGSd"
    t.index ["InformationDate"], name: "hmis2022currentlivingsituations_cf01"
    t.index ["PersonalID"], name: "hmis2022currentlivingsituations_1i8x"
    t.index ["PersonalID"], name: "hmis2022currentlivingsituations_Dihe"
    t.index ["PersonalID"], name: "hmis2022currentlivingsituations_P7xE"
    t.index ["PersonalID"], name: "hmis2022currentlivingsituations_aP5P"
    t.index ["PersonalID"], name: "hmis2022currentlivingsituations_ktGp"
    t.index ["importer_log_id"], name: "index_hmis_2022_current_living_situations_on_importer_log_id"
  end

  create_table "hmis_2022_disabilities", force: :cascade do |t|
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
    t.integer "AntiRetroviral"
    t.integer "DataCollectionStage"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis2022disabilities_DcsA"
    t.index ["DateCreated"], name: "hmis2022disabilities_JZgU"
    t.index ["DateCreated"], name: "hmis2022disabilities_RCMq"
    t.index ["DateCreated"], name: "hmis2022disabilities_XtPr"
    t.index ["DateCreated"], name: "hmis2022disabilities_f6dj"
    t.index ["DateUpdated"], name: "hmis2022disabilities_8STr"
    t.index ["DateUpdated"], name: "hmis2022disabilities_RKMq"
    t.index ["DateUpdated"], name: "hmis2022disabilities_YfE6"
    t.index ["DateUpdated"], name: "hmis2022disabilities_mwGB"
    t.index ["DateUpdated"], name: "hmis2022disabilities_yEVb"
    t.index ["DisabilitiesID", "importer_log_id"], name: "hmis_2022_disabilities_hk_l_id"
    t.index ["DisabilitiesID"], name: "hmis2022disabilities_UzGK"
    t.index ["DisabilitiesID"], name: "hmis2022disabilities_XiFD"
    t.index ["DisabilitiesID"], name: "hmis2022disabilities_mMjd"
    t.index ["DisabilitiesID"], name: "hmis2022disabilities_sUB4"
    t.index ["DisabilitiesID"], name: "hmis2022disabilities_sWeo"
    t.index ["EnrollmentID"], name: "hmis2022disabilities_EnAl"
    t.index ["EnrollmentID"], name: "hmis2022disabilities_GjW5"
    t.index ["EnrollmentID"], name: "hmis2022disabilities_HxEV"
    t.index ["EnrollmentID"], name: "hmis2022disabilities_QvrC"
    t.index ["EnrollmentID"], name: "hmis2022disabilities_trSP"
    t.index ["ExportID"], name: "hmis2022disabilities_Fc3v"
    t.index ["ExportID"], name: "hmis2022disabilities_KpIn"
    t.index ["ExportID"], name: "hmis2022disabilities_Ku2m"
    t.index ["ExportID"], name: "hmis2022disabilities_VCx7"
    t.index ["ExportID"], name: "hmis2022disabilities_e39G"
    t.index ["PersonalID"], name: "hmis2022disabilities_2fdh"
    t.index ["PersonalID"], name: "hmis2022disabilities_Clxr"
    t.index ["PersonalID"], name: "hmis2022disabilities_GajH"
    t.index ["PersonalID"], name: "hmis2022disabilities_Yqqw"
    t.index ["PersonalID"], name: "hmis2022disabilities_v0nQ"
    t.index ["importer_log_id"], name: "index_hmis_2022_disabilities_on_importer_log_id"
  end

  create_table "hmis_2022_employment_educations", force: :cascade do |t|
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis2022employmenteducations_0mfY"
    t.index ["DateCreated"], name: "hmis2022employmenteducations_2YQq"
    t.index ["DateCreated"], name: "hmis2022employmenteducations_6zwy"
    t.index ["DateCreated"], name: "hmis2022employmenteducations_LanN"
    t.index ["DateCreated"], name: "hmis2022employmenteducations_TEaN"
    t.index ["DateUpdated"], name: "hmis2022employmenteducations_0QcH"
    t.index ["DateUpdated"], name: "hmis2022employmenteducations_1Y1K"
    t.index ["DateUpdated"], name: "hmis2022employmenteducations_m0aK"
    t.index ["DateUpdated"], name: "hmis2022employmenteducations_nQzF"
    t.index ["DateUpdated"], name: "hmis2022employmenteducations_piba"
    t.index ["EmploymentEducationID", "data_source_id"], name: "hmis_2022_employment_educations-3032"
    t.index ["EmploymentEducationID"], name: "hmis2022employmenteducations_01I4"
    t.index ["EmploymentEducationID"], name: "hmis2022employmenteducations_10CJ"
    t.index ["EmploymentEducationID"], name: "hmis2022employmenteducations_dg9r"
    t.index ["EmploymentEducationID"], name: "hmis2022employmenteducations_rUdW"
    t.index ["EmploymentEducationID"], name: "hmis2022employmenteducations_telE"
    t.index ["EnrollmentID"], name: "hmis2022employmenteducations_4vda"
    t.index ["EnrollmentID"], name: "hmis2022employmenteducations_8RGj"
    t.index ["EnrollmentID"], name: "hmis2022employmenteducations_Dnln"
    t.index ["EnrollmentID"], name: "hmis2022employmenteducations_e8J8"
    t.index ["EnrollmentID"], name: "hmis2022employmenteducations_vFzw"
    t.index ["ExportID"], name: "hmis2022employmenteducations_BpmW"
    t.index ["ExportID"], name: "hmis2022employmenteducations_D2yI"
    t.index ["ExportID"], name: "hmis2022employmenteducations_Fj6e"
    t.index ["ExportID"], name: "hmis2022employmenteducations_VQ2U"
    t.index ["ExportID"], name: "hmis2022employmenteducations_kcTC"
    t.index ["PersonalID"], name: "hmis2022employmenteducations_0bvE"
    t.index ["PersonalID"], name: "hmis2022employmenteducations_1uKW"
    t.index ["PersonalID"], name: "hmis2022employmenteducations_a5yU"
    t.index ["PersonalID"], name: "hmis2022employmenteducations_g4D9"
    t.index ["PersonalID"], name: "hmis2022employmenteducations_njVL"
    t.index ["importer_log_id"], name: "index_hmis_2022_employment_educations_on_importer_log_id"
  end

  create_table "hmis_2022_enrollment_cocs", force: :cascade do |t|
    t.string "EnrollmentCoCID"
    t.string "EnrollmentID"
    t.string "HouseholdID"
    t.string "ProjectID"
    t.string "PersonalID"
    t.date "InformationDate"
    t.string "CoCCode"
    t.integer "DataCollectionStage"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["CoCCode"], name: "hmis2022enrollmentcocs_DPzf"
    t.index ["CoCCode"], name: "hmis2022enrollmentcocs_e294"
    t.index ["CoCCode"], name: "hmis2022enrollmentcocs_e6x1"
    t.index ["CoCCode"], name: "hmis2022enrollmentcocs_kTmm"
    t.index ["CoCCode"], name: "hmis2022enrollmentcocs_ltSs"
    t.index ["CoCCode"], name: "hmis2022enrollmentcocs_tZAm"
    t.index ["DateCreated"], name: "hmis2022enrollmentcocs_Gu7W"
    t.index ["DateCreated"], name: "hmis2022enrollmentcocs_IMgq"
    t.index ["DateCreated"], name: "hmis2022enrollmentcocs_XK0J"
    t.index ["DateCreated"], name: "hmis2022enrollmentcocs_goeT"
    t.index ["DateCreated"], name: "hmis2022enrollmentcocs_vL8z"
    t.index ["DateDeleted"], name: "hmis2022enrollmentcocs_00w1"
    t.index ["DateDeleted"], name: "hmis2022enrollmentcocs_AwFj"
    t.index ["DateDeleted"], name: "hmis2022enrollmentcocs_DDdl"
    t.index ["DateDeleted"], name: "hmis2022enrollmentcocs_Oj66"
    t.index ["DateDeleted"], name: "hmis2022enrollmentcocs_ptxT"
    t.index ["DateUpdated"], name: "hmis2022enrollmentcocs_Xq7j"
    t.index ["DateUpdated"], name: "hmis2022enrollmentcocs_ce8t"
    t.index ["DateUpdated"], name: "hmis2022enrollmentcocs_d0Ax"
    t.index ["DateUpdated"], name: "hmis2022enrollmentcocs_nLeg"
    t.index ["DateUpdated"], name: "hmis2022enrollmentcocs_qb26"
    t.index ["EnrollmentCoCID", "data_source_id"], name: "hmis_2022_enrollment_cocs-d4b8"
    t.index ["EnrollmentCoCID"], name: "hmis2022enrollmentcocs_BpYl"
    t.index ["EnrollmentCoCID"], name: "hmis2022enrollmentcocs_ErL4"
    t.index ["EnrollmentCoCID"], name: "hmis2022enrollmentcocs_NW2c"
    t.index ["EnrollmentCoCID"], name: "hmis2022enrollmentcocs_bKTB"
    t.index ["EnrollmentCoCID"], name: "hmis2022enrollmentcocs_yNaH"
    t.index ["EnrollmentID"], name: "hmis2022enrollmentcocs_1cHr"
    t.index ["EnrollmentID"], name: "hmis2022enrollmentcocs_JhHT"
    t.index ["EnrollmentID"], name: "hmis2022enrollmentcocs_RDDm"
    t.index ["EnrollmentID"], name: "hmis2022enrollmentcocs_emfv"
    t.index ["EnrollmentID"], name: "hmis2022enrollmentcocs_rftp"
    t.index ["ExportID"], name: "hmis2022enrollmentcocs_4x91"
    t.index ["ExportID"], name: "hmis2022enrollmentcocs_6tJM"
    t.index ["ExportID"], name: "hmis2022enrollmentcocs_DssF"
    t.index ["ExportID"], name: "hmis2022enrollmentcocs_SLq3"
    t.index ["ExportID"], name: "hmis2022enrollmentcocs_TBBA"
    t.index ["PersonalID"], name: "hmis2022enrollmentcocs_0w9c"
    t.index ["PersonalID"], name: "hmis2022enrollmentcocs_5zjF"
    t.index ["PersonalID"], name: "hmis2022enrollmentcocs_CPqr"
    t.index ["PersonalID"], name: "hmis2022enrollmentcocs_JPql"
    t.index ["PersonalID"], name: "hmis2022enrollmentcocs_gtAC"
    t.index ["importer_log_id"], name: "index_hmis_2022_enrollment_cocs_on_importer_log_id"
  end

  create_table "hmis_2022_enrollments", force: :cascade do |t|
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
    t.integer "ReferralSource"
    t.integer "CountOutreachReferralApproaches"
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
    t.integer "MentalHealthDisorderFam"
    t.integer "PhysicalDisabilityFam"
    t.integer "AlcoholDrugUseDisorderFam"
    t.integer "InsufficientIncome"
    t.integer "IncarceratedParent"
    t.string "VAMCStation"
    t.integer "TargetScreenReqd"
    t.integer "TimeToHousingLoss"
    t.integer "AnnualPercentAMI"
    t.integer "LiteralHomelessHistory"
    t.integer "ClientLeaseholder"
    t.integer "HOHLeaseholder"
    t.integer "SubsidyAtRisk"
    t.integer "EvictionHistory"
    t.integer "CriminalRecord"
    t.integer "IncarceratedAdult"
    t.integer "PrisonDischarge"
    t.integer "SexOffender"
    t.integer "DisabledHoH"
    t.integer "CurrentPregnant"
    t.integer "SingleParent"
    t.integer "DependentUnder6"
    t.integer "HH5Plus"
    t.integer "CoCPrioritized"
    t.integer "HPScreeningScore"
    t.integer "ThresholdScore"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis2022enrollments_2j3v"
    t.index ["DateCreated"], name: "hmis2022enrollments_BDpp"
    t.index ["DateCreated"], name: "hmis2022enrollments_HULG"
    t.index ["DateCreated"], name: "hmis2022enrollments_SyID"
    t.index ["DateCreated"], name: "hmis2022enrollments_eyPk"
    t.index ["DateDeleted"], name: "hmis2022enrollments_4EjQ"
    t.index ["DateDeleted"], name: "hmis2022enrollments_EC9L"
    t.index ["DateDeleted"], name: "hmis2022enrollments_Mjsu"
    t.index ["DateDeleted"], name: "hmis2022enrollments_gz2q"
    t.index ["DateDeleted"], name: "hmis2022enrollments_seem"
    t.index ["DateUpdated"], name: "hmis2022enrollments_3Y3B"
    t.index ["DateUpdated"], name: "hmis2022enrollments_ClYG"
    t.index ["DateUpdated"], name: "hmis2022enrollments_SvKn"
    t.index ["DateUpdated"], name: "hmis2022enrollments_bIh3"
    t.index ["DateUpdated"], name: "hmis2022enrollments_tVoY"
    t.index ["EnrollmentID", "PersonalID", "importer_log_id", "data_source_id"], name: "en_tt"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis2022enrollments_6d0L"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis2022enrollments_Dclz"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis2022enrollments_Mz76"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis2022enrollments_c548"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis2022enrollments_pWJS"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis2022enrollments_uaMe"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmis2022enrollments_3vdn"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmis2022enrollments_9HQ9"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmis2022enrollments_PFBl"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmis2022enrollments_TSRY"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmis2022enrollments_mM9g"
    t.index ["EnrollmentID", "data_source_id"], name: "hmis_2022_enrollments-0a46"
    t.index ["EnrollmentID"], name: "hmis2022enrollments_3RmC"
    t.index ["EnrollmentID"], name: "hmis2022enrollments_HQ8T"
    t.index ["EnrollmentID"], name: "hmis2022enrollments_QC4k"
    t.index ["EnrollmentID"], name: "hmis2022enrollments_geFN"
    t.index ["EnrollmentID"], name: "hmis2022enrollments_rcM8"
    t.index ["EntryDate"], name: "hmis2022enrollments_AUyr"
    t.index ["EntryDate"], name: "hmis2022enrollments_F7ci"
    t.index ["EntryDate"], name: "hmis2022enrollments_TMSu"
    t.index ["EntryDate"], name: "hmis2022enrollments_bbpQ"
    t.index ["EntryDate"], name: "hmis2022enrollments_c5yw"
    t.index ["ExportID"], name: "hmis2022enrollments_0jfu"
    t.index ["ExportID"], name: "hmis2022enrollments_6aWK"
    t.index ["ExportID"], name: "hmis2022enrollments_HTOM"
    t.index ["ExportID"], name: "hmis2022enrollments_NCDd"
    t.index ["ExportID"], name: "hmis2022enrollments_dl2L"
    t.index ["HouseholdID"], name: "hmis2022enrollments_5mgY"
    t.index ["HouseholdID"], name: "hmis2022enrollments_LiYM"
    t.index ["HouseholdID"], name: "hmis2022enrollments_SjW2"
    t.index ["HouseholdID"], name: "hmis2022enrollments_V3qz"
    t.index ["HouseholdID"], name: "hmis2022enrollments_k0nD"
    t.index ["LivingSituation"], name: "hmis2022enrollments_37TX"
    t.index ["LivingSituation"], name: "hmis2022enrollments_4AvS"
    t.index ["LivingSituation"], name: "hmis2022enrollments_MzHk"
    t.index ["LivingSituation"], name: "hmis2022enrollments_hDxL"
    t.index ["LivingSituation"], name: "hmis2022enrollments_zmTQ"
    t.index ["PersonalID"], name: "hmis2022enrollments_4KrJ"
    t.index ["PersonalID"], name: "hmis2022enrollments_8n5u"
    t.index ["PersonalID"], name: "hmis2022enrollments_LElu"
    t.index ["PersonalID"], name: "hmis2022enrollments_icgG"
    t.index ["PersonalID"], name: "hmis2022enrollments_q5xg"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmis2022enrollments_N8KZ"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmis2022enrollments_aTDs"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmis2022enrollments_oSGW"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmis2022enrollments_qHpP"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmis2022enrollments_t4ln"
    t.index ["ProjectID", "HouseholdID"], name: "hmis2022enrollments_3qUb"
    t.index ["ProjectID", "HouseholdID"], name: "hmis2022enrollments_BTri"
    t.index ["ProjectID", "HouseholdID"], name: "hmis2022enrollments_ELY8"
    t.index ["ProjectID", "HouseholdID"], name: "hmis2022enrollments_NsV4"
    t.index ["ProjectID", "HouseholdID"], name: "hmis2022enrollments_hHFu"
    t.index ["ProjectID", "RelationshipToHoH"], name: "hmis2022enrollments_7SGc"
    t.index ["ProjectID", "RelationshipToHoH"], name: "hmis2022enrollments_G9GI"
    t.index ["ProjectID", "RelationshipToHoH"], name: "hmis2022enrollments_Xexy"
    t.index ["ProjectID", "RelationshipToHoH"], name: "hmis2022enrollments_inZc"
    t.index ["ProjectID", "RelationshipToHoH"], name: "hmis2022enrollments_ynuX"
    t.index ["ProjectID"], name: "hmis2022enrollments_7LRJ"
    t.index ["ProjectID"], name: "hmis2022enrollments_J8cl"
    t.index ["ProjectID"], name: "hmis2022enrollments_gSa1"
    t.index ["ProjectID"], name: "hmis2022enrollments_nrVw"
    t.index ["ProjectID"], name: "hmis2022enrollments_pPK5"
    t.index ["RelationshipToHoH"], name: "hmis2022enrollments_3328"
    t.index ["RelationshipToHoH"], name: "hmis2022enrollments_B6MA"
    t.index ["RelationshipToHoH"], name: "hmis2022enrollments_DCEF"
    t.index ["RelationshipToHoH"], name: "hmis2022enrollments_vRaD"
    t.index ["RelationshipToHoH"], name: "hmis2022enrollments_y3F2"
    t.index ["RelationshipToHoH"], name: "hmis2022enrollments_zo2X"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears"], name: "hmis2022enrollments_20lu"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears"], name: "hmis2022enrollments_7WTk"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears"], name: "hmis2022enrollments_8p3b"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears"], name: "hmis2022enrollments_oD3L"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears"], name: "hmis2022enrollments_oO3x"
    t.index ["importer_log_id"], name: "index_hmis_2022_enrollments_on_importer_log_id"
  end

  create_table "hmis_2022_events", force: :cascade do |t|
    t.string "EventID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "EventDate"
    t.integer "Event"
    t.integer "ProbSolDivRRResult"
    t.integer "ReferralCaseManageAfter"
    t.string "LocationCrisisOrPHHousing"
    t.integer "ReferralResult"
    t.date "ResultDate"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["EnrollmentID"], name: "hmis2022events_3GeP"
    t.index ["EnrollmentID"], name: "hmis2022events_JK9C"
    t.index ["EnrollmentID"], name: "hmis2022events_TcFv"
    t.index ["EnrollmentID"], name: "hmis2022events_jZh3"
    t.index ["EnrollmentID"], name: "hmis2022events_uIUg"
    t.index ["EventDate"], name: "hmis2022events_2XYp"
    t.index ["EventDate"], name: "hmis2022events_EwgP"
    t.index ["EventDate"], name: "hmis2022events_GNsx"
    t.index ["EventDate"], name: "hmis2022events_LXwo"
    t.index ["EventDate"], name: "hmis2022events_unUI"
    t.index ["EventID", "importer_log_id"], name: "hmis_2022_events_hk_l_id"
    t.index ["EventID"], name: "hmis2022events_Exri"
    t.index ["EventID"], name: "hmis2022events_SLKf"
    t.index ["EventID"], name: "hmis2022events_oHnT"
    t.index ["EventID"], name: "hmis2022events_pGIP"
    t.index ["EventID"], name: "hmis2022events_pf5U"
    t.index ["ExportID"], name: "hmis2022events_Evth"
    t.index ["ExportID"], name: "hmis2022events_HaIL"
    t.index ["ExportID"], name: "hmis2022events_OBnR"
    t.index ["ExportID"], name: "hmis2022events_Uk3l"
    t.index ["ExportID"], name: "hmis2022events_fsBr"
    t.index ["PersonalID"], name: "hmis2022events_LCxa"
    t.index ["PersonalID"], name: "hmis2022events_T5lV"
    t.index ["PersonalID"], name: "hmis2022events_ZWfu"
    t.index ["PersonalID"], name: "hmis2022events_jTpi"
    t.index ["PersonalID"], name: "hmis2022events_lU5Z"
    t.index ["importer_log_id"], name: "index_hmis_2022_events_on_importer_log_id"
  end

  create_table "hmis_2022_exits", force: :cascade do |t|
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis2022exits_4FaP"
    t.index ["DateCreated"], name: "hmis2022exits_E5ii"
    t.index ["DateCreated"], name: "hmis2022exits_Tldv"
    t.index ["DateCreated"], name: "hmis2022exits_ZNEH"
    t.index ["DateCreated"], name: "hmis2022exits_ssZQ"
    t.index ["DateDeleted"], name: "hmis2022exits_0mCE"
    t.index ["DateDeleted"], name: "hmis2022exits_IuDI"
    t.index ["DateDeleted"], name: "hmis2022exits_KKNd"
    t.index ["DateDeleted"], name: "hmis2022exits_MqXv"
    t.index ["DateDeleted"], name: "hmis2022exits_dFpc"
    t.index ["DateUpdated"], name: "hmis2022exits_4AWu"
    t.index ["DateUpdated"], name: "hmis2022exits_Rbol"
    t.index ["DateUpdated"], name: "hmis2022exits_msZd"
    t.index ["DateUpdated"], name: "hmis2022exits_noAP"
    t.index ["DateUpdated"], name: "hmis2022exits_vL1k"
    t.index ["EnrollmentID", "PersonalID", "importer_log_id", "data_source_id"], name: "hmis_2022_exit_e_id_compound"
    t.index ["EnrollmentID", "PersonalID", "importer_log_id", "data_source_id"], name: "tt"
    t.index ["EnrollmentID"], name: "hmis2022exits_Af3i"
    t.index ["EnrollmentID"], name: "hmis2022exits_Cl49"
    t.index ["EnrollmentID"], name: "hmis2022exits_EVIM"
    t.index ["EnrollmentID"], name: "hmis2022exits_vktj"
    t.index ["EnrollmentID"], name: "hmis2022exits_x3r7"
    t.index ["ExitDate"], name: "hmis2022exits_2fAC"
    t.index ["ExitDate"], name: "hmis2022exits_AuYr"
    t.index ["ExitDate"], name: "hmis2022exits_L2iM"
    t.index ["ExitDate"], name: "hmis2022exits_R91g"
    t.index ["ExitDate"], name: "hmis2022exits_d4hu"
    t.index ["ExitDate"], name: "hmis2022exits_fa9a"
    t.index ["ExitID", "data_source_id"], name: "hmis_2022_exits-cfdd"
    t.index ["ExitID"], name: "hmis2022exits_3ric"
    t.index ["ExitID"], name: "hmis2022exits_ksT2"
    t.index ["ExitID"], name: "hmis2022exits_lzvt"
    t.index ["ExitID"], name: "hmis2022exits_oWLc"
    t.index ["ExitID"], name: "hmis2022exits_sMXZ"
    t.index ["ExportID"], name: "hmis2022exits_LBAD"
    t.index ["ExportID"], name: "hmis2022exits_XAoJ"
    t.index ["ExportID"], name: "hmis2022exits_cyno"
    t.index ["ExportID"], name: "hmis2022exits_fTOL"
    t.index ["ExportID"], name: "hmis2022exits_r50N"
    t.index ["PersonalID"], name: "hmis2022exits_9U2x"
    t.index ["PersonalID"], name: "hmis2022exits_Pdxz"
    t.index ["PersonalID"], name: "hmis2022exits_VVBK"
    t.index ["PersonalID"], name: "hmis2022exits_p6Jb"
    t.index ["PersonalID"], name: "hmis2022exits_uttT"
    t.index ["importer_log_id"], name: "index_hmis_2022_exits_on_importer_log_id"
  end

  create_table "hmis_2022_exports", force: :cascade do |t|
    t.string "ExportID"
    t.integer "SourceType"
    t.string "SourceID"
    t.string "SourceName"
    t.string "SourceContactFirst"
    t.string "SourceContactLast"
    t.string "SourceContactPhone"
    t.string "SourceContactExtension"
    t.string "SourceContactEmail"
    t.datetime "ExportDate", precision: nil
    t.date "ExportStartDate"
    t.date "ExportEndDate"
    t.string "SoftwareName"
    t.string "SoftwareVersion"
    t.string "CSVVersion"
    t.integer "ExportPeriodType"
    t.integer "ExportDirective"
    t.integer "HashStatus"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["ExportID", "data_source_id"], name: "hmis_2022_exports-86be"
    t.index ["ExportID"], name: "hmis2022exports_0o3Y"
    t.index ["ExportID"], name: "hmis2022exports_Vb9V"
    t.index ["ExportID"], name: "hmis2022exports_kbyY"
    t.index ["ExportID"], name: "hmis2022exports_r5Vj"
    t.index ["ExportID"], name: "hmis2022exports_vVa8"
    t.index ["importer_log_id"], name: "index_hmis_2022_exports_on_importer_log_id"
  end

  create_table "hmis_2022_funders", force: :cascade do |t|
    t.string "FunderID"
    t.string "ProjectID"
    t.integer "Funder"
    t.string "OtherFunder"
    t.string "GrantID"
    t.date "StartDate"
    t.date "EndDate"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis2022funders_CM44"
    t.index ["DateCreated"], name: "hmis2022funders_DmBq"
    t.index ["DateCreated"], name: "hmis2022funders_hjB3"
    t.index ["DateCreated"], name: "hmis2022funders_ml9I"
    t.index ["DateCreated"], name: "hmis2022funders_rbeh"
    t.index ["DateUpdated"], name: "hmis2022funders_46DZ"
    t.index ["DateUpdated"], name: "hmis2022funders_4uvj"
    t.index ["DateUpdated"], name: "hmis2022funders_aqqv"
    t.index ["DateUpdated"], name: "hmis2022funders_e42h"
    t.index ["DateUpdated"], name: "hmis2022funders_zCs4"
    t.index ["ExportID"], name: "hmis2022funders_26bc"
    t.index ["ExportID"], name: "hmis2022funders_La2t"
    t.index ["ExportID"], name: "hmis2022funders_OTDJ"
    t.index ["ExportID"], name: "hmis2022funders_SshV"
    t.index ["ExportID"], name: "hmis2022funders_p7Md"
    t.index ["FunderID", "data_source_id"], name: "hmis_2022_funders-4ad5"
    t.index ["FunderID"], name: "hmis2022funders_ABi2"
    t.index ["FunderID"], name: "hmis2022funders_ahFB"
    t.index ["FunderID"], name: "hmis2022funders_pYDL"
    t.index ["FunderID"], name: "hmis2022funders_tO3b"
    t.index ["FunderID"], name: "hmis2022funders_wrmf"
    t.index ["importer_log_id"], name: "index_hmis_2022_funders_on_importer_log_id"
  end

  create_table "hmis_2022_health_and_dvs", force: :cascade do |t|
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
    t.integer "LifeValue"
    t.integer "SupportFromOthers"
    t.integer "BounceBack"
    t.integer "FeelingFrequency"
    t.integer "DataCollectionStage"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis2022healthanddvs_LYST"
    t.index ["DateCreated"], name: "hmis2022healthanddvs_PTMk"
    t.index ["DateCreated"], name: "hmis2022healthanddvs_Vitu"
    t.index ["DateCreated"], name: "hmis2022healthanddvs_jsVe"
    t.index ["DateCreated"], name: "hmis2022healthanddvs_lrk9"
    t.index ["DateUpdated"], name: "hmis2022healthanddvs_GwLc"
    t.index ["DateUpdated"], name: "hmis2022healthanddvs_J2k9"
    t.index ["DateUpdated"], name: "hmis2022healthanddvs_MM9C"
    t.index ["DateUpdated"], name: "hmis2022healthanddvs_oE33"
    t.index ["DateUpdated"], name: "hmis2022healthanddvs_sSdO"
    t.index ["EnrollmentID"], name: "hmis2022healthanddvs_9xtv"
    t.index ["EnrollmentID"], name: "hmis2022healthanddvs_IGDp"
    t.index ["EnrollmentID"], name: "hmis2022healthanddvs_JnNy"
    t.index ["EnrollmentID"], name: "hmis2022healthanddvs_nCmK"
    t.index ["EnrollmentID"], name: "hmis2022healthanddvs_rKKo"
    t.index ["ExportID"], name: "hmis2022healthanddvs_C3P0"
    t.index ["ExportID"], name: "hmis2022healthanddvs_L20r"
    t.index ["ExportID"], name: "hmis2022healthanddvs_RZLE"
    t.index ["ExportID"], name: "hmis2022healthanddvs_Zsjv"
    t.index ["ExportID"], name: "hmis2022healthanddvs_d4Mp"
    t.index ["HealthAndDVID", "importer_log_id"], name: "hmis_2022_health_and_dvs_hk_l_id"
    t.index ["HealthAndDVID"], name: "hmis2022healthanddvs_B3cK"
    t.index ["HealthAndDVID"], name: "hmis2022healthanddvs_bSYK"
    t.index ["HealthAndDVID"], name: "hmis2022healthanddvs_eFRE"
    t.index ["HealthAndDVID"], name: "hmis2022healthanddvs_mxKc"
    t.index ["HealthAndDVID"], name: "hmis2022healthanddvs_qQGt"
    t.index ["PersonalID"], name: "hmis2022healthanddvs_39pa"
    t.index ["PersonalID"], name: "hmis2022healthanddvs_81Ip"
    t.index ["PersonalID"], name: "hmis2022healthanddvs_CqjD"
    t.index ["PersonalID"], name: "hmis2022healthanddvs_EmeI"
    t.index ["PersonalID"], name: "hmis2022healthanddvs_kG26"
    t.index ["importer_log_id"], name: "index_hmis_2022_health_and_dvs_on_importer_log_id"
  end

  create_table "hmis_2022_income_benefits", force: :cascade do |t|
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
    t.integer "RyanWhiteMedDent"
    t.integer "NoRyanWhiteReason"
    t.integer "ConnectionWithSOAR"
    t.integer "DataCollectionStage"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis2022incomebenefits_84A2"
    t.index ["DateCreated"], name: "hmis2022incomebenefits_JHq0"
    t.index ["DateCreated"], name: "hmis2022incomebenefits_Sy6R"
    t.index ["DateCreated"], name: "hmis2022incomebenefits_TMFo"
    t.index ["DateCreated"], name: "hmis2022incomebenefits_UERs"
    t.index ["DateUpdated"], name: "hmis2022incomebenefits_JwMD"
    t.index ["DateUpdated"], name: "hmis2022incomebenefits_Vn6L"
    t.index ["DateUpdated"], name: "hmis2022incomebenefits_Zgub"
    t.index ["DateUpdated"], name: "hmis2022incomebenefits_tIGj"
    t.index ["DateUpdated"], name: "hmis2022incomebenefits_ts9d"
    t.index ["Earned", "DataCollectionStage"], name: "hmis2022incomebenefits_HA2R"
    t.index ["Earned", "DataCollectionStage"], name: "hmis2022incomebenefits_Hrr8"
    t.index ["Earned", "DataCollectionStage"], name: "hmis2022incomebenefits_dRwA"
    t.index ["Earned", "DataCollectionStage"], name: "hmis2022incomebenefits_fD7y"
    t.index ["Earned", "DataCollectionStage"], name: "hmis2022incomebenefits_mvDZ"
    t.index ["EnrollmentID"], name: "hmis2022incomebenefits_0x7T"
    t.index ["EnrollmentID"], name: "hmis2022incomebenefits_AOIn"
    t.index ["EnrollmentID"], name: "hmis2022incomebenefits_AhcR"
    t.index ["EnrollmentID"], name: "hmis2022incomebenefits_JHkd"
    t.index ["EnrollmentID"], name: "hmis2022incomebenefits_vzlx"
    t.index ["ExportID"], name: "hmis2022incomebenefits_634d"
    t.index ["ExportID"], name: "hmis2022incomebenefits_9VUZ"
    t.index ["ExportID"], name: "hmis2022incomebenefits_CqV2"
    t.index ["ExportID"], name: "hmis2022incomebenefits_JzOv"
    t.index ["ExportID"], name: "hmis2022incomebenefits_azJ6"
    t.index ["ExportID"], name: "hmis2022incomebenefits_bPyx"
    t.index ["IncomeBenefitsID", "importer_log_id"], name: "hmis_2022_income_benefits_hk_l_id"
    t.index ["IncomeBenefitsID"], name: "hmis2022incomebenefits_8YX1"
    t.index ["IncomeBenefitsID"], name: "hmis2022incomebenefits_G13K"
    t.index ["IncomeBenefitsID"], name: "hmis2022incomebenefits_PI60"
    t.index ["IncomeBenefitsID"], name: "hmis2022incomebenefits_VnlT"
    t.index ["IncomeBenefitsID"], name: "hmis2022incomebenefits_n8pL"
    t.index ["IncomeFromAnySource", "DataCollectionStage"], name: "hmis2022incomebenefits_1iTb"
    t.index ["IncomeFromAnySource", "DataCollectionStage"], name: "hmis2022incomebenefits_DEc8"
    t.index ["IncomeFromAnySource", "DataCollectionStage"], name: "hmis2022incomebenefits_DHfs"
    t.index ["IncomeFromAnySource", "DataCollectionStage"], name: "hmis2022incomebenefits_ae8d"
    t.index ["IncomeFromAnySource", "DataCollectionStage"], name: "hmis2022incomebenefits_haCV"
    t.index ["IncomeFromAnySource", "DataCollectionStage"], name: "hmis2022incomebenefits_lvsq"
    t.index ["InformationDate"], name: "hmis2022incomebenefits_FKM8"
    t.index ["InformationDate"], name: "hmis2022incomebenefits_GZEz"
    t.index ["InformationDate"], name: "hmis2022incomebenefits_ek1a"
    t.index ["InformationDate"], name: "hmis2022incomebenefits_uWiD"
    t.index ["InformationDate"], name: "hmis2022incomebenefits_x9tg"
    t.index ["PersonalID"], name: "hmis2022incomebenefits_GskQ"
    t.index ["PersonalID"], name: "hmis2022incomebenefits_ciWw"
    t.index ["PersonalID"], name: "hmis2022incomebenefits_is5G"
    t.index ["PersonalID"], name: "hmis2022incomebenefits_qGS5"
    t.index ["PersonalID"], name: "hmis2022incomebenefits_sQmz"
    t.index ["importer_log_id"], name: "index_hmis_2022_income_benefits_on_importer_log_id"
  end

  create_table "hmis_2022_inventories", force: :cascade do |t|
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis2022inventories_3i1a"
    t.index ["DateCreated"], name: "hmis2022inventories_C1bt"
    t.index ["DateCreated"], name: "hmis2022inventories_KB9n"
    t.index ["DateCreated"], name: "hmis2022inventories_M3Ha"
    t.index ["DateCreated"], name: "hmis2022inventories_Qelf"
    t.index ["DateUpdated"], name: "hmis2022inventories_Arn3"
    t.index ["DateUpdated"], name: "hmis2022inventories_PsW9"
    t.index ["DateUpdated"], name: "hmis2022inventories_SWlE"
    t.index ["DateUpdated"], name: "hmis2022inventories_eLHl"
    t.index ["DateUpdated"], name: "hmis2022inventories_yY0M"
    t.index ["ExportID"], name: "hmis2022inventories_6jdY"
    t.index ["ExportID"], name: "hmis2022inventories_bofb"
    t.index ["ExportID"], name: "hmis2022inventories_iP6i"
    t.index ["ExportID"], name: "hmis2022inventories_kR2K"
    t.index ["ExportID"], name: "hmis2022inventories_wLQS"
    t.index ["InventoryID", "data_source_id"], name: "hmis_2022_inventories-86c0"
    t.index ["InventoryID"], name: "hmis2022inventories_8BiB"
    t.index ["InventoryID"], name: "hmis2022inventories_9529"
    t.index ["InventoryID"], name: "hmis2022inventories_9WW6"
    t.index ["InventoryID"], name: "hmis2022inventories_LdMP"
    t.index ["InventoryID"], name: "hmis2022inventories_cXOY"
    t.index ["InventoryID"], name: "hmis2022inventories_sm3T"
    t.index ["ProjectID", "CoCCode"], name: "hmis2022inventories_AYgL"
    t.index ["ProjectID", "CoCCode"], name: "hmis2022inventories_IstJ"
    t.index ["ProjectID", "CoCCode"], name: "hmis2022inventories_eXpd"
    t.index ["ProjectID", "CoCCode"], name: "hmis2022inventories_ovgT"
    t.index ["ProjectID", "CoCCode"], name: "hmis2022inventories_rLxn"
    t.index ["importer_log_id"], name: "index_hmis_2022_inventories_on_importer_log_id"
  end

  create_table "hmis_2022_organizations", force: :cascade do |t|
    t.string "OrganizationID"
    t.string "OrganizationName"
    t.integer "VictimServiceProvider"
    t.string "OrganizationCommonName"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["ExportID"], name: "hmis2022organizations_Psl1"
    t.index ["ExportID"], name: "hmis2022organizations_TdT2"
    t.index ["ExportID"], name: "hmis2022organizations_mjhZ"
    t.index ["ExportID"], name: "hmis2022organizations_rt9t"
    t.index ["ExportID"], name: "hmis2022organizations_sCgG"
    t.index ["OrganizationID", "data_source_id"], name: "hmis_2022_organizations-7580"
    t.index ["OrganizationID"], name: "hmis2022organizations_011s"
    t.index ["OrganizationID"], name: "hmis2022organizations_LOzw"
    t.index ["OrganizationID"], name: "hmis2022organizations_TLP5"
    t.index ["OrganizationID"], name: "hmis2022organizations_UwWr"
    t.index ["OrganizationID"], name: "hmis2022organizations_XsGg"
    t.index ["importer_log_id"], name: "index_hmis_2022_organizations_on_importer_log_id"
  end

  create_table "hmis_2022_project_cocs", force: :cascade do |t|
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis2022projectcocs_5LwF"
    t.index ["DateCreated"], name: "hmis2022projectcocs_5tqd"
    t.index ["DateCreated"], name: "hmis2022projectcocs_kX0x"
    t.index ["DateCreated"], name: "hmis2022projectcocs_lrLY"
    t.index ["DateCreated"], name: "hmis2022projectcocs_lty3"
    t.index ["DateUpdated"], name: "hmis2022projectcocs_1ike"
    t.index ["DateUpdated"], name: "hmis2022projectcocs_Mi4u"
    t.index ["DateUpdated"], name: "hmis2022projectcocs_X9kf"
    t.index ["DateUpdated"], name: "hmis2022projectcocs_XYpN"
    t.index ["DateUpdated"], name: "hmis2022projectcocs_yEto"
    t.index ["ExportID"], name: "hmis2022projectcocs_4qjb"
    t.index ["ExportID"], name: "hmis2022projectcocs_6Ygh"
    t.index ["ExportID"], name: "hmis2022projectcocs_9Yoi"
    t.index ["ExportID"], name: "hmis2022projectcocs_TNSX"
    t.index ["ExportID"], name: "hmis2022projectcocs_Vz5V"
    t.index ["ProjectCoCID", "data_source_id"], name: "hmis_2022_project_cocs-3966"
    t.index ["ProjectCoCID"], name: "hmis2022projectcocs_0Now"
    t.index ["ProjectCoCID"], name: "hmis2022projectcocs_3zNV"
    t.index ["ProjectCoCID"], name: "hmis2022projectcocs_4M5C"
    t.index ["ProjectCoCID"], name: "hmis2022projectcocs_PKtl"
    t.index ["ProjectCoCID"], name: "hmis2022projectcocs_sQfd"
    t.index ["ProjectID", "CoCCode"], name: "hmis2022projectcocs_3ED0"
    t.index ["ProjectID", "CoCCode"], name: "hmis2022projectcocs_CcFO"
    t.index ["ProjectID", "CoCCode"], name: "hmis2022projectcocs_b6rB"
    t.index ["ProjectID", "CoCCode"], name: "hmis2022projectcocs_ef8C"
    t.index ["ProjectID", "CoCCode"], name: "hmis2022projectcocs_oD4E"
    t.index ["importer_log_id"], name: "index_hmis_2022_project_cocs_on_importer_log_id"
  end

  create_table "hmis_2022_projects", force: :cascade do |t|
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
    t.integer "HOPWAMedAssistedLivingFac"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.integer "PITCount"
    t.index ["DateCreated"], name: "hmis2022projects_F8tr"
    t.index ["DateCreated"], name: "hmis2022projects_GF0h"
    t.index ["DateCreated"], name: "hmis2022projects_K13K"
    t.index ["DateCreated"], name: "hmis2022projects_eOC7"
    t.index ["DateCreated"], name: "hmis2022projects_vOpf"
    t.index ["DateUpdated"], name: "hmis2022projects_2k9I"
    t.index ["DateUpdated"], name: "hmis2022projects_ADJi"
    t.index ["DateUpdated"], name: "hmis2022projects_fcQR"
    t.index ["DateUpdated"], name: "hmis2022projects_v8Tc"
    t.index ["DateUpdated"], name: "hmis2022projects_wkvZ"
    t.index ["ExportID"], name: "hmis2022projects_AnNo"
    t.index ["ExportID"], name: "hmis2022projects_Gu3H"
    t.index ["ExportID"], name: "hmis2022projects_OT6u"
    t.index ["ExportID"], name: "hmis2022projects_dQCA"
    t.index ["ExportID"], name: "hmis2022projects_eUQm"
    t.index ["ProjectID", "data_source_id"], name: "hmis_2022_projects-92c5"
    t.index ["ProjectID"], name: "hmis2022projects_784w"
    t.index ["ProjectID"], name: "hmis2022projects_9qGh"
    t.index ["ProjectID"], name: "hmis2022projects_DMpm"
    t.index ["ProjectID"], name: "hmis2022projects_JSje"
    t.index ["ProjectID"], name: "hmis2022projects_snHq"
    t.index ["ProjectType"], name: "hmis2022projects_CYGj"
    t.index ["ProjectType"], name: "hmis2022projects_GbSc"
    t.index ["ProjectType"], name: "hmis2022projects_Pwue"
    t.index ["ProjectType"], name: "hmis2022projects_own3"
    t.index ["ProjectType"], name: "hmis2022projects_qlW7"
    t.index ["importer_log_id"], name: "index_hmis_2022_projects_on_importer_log_id"
  end

  create_table "hmis_2022_services", force: :cascade do |t|
    t.string "ServicesID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "DateProvided"
    t.integer "RecordType"
    t.integer "TypeProvided"
    t.string "OtherTypeProvided"
    t.string "MovingOnOtherType"
    t.integer "SubTypeProvided"
    t.string "FAAmount"
    t.integer "ReferralOutcome"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis2022services_LTfU"
    t.index ["DateCreated"], name: "hmis2022services_R4Ug"
    t.index ["DateCreated"], name: "hmis2022services_jnER"
    t.index ["DateCreated"], name: "hmis2022services_pQHA"
    t.index ["DateCreated"], name: "hmis2022services_z7LQ"
    t.index ["DateDeleted"], name: "hmis2022services_4IqJ"
    t.index ["DateDeleted"], name: "hmis2022services_Qscs"
    t.index ["DateDeleted"], name: "hmis2022services_UhG8"
    t.index ["DateDeleted"], name: "hmis2022services_Xp4E"
    t.index ["DateDeleted"], name: "hmis2022services_vfjk"
    t.index ["DateProvided"], name: "hmis2022services_2Pi6"
    t.index ["DateProvided"], name: "hmis2022services_8Bt5"
    t.index ["DateProvided"], name: "hmis2022services_BCCk"
    t.index ["DateProvided"], name: "hmis2022services_dkaE"
    t.index ["DateProvided"], name: "hmis2022services_s8In"
    t.index ["DateUpdated"], name: "hmis2022services_CsGp"
    t.index ["DateUpdated"], name: "hmis2022services_D1jd"
    t.index ["DateUpdated"], name: "hmis2022services_Ek53"
    t.index ["DateUpdated"], name: "hmis2022services_FSBY"
    t.index ["DateUpdated"], name: "hmis2022services_YlM0"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis2022services_1VpJ"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis2022services_8evh"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis2022services_c548"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis2022services_kMoh"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis2022services_n6xL"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis2022services_tYIb"
    t.index ["EnrollmentID", "RecordType", "DateDeleted", "DateProvided"], name: "hmis2022services_4Fxe"
    t.index ["EnrollmentID", "RecordType", "DateDeleted", "DateProvided"], name: "hmis2022services_Fd80"
    t.index ["EnrollmentID", "RecordType", "DateDeleted", "DateProvided"], name: "hmis2022services_jK9O"
    t.index ["EnrollmentID", "RecordType", "DateDeleted", "DateProvided"], name: "hmis2022services_taNN"
    t.index ["EnrollmentID", "RecordType", "DateDeleted", "DateProvided"], name: "hmis2022services_zbEp"
    t.index ["EnrollmentID"], name: "hmis2022services_9eiT"
    t.index ["EnrollmentID"], name: "hmis2022services_OuBj"
    t.index ["EnrollmentID"], name: "hmis2022services_WzIZ"
    t.index ["EnrollmentID"], name: "hmis2022services_ZeNL"
    t.index ["EnrollmentID"], name: "hmis2022services_rKMA"
    t.index ["ExportID"], name: "hmis2022services_7WwG"
    t.index ["ExportID"], name: "hmis2022services_80Zv"
    t.index ["ExportID"], name: "hmis2022services_JfRQ"
    t.index ["ExportID"], name: "hmis2022services_Qxai"
    t.index ["ExportID"], name: "hmis2022services_UdjB"
    t.index ["PersonalID", "RecordType", "EnrollmentID", "DateProvided"], name: "hmis2022services_QVc8"
    t.index ["PersonalID", "RecordType", "EnrollmentID", "DateProvided"], name: "hmis2022services_aZ1P"
    t.index ["PersonalID", "RecordType", "EnrollmentID", "DateProvided"], name: "hmis2022services_evj6"
    t.index ["PersonalID", "RecordType", "EnrollmentID", "DateProvided"], name: "hmis2022services_gLfJ"
    t.index ["PersonalID", "RecordType", "EnrollmentID", "DateProvided"], name: "hmis2022services_l83Q"
    t.index ["PersonalID"], name: "hmis2022services_PgzK"
    t.index ["PersonalID"], name: "hmis2022services_QM5r"
    t.index ["PersonalID"], name: "hmis2022services_fS9c"
    t.index ["PersonalID"], name: "hmis2022services_i3Fn"
    t.index ["PersonalID"], name: "hmis2022services_jPzY"
    t.index ["RecordType", "DateDeleted"], name: "hmis2022services_93jP"
    t.index ["RecordType", "DateDeleted"], name: "hmis2022services_LA4D"
    t.index ["RecordType", "DateDeleted"], name: "hmis2022services_Q64k"
    t.index ["RecordType", "DateDeleted"], name: "hmis2022services_QsED"
    t.index ["RecordType", "DateDeleted"], name: "hmis2022services_TeiS"
    t.index ["RecordType", "DateProvided"], name: "hmis2022services_5tYV"
    t.index ["RecordType", "DateProvided"], name: "hmis2022services_8XXq"
    t.index ["RecordType", "DateProvided"], name: "hmis2022services_FcVG"
    t.index ["RecordType", "DateProvided"], name: "hmis2022services_Y9OY"
    t.index ["RecordType", "DateProvided"], name: "hmis2022services_w0lh"
    t.index ["RecordType"], name: "hmis2022services_3F1O"
    t.index ["RecordType"], name: "hmis2022services_68qY"
    t.index ["RecordType"], name: "hmis2022services_Rgn7"
    t.index ["RecordType"], name: "hmis2022services_hp6g"
    t.index ["RecordType"], name: "hmis2022services_rwkF"
    t.index ["ServicesID", "importer_log_id"], name: "hmis_2022_services_hk_l_id"
    t.index ["ServicesID"], name: "hmis2022services_HEJX"
    t.index ["ServicesID"], name: "hmis2022services_MR5w"
    t.index ["ServicesID"], name: "hmis2022services_TR6P"
    t.index ["ServicesID"], name: "hmis2022services_u0nP"
    t.index ["ServicesID"], name: "hmis2022services_vsKi"
    t.index ["importer_log_id"], name: "index_hmis_2022_services_on_importer_log_id"
  end

  create_table "hmis_2022_users", force: :cascade do |t|
    t.string "UserID"
    t.string "UserFirstName"
    t.string "UserLastName"
    t.string "UserPhone"
    t.string "UserExtension"
    t.string "UserEmail"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["ExportID"], name: "hmis2022users_6bs3"
    t.index ["ExportID"], name: "hmis2022users_Bb37"
    t.index ["ExportID"], name: "hmis2022users_L8dm"
    t.index ["ExportID"], name: "hmis2022users_iRM6"
    t.index ["ExportID"], name: "hmis2022users_ixDP"
    t.index ["UserID"], name: "hmis2022users_57c7"
    t.index ["UserID"], name: "hmis2022users_9tte"
    t.index ["UserID"], name: "hmis2022users_I56Y"
    t.index ["UserID"], name: "hmis2022users_cfDN"
    t.index ["UserID"], name: "hmis2022users_jC3x"
    t.index ["UserID"], name: "hmis2022users_n0RN"
    t.index ["importer_log_id"], name: "index_hmis_2022_users_on_importer_log_id"
  end

  create_table "hmis_2022_youth_education_statuses", force: :cascade do |t|
    t.string "YouthEducationStatusID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "InformationDate"
    t.integer "CurrentSchoolAttend"
    t.integer "MostRecentEdStatus"
    t.integer "CurrentEdStatus"
    t.integer "DataCollectionStage"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["EnrollmentID"], name: "hmis2022youtheducationstatuses_3nPV"
    t.index ["EnrollmentID"], name: "hmis2022youtheducationstatuses_Jb6k"
    t.index ["EnrollmentID"], name: "hmis2022youtheducationstatuses_qY17"
    t.index ["EnrollmentID"], name: "hmis2022youtheducationstatuses_tADn"
    t.index ["EnrollmentID"], name: "hmis2022youtheducationstatuses_xQUJ"
    t.index ["ExportID"], name: "hmis2022youtheducationstatuses_6acJ"
    t.index ["ExportID"], name: "hmis2022youtheducationstatuses_9lDW"
    t.index ["ExportID"], name: "hmis2022youtheducationstatuses_E26n"
    t.index ["ExportID"], name: "hmis2022youtheducationstatuses_oUUw"
    t.index ["ExportID"], name: "hmis2022youtheducationstatuses_rWnz"
    t.index ["InformationDate"], name: "hmis2022youtheducationstatuses_CPRH"
    t.index ["InformationDate"], name: "hmis2022youtheducationstatuses_GqWc"
    t.index ["InformationDate"], name: "hmis2022youtheducationstatuses_MXhY"
    t.index ["InformationDate"], name: "hmis2022youtheducationstatuses_V5KQ"
    t.index ["InformationDate"], name: "hmis2022youtheducationstatuses_fabe"
    t.index ["InformationDate"], name: "hmis2022youtheducationstatuses_u4Ae"
    t.index ["PersonalID"], name: "hmis2022youtheducationstatuses_5Amx"
    t.index ["PersonalID"], name: "hmis2022youtheducationstatuses_Xvwe"
    t.index ["PersonalID"], name: "hmis2022youtheducationstatuses_pIqT"
    t.index ["PersonalID"], name: "hmis2022youtheducationstatuses_r4i7"
    t.index ["PersonalID"], name: "hmis2022youtheducationstatuses_yBQz"
    t.index ["YouthEducationStatusID", "data_source_id"], name: "hmis_2022_youth_education_statuses-a32f"
    t.index ["YouthEducationStatusID"], name: "hmis2022youtheducationstatuses_2ePH"
    t.index ["YouthEducationStatusID"], name: "hmis2022youtheducationstatuses_Cl2V"
    t.index ["YouthEducationStatusID"], name: "hmis2022youtheducationstatuses_EioI"
    t.index ["YouthEducationStatusID"], name: "hmis2022youtheducationstatuses_KWZP"
    t.index ["YouthEducationStatusID"], name: "hmis2022youtheducationstatuses_bmwi"
    t.index ["importer_log_id"], name: "index_hmis_2022_youth_education_statuses_on_importer_log_id"
  end

  create_table "hmis_2024_affiliations", force: :cascade do |t|
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
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["AffiliationID", "data_source_id"], name: "hmis_2024_affiliations-6457"
  end

  create_table "hmis_2024_assessment_questions", force: :cascade do |t|
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
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["AssessmentID"], name: "hmis2024assessmentquestions_da04"
    t.index ["AssessmentQuestionID", "data_source_id"], name: "hmis_2024_assessment_questions-0cd3"
    t.index ["ExportID"], name: "hmis2024assessmentquestions_634d"
  end

  create_table "hmis_2024_assessment_results", force: :cascade do |t|
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
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["AssessmentResultID", "data_source_id"], name: "hmis_2024_assessment_results-d6c9"
    t.index ["ExportID"], name: "hmis2024assessmentresults_634d"
  end

  create_table "hmis_2024_assessments", force: :cascade do |t|
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
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["AssessmentDate"], name: "hmis2024assessments_4fa0"
    t.index ["AssessmentID", "data_source_id"], name: "hmis_2024_assessments-df76"
    t.index ["AssessmentID"], name: "hmis2024assessments_da04"
    t.index ["ExportID"], name: "hmis2024assessments_634d"
  end

  create_table "hmis_2024_ce_participations", force: :cascade do |t|
    t.string "CEParticipationID"
    t.string "ProjectID"
    t.integer "AccessPoint"
    t.integer "PreventionAssessment"
    t.integer "CrisisAssessment"
    t.integer "HousingAssessment"
    t.integer "DirectServices"
    t.integer "ReceivesReferrals"
    t.date "CEParticipationStatusStartDate"
    t.date "CEParticipationStatusEndDate"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["CEParticipationID", "data_source_id"], name: "hmis_2024_ce_participations-5c6f"
    t.index ["CEParticipationID"], name: "hmis2024ceparticipations_5a29"
    t.index ["ExportID"], name: "hmis2024ceparticipations_634d"
    t.index ["ProjectID"], name: "hmis2024ceparticipations_42af"
  end

  create_table "hmis_2024_clients", force: :cascade do |t|
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
    t.integer "HispanicLatinaeo"
    t.integer "MidEastNAfrican"
    t.integer "NativeHIPacific"
    t.integer "White"
    t.integer "RaceNone"
    t.string "AdditionalRaceEthnicity"
    t.integer "Woman"
    t.integer "Man"
    t.integer "NonBinary"
    t.integer "CulturallySpecific"
    t.integer "Transgender"
    t.integer "Questioning"
    t.integer "DifferentIdentity"
    t.integer "GenderNone"
    t.string "DifferentIdentityText"
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
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateUpdated"], name: "hmis2024clients_42d5"
    t.index ["ExportID"], name: "hmis2024clients_634d"
    t.index ["PersonalID", "data_source_id"], name: "hmis_2024_clients-230f"
    t.index ["PersonalID"], name: "hmis2024clients_603f"
    t.index ["VeteranStatus"], name: "hmis2024clients_20a8"
  end

  create_table "hmis_2024_current_living_situations", force: :cascade do |t|
    t.string "CurrentLivingSitID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "InformationDate"
    t.integer "CurrentLivingSituation"
    t.integer "CLSSubsidyType"
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
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["CurrentLivingSitID", "data_source_id"], name: "hmis_2024_current_living_situations-cf31"
    t.index ["CurrentLivingSitID"], name: "hmis2024currentlivingsituations_c1ef"
    t.index ["CurrentLivingSituation"], name: "hmis2024currentlivingsituations_d718"
    t.index ["EnrollmentID"], name: "hmis2024currentlivingsituations_4337"
    t.index ["ExportID"], name: "hmis2024currentlivingsituations_634d"
    t.index ["InformationDate"], name: "hmis2024currentlivingsituations_fabe"
  end

  create_table "hmis_2024_disabilities", force: :cascade do |t|
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
    t.integer "AntiRetroviral"
    t.integer "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis2024disabilities_d381"
    t.index ["DateUpdated"], name: "hmis2024disabilities_42d5"
    t.index ["DisabilitiesID", "data_source_id"], name: "hmis_2024_disabilities-7712"
    t.index ["DisabilitiesID"], name: "hmis2024disabilities_1873"
    t.index ["ExportID"], name: "hmis2024disabilities_634d"
    t.index ["PersonalID"], name: "hmis2024disabilities_603f"
  end

  create_table "hmis_2024_employment_educations", force: :cascade do |t|
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
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateUpdated"], name: "hmis2024employmenteducations_42d5"
    t.index ["EmploymentEducationID", "data_source_id"], name: "hmis_2024_employment_educations-3032"
    t.index ["EmploymentEducationID"], name: "hmis2024employmenteducations_350e"
    t.index ["ExportID"], name: "hmis2024employmenteducations_634d"
  end

  create_table "hmis_2024_enrollments", force: :cascade do |t|
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "ProjectID"
    t.date "EntryDate"
    t.string "HouseholdID"
    t.integer "RelationshipToHoH"
    t.string "EnrollmentCoC"
    t.integer "LivingSituation"
    t.integer "RentalSubsidyType"
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
    t.integer "PercentAMI"
    t.integer "ReferralSource"
    t.integer "CountOutreachReferralApproaches"
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
    t.integer "MentalHealthDisorderFam"
    t.integer "PhysicalDisabilityFam"
    t.integer "AlcoholDrugUseDisorderFam"
    t.integer "InsufficientIncome"
    t.integer "IncarceratedParent"
    t.string "VAMCStation"
    t.integer "TargetScreenReqd"
    t.integer "TimeToHousingLoss"
    t.integer "AnnualPercentAMI"
    t.integer "LiteralHomelessHistory"
    t.integer "ClientLeaseholder"
    t.integer "HOHLeaseholder"
    t.integer "SubsidyAtRisk"
    t.integer "EvictionHistory"
    t.integer "CriminalRecord"
    t.integer "IncarceratedAdult"
    t.integer "PrisonDischarge"
    t.integer "SexOffender"
    t.integer "DisabledHoH"
    t.integer "CurrentPregnant"
    t.integer "SingleParent"
    t.integer "DependentUnder6"
    t.integer "HH5Plus"
    t.integer "CoCPrioritized"
    t.integer "HPScreeningScore"
    t.integer "ThresholdScore"
    t.integer "TranslationNeeded"
    t.integer "PreferredLanguage"
    t.string "PreferredLanguageDifferent"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateDeleted", "EntryDate", "EnrollmentID", "HouseholdID", "ProjectID", "RelationshipToHoH"], name: "hmis2024enrollments_c830"
    t.index ["DateDeleted", "RelationshipToHoH", "EnrollmentID", "PersonalID", "EntryDate", "HouseholdID", "DisablingCondition"], name: "hmis2024enrollments_8d5c"
    t.index ["DateDeleted"], name: "hmis2024enrollments_f3a2"
    t.index ["DateUpdated"], name: "hmis2024enrollments_42d5"
    t.index ["EnrollmentID", "PersonalID"], name: "hmis2024enrollments_c548"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmis2024enrollments_34e3"
    t.index ["EnrollmentID", "data_source_id"], name: "hmis_2024_enrollments-0a46"
    t.index ["EnrollmentID"], name: "hmis2024enrollments_4337"
    t.index ["EntryDate", "EnrollmentID", "ProjectID", "HouseholdID", "RelationshipToHoH", "DateDeleted"], name: "hmis2024enrollments_6191"
    t.index ["ExportID"], name: "hmis2024enrollments_634d"
    t.index ["HouseholdID", "DateDeleted", "EntryDate", "RelationshipToHoH", "EnrollmentID", "PersonalID", "DisablingCondition"], name: "hmis2024enrollments_5d40"
    t.index ["HouseholdID", "DateDeleted", "RelationshipToHoH", "EnrollmentID", "PersonalID", "EntryDate", "DisablingCondition"], name: "hmis2024enrollments_89e7"
    t.index ["HouseholdID", "RelationshipToHoH", "DateDeleted", "EnrollmentID"], name: "hmis2024enrollments_ea7f"
    t.index ["HouseholdID"], name: "hmis2024enrollments_5328"
    t.index ["LengthOfStay", "EnrollmentID"], name: "hmis2024enrollments_4685"
    t.index ["LivingSituation", "EnrollmentID"], name: "hmis2024enrollments_821a"
    t.index ["MonthsHomelessPastThreeYears", "EnrollmentID", "LivingSituation", "PreviousStreetESSH"], name: "hmis2024enrollments_44c4"
    t.index ["MoveInDate", "EnrollmentID"], name: "hmis2024enrollments_fbbd"
    t.index ["PersonalID"], name: "hmis2024enrollments_603f"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmis2024enrollments_3085"
    t.index ["ProjectID", "HouseholdID"], name: "hmis2024enrollments_2735"
    t.index ["ProjectID", "RelationshipToHoH", "DateDeleted", "EnrollmentID", "PersonalID", "EntryDate", "HouseholdID", "MoveInDate"], name: "hmis2024enrollments_9005"
    t.index ["ProjectID"], name: "hmis2024enrollments_42af"
    t.index ["RelationshipToHoH", "DateDeleted", "EnrollmentID", "PersonalID", "ProjectID", "EntryDate", "HouseholdID", "MoveInDate", "DisablingCondition"], name: "hmis2024enrollments_c3b4"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears", "EnrollmentID"], name: "hmis2024enrollments_c321"
  end

  create_table "hmis_2024_events", force: :cascade do |t|
    t.string "EventID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "EventDate"
    t.integer "Event"
    t.integer "ProbSolDivRRResult"
    t.integer "ReferralCaseManageAfter"
    t.string "LocationCrisisOrPHHousing"
    t.integer "ReferralResult"
    t.date "ResultDate"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["EventDate"], name: "hmis2024events_ab19"
    t.index ["EventID", "data_source_id"], name: "hmis_2024_events-9f9c"
    t.index ["EventID"], name: "hmis2024events_5251"
    t.index ["ExportID"], name: "hmis2024events_634d"
  end

  create_table "hmis_2024_exits", force: :cascade do |t|
    t.string "ExitID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "ExitDate"
    t.integer "Destination"
    t.integer "DestinationSubsidyType"
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
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateDeleted", "EnrollmentID", "ExitDate"], name: "hmis2024exits_f3a2"
    t.index ["DateUpdated"], name: "hmis2024exits_42d5"
    t.index ["EnrollmentID"], name: "hmis2024exits_4337"
    t.index ["ExitDate", "Destination", "EnrollmentID"], name: "hmis2024exits_13dc"
    t.index ["ExitDate"], name: "hmis2024exits_fa9a"
    t.index ["ExitID", "data_source_id"], name: "hmis_2024_exits-cfdd"
    t.index ["ExitID"], name: "hmis2024exits_6f2b"
    t.index ["ExportID"], name: "hmis2024exits_634d"
    t.index ["PersonalID"], name: "hmis2024exits_603f"
    t.index ["importer_log_id"], name: "index_hmis_2024_exits_on_importer_log_id"
  end

  create_table "hmis_2024_exports", force: :cascade do |t|
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
    t.string "CSVVersion"
    t.integer "ExportPeriodType"
    t.integer "ExportDirective"
    t.integer "HashStatus"
    t.string "ImplementationID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["ExportID", "data_source_id"], name: "hmis_2024_exports-86be"
  end

  create_table "hmis_2024_funders", force: :cascade do |t|
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
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis2024funders_d381"
    t.index ["DateUpdated"], name: "hmis2024funders_42d5"
    t.index ["ExportID"], name: "hmis2024funders_634d"
    t.index ["FunderID", "data_source_id"], name: "hmis_2024_funders-4ad5"
    t.index ["FunderID"], name: "hmis2024funders_4657"
  end

  create_table "hmis_2024_health_and_dvs", force: :cascade do |t|
    t.string "HealthAndDVID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "InformationDate"
    t.integer "DomesticViolenceSurvivor"
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
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateUpdated"], name: "hmis2024healthanddvs_42d5"
    t.index ["ExportID"], name: "hmis2024healthanddvs_634d"
    t.index ["HealthAndDVID", "data_source_id"], name: "hmis_2024_health_and_dvs-e384"
    t.index ["HealthAndDVID"], name: "hmis2024healthanddvs_1329"
  end

  create_table "hmis_2024_hmis_participations", force: :cascade do |t|
    t.string "HMISParticipationID"
    t.string "ProjectID"
    t.integer "HMISParticipationType"
    t.date "HMISParticipationStatusStartDate"
    t.date "HMISParticipationStatusEndDate"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["ExportID"], name: "hmis2024hmisparticipations_634d"
    t.index ["HMISParticipationID", "data_source_id"], name: "hmis_2024_hmis_participations-0f0d"
    t.index ["HMISParticipationID"], name: "hmis2024hmisparticipations_827e"
    t.index ["ProjectID"], name: "hmis2024hmisparticipations_42af"
  end

  create_table "hmis_2024_income_benefits", force: :cascade do |t|
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
    t.integer "VHAServices"
    t.integer "NoVHAReason"
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
    t.integer "ADAP"
    t.integer "NoADAPReason"
    t.integer "RyanWhiteMedDent"
    t.integer "NoRyanWhiteReason"
    t.integer "ConnectionWithSOAR"
    t.integer "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateUpdated"], name: "hmis2024incomebenefits_42d5"
    t.index ["Earned", "DataCollectionStage"], name: "hmis2024incomebenefits_16c2"
    t.index ["ExportID"], name: "hmis2024incomebenefits_634d"
    t.index ["IncomeBenefitsID", "data_source_id"], name: "hmis_2024_income_benefits-200d"
    t.index ["IncomeBenefitsID"], name: "hmis2024incomebenefits_f5f5"
    t.index ["IncomeFromAnySource", "DataCollectionStage"], name: "hmis2024incomebenefits_ae8d"
    t.index ["InformationDate"], name: "hmis2024incomebenefits_fabe"
  end

  create_table "hmis_2024_inventories", force: :cascade do |t|
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
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateCreated"], name: "hmis2024inventories_d381"
    t.index ["DateUpdated"], name: "hmis2024inventories_42d5"
    t.index ["ExportID"], name: "hmis2024inventories_634d"
    t.index ["InventoryID", "data_source_id"], name: "hmis_2024_inventories-86c0"
    t.index ["InventoryID"], name: "hmis2024inventories_9529"
  end

  create_table "hmis_2024_organizations", force: :cascade do |t|
    t.string "OrganizationID"
    t.string "OrganizationName"
    t.integer "VictimServiceProvider"
    t.string "OrganizationCommonName"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["ExportID"], name: "hmis2024organizations_634d"
    t.index ["OrganizationID", "data_source_id"], name: "hmis_2024_organizations-7580"
    t.index ["OrganizationID"], name: "hmis2024organizations_b19d"
  end

  create_table "hmis_2024_project_cocs", force: :cascade do |t|
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
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateUpdated"], name: "hmis2024projectcocs_42d5"
    t.index ["ExportID"], name: "hmis2024projectcocs_634d"
    t.index ["ProjectCoCID", "data_source_id"], name: "hmis_2024_project_cocs-3966"
    t.index ["ProjectCoCID"], name: "hmis2024projectcocs_787b"
  end

  create_table "hmis_2024_projects", force: :cascade do |t|
    t.string "ProjectID"
    t.string "OrganizationID"
    t.string "ProjectName"
    t.string "ProjectCommonName"
    t.date "OperatingStartDate"
    t.date "OperatingEndDate"
    t.integer "ContinuumProject"
    t.integer "ProjectType"
    t.integer "HousingType"
    t.integer "RRHSubType"
    t.integer "ResidentialAffiliation"
    t.integer "TargetPopulation"
    t.integer "HOPWAMedAssistedLivingFac"
    t.integer "PITCount"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateUpdated"], name: "hmis2024projects_42d5"
    t.index ["ProjectID", "data_source_id"], name: "hmis_2024_projects-92c5"
    t.index ["ProjectID"], name: "hmis2024projects_42af"
    t.index ["ProjectType"], name: "hmis2024projects_e4bb"
  end

  create_table "hmis_2024_services", force: :cascade do |t|
    t.string "ServicesID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "DateProvided"
    t.integer "RecordType"
    t.integer "TypeProvided"
    t.string "OtherTypeProvided"
    t.string "MovingOnOtherType"
    t.integer "SubTypeProvided"
    t.string "FAAmount"
    t.date "FAStartDate"
    t.date "FAEndDate"
    t.integer "ReferralOutcome"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["DateDeleted"], name: "hmis2024services_f3a2"
    t.index ["DateProvided"], name: "hmis2024services_3444"
    t.index ["DateUpdated"], name: "hmis2024services_42d5"
    t.index ["EnrollmentID", "RecordType", "DateDeleted", "DateProvided"], name: "hmis2024services_9c1a"
    t.index ["EnrollmentID"], name: "hmis2024services_4337"
    t.index ["ExportID"], name: "hmis2024services_634d"
    t.index ["RecordType", "DateDeleted", "DateProvided", "EnrollmentID"], name: "hmis2024services_8dbb"
    t.index ["RecordType"], name: "hmis2024services_237b"
    t.index ["ServicesID", "data_source_id"], name: "hmis_2024_services-7a57"
    t.index ["ServicesID"], name: "hmis2024services_6415"
  end

  create_table "hmis_2024_users", force: :cascade do |t|
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
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["ExportID"], name: "hmis2024users_634d"
    t.index ["UserID", "data_source_id"], name: "hmis_2024_users-b749"
    t.index ["UserID"], name: "hmis2024users_57c7"
  end

  create_table "hmis_2024_youth_education_statuses", force: :cascade do |t|
    t.string "YouthEducationStatusID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.date "InformationDate"
    t.integer "CurrentSchoolAttend"
    t.integer "MostRecentEdStatus"
    t.integer "CurrentEdStatus"
    t.integer "DataCollectionStage"
    t.datetime "DateCreated"
    t.datetime "DateUpdated"
    t.string "UserID"
    t.datetime "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.boolean "should_import", default: true
    t.index ["ExportID"], name: "hmis2024youtheducationstatuses_634d"
    t.index ["InformationDate"], name: "hmis2024youtheducationstatuses_fabe"
    t.index ["YouthEducationStatusID", "data_source_id"], name: "hmis_2024_youth_education_statuses-a32f"
    t.index ["YouthEducationStatusID"], name: "hmis2024youtheducationstatuses_6049"
  end

  create_table "hmis_active_ranges", force: :cascade do |t|
    t.string "entity_type"
    t.bigint "entity_id"
    t.date "start_date", null: false
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.string "user_id", null: false
    t.index ["entity_type", "entity_id"], name: "index_hmis_active_ranges_on_entity"
  end

  create_table "hmis_aggregated_enrollments", force: :cascade do |t|
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
    t.integer "ReferralSource"
    t.integer "CountOutreachReferralApproaches"
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
    t.integer "MentalHealthDisorderFam"
    t.integer "PhysicalDisabilityFam"
    t.integer "AlcoholDrugUseDisorderFam"
    t.integer "InsufficientIncome"
    t.integer "IncarceratedParent"
    t.string "VAMCStation"
    t.integer "TargetScreenReqd"
    t.integer "TimeToHousingLoss"
    t.integer "AnnualPercentAMI"
    t.integer "LiteralHomelessHistory"
    t.integer "ClientLeaseholder"
    t.integer "HOHLeaseholder"
    t.integer "SubsidyAtRisk"
    t.integer "EvictionHistory"
    t.integer "CriminalRecord"
    t.integer "IncarceratedAdult"
    t.integer "PrisonDischarge"
    t.integer "SexOffender"
    t.integer "DisabledHoH"
    t.integer "CurrentPregnant"
    t.integer "SingleParent"
    t.integer "DependentUnder6"
    t.integer "HH5Plus"
    t.integer "CoCPrioritized"
    t.integer "HPScreeningScore"
    t.integer "ThresholdScore"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.string "EnrollmentCoC"
    t.integer "RentalSubsidyType"
    t.integer "TranslationNeeded"
    t.integer "PreferredLanguage"
    t.string "PreferredLanguageDifferent"
    t.index ["DateCreated"], name: "hmisaggregatedenrollments_c08h"
    t.index ["DateDeleted"], name: "hmisaggregatedenrollments_A5GJ"
    t.index ["DateUpdated"], name: "hmisaggregatedenrollments_NHNS"
    t.index ["EnrollmentID", "PersonalID", "data_source_id"], name: "hmis_aggregated_enrollments-aTmv", unique: true
    t.index ["EnrollmentID", "PersonalID"], name: "hmisaggregatedenrollments_Uv3q"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmisaggregatedenrollments_uy6S"
    t.index ["EnrollmentID"], name: "hmisaggregatedenrollments_V6EX"
    t.index ["EntryDate"], name: "hmisaggregatedenrollments_oNYR"
    t.index ["ExportID"], name: "hmisaggregatedenrollments_bGvX"
    t.index ["HouseholdID"], name: "hmisaggregatedenrollments_bHWN"
    t.index ["LivingSituation"], name: "hmisaggregatedenrollments_kHZg"
    t.index ["PersonalID", "ProjectID", "data_source_id"], name: "hmis_agg_enrollments_p_id_p_id_ds_id"
    t.index ["PersonalID"], name: "hmisaggregatedenrollments_QCCR"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmisaggregatedenrollments_FHjE"
    t.index ["ProjectID", "HouseholdID"], name: "hmisaggregatedenrollments_eq3c"
    t.index ["ProjectID", "RelationshipToHoH"], name: "hmisaggregatedenrollments_kQyq"
    t.index ["ProjectID"], name: "hmisaggregatedenrollments_naBW"
    t.index ["RelationshipToHoH"], name: "hmisaggregatedenrollments_VpLz"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears"], name: "hmisaggregatedenrollments_1KEG"
    t.index ["source_type", "source_id"], name: "hmis_aggregated_enrollments-qHbn"
  end

  create_table "hmis_aggregated_exits", force: :cascade do |t|
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.integer "importer_log_id", null: false
    t.datetime "pre_processed_at", precision: nil, null: false
    t.string "source_hash"
    t.integer "source_id", null: false
    t.string "source_type", null: false
    t.datetime "dirty_at", precision: nil
    t.datetime "clean_at", precision: nil
    t.integer "DestinationSubsidyType"
    t.index ["DateCreated"], name: "hmisaggregatedexits_IKVS"
    t.index ["DateDeleted"], name: "hmisaggregatedexits_IHNR"
    t.index ["DateUpdated"], name: "hmisaggregatedexits_tmOV"
    t.index ["EnrollmentID"], name: "hmisaggregatedexits_YcRf"
    t.index ["ExitDate"], name: "hmisaggregatedexits_rDFN"
    t.index ["ExitID", "data_source_id"], name: "hmis_aggregated_exits-FiCn", unique: true
    t.index ["ExitID"], name: "hmisaggregatedexits_XuIA"
    t.index ["ExportID"], name: "hmisaggregatedexits_3LO0"
    t.index ["PersonalID"], name: "hmisaggregatedexits_bSNd"
    t.index ["source_type", "source_id"], name: "hmis_aggregated_exits-Nmym"
  end

  create_table "hmis_assessment_details", force: :cascade do |t|
    t.bigint "assessment_id"
    t.bigint "definition_id"
    t.integer "data_collection_stage", null: false, comment: "One of the HMIS 5.03.1 or 99 for local use"
    t.string "role", null: false, comment: "Usually one of INTAKE, UPDATE, ANNUAL, EXIT, POST_EXIT, CE, CUSTOM"
    t.string "status", comment: "Usually one of submitted, draft"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "values"
    t.jsonb "hud_values"
    t.bigint "assessment_processor_id"
    t.index ["assessment_id"], name: "index_hmis_assessment_details_on_assessment_id"
    t.index ["assessment_processor_id"], name: "index_hmis_assessment_details_on_assessment_processor_id"
    t.index ["definition_id"], name: "index_hmis_assessment_details_on_definition_id"
  end

  create_table "hmis_assessments", id: :serial, force: :cascade do |t|
    t.integer "assessment_id", null: false
    t.integer "site_id", null: false
    t.string "site_name"
    t.string "name", null: false
    t.boolean "fetch", default: false, null: false
    t.boolean "active", default: true, null: false
    t.datetime "last_fetched_at", precision: nil
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
    t.boolean "covid_19_impact_assessment", default: false
    t.boolean "with_location_data", default: false, null: false
    t.index ["active", "exclude_from_window", "confidential"], name: "hmis_a_act_exl_con"
    t.index ["assessment_id"], name: "index_hmis_assessments_on_assessment_id"
    t.index ["data_source_id"], name: "index_hmis_assessments_on_data_source_id"
    t.index ["name"], name: "index_hmis_assessments_on_name"
    t.index ["site_id"], name: "index_hmis_assessments_on_site_id"
  end

  create_table "hmis_case_notes", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "user_id", null: false
    t.bigint "organization_id"
    t.bigint "project_id"
    t.bigint "enrollment_id"
    t.string "source_type"
    t.bigint "source_id"
    t.date "information_date", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["client_id"], name: "index_hmis_case_notes_on_client_id"
    t.index ["enrollment_id"], name: "index_hmis_case_notes_on_enrollment_id"
    t.index ["organization_id"], name: "index_hmis_case_notes_on_organization_id"
    t.index ["project_id"], name: "index_hmis_case_notes_on_project_id"
    t.index ["source_type", "source_id"], name: "index_hmis_case_notes_on_source"
    t.index ["user_id"], name: "index_hmis_case_notes_on_user_id"
  end

  create_table "hmis_client_alerts", force: :cascade do |t|
    t.text "note", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.date "expiration_date"
    t.bigint "created_by_id", null: false
    t.bigint "client_id", null: false
    t.string "priority"
    t.index ["client_id"], name: "index_hmis_client_alerts_on_client_id"
    t.index ["created_by_id"], name: "index_hmis_client_alerts_on_created_by_id"
  end

  create_table "hmis_client_attributes_defined_text", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.integer "data_source_id"
    t.string "consent_form_status"
    t.datetime "consent_form_updated_at", precision: nil
    t.string "source_id"
    t.string "source_class"
    t.index ["client_id"], name: "index_hmis_client_attributes_defined_text_on_client_id"
    t.index ["data_source_id"], name: "index_hmis_client_attributes_defined_text_on_data_source_id"
  end

  create_table "hmis_client_merge_audits", force: :cascade do |t|
    t.jsonb "pre_merge_state", null: false
    t.bigint "actor_id", null: false
    t.datetime "merged_at", precision: nil, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hmis_client_merge_histories", force: :cascade do |t|
    t.bigint "retained_client_id", null: false
    t.bigint "deleted_client_id", null: false
    t.bigint "client_merge_audit_id", null: false, comment: "Audit log for the merge that deleted the deleted_client"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_merge_audit_id"], name: "index_hmis_client_merge_histories_on_client_merge_audit_id"
    t.index ["deleted_client_id"], name: "index_hmis_client_merge_histories_on_deleted_client_id"
    t.index ["retained_client_id"], name: "index_hmis_client_merge_histories_on_retained_client_id"
  end

  create_table "hmis_clients", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.text "response"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "eto_last_updated", precision: nil
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
    t.datetime "loaded_at", precision: nil, null: false
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
    t.datetime "loaded_at", precision: nil, null: false
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["AssessmentID"], name: "hmis_csv_2020_assessment_results-NEN7"
    t.index ["AssessmentResultID", "data_source_id"], name: "hmis_csv_2020_assessment_results-Rkod"
    t.index ["ExportID"], name: "hmis_csv_2020_assessment_results-NLC4"
    t.index ["loader_id"], name: "index_hmis_csv_2020_assessment_results_on_loader_id"
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
    t.datetime "loaded_at", precision: nil, null: false
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
    t.datetime "loaded_at", precision: nil, null: false
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
    t.index ["loader_id"], name: "index_hmis_csv_2020_clients_on_loader_id"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["CurrentLivingSitID", "data_source_id"], name: "hmis_csv_2020_current_living_situations-jzq2"
    t.index ["CurrentLivingSitID"], name: "hmis_csv_2020_current_living_situations-EGfX"
    t.index ["CurrentLivingSituation"], name: "hmis_csv_2020_current_living_situations-Vh4Y"
    t.index ["EnrollmentID"], name: "hmis_csv_2020_current_living_situations-ScsR"
    t.index ["ExportID"], name: "hmis_csv_2020_current_living_situations-KGuH"
    t.index ["InformationDate"], name: "hmis_csv_2020_current_living_situations-VCsb"
    t.index ["PersonalID"], name: "hmis_csv_2020_current_living_situations-3hVq"
    t.index ["loader_id"], name: "index_hmis_csv_2020_current_living_situations_on_loader_id"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_disabilities-ohpt"
    t.index ["DateUpdated"], name: "hmis_csv_2020_disabilities-4Nml"
    t.index ["DisabilitiesID", "data_source_id"], name: "hmis_csv_2020_disabilities-anqe"
    t.index ["DisabilitiesID"], name: "hmis_csv_2020_disabilities-toFu"
    t.index ["EnrollmentID"], name: "hmis_csv_2020_disabilities-9jL3"
    t.index ["ExportID"], name: "hmis_csv_2020_disabilities-Sp4k"
    t.index ["PersonalID"], name: "hmis_csv_2020_disabilities-xa8A"
    t.index ["loader_id"], name: "index_hmis_csv_2020_disabilities_on_loader_id"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_employment_educations-bTVG"
    t.index ["DateUpdated"], name: "hmis_csv_2020_employment_educations-4yxa"
    t.index ["EmploymentEducationID", "data_source_id"], name: "hmis_csv_2020_employment_educations-3UVX"
    t.index ["EmploymentEducationID"], name: "hmis_csv_2020_employment_educations-U3yq"
    t.index ["EnrollmentID"], name: "hmis_csv_2020_employment_educations-JTgH"
    t.index ["ExportID"], name: "hmis_csv_2020_employment_educations-8u1c"
    t.index ["PersonalID"], name: "hmis_csv_2020_employment_educations-ffjb"
    t.index ["loader_id"], name: "index_hmis_csv_2020_employment_educations_on_loader_id"
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
    t.datetime "loaded_at", precision: nil, null: false
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
    t.index ["loader_id"], name: "index_hmis_csv_2020_enrollment_cocs_on_loader_id"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_enrollments-djbw"
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
    t.index ["loader_id"], name: "index_hmis_csv_2020_enrollments_on_loader_id"
  end

  create_table "hmis_csv_2020_events", force: :cascade do |t|
    t.string "EventID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "EventDate"
    t.string "Event"
    t.string "ProbSolDivRRResult"
    t.string "ReferralCaseManageAfter"
    t.string "LocationCrisisOrPHHousing"
    t.string "ReferralResult"
    t.string "ResultDate"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
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
    t.datetime "loaded_at", precision: nil, null: false
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ExportID", "data_source_id"], name: "hmis_csv_2020_exports-K9wp"
    t.index ["ExportID"], name: "hmis_csv_2020_exports-iweG"
    t.index ["loader_id"], name: "index_hmis_csv_2020_exports_on_loader_id"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_funders-IC4k"
    t.index ["DateUpdated"], name: "hmis_csv_2020_funders-Ix1m"
    t.index ["ExportID"], name: "hmis_csv_2020_funders-PEzG"
    t.index ["FunderID", "data_source_id"], name: "hmis_csv_2020_funders-BLkd"
    t.index ["FunderID"], name: "hmis_csv_2020_funders-1HLT"
    t.index ["loader_id"], name: "index_hmis_csv_2020_funders_on_loader_id"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_health_and_dvs-TUWh"
    t.index ["DateUpdated"], name: "hmis_csv_2020_health_and_dvs-y2fn"
    t.index ["EnrollmentID"], name: "hmis_csv_2020_health_and_dvs-zvlJ"
    t.index ["ExportID"], name: "hmis_csv_2020_health_and_dvs-lO76"
    t.index ["HealthAndDVID", "data_source_id"], name: "hmis_csv_2020_health_and_dvs-6zDo"
    t.index ["HealthAndDVID"], name: "hmis_csv_2020_health_and_dvs-2NoM"
    t.index ["PersonalID"], name: "hmis_csv_2020_health_and_dvs-xYMb"
    t.index ["loader_id"], name: "index_hmis_csv_2020_health_and_dvs_on_loader_id"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_income_benefits-lVjn"
    t.index ["DateUpdated"], name: "hmis_csv_2020_income_benefits-YyfJ"
    t.index ["EnrollmentID"], name: "hmis_csv_2020_income_benefits-6HMy"
    t.index ["ExportID"], name: "hmis_csv_2020_income_benefits-SEnq"
    t.index ["IncomeBenefitsID", "data_source_id"], name: "hmis_csv_2020_income_benefits-O58u"
    t.index ["IncomeBenefitsID"], name: "hmis_csv_2020_income_benefits-KXp0"
    t.index ["PersonalID"], name: "hmis_csv_2020_income_benefits-Qf5l"
    t.index ["loader_id"], name: "index_hmis_csv_2020_income_benefits_on_loader_id"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_inventories-eYpq"
    t.index ["DateUpdated"], name: "hmis_csv_2020_inventories-NeSc"
    t.index ["ExportID"], name: "hmis_csv_2020_inventories-wdcK"
    t.index ["InventoryID", "data_source_id"], name: "hmis_csv_2020_inventories-sfWI"
    t.index ["InventoryID"], name: "hmis_csv_2020_inventories-RGrg"
    t.index ["ProjectID", "CoCCode"], name: "hmis_csv_2020_inventories-BTZq"
    t.index ["loader_id"], name: "index_hmis_csv_2020_inventories_on_loader_id"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmis_csv_2020_organizations-LqQF"
    t.index ["OrganizationID", "data_source_id"], name: "hmis_csv_2020_organizations-cRJF"
    t.index ["OrganizationID"], name: "hmis_csv_2020_organizations-tyIy"
    t.index ["loader_id"], name: "index_hmis_csv_2020_organizations_on_loader_id"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_project_cocs-fRQZ"
    t.index ["DateUpdated"], name: "hmis_csv_2020_project_cocs-wP5S"
    t.index ["ExportID"], name: "hmis_csv_2020_project_cocs-336L"
    t.index ["ProjectCoCID", "data_source_id"], name: "hmis_csv_2020_project_cocs-K765"
    t.index ["ProjectCoCID"], name: "hmis_csv_2020_project_cocs-5NHP"
    t.index ["ProjectID", "CoCCode"], name: "hmis_csv_2020_project_cocs-G4ij"
    t.index ["loader_id"], name: "index_hmis_csv_2020_project_cocs_on_loader_id"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_projects-m4tQ"
    t.index ["DateUpdated"], name: "hmis_csv_2020_projects-MNAC"
    t.index ["ExportID"], name: "hmis_csv_2020_projects-f4DP"
    t.index ["ProjectID", "data_source_id"], name: "hmis_csv_2020_projects-StS2"
    t.index ["ProjectID"], name: "hmis_csv_2020_projects-I9LN"
    t.index ["ProjectType"], name: "hmis_csv_2020_projects-gAEK"
    t.index ["loader_id"], name: "index_hmis_csv_2020_projects_on_loader_id"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmis_csv_2020_services-Nlyp"
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
    t.index ["loader_id"], name: "index_hmis_csv_2020_services_on_loader_id"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmis_csv_2020_users-Vflk"
    t.index ["UserID", "data_source_id"], name: "hmis_csv_2020_users-Y4OW"
    t.index ["UserID"], name: "hmis_csv_2020_users-3tXl"
    t.index ["loader_id"], name: "index_hmis_csv_2020_users_on_loader_id"
  end

  create_table "hmis_csv_2022_affiliations", force: :cascade do |t|
    t.string "AffiliationID"
    t.string "ProjectID"
    t.string "ResProjectID"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["AffiliationID", "data_source_id"], name: "hmis_csv_2022_affiliations-6457"
    t.index ["ExportID"], name: "hmiscsv2022affiliations_6QZN"
    t.index ["ExportID"], name: "hmiscsv2022affiliations_IYWP"
    t.index ["ExportID"], name: "hmiscsv2022affiliations_K0pm"
    t.index ["ExportID"], name: "hmiscsv2022affiliations_ZrIt"
    t.index ["ExportID"], name: "hmiscsv2022affiliations_ayf6"
    t.index ["loader_id"], name: "index_hmis_csv_2022_affiliations_on_loader_id"
  end

  create_table "hmis_csv_2022_assessment_questions", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["AssessmentID"], name: "hmiscsv2022assessmentquestions_9OKb"
    t.index ["AssessmentID"], name: "hmiscsv2022assessmentquestions_Ce5I"
    t.index ["AssessmentID"], name: "hmiscsv2022assessmentquestions_Wboq"
    t.index ["AssessmentID"], name: "hmiscsv2022assessmentquestions_b7du"
    t.index ["AssessmentID"], name: "hmiscsv2022assessmentquestions_f92d"
    t.index ["ExportID"], name: "hmiscsv2022assessmentquestions_0Hnw"
    t.index ["ExportID"], name: "hmiscsv2022assessmentquestions_BYOc"
    t.index ["ExportID"], name: "hmiscsv2022assessmentquestions_YiRf"
    t.index ["ExportID"], name: "hmiscsv2022assessmentquestions_tkC5"
    t.index ["ExportID"], name: "hmiscsv2022assessmentquestions_zaOr"
    t.index ["loader_id"], name: "index_hmis_csv_2022_assessment_questions_on_loader_id"
  end

  create_table "hmis_csv_2022_assessment_results", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["AssessmentID"], name: "hmiscsv2022assessmentresults_FEyR"
    t.index ["AssessmentID"], name: "hmiscsv2022assessmentresults_WyDM"
    t.index ["AssessmentID"], name: "hmiscsv2022assessmentresults_deg4"
    t.index ["AssessmentID"], name: "hmiscsv2022assessmentresults_fmqe"
    t.index ["AssessmentID"], name: "hmiscsv2022assessmentresults_tz9L"
    t.index ["ExportID"], name: "hmiscsv2022assessmentresults_HXI3"
    t.index ["ExportID"], name: "hmiscsv2022assessmentresults_IHby"
    t.index ["ExportID"], name: "hmiscsv2022assessmentresults_Kx2Z"
    t.index ["ExportID"], name: "hmiscsv2022assessmentresults_jF3M"
    t.index ["ExportID"], name: "hmiscsv2022assessmentresults_mcU2"
    t.index ["loader_id"], name: "index_hmis_csv_2022_assessment_results_on_loader_id"
  end

  create_table "hmis_csv_2022_assessments", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["AssessmentDate"], name: "hmiscsv2022assessments_2PIZ"
    t.index ["AssessmentDate"], name: "hmiscsv2022assessments_53fu"
    t.index ["AssessmentDate"], name: "hmiscsv2022assessments_Rg8h"
    t.index ["AssessmentDate"], name: "hmiscsv2022assessments_UsZf"
    t.index ["AssessmentDate"], name: "hmiscsv2022assessments_iP36"
    t.index ["AssessmentID"], name: "hmiscsv2022assessments_BR24"
    t.index ["AssessmentID"], name: "hmiscsv2022assessments_C04R"
    t.index ["AssessmentID"], name: "hmiscsv2022assessments_V72H"
    t.index ["AssessmentID"], name: "hmiscsv2022assessments_X4D5"
    t.index ["AssessmentID"], name: "hmiscsv2022assessments_mO4c"
    t.index ["EnrollmentID"], name: "hmiscsv2022assessments_NaP9"
    t.index ["EnrollmentID"], name: "hmiscsv2022assessments_ZFcY"
    t.index ["EnrollmentID"], name: "hmiscsv2022assessments_bNif"
    t.index ["EnrollmentID"], name: "hmiscsv2022assessments_peUV"
    t.index ["EnrollmentID"], name: "hmiscsv2022assessments_rylL"
    t.index ["ExportID"], name: "hmiscsv2022assessments_7pXC"
    t.index ["ExportID"], name: "hmiscsv2022assessments_9pYi"
    t.index ["ExportID"], name: "hmiscsv2022assessments_Pd8t"
    t.index ["ExportID"], name: "hmiscsv2022assessments_UlUg"
    t.index ["ExportID"], name: "hmiscsv2022assessments_vgMX"
    t.index ["PersonalID"], name: "hmiscsv2022assessments_NGHw"
    t.index ["PersonalID"], name: "hmiscsv2022assessments_OGHC"
    t.index ["PersonalID"], name: "hmiscsv2022assessments_Rthi"
    t.index ["PersonalID"], name: "hmiscsv2022assessments_rDxW"
    t.index ["PersonalID"], name: "hmiscsv2022assessments_tGj7"
    t.index ["loader_id"], name: "index_hmis_csv_2022_assessments_on_loader_id"
  end

  create_table "hmis_csv_2022_clients", force: :cascade do |t|
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
    t.string "NativeHIPacific"
    t.string "White"
    t.string "RaceNone"
    t.string "Ethnicity"
    t.string "Female"
    t.string "Male"
    t.string "NoSingleGender"
    t.string "Transgender"
    t.string "Questioning"
    t.string "GenderNone"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DOB"], name: "hmiscsv2022clients_1B2M"
    t.index ["DOB"], name: "hmiscsv2022clients_DlZc"
    t.index ["DOB"], name: "hmiscsv2022clients_ZIZI"
    t.index ["DOB"], name: "hmiscsv2022clients_bTWy"
    t.index ["DOB"], name: "hmiscsv2022clients_preE"
    t.index ["DateCreated"], name: "hmiscsv2022clients_ATux"
    t.index ["DateCreated"], name: "hmiscsv2022clients_Tyfa"
    t.index ["DateCreated"], name: "hmiscsv2022clients_XjIr"
    t.index ["DateCreated"], name: "hmiscsv2022clients_dxgO"
    t.index ["DateCreated"], name: "hmiscsv2022clients_tWOM"
    t.index ["DateUpdated"], name: "hmiscsv2022clients_2g9p"
    t.index ["DateUpdated"], name: "hmiscsv2022clients_ANF3"
    t.index ["DateUpdated"], name: "hmiscsv2022clients_hLhh"
    t.index ["DateUpdated"], name: "hmiscsv2022clients_jtrl"
    t.index ["DateUpdated"], name: "hmiscsv2022clients_u5Dy"
    t.index ["ExportID"], name: "hmiscsv2022clients_HyWK"
    t.index ["ExportID"], name: "hmiscsv2022clients_ZbiK"
    t.index ["ExportID"], name: "hmiscsv2022clients_nuV1"
    t.index ["ExportID"], name: "hmiscsv2022clients_qxVi"
    t.index ["ExportID"], name: "hmiscsv2022clients_tVth"
    t.index ["FirstName"], name: "hmiscsv2022clients_Ipa3"
    t.index ["FirstName"], name: "hmiscsv2022clients_dpoO"
    t.index ["FirstName"], name: "hmiscsv2022clients_ilET"
    t.index ["FirstName"], name: "hmiscsv2022clients_nEPb"
    t.index ["FirstName"], name: "hmiscsv2022clients_yj7O"
    t.index ["LastName"], name: "hmiscsv2022clients_DFQP"
    t.index ["LastName"], name: "hmiscsv2022clients_Ue7r"
    t.index ["LastName"], name: "hmiscsv2022clients_lhQG"
    t.index ["LastName"], name: "hmiscsv2022clients_oEBV"
    t.index ["LastName"], name: "hmiscsv2022clients_xYa1"
    t.index ["PersonalID", "data_source_id"], name: "hmis_csv_2022_clients-230f"
    t.index ["PersonalID"], name: "hmiscsv2022clients_603f"
    t.index ["PersonalID"], name: "hmiscsv2022clients_9y96"
    t.index ["PersonalID"], name: "hmiscsv2022clients_AblB"
    t.index ["PersonalID"], name: "hmiscsv2022clients_HMAT"
    t.index ["PersonalID"], name: "hmiscsv2022clients_SPth"
    t.index ["PersonalID"], name: "hmiscsv2022clients_zrAC"
    t.index ["VeteranStatus"], name: "hmiscsv2022clients_4Erz"
    t.index ["VeteranStatus"], name: "hmiscsv2022clients_CftS"
    t.index ["VeteranStatus"], name: "hmiscsv2022clients_Go11"
    t.index ["VeteranStatus"], name: "hmiscsv2022clients_UOq6"
    t.index ["VeteranStatus"], name: "hmiscsv2022clients_vJDq"
    t.index ["loader_id"], name: "index_hmis_csv_2022_clients_on_loader_id"
  end

  create_table "hmis_csv_2022_current_living_situations", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["CurrentLivingSitID", "data_source_id"], name: "hmis_csv_2022_current_living_situations-cf31"
    t.index ["CurrentLivingSitID"], name: "hmiscsv2022currentlivingsituations_G53q"
    t.index ["CurrentLivingSitID"], name: "hmiscsv2022currentlivingsituations_L04m"
    t.index ["CurrentLivingSitID"], name: "hmiscsv2022currentlivingsituations_Rq1z"
    t.index ["CurrentLivingSitID"], name: "hmiscsv2022currentlivingsituations_lc17"
    t.index ["CurrentLivingSitID"], name: "hmiscsv2022currentlivingsituations_ttmJ"
    t.index ["CurrentLivingSituation"], name: "hmiscsv2022currentlivingsituations_0whq"
    t.index ["CurrentLivingSituation"], name: "hmiscsv2022currentlivingsituations_OoDu"
    t.index ["CurrentLivingSituation"], name: "hmiscsv2022currentlivingsituations_Rgzv"
    t.index ["CurrentLivingSituation"], name: "hmiscsv2022currentlivingsituations_c7Fg"
    t.index ["CurrentLivingSituation"], name: "hmiscsv2022currentlivingsituations_oN7a"
    t.index ["EnrollmentID"], name: "hmiscsv2022currentlivingsituations_0QjY"
    t.index ["EnrollmentID"], name: "hmiscsv2022currentlivingsituations_MBRO"
    t.index ["EnrollmentID"], name: "hmiscsv2022currentlivingsituations_y4vM"
    t.index ["EnrollmentID"], name: "hmiscsv2022currentlivingsituations_yXYJ"
    t.index ["EnrollmentID"], name: "hmiscsv2022currentlivingsituations_zYGE"
    t.index ["ExportID"], name: "hmiscsv2022currentlivingsituations_Wec8"
    t.index ["ExportID"], name: "hmiscsv2022currentlivingsituations_Zwl1"
    t.index ["ExportID"], name: "hmiscsv2022currentlivingsituations_dUT6"
    t.index ["ExportID"], name: "hmiscsv2022currentlivingsituations_iNeW"
    t.index ["ExportID"], name: "hmiscsv2022currentlivingsituations_qJOi"
    t.index ["InformationDate"], name: "hmiscsv2022currentlivingsituations_79om"
    t.index ["InformationDate"], name: "hmiscsv2022currentlivingsituations_Lu7u"
    t.index ["InformationDate"], name: "hmiscsv2022currentlivingsituations_beIg"
    t.index ["InformationDate"], name: "hmiscsv2022currentlivingsituations_hxGV"
    t.index ["InformationDate"], name: "hmiscsv2022currentlivingsituations_xWxO"
    t.index ["PersonalID"], name: "hmiscsv2022currentlivingsituations_2ix3"
    t.index ["PersonalID"], name: "hmiscsv2022currentlivingsituations_IbRS"
    t.index ["PersonalID"], name: "hmiscsv2022currentlivingsituations_L44P"
    t.index ["PersonalID"], name: "hmiscsv2022currentlivingsituations_prGC"
    t.index ["PersonalID"], name: "hmiscsv2022currentlivingsituations_z0XS"
    t.index ["loader_id"], name: "index_hmis_csv_2022_current_living_situations_on_loader_id"
  end

  create_table "hmis_csv_2022_disabilities", force: :cascade do |t|
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
    t.string "AntiRetroviral"
    t.string "DataCollectionStage"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmiscsv2022disabilities_0FAj"
    t.index ["DateCreated"], name: "hmiscsv2022disabilities_6NwA"
    t.index ["DateCreated"], name: "hmiscsv2022disabilities_HfAi"
    t.index ["DateCreated"], name: "hmiscsv2022disabilities_NAn7"
    t.index ["DateCreated"], name: "hmiscsv2022disabilities_TwHW"
    t.index ["DateUpdated"], name: "hmiscsv2022disabilities_Ia96"
    t.index ["DateUpdated"], name: "hmiscsv2022disabilities_JlIz"
    t.index ["DateUpdated"], name: "hmiscsv2022disabilities_dHHy"
    t.index ["DateUpdated"], name: "hmiscsv2022disabilities_eK81"
    t.index ["DateUpdated"], name: "hmiscsv2022disabilities_kUs4"
    t.index ["DisabilitiesID"], name: "hmiscsv2022disabilities_14pD"
    t.index ["DisabilitiesID"], name: "hmiscsv2022disabilities_BfOC"
    t.index ["DisabilitiesID"], name: "hmiscsv2022disabilities_JS03"
    t.index ["DisabilitiesID"], name: "hmiscsv2022disabilities_Tf5p"
    t.index ["DisabilitiesID"], name: "hmiscsv2022disabilities_xTGY"
    t.index ["EnrollmentID"], name: "hmiscsv2022disabilities_3jSy"
    t.index ["EnrollmentID"], name: "hmiscsv2022disabilities_6PJV"
    t.index ["EnrollmentID"], name: "hmiscsv2022disabilities_VMgh"
    t.index ["EnrollmentID"], name: "hmiscsv2022disabilities_fd6N"
    t.index ["EnrollmentID"], name: "hmiscsv2022disabilities_jDA7"
    t.index ["ExportID"], name: "hmiscsv2022disabilities_ARC4"
    t.index ["ExportID"], name: "hmiscsv2022disabilities_Gwg7"
    t.index ["ExportID"], name: "hmiscsv2022disabilities_OFo6"
    t.index ["ExportID"], name: "hmiscsv2022disabilities_OMdy"
    t.index ["ExportID"], name: "hmiscsv2022disabilities_y3fv"
    t.index ["PersonalID"], name: "hmiscsv2022disabilities_DUOj"
    t.index ["PersonalID"], name: "hmiscsv2022disabilities_MLpw"
    t.index ["PersonalID"], name: "hmiscsv2022disabilities_Olzq"
    t.index ["PersonalID"], name: "hmiscsv2022disabilities_bckS"
    t.index ["PersonalID"], name: "hmiscsv2022disabilities_jabB"
    t.index ["loader_id"], name: "index_hmis_csv_2022_disabilities_on_loader_id"
  end

  create_table "hmis_csv_2022_employment_educations", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmiscsv2022employmenteducations_LI7n"
    t.index ["DateCreated"], name: "hmiscsv2022employmenteducations_bJWx"
    t.index ["DateCreated"], name: "hmiscsv2022employmenteducations_cugU"
    t.index ["DateCreated"], name: "hmiscsv2022employmenteducations_dRqv"
    t.index ["DateCreated"], name: "hmiscsv2022employmenteducations_skDR"
    t.index ["DateUpdated"], name: "hmiscsv2022employmenteducations_A6mw"
    t.index ["DateUpdated"], name: "hmiscsv2022employmenteducations_Ysak"
    t.index ["DateUpdated"], name: "hmiscsv2022employmenteducations_iobe"
    t.index ["DateUpdated"], name: "hmiscsv2022employmenteducations_oprT"
    t.index ["DateUpdated"], name: "hmiscsv2022employmenteducations_ozcJ"
    t.index ["EmploymentEducationID"], name: "hmiscsv2022employmenteducations_78id"
    t.index ["EmploymentEducationID"], name: "hmiscsv2022employmenteducations_NAxg"
    t.index ["EmploymentEducationID"], name: "hmiscsv2022employmenteducations_NbWu"
    t.index ["EmploymentEducationID"], name: "hmiscsv2022employmenteducations_fmAi"
    t.index ["EmploymentEducationID"], name: "hmiscsv2022employmenteducations_wddn"
    t.index ["EnrollmentID"], name: "hmiscsv2022employmenteducations_EVib"
    t.index ["EnrollmentID"], name: "hmiscsv2022employmenteducations_FiLV"
    t.index ["EnrollmentID"], name: "hmiscsv2022employmenteducations_R9hB"
    t.index ["EnrollmentID"], name: "hmiscsv2022employmenteducations_Yxep"
    t.index ["EnrollmentID"], name: "hmiscsv2022employmenteducations_ocww"
    t.index ["ExportID"], name: "hmiscsv2022employmenteducations_AiJX"
    t.index ["ExportID"], name: "hmiscsv2022employmenteducations_F0mG"
    t.index ["ExportID"], name: "hmiscsv2022employmenteducations_j9oN"
    t.index ["ExportID"], name: "hmiscsv2022employmenteducations_lIAh"
    t.index ["ExportID"], name: "hmiscsv2022employmenteducations_zwTX"
    t.index ["PersonalID"], name: "hmiscsv2022employmenteducations_6eDi"
    t.index ["PersonalID"], name: "hmiscsv2022employmenteducations_8Z2N"
    t.index ["PersonalID"], name: "hmiscsv2022employmenteducations_MSFC"
    t.index ["PersonalID"], name: "hmiscsv2022employmenteducations_ZbXO"
    t.index ["PersonalID"], name: "hmiscsv2022employmenteducations_mmce"
    t.index ["loader_id"], name: "index_hmis_csv_2022_employment_educations_on_loader_id"
  end

  create_table "hmis_csv_2022_enrollment_cocs", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["CoCCode"], name: "hmiscsv2022enrollmentcocs_SbfY"
    t.index ["CoCCode"], name: "hmiscsv2022enrollmentcocs_WRnl"
    t.index ["CoCCode"], name: "hmiscsv2022enrollmentcocs_axDz"
    t.index ["CoCCode"], name: "hmiscsv2022enrollmentcocs_emcB"
    t.index ["CoCCode"], name: "hmiscsv2022enrollmentcocs_ybyR"
    t.index ["DateCreated"], name: "hmiscsv2022enrollmentcocs_8MhC"
    t.index ["DateCreated"], name: "hmiscsv2022enrollmentcocs_g5J5"
    t.index ["DateCreated"], name: "hmiscsv2022enrollmentcocs_mKux"
    t.index ["DateCreated"], name: "hmiscsv2022enrollmentcocs_pmSf"
    t.index ["DateCreated"], name: "hmiscsv2022enrollmentcocs_wcbV"
    t.index ["DateDeleted"], name: "hmiscsv2022enrollmentcocs_0IAL"
    t.index ["DateDeleted"], name: "hmiscsv2022enrollmentcocs_1Xm2"
    t.index ["DateDeleted"], name: "hmiscsv2022enrollmentcocs_FwbF"
    t.index ["DateDeleted"], name: "hmiscsv2022enrollmentcocs_ZMp3"
    t.index ["DateDeleted"], name: "hmiscsv2022enrollmentcocs_f3a2"
    t.index ["DateDeleted"], name: "hmiscsv2022enrollmentcocs_iz8D"
    t.index ["DateUpdated"], name: "hmiscsv2022enrollmentcocs_GQqO"
    t.index ["DateUpdated"], name: "hmiscsv2022enrollmentcocs_RAnO"
    t.index ["DateUpdated"], name: "hmiscsv2022enrollmentcocs_aC6n"
    t.index ["DateUpdated"], name: "hmiscsv2022enrollmentcocs_oCoG"
    t.index ["DateUpdated"], name: "hmiscsv2022enrollmentcocs_qsT9"
    t.index ["EnrollmentCoCID"], name: "hmiscsv2022enrollmentcocs_DOSa"
    t.index ["EnrollmentCoCID"], name: "hmiscsv2022enrollmentcocs_VVbQ"
    t.index ["EnrollmentCoCID"], name: "hmiscsv2022enrollmentcocs_nt0O"
    t.index ["EnrollmentCoCID"], name: "hmiscsv2022enrollmentcocs_p3i5"
    t.index ["EnrollmentCoCID"], name: "hmiscsv2022enrollmentcocs_pfEL"
    t.index ["EnrollmentID"], name: "hmiscsv2022enrollmentcocs_1dHp"
    t.index ["EnrollmentID"], name: "hmiscsv2022enrollmentcocs_XgoM"
    t.index ["EnrollmentID"], name: "hmiscsv2022enrollmentcocs_Yhrm"
    t.index ["EnrollmentID"], name: "hmiscsv2022enrollmentcocs_caGj"
    t.index ["EnrollmentID"], name: "hmiscsv2022enrollmentcocs_zIJt"
    t.index ["ExportID"], name: "hmiscsv2022enrollmentcocs_CkJU"
    t.index ["ExportID"], name: "hmiscsv2022enrollmentcocs_EYBf"
    t.index ["ExportID"], name: "hmiscsv2022enrollmentcocs_GuqN"
    t.index ["ExportID"], name: "hmiscsv2022enrollmentcocs_gXcN"
    t.index ["ExportID"], name: "hmiscsv2022enrollmentcocs_wiac"
    t.index ["PersonalID"], name: "hmiscsv2022enrollmentcocs_MbjI"
    t.index ["PersonalID"], name: "hmiscsv2022enrollmentcocs_RFoA"
    t.index ["PersonalID"], name: "hmiscsv2022enrollmentcocs_RWu2"
    t.index ["PersonalID"], name: "hmiscsv2022enrollmentcocs_Uzo4"
    t.index ["PersonalID"], name: "hmiscsv2022enrollmentcocs_cezi"
    t.index ["loader_id"], name: "index_hmis_csv_2022_enrollment_cocs_on_loader_id"
  end

  create_table "hmis_csv_2022_enrollments", force: :cascade do |t|
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
    t.string "ReferralSource"
    t.string "CountOutreachReferralApproaches"
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
    t.string "MentalHealthDisorderFam"
    t.string "PhysicalDisabilityFam"
    t.string "AlcoholDrugUseDisorderFam"
    t.string "InsufficientIncome"
    t.string "IncarceratedParent"
    t.string "VAMCStation"
    t.string "TargetScreenReqd"
    t.string "TimeToHousingLoss"
    t.string "AnnualPercentAMI"
    t.string "LiteralHomelessHistory"
    t.string "ClientLeaseholder"
    t.string "HOHLeaseholder"
    t.string "SubsidyAtRisk"
    t.string "EvictionHistory"
    t.string "CriminalRecord"
    t.string "IncarceratedAdult"
    t.string "PrisonDischarge"
    t.string "SexOffender"
    t.string "DisabledHoH"
    t.string "CurrentPregnant"
    t.string "SingleParent"
    t.string "DependentUnder6"
    t.string "HH5Plus"
    t.string "CoCPrioritized"
    t.string "HPScreeningScore"
    t.string "ThresholdScore"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmiscsv2022enrollments_N5Wd"
    t.index ["DateCreated"], name: "hmiscsv2022enrollments_SIaS"
    t.index ["DateCreated"], name: "hmiscsv2022enrollments_rufY"
    t.index ["DateCreated"], name: "hmiscsv2022enrollments_upFd"
    t.index ["DateCreated"], name: "hmiscsv2022enrollments_xYjO"
    t.index ["DateDeleted"], name: "hmiscsv2022enrollments_LOT5"
    t.index ["DateDeleted"], name: "hmiscsv2022enrollments_jJjY"
    t.index ["DateDeleted"], name: "hmiscsv2022enrollments_lCDv"
    t.index ["DateDeleted"], name: "hmiscsv2022enrollments_nhXb"
    t.index ["DateDeleted"], name: "hmiscsv2022enrollments_py9x"
    t.index ["DateUpdated"], name: "hmiscsv2022enrollments_G6mN"
    t.index ["DateUpdated"], name: "hmiscsv2022enrollments_Jfc4"
    t.index ["DateUpdated"], name: "hmiscsv2022enrollments_TUkM"
    t.index ["DateUpdated"], name: "hmiscsv2022enrollments_cCys"
    t.index ["DateUpdated"], name: "hmiscsv2022enrollments_jiTz"
    t.index ["EnrollmentID", "PersonalID"], name: "hmiscsv2022enrollments_LVhZ"
    t.index ["EnrollmentID", "PersonalID"], name: "hmiscsv2022enrollments_QJf5"
    t.index ["EnrollmentID", "PersonalID"], name: "hmiscsv2022enrollments_kfHu"
    t.index ["EnrollmentID", "PersonalID"], name: "hmiscsv2022enrollments_qhAg"
    t.index ["EnrollmentID", "PersonalID"], name: "hmiscsv2022enrollments_wCi5"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmiscsv2022enrollments_HAgm"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmiscsv2022enrollments_NGvh"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmiscsv2022enrollments_PKib"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmiscsv2022enrollments_dc9H"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmiscsv2022enrollments_xkHU"
    t.index ["EnrollmentID", "data_source_id"], name: "hmis_csv_2022_enrollments-0a46"
    t.index ["EnrollmentID"], name: "hmiscsv2022enrollments_G41a"
    t.index ["EnrollmentID"], name: "hmiscsv2022enrollments_Lr7G"
    t.index ["EnrollmentID"], name: "hmiscsv2022enrollments_QE4p"
    t.index ["EnrollmentID"], name: "hmiscsv2022enrollments_QqES"
    t.index ["EnrollmentID"], name: "hmiscsv2022enrollments_iWHQ"
    t.index ["EntryDate"], name: "hmiscsv2022enrollments_2Uh6"
    t.index ["EntryDate"], name: "hmiscsv2022enrollments_INhf"
    t.index ["EntryDate"], name: "hmiscsv2022enrollments_Knt6"
    t.index ["EntryDate"], name: "hmiscsv2022enrollments_hdwb"
    t.index ["EntryDate"], name: "hmiscsv2022enrollments_kdcK"
    t.index ["ExportID"], name: "hmiscsv2022enrollments_02Gq"
    t.index ["ExportID"], name: "hmiscsv2022enrollments_1O7e"
    t.index ["ExportID"], name: "hmiscsv2022enrollments_5Od1"
    t.index ["ExportID"], name: "hmiscsv2022enrollments_6RGw"
    t.index ["ExportID"], name: "hmiscsv2022enrollments_rmZr"
    t.index ["HouseholdID"], name: "hmiscsv2022enrollments_000u"
    t.index ["HouseholdID"], name: "hmiscsv2022enrollments_COSj"
    t.index ["HouseholdID"], name: "hmiscsv2022enrollments_Vf7B"
    t.index ["HouseholdID"], name: "hmiscsv2022enrollments_YiGw"
    t.index ["HouseholdID"], name: "hmiscsv2022enrollments_pksT"
    t.index ["LivingSituation"], name: "hmiscsv2022enrollments_DEbx"
    t.index ["LivingSituation"], name: "hmiscsv2022enrollments_Kbfs"
    t.index ["LivingSituation"], name: "hmiscsv2022enrollments_OvVn"
    t.index ["LivingSituation"], name: "hmiscsv2022enrollments_S95a"
    t.index ["LivingSituation"], name: "hmiscsv2022enrollments_gn6K"
    t.index ["PersonalID"], name: "hmiscsv2022enrollments_9KtN"
    t.index ["PersonalID"], name: "hmiscsv2022enrollments_YwGX"
    t.index ["PersonalID"], name: "hmiscsv2022enrollments_ZJOW"
    t.index ["PersonalID"], name: "hmiscsv2022enrollments_b4C4"
    t.index ["PersonalID"], name: "hmiscsv2022enrollments_bItG"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmiscsv2022enrollments_0x3v"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmiscsv2022enrollments_3085"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmiscsv2022enrollments_dJ9X"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmiscsv2022enrollments_fYTX"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmiscsv2022enrollments_pYk7"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmiscsv2022enrollments_xwum"
    t.index ["ProjectID", "HouseholdID"], name: "hmiscsv2022enrollments_0HUb"
    t.index ["ProjectID", "HouseholdID"], name: "hmiscsv2022enrollments_eMPH"
    t.index ["ProjectID", "HouseholdID"], name: "hmiscsv2022enrollments_goII"
    t.index ["ProjectID", "HouseholdID"], name: "hmiscsv2022enrollments_hYxd"
    t.index ["ProjectID", "HouseholdID"], name: "hmiscsv2022enrollments_rgZ9"
    t.index ["ProjectID", "RelationshipToHoH"], name: "hmiscsv2022enrollments_2W2h"
    t.index ["ProjectID", "RelationshipToHoH"], name: "hmiscsv2022enrollments_6xDx"
    t.index ["ProjectID", "RelationshipToHoH"], name: "hmiscsv2022enrollments_fkcM"
    t.index ["ProjectID", "RelationshipToHoH"], name: "hmiscsv2022enrollments_z9WI"
    t.index ["ProjectID", "RelationshipToHoH"], name: "hmiscsv2022enrollments_zumz"
    t.index ["ProjectID"], name: "hmiscsv2022enrollments_WODv"
    t.index ["ProjectID"], name: "hmiscsv2022enrollments_XcDq"
    t.index ["ProjectID"], name: "hmiscsv2022enrollments_oOOv"
    t.index ["ProjectID"], name: "hmiscsv2022enrollments_sD3N"
    t.index ["ProjectID"], name: "hmiscsv2022enrollments_yiWK"
    t.index ["RelationshipToHoH"], name: "hmiscsv2022enrollments_0CSP"
    t.index ["RelationshipToHoH"], name: "hmiscsv2022enrollments_1jXQ"
    t.index ["RelationshipToHoH"], name: "hmiscsv2022enrollments_PZWA"
    t.index ["RelationshipToHoH"], name: "hmiscsv2022enrollments_YQva"
    t.index ["RelationshipToHoH"], name: "hmiscsv2022enrollments_oC1q"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears"], name: "hmiscsv2022enrollments_04uI"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears"], name: "hmiscsv2022enrollments_2KUN"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears"], name: "hmiscsv2022enrollments_Xlha"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears"], name: "hmiscsv2022enrollments_mGyY"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears"], name: "hmiscsv2022enrollments_vfUq"
    t.index ["loader_id"], name: "index_hmis_csv_2022_enrollments_on_loader_id"
  end

  create_table "hmis_csv_2022_events", force: :cascade do |t|
    t.string "EventID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "EventDate"
    t.string "Event"
    t.string "ProbSolDivRRResult"
    t.string "ReferralCaseManageAfter"
    t.string "LocationCrisisOrPHHousing"
    t.string "ReferralResult"
    t.string "ResultDate"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["EnrollmentID"], name: "hmiscsv2022events_RRPj"
    t.index ["EnrollmentID"], name: "hmiscsv2022events_gFxo"
    t.index ["EnrollmentID"], name: "hmiscsv2022events_jBzv"
    t.index ["EnrollmentID"], name: "hmiscsv2022events_wPoI"
    t.index ["EnrollmentID"], name: "hmiscsv2022events_yhpj"
    t.index ["EventDate"], name: "hmiscsv2022events_6eMI"
    t.index ["EventDate"], name: "hmiscsv2022events_9r3x"
    t.index ["EventDate"], name: "hmiscsv2022events_AFoC"
    t.index ["EventDate"], name: "hmiscsv2022events_RGSg"
    t.index ["EventDate"], name: "hmiscsv2022events_k3Vz"
    t.index ["EventID"], name: "hmiscsv2022events_9PUb"
    t.index ["EventID"], name: "hmiscsv2022events_9rNL"
    t.index ["EventID"], name: "hmiscsv2022events_EF2x"
    t.index ["EventID"], name: "hmiscsv2022events_TrwM"
    t.index ["EventID"], name: "hmiscsv2022events_f8eV"
    t.index ["ExportID"], name: "hmiscsv2022events_HWMU"
    t.index ["ExportID"], name: "hmiscsv2022events_MpdL"
    t.index ["ExportID"], name: "hmiscsv2022events_UMEc"
    t.index ["ExportID"], name: "hmiscsv2022events_b0HY"
    t.index ["ExportID"], name: "hmiscsv2022events_wiJI"
    t.index ["PersonalID"], name: "hmiscsv2022events_70cK"
    t.index ["PersonalID"], name: "hmiscsv2022events_A0Re"
    t.index ["PersonalID"], name: "hmiscsv2022events_PVi4"
    t.index ["PersonalID"], name: "hmiscsv2022events_SEgq"
    t.index ["PersonalID"], name: "hmiscsv2022events_fVxv"
    t.index ["loader_id"], name: "index_hmis_csv_2022_events_on_loader_id"
  end

  create_table "hmis_csv_2022_exits", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmiscsv2022exits_7kNM"
    t.index ["DateCreated"], name: "hmiscsv2022exits_Sweu"
    t.index ["DateCreated"], name: "hmiscsv2022exits_YPuW"
    t.index ["DateCreated"], name: "hmiscsv2022exits_t4xs"
    t.index ["DateCreated"], name: "hmiscsv2022exits_xila"
    t.index ["DateDeleted"], name: "hmiscsv2022exits_H1wM"
    t.index ["DateDeleted"], name: "hmiscsv2022exits_jid6"
    t.index ["DateDeleted"], name: "hmiscsv2022exits_pVQh"
    t.index ["DateDeleted"], name: "hmiscsv2022exits_sUuv"
    t.index ["DateDeleted"], name: "hmiscsv2022exits_xm89"
    t.index ["DateUpdated"], name: "hmiscsv2022exits_0oqJ"
    t.index ["DateUpdated"], name: "hmiscsv2022exits_QIyW"
    t.index ["DateUpdated"], name: "hmiscsv2022exits_V4hG"
    t.index ["DateUpdated"], name: "hmiscsv2022exits_lR9a"
    t.index ["DateUpdated"], name: "hmiscsv2022exits_s2TS"
    t.index ["EnrollmentID"], name: "hmiscsv2022exits_GVqN"
    t.index ["EnrollmentID"], name: "hmiscsv2022exits_UpXI"
    t.index ["EnrollmentID"], name: "hmiscsv2022exits_sL74"
    t.index ["EnrollmentID"], name: "hmiscsv2022exits_vZPo"
    t.index ["EnrollmentID"], name: "hmiscsv2022exits_vtCz"
    t.index ["ExitDate"], name: "hmiscsv2022exits_3hM6"
    t.index ["ExitDate"], name: "hmiscsv2022exits_JFIj"
    t.index ["ExitDate"], name: "hmiscsv2022exits_QQgW"
    t.index ["ExitDate"], name: "hmiscsv2022exits_w7ex"
    t.index ["ExitDate"], name: "hmiscsv2022exits_yCw0"
    t.index ["ExitID", "data_source_id"], name: "hmis_csv_2022_exits-cfdd"
    t.index ["ExitID"], name: "hmiscsv2022exits_AJQd"
    t.index ["ExitID"], name: "hmiscsv2022exits_CFOy"
    t.index ["ExitID"], name: "hmiscsv2022exits_FaOP"
    t.index ["ExitID"], name: "hmiscsv2022exits_ZLAK"
    t.index ["ExitID"], name: "hmiscsv2022exits_nNms"
    t.index ["ExportID"], name: "hmiscsv2022exits_6mEQ"
    t.index ["ExportID"], name: "hmiscsv2022exits_7XJm"
    t.index ["ExportID"], name: "hmiscsv2022exits_97kE"
    t.index ["ExportID"], name: "hmiscsv2022exits_9wKe"
    t.index ["ExportID"], name: "hmiscsv2022exits_nix9"
    t.index ["PersonalID"], name: "hmiscsv2022exits_2IJt"
    t.index ["PersonalID"], name: "hmiscsv2022exits_BugK"
    t.index ["PersonalID"], name: "hmiscsv2022exits_HEXL"
    t.index ["PersonalID"], name: "hmiscsv2022exits_b9Iz"
    t.index ["PersonalID"], name: "hmiscsv2022exits_othX"
    t.index ["loader_id"], name: "index_hmis_csv_2022_exits_on_loader_id"
  end

  create_table "hmis_csv_2022_exports", force: :cascade do |t|
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
    t.string "CSVVersion"
    t.string "ExportPeriodType"
    t.string "ExportDirective"
    t.string "HashStatus"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmiscsv2022exports_4A4m"
    t.index ["ExportID"], name: "hmiscsv2022exports_786V"
    t.index ["ExportID"], name: "hmiscsv2022exports_7cpb"
    t.index ["ExportID"], name: "hmiscsv2022exports_Gf6i"
    t.index ["ExportID"], name: "hmiscsv2022exports_qkPK"
    t.index ["loader_id"], name: "index_hmis_csv_2022_exports_on_loader_id"
  end

  create_table "hmis_csv_2022_funders", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmiscsv2022funders_FasV"
    t.index ["DateCreated"], name: "hmiscsv2022funders_KCdj"
    t.index ["DateCreated"], name: "hmiscsv2022funders_Zyir"
    t.index ["DateCreated"], name: "hmiscsv2022funders_wAAz"
    t.index ["DateCreated"], name: "hmiscsv2022funders_zZPu"
    t.index ["DateUpdated"], name: "hmiscsv2022funders_EBQd"
    t.index ["DateUpdated"], name: "hmiscsv2022funders_EeF8"
    t.index ["DateUpdated"], name: "hmiscsv2022funders_I59Y"
    t.index ["DateUpdated"], name: "hmiscsv2022funders_aEqh"
    t.index ["DateUpdated"], name: "hmiscsv2022funders_trtP"
    t.index ["ExportID"], name: "hmiscsv2022funders_U23e"
    t.index ["ExportID"], name: "hmiscsv2022funders_W9nA"
    t.index ["ExportID"], name: "hmiscsv2022funders_acMZ"
    t.index ["ExportID"], name: "hmiscsv2022funders_gFjD"
    t.index ["ExportID"], name: "hmiscsv2022funders_y0jT"
    t.index ["FunderID", "data_source_id"], name: "hmis_csv_2022_funders-4ad5"
    t.index ["FunderID"], name: "hmiscsv2022funders_Q8i7"
    t.index ["FunderID"], name: "hmiscsv2022funders_hsxT"
    t.index ["FunderID"], name: "hmiscsv2022funders_vp8u"
    t.index ["FunderID"], name: "hmiscsv2022funders_wkTK"
    t.index ["FunderID"], name: "hmiscsv2022funders_yNBZ"
    t.index ["loader_id"], name: "index_hmis_csv_2022_funders_on_loader_id"
  end

  create_table "hmis_csv_2022_health_and_dvs", force: :cascade do |t|
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
    t.string "LifeValue"
    t.string "SupportFromOthers"
    t.string "BounceBack"
    t.string "FeelingFrequency"
    t.string "DataCollectionStage"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmiscsv2022healthanddvs_3s5V"
    t.index ["DateCreated"], name: "hmiscsv2022healthanddvs_HnGC"
    t.index ["DateCreated"], name: "hmiscsv2022healthanddvs_I9SQ"
    t.index ["DateCreated"], name: "hmiscsv2022healthanddvs_r4Lx"
    t.index ["DateCreated"], name: "hmiscsv2022healthanddvs_zf1v"
    t.index ["DateUpdated"], name: "hmiscsv2022healthanddvs_BRTj"
    t.index ["DateUpdated"], name: "hmiscsv2022healthanddvs_JFxv"
    t.index ["DateUpdated"], name: "hmiscsv2022healthanddvs_Vsks"
    t.index ["DateUpdated"], name: "hmiscsv2022healthanddvs_pyNn"
    t.index ["DateUpdated"], name: "hmiscsv2022healthanddvs_xsrk"
    t.index ["EnrollmentID"], name: "hmiscsv2022healthanddvs_DBWO"
    t.index ["EnrollmentID"], name: "hmiscsv2022healthanddvs_elHq"
    t.index ["EnrollmentID"], name: "hmiscsv2022healthanddvs_h8HB"
    t.index ["EnrollmentID"], name: "hmiscsv2022healthanddvs_i9dN"
    t.index ["EnrollmentID"], name: "hmiscsv2022healthanddvs_q5XV"
    t.index ["ExportID"], name: "hmiscsv2022healthanddvs_CRfc"
    t.index ["ExportID"], name: "hmiscsv2022healthanddvs_TMQt"
    t.index ["ExportID"], name: "hmiscsv2022healthanddvs_Xory"
    t.index ["ExportID"], name: "hmiscsv2022healthanddvs_lP0u"
    t.index ["ExportID"], name: "hmiscsv2022healthanddvs_sdZG"
    t.index ["HealthAndDVID", "data_source_id"], name: "hmis_csv_2022_health_and_dvs-e384"
    t.index ["HealthAndDVID"], name: "hmiscsv2022healthanddvs_8V6w"
    t.index ["HealthAndDVID"], name: "hmiscsv2022healthanddvs_Y01x"
    t.index ["HealthAndDVID"], name: "hmiscsv2022healthanddvs_fkYA"
    t.index ["HealthAndDVID"], name: "hmiscsv2022healthanddvs_lDba"
    t.index ["HealthAndDVID"], name: "hmiscsv2022healthanddvs_nNgi"
    t.index ["PersonalID"], name: "hmiscsv2022healthanddvs_9xZf"
    t.index ["PersonalID"], name: "hmiscsv2022healthanddvs_PVQH"
    t.index ["PersonalID"], name: "hmiscsv2022healthanddvs_n8lZ"
    t.index ["PersonalID"], name: "hmiscsv2022healthanddvs_qUR2"
    t.index ["PersonalID"], name: "hmiscsv2022healthanddvs_yG7j"
    t.index ["loader_id"], name: "index_hmis_csv_2022_health_and_dvs_on_loader_id"
  end

  create_table "hmis_csv_2022_income_benefits", force: :cascade do |t|
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
    t.string "RyanWhiteMedDent"
    t.string "NoRyanWhiteReason"
    t.string "ConnectionWithSOAR"
    t.string "DataCollectionStage"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmiscsv2022incomebenefits_FnDI"
    t.index ["DateCreated"], name: "hmiscsv2022incomebenefits_OVW3"
    t.index ["DateCreated"], name: "hmiscsv2022incomebenefits_mM7W"
    t.index ["DateCreated"], name: "hmiscsv2022incomebenefits_nLIb"
    t.index ["DateCreated"], name: "hmiscsv2022incomebenefits_w5M0"
    t.index ["DateUpdated"], name: "hmiscsv2022incomebenefits_6g8h"
    t.index ["DateUpdated"], name: "hmiscsv2022incomebenefits_BPxA"
    t.index ["DateUpdated"], name: "hmiscsv2022incomebenefits_F7Yo"
    t.index ["DateUpdated"], name: "hmiscsv2022incomebenefits_Yjz6"
    t.index ["DateUpdated"], name: "hmiscsv2022incomebenefits_cE9a"
    t.index ["Earned", "DataCollectionStage"], name: "hmiscsv2022incomebenefits_16c2"
    t.index ["Earned", "DataCollectionStage"], name: "hmiscsv2022incomebenefits_7IcJ"
    t.index ["Earned", "DataCollectionStage"], name: "hmiscsv2022incomebenefits_EY8v"
    t.index ["Earned", "DataCollectionStage"], name: "hmiscsv2022incomebenefits_QURQ"
    t.index ["Earned", "DataCollectionStage"], name: "hmiscsv2022incomebenefits_SyN5"
    t.index ["Earned", "DataCollectionStage"], name: "hmiscsv2022incomebenefits_jnNE"
    t.index ["EnrollmentID"], name: "hmiscsv2022incomebenefits_EJv6"
    t.index ["EnrollmentID"], name: "hmiscsv2022incomebenefits_EOkg"
    t.index ["EnrollmentID"], name: "hmiscsv2022incomebenefits_Gcc7"
    t.index ["EnrollmentID"], name: "hmiscsv2022incomebenefits_HQxa"
    t.index ["EnrollmentID"], name: "hmiscsv2022incomebenefits_rV97"
    t.index ["ExportID"], name: "hmiscsv2022incomebenefits_1XAs"
    t.index ["ExportID"], name: "hmiscsv2022incomebenefits_6HiZ"
    t.index ["ExportID"], name: "hmiscsv2022incomebenefits_KDpF"
    t.index ["ExportID"], name: "hmiscsv2022incomebenefits_VKKY"
    t.index ["ExportID"], name: "hmiscsv2022incomebenefits_ZRt9"
    t.index ["IncomeBenefitsID"], name: "hmiscsv2022incomebenefits_Fget"
    t.index ["IncomeBenefitsID"], name: "hmiscsv2022incomebenefits_Myd9"
    t.index ["IncomeBenefitsID"], name: "hmiscsv2022incomebenefits_W8mA"
    t.index ["IncomeBenefitsID"], name: "hmiscsv2022incomebenefits_ZW68"
    t.index ["IncomeBenefitsID"], name: "hmiscsv2022incomebenefits_pgB6"
    t.index ["IncomeFromAnySource", "DataCollectionStage"], name: "hmiscsv2022incomebenefits_1RQb"
    t.index ["IncomeFromAnySource", "DataCollectionStage"], name: "hmiscsv2022incomebenefits_Aw1x"
    t.index ["IncomeFromAnySource", "DataCollectionStage"], name: "hmiscsv2022incomebenefits_WpiB"
    t.index ["IncomeFromAnySource", "DataCollectionStage"], name: "hmiscsv2022incomebenefits_ae8d"
    t.index ["IncomeFromAnySource", "DataCollectionStage"], name: "hmiscsv2022incomebenefits_irza"
    t.index ["IncomeFromAnySource", "DataCollectionStage"], name: "hmiscsv2022incomebenefits_t2OW"
    t.index ["InformationDate"], name: "hmiscsv2022incomebenefits_1tdi"
    t.index ["InformationDate"], name: "hmiscsv2022incomebenefits_7obR"
    t.index ["InformationDate"], name: "hmiscsv2022incomebenefits_Hzxy"
    t.index ["InformationDate"], name: "hmiscsv2022incomebenefits_RlAP"
    t.index ["InformationDate"], name: "hmiscsv2022incomebenefits_z5mn"
    t.index ["PersonalID"], name: "hmiscsv2022incomebenefits_2tUP"
    t.index ["PersonalID"], name: "hmiscsv2022incomebenefits_GD5Y"
    t.index ["PersonalID"], name: "hmiscsv2022incomebenefits_GRRK"
    t.index ["PersonalID"], name: "hmiscsv2022incomebenefits_HeoF"
    t.index ["PersonalID"], name: "hmiscsv2022incomebenefits_vuok"
    t.index ["loader_id"], name: "index_hmis_csv_2022_income_benefits_on_loader_id"
  end

  create_table "hmis_csv_2022_inventories", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmiscsv2022inventories_HoVQ"
    t.index ["DateCreated"], name: "hmiscsv2022inventories_h8H6"
    t.index ["DateCreated"], name: "hmiscsv2022inventories_hcBa"
    t.index ["DateCreated"], name: "hmiscsv2022inventories_hpp8"
    t.index ["DateCreated"], name: "hmiscsv2022inventories_yEox"
    t.index ["DateUpdated"], name: "hmiscsv2022inventories_2JYH"
    t.index ["DateUpdated"], name: "hmiscsv2022inventories_O4mI"
    t.index ["DateUpdated"], name: "hmiscsv2022inventories_TTYE"
    t.index ["DateUpdated"], name: "hmiscsv2022inventories_vHpP"
    t.index ["DateUpdated"], name: "hmiscsv2022inventories_yqNs"
    t.index ["ExportID"], name: "hmiscsv2022inventories_5blG"
    t.index ["ExportID"], name: "hmiscsv2022inventories_7XPQ"
    t.index ["ExportID"], name: "hmiscsv2022inventories_Mam6"
    t.index ["ExportID"], name: "hmiscsv2022inventories_UVsK"
    t.index ["ExportID"], name: "hmiscsv2022inventories_Xkhg"
    t.index ["InventoryID", "data_source_id"], name: "hmis_csv_2022_inventories-86c0"
    t.index ["InventoryID"], name: "hmiscsv2022inventories_0hc8"
    t.index ["InventoryID"], name: "hmiscsv2022inventories_9529"
    t.index ["InventoryID"], name: "hmiscsv2022inventories_FcjB"
    t.index ["InventoryID"], name: "hmiscsv2022inventories_f8rb"
    t.index ["InventoryID"], name: "hmiscsv2022inventories_hu1F"
    t.index ["InventoryID"], name: "hmiscsv2022inventories_pqsZ"
    t.index ["ProjectID", "CoCCode"], name: "hmiscsv2022inventories_MaX0"
    t.index ["ProjectID", "CoCCode"], name: "hmiscsv2022inventories_bqiF"
    t.index ["ProjectID", "CoCCode"], name: "hmiscsv2022inventories_ctyg"
    t.index ["ProjectID", "CoCCode"], name: "hmiscsv2022inventories_nYsR"
    t.index ["ProjectID", "CoCCode"], name: "hmiscsv2022inventories_wNmp"
    t.index ["loader_id"], name: "index_hmis_csv_2022_inventories_on_loader_id"
  end

  create_table "hmis_csv_2022_organizations", force: :cascade do |t|
    t.string "OrganizationID"
    t.string "OrganizationName"
    t.string "VictimServiceProvider"
    t.string "OrganizationCommonName"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmiscsv2022organizations_FjV6"
    t.index ["ExportID"], name: "hmiscsv2022organizations_PW7F"
    t.index ["ExportID"], name: "hmiscsv2022organizations_Q2CY"
    t.index ["ExportID"], name: "hmiscsv2022organizations_SBB6"
    t.index ["ExportID"], name: "hmiscsv2022organizations_uD5T"
    t.index ["OrganizationID", "data_source_id"], name: "hmis_csv_2022_organizations-7580"
    t.index ["OrganizationID"], name: "hmiscsv2022organizations_LnYR"
    t.index ["OrganizationID"], name: "hmiscsv2022organizations_P9WD"
    t.index ["OrganizationID"], name: "hmiscsv2022organizations_eKN2"
    t.index ["OrganizationID"], name: "hmiscsv2022organizations_gmSL"
    t.index ["OrganizationID"], name: "hmiscsv2022organizations_qR0a"
    t.index ["loader_id"], name: "index_hmis_csv_2022_organizations_on_loader_id"
  end

  create_table "hmis_csv_2022_project_cocs", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmiscsv2022projectcocs_0mWW"
    t.index ["DateCreated"], name: "hmiscsv2022projectcocs_Jfub"
    t.index ["DateCreated"], name: "hmiscsv2022projectcocs_QHMr"
    t.index ["DateCreated"], name: "hmiscsv2022projectcocs_hhqc"
    t.index ["DateCreated"], name: "hmiscsv2022projectcocs_uGEA"
    t.index ["DateUpdated"], name: "hmiscsv2022projectcocs_7coH"
    t.index ["DateUpdated"], name: "hmiscsv2022projectcocs_fHPb"
    t.index ["DateUpdated"], name: "hmiscsv2022projectcocs_haHj"
    t.index ["DateUpdated"], name: "hmiscsv2022projectcocs_rI43"
    t.index ["DateUpdated"], name: "hmiscsv2022projectcocs_xNgm"
    t.index ["ExportID"], name: "hmiscsv2022projectcocs_7QwC"
    t.index ["ExportID"], name: "hmiscsv2022projectcocs_F3r0"
    t.index ["ExportID"], name: "hmiscsv2022projectcocs_ZaMC"
    t.index ["ExportID"], name: "hmiscsv2022projectcocs_Zv8Z"
    t.index ["ExportID"], name: "hmiscsv2022projectcocs_snwr"
    t.index ["ProjectCoCID", "data_source_id"], name: "hmis_csv_2022_project_cocs-3966"
    t.index ["ProjectCoCID"], name: "hmiscsv2022projectcocs_KMu5"
    t.index ["ProjectCoCID"], name: "hmiscsv2022projectcocs_XKYG"
    t.index ["ProjectCoCID"], name: "hmiscsv2022projectcocs_gMun"
    t.index ["ProjectCoCID"], name: "hmiscsv2022projectcocs_jWiU"
    t.index ["ProjectCoCID"], name: "hmiscsv2022projectcocs_toVK"
    t.index ["ProjectID", "CoCCode"], name: "hmiscsv2022projectcocs_KccU"
    t.index ["ProjectID", "CoCCode"], name: "hmiscsv2022projectcocs_R2Yn"
    t.index ["ProjectID", "CoCCode"], name: "hmiscsv2022projectcocs_ZwP7"
    t.index ["ProjectID", "CoCCode"], name: "hmiscsv2022projectcocs_lfWt"
    t.index ["ProjectID", "CoCCode"], name: "hmiscsv2022projectcocs_mLOc"
    t.index ["loader_id"], name: "index_hmis_csv_2022_project_cocs_on_loader_id"
  end

  create_table "hmis_csv_2022_projects", force: :cascade do |t|
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
    t.string "HOPWAMedAssistedLivingFac"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.string "PITCount"
    t.index ["DateCreated"], name: "hmiscsv2022projects_BNpw"
    t.index ["DateCreated"], name: "hmiscsv2022projects_BcGz"
    t.index ["DateCreated"], name: "hmiscsv2022projects_CrgU"
    t.index ["DateCreated"], name: "hmiscsv2022projects_ftTe"
    t.index ["DateCreated"], name: "hmiscsv2022projects_jgtt"
    t.index ["DateUpdated"], name: "hmiscsv2022projects_CR7E"
    t.index ["DateUpdated"], name: "hmiscsv2022projects_K1g9"
    t.index ["DateUpdated"], name: "hmiscsv2022projects_fGby"
    t.index ["DateUpdated"], name: "hmiscsv2022projects_ouoy"
    t.index ["DateUpdated"], name: "hmiscsv2022projects_uN6c"
    t.index ["ExportID"], name: "hmiscsv2022projects_6pjf"
    t.index ["ExportID"], name: "hmiscsv2022projects_EHcK"
    t.index ["ExportID"], name: "hmiscsv2022projects_Oj9G"
    t.index ["ExportID"], name: "hmiscsv2022projects_qPVR"
    t.index ["ExportID"], name: "hmiscsv2022projects_yGw1"
    t.index ["ProjectID", "data_source_id"], name: "hmis_csv_2022_projects-92c5"
    t.index ["ProjectID"], name: "hmiscsv2022projects_AZRv"
    t.index ["ProjectID"], name: "hmiscsv2022projects_FH4m"
    t.index ["ProjectID"], name: "hmiscsv2022projects_LGTq"
    t.index ["ProjectID"], name: "hmiscsv2022projects_OtF6"
    t.index ["ProjectID"], name: "hmiscsv2022projects_oatJ"
    t.index ["ProjectType"], name: "hmiscsv2022projects_EFMI"
    t.index ["ProjectType"], name: "hmiscsv2022projects_K1UM"
    t.index ["ProjectType"], name: "hmiscsv2022projects_Oc0U"
    t.index ["ProjectType"], name: "hmiscsv2022projects_QkSr"
    t.index ["ProjectType"], name: "hmiscsv2022projects_VzMf"
    t.index ["loader_id"], name: "index_hmis_csv_2022_projects_on_loader_id"
  end

  create_table "hmis_csv_2022_services", force: :cascade do |t|
    t.string "ServicesID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "DateProvided"
    t.string "RecordType"
    t.string "TypeProvided"
    t.string "OtherTypeProvided"
    t.string "MovingOnOtherType"
    t.string "SubTypeProvided"
    t.string "FAAmount"
    t.string "ReferralOutcome"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateCreated"], name: "hmiscsv2022services_Bo1g"
    t.index ["DateCreated"], name: "hmiscsv2022services_LD3i"
    t.index ["DateCreated"], name: "hmiscsv2022services_cOsh"
    t.index ["DateCreated"], name: "hmiscsv2022services_f8LM"
    t.index ["DateCreated"], name: "hmiscsv2022services_ytLZ"
    t.index ["DateDeleted"], name: "hmiscsv2022services_1kzC"
    t.index ["DateDeleted"], name: "hmiscsv2022services_G0rQ"
    t.index ["DateDeleted"], name: "hmiscsv2022services_Lk4w"
    t.index ["DateDeleted"], name: "hmiscsv2022services_WkLH"
    t.index ["DateDeleted"], name: "hmiscsv2022services_Xjc3"
    t.index ["DateProvided"], name: "hmiscsv2022services_BZI2"
    t.index ["DateProvided"], name: "hmiscsv2022services_EtU3"
    t.index ["DateProvided"], name: "hmiscsv2022services_WxH1"
    t.index ["DateProvided"], name: "hmiscsv2022services_enQH"
    t.index ["DateProvided"], name: "hmiscsv2022services_lCd2"
    t.index ["DateUpdated"], name: "hmiscsv2022services_Ke4l"
    t.index ["DateUpdated"], name: "hmiscsv2022services_NI7r"
    t.index ["DateUpdated"], name: "hmiscsv2022services_U2RZ"
    t.index ["DateUpdated"], name: "hmiscsv2022services_Xt15"
    t.index ["DateUpdated"], name: "hmiscsv2022services_f0qq"
    t.index ["EnrollmentID", "PersonalID"], name: "hmiscsv2022services_78KE"
    t.index ["EnrollmentID", "PersonalID"], name: "hmiscsv2022services_QQPx"
    t.index ["EnrollmentID", "PersonalID"], name: "hmiscsv2022services_kUi3"
    t.index ["EnrollmentID", "PersonalID"], name: "hmiscsv2022services_thj9"
    t.index ["EnrollmentID", "PersonalID"], name: "hmiscsv2022services_ut9w"
    t.index ["EnrollmentID", "RecordType", "DateDeleted", "DateProvided"], name: "hmiscsv2022services_68n9"
    t.index ["EnrollmentID", "RecordType", "DateDeleted", "DateProvided"], name: "hmiscsv2022services_AMYt"
    t.index ["EnrollmentID", "RecordType", "DateDeleted", "DateProvided"], name: "hmiscsv2022services_E4Js"
    t.index ["EnrollmentID", "RecordType", "DateDeleted", "DateProvided"], name: "hmiscsv2022services_PZaU"
    t.index ["EnrollmentID", "RecordType", "DateDeleted", "DateProvided"], name: "hmiscsv2022services_dQSt"
    t.index ["EnrollmentID"], name: "hmiscsv2022services_3wwH"
    t.index ["EnrollmentID"], name: "hmiscsv2022services_LJSD"
    t.index ["EnrollmentID"], name: "hmiscsv2022services_Owsi"
    t.index ["EnrollmentID"], name: "hmiscsv2022services_n0Bz"
    t.index ["EnrollmentID"], name: "hmiscsv2022services_qYm3"
    t.index ["ExportID"], name: "hmiscsv2022services_4qG7"
    t.index ["ExportID"], name: "hmiscsv2022services_JOKs"
    t.index ["ExportID"], name: "hmiscsv2022services_ZsCG"
    t.index ["ExportID"], name: "hmiscsv2022services_s7W3"
    t.index ["ExportID"], name: "hmiscsv2022services_x0QA"
    t.index ["PersonalID", "RecordType", "EnrollmentID", "DateProvided"], name: "hmiscsv2022services_9Ain"
    t.index ["PersonalID", "RecordType", "EnrollmentID", "DateProvided"], name: "hmiscsv2022services_BbIE"
    t.index ["PersonalID", "RecordType", "EnrollmentID", "DateProvided"], name: "hmiscsv2022services_D39O"
    t.index ["PersonalID", "RecordType", "EnrollmentID", "DateProvided"], name: "hmiscsv2022services_MBfF"
    t.index ["PersonalID", "RecordType", "EnrollmentID", "DateProvided"], name: "hmiscsv2022services_cK9O"
    t.index ["PersonalID"], name: "hmiscsv2022services_AGvJ"
    t.index ["PersonalID"], name: "hmiscsv2022services_aK50"
    t.index ["PersonalID"], name: "hmiscsv2022services_mSwA"
    t.index ["PersonalID"], name: "hmiscsv2022services_t2qL"
    t.index ["PersonalID"], name: "hmiscsv2022services_wl51"
    t.index ["RecordType", "DateDeleted"], name: "hmiscsv2022services_OCo1"
    t.index ["RecordType", "DateDeleted"], name: "hmiscsv2022services_gUHS"
    t.index ["RecordType", "DateDeleted"], name: "hmiscsv2022services_ipWR"
    t.index ["RecordType", "DateDeleted"], name: "hmiscsv2022services_lbEG"
    t.index ["RecordType", "DateDeleted"], name: "hmiscsv2022services_mIWt"
    t.index ["RecordType", "DateProvided"], name: "hmiscsv2022services_3gBa"
    t.index ["RecordType", "DateProvided"], name: "hmiscsv2022services_732S"
    t.index ["RecordType", "DateProvided"], name: "hmiscsv2022services_K7Zt"
    t.index ["RecordType", "DateProvided"], name: "hmiscsv2022services_fGnF"
    t.index ["RecordType", "DateProvided"], name: "hmiscsv2022services_x32D"
    t.index ["RecordType"], name: "hmiscsv2022services_FnGv"
    t.index ["RecordType"], name: "hmiscsv2022services_HfxJ"
    t.index ["RecordType"], name: "hmiscsv2022services_RLdg"
    t.index ["RecordType"], name: "hmiscsv2022services_Zeox"
    t.index ["RecordType"], name: "hmiscsv2022services_tUIX"
    t.index ["ServicesID", "data_source_id"], name: "hmis_csv_2022_services-7a57"
    t.index ["ServicesID"], name: "hmiscsv2022services_53sL"
    t.index ["ServicesID"], name: "hmiscsv2022services_IyZM"
    t.index ["ServicesID"], name: "hmiscsv2022services_JiC3"
    t.index ["ServicesID"], name: "hmiscsv2022services_iILP"
    t.index ["ServicesID"], name: "hmiscsv2022services_zkJ3"
    t.index ["loader_id"], name: "index_hmis_csv_2022_services_on_loader_id"
  end

  create_table "hmis_csv_2022_users", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmiscsv2022users_9lCp"
    t.index ["ExportID"], name: "hmiscsv2022users_MWOa"
    t.index ["ExportID"], name: "hmiscsv2022users_ZsWm"
    t.index ["ExportID"], name: "hmiscsv2022users_ut6h"
    t.index ["ExportID"], name: "hmiscsv2022users_wBZo"
    t.index ["UserID"], name: "hmiscsv2022users_57c7"
    t.index ["UserID"], name: "hmiscsv2022users_7hAX"
    t.index ["UserID"], name: "hmiscsv2022users_8RTX"
    t.index ["UserID"], name: "hmiscsv2022users_FSU8"
    t.index ["UserID"], name: "hmiscsv2022users_T7HY"
    t.index ["UserID"], name: "hmiscsv2022users_xDzZ"
    t.index ["loader_id"], name: "index_hmis_csv_2022_users_on_loader_id"
  end

  create_table "hmis_csv_2022_youth_education_statuses", force: :cascade do |t|
    t.string "YouthEducationStatusID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "InformationDate"
    t.string "CurrentSchoolAttend"
    t.string "MostRecentEdStatus"
    t.string "CurrentEdStatus"
    t.string "DataCollectionStage"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["EnrollmentID"], name: "hmiscsv2022youtheducationstatuses_9dk3"
    t.index ["EnrollmentID"], name: "hmiscsv2022youtheducationstatuses_WARO"
    t.index ["EnrollmentID"], name: "hmiscsv2022youtheducationstatuses_hkeS"
    t.index ["EnrollmentID"], name: "hmiscsv2022youtheducationstatuses_nb9y"
    t.index ["EnrollmentID"], name: "hmiscsv2022youtheducationstatuses_uegS"
    t.index ["ExportID"], name: "hmiscsv2022youtheducationstatuses_22GP"
    t.index ["ExportID"], name: "hmiscsv2022youtheducationstatuses_9UF7"
    t.index ["ExportID"], name: "hmiscsv2022youtheducationstatuses_LsJX"
    t.index ["ExportID"], name: "hmiscsv2022youtheducationstatuses_O5XN"
    t.index ["ExportID"], name: "hmiscsv2022youtheducationstatuses_vPI4"
    t.index ["InformationDate"], name: "hmiscsv2022youtheducationstatuses_27QU"
    t.index ["InformationDate"], name: "hmiscsv2022youtheducationstatuses_6Gvz"
    t.index ["InformationDate"], name: "hmiscsv2022youtheducationstatuses_PBWg"
    t.index ["InformationDate"], name: "hmiscsv2022youtheducationstatuses_PMHG"
    t.index ["InformationDate"], name: "hmiscsv2022youtheducationstatuses_u98C"
    t.index ["PersonalID"], name: "hmiscsv2022youtheducationstatuses_3wUp"
    t.index ["PersonalID"], name: "hmiscsv2022youtheducationstatuses_IQMw"
    t.index ["PersonalID"], name: "hmiscsv2022youtheducationstatuses_LLFz"
    t.index ["PersonalID"], name: "hmiscsv2022youtheducationstatuses_Msvb"
    t.index ["PersonalID"], name: "hmiscsv2022youtheducationstatuses_eWaV"
    t.index ["YouthEducationStatusID"], name: "hmiscsv2022youtheducationstatuses_P7pk"
    t.index ["YouthEducationStatusID"], name: "hmiscsv2022youtheducationstatuses_Tv5M"
    t.index ["YouthEducationStatusID"], name: "hmiscsv2022youtheducationstatuses_fsBL"
    t.index ["YouthEducationStatusID"], name: "hmiscsv2022youtheducationstatuses_g8wl"
    t.index ["YouthEducationStatusID"], name: "hmiscsv2022youtheducationstatuses_xGU1"
    t.index ["loader_id"], name: "index_hmis_csv_2022_youth_education_statuses_on_loader_id"
  end

  create_table "hmis_csv_2024_affiliations", force: :cascade do |t|
    t.string "AffiliationID"
    t.string "ProjectID"
    t.string "ResProjectID"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["AffiliationID", "data_source_id"], name: "hmis_csv_2024_affiliations-6457"
  end

  create_table "hmis_csv_2024_assessment_questions", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["AssessmentID"], name: "hmiscsv2024assessmentquestions_da04"
    t.index ["AssessmentQuestionID", "data_source_id"], name: "hmis_csv_2024_assessment_questions-0cd3"
    t.index ["ExportID"], name: "hmiscsv2024assessmentquestions_634d"
  end

  create_table "hmis_csv_2024_assessment_results", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmiscsv2024assessmentresults_634d"
  end

  create_table "hmis_csv_2024_assessments", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["AssessmentDate"], name: "hmiscsv2024assessments_4fa0"
    t.index ["AssessmentID", "data_source_id"], name: "hmis_csv_2024_assessments-df76"
    t.index ["AssessmentID"], name: "hmiscsv2024assessments_da04"
    t.index ["ExportID"], name: "hmiscsv2024assessments_634d"
  end

  create_table "hmis_csv_2024_ce_participations", force: :cascade do |t|
    t.string "CEParticipationID"
    t.string "ProjectID"
    t.string "AccessPoint"
    t.string "PreventionAssessment"
    t.string "CrisisAssessment"
    t.string "HousingAssessment"
    t.string "DirectServices"
    t.string "ReceivesReferrals"
    t.string "CEParticipationStatusStartDate"
    t.string "CEParticipationStatusEndDate"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["CEParticipationID", "data_source_id"], name: "hmis_csv_2024_ce_participations-5c6f"
    t.index ["CEParticipationID"], name: "hmiscsv2024ceparticipations_5a29"
    t.index ["ExportID"], name: "hmiscsv2024ceparticipations_634d"
    t.index ["ProjectID"], name: "hmiscsv2024ceparticipations_42af"
  end

  create_table "hmis_csv_2024_clients", force: :cascade do |t|
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
    t.string "HispanicLatinaeo"
    t.string "MidEastNAfrican"
    t.string "NativeHIPacific"
    t.string "White"
    t.string "RaceNone"
    t.string "AdditionalRaceEthnicity"
    t.string "Woman"
    t.string "Man"
    t.string "NonBinary"
    t.string "CulturallySpecific"
    t.string "Transgender"
    t.string "Questioning"
    t.string "DifferentIdentity"
    t.string "GenderNone"
    t.string "DifferentIdentityText"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmiscsv2024clients_634d"
    t.index ["PersonalID", "data_source_id"], name: "hmis_csv_2024_clients-230f"
    t.index ["PersonalID"], name: "hmiscsv2024clients_603f"
    t.index ["VeteranStatus"], name: "hmiscsv2024clients_20a8"
  end

  create_table "hmis_csv_2024_current_living_situations", force: :cascade do |t|
    t.string "CurrentLivingSitID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "InformationDate"
    t.string "CurrentLivingSituation"
    t.string "CLSSubsidyType"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["CurrentLivingSitID", "data_source_id"], name: "hmis_csv_2024_current_living_situations-cf31"
    t.index ["CurrentLivingSitID"], name: "hmiscsv2024currentlivingsituations_c1ef"
    t.index ["CurrentLivingSituation"], name: "hmiscsv2024currentlivingsituations_d718"
    t.index ["ExportID"], name: "hmiscsv2024currentlivingsituations_634d"
  end

  create_table "hmis_csv_2024_disabilities", force: :cascade do |t|
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
    t.string "AntiRetroviral"
    t.string "DataCollectionStage"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DisabilitiesID", "data_source_id"], name: "hmis_csv_2024_disabilities-7712"
    t.index ["DisabilitiesID"], name: "hmiscsv2024disabilities_1873"
    t.index ["EnrollmentID"], name: "hmiscsv2024disabilities_4337"
    t.index ["ExportID"], name: "hmiscsv2024disabilities_634d"
    t.index ["PersonalID"], name: "hmiscsv2024disabilities_603f"
  end

  create_table "hmis_csv_2024_employment_educations", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["EmploymentEducationID", "data_source_id"], name: "hmis_csv_2024_employment_educations-3032"
    t.index ["EmploymentEducationID"], name: "hmiscsv2024employmenteducations_350e"
    t.index ["ExportID"], name: "hmiscsv2024employmenteducations_634d"
  end

  create_table "hmis_csv_2024_enrollments", force: :cascade do |t|
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "ProjectID"
    t.string "EntryDate"
    t.string "HouseholdID"
    t.string "RelationshipToHoH"
    t.string "EnrollmentCoC"
    t.string "LivingSituation"
    t.string "RentalSubsidyType"
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
    t.string "PercentAMI"
    t.string "ReferralSource"
    t.string "CountOutreachReferralApproaches"
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
    t.string "MentalHealthDisorderFam"
    t.string "PhysicalDisabilityFam"
    t.string "AlcoholDrugUseDisorderFam"
    t.string "InsufficientIncome"
    t.string "IncarceratedParent"
    t.string "VAMCStation"
    t.string "TargetScreenReqd"
    t.string "TimeToHousingLoss"
    t.string "AnnualPercentAMI"
    t.string "LiteralHomelessHistory"
    t.string "ClientLeaseholder"
    t.string "HOHLeaseholder"
    t.string "SubsidyAtRisk"
    t.string "EvictionHistory"
    t.string "CriminalRecord"
    t.string "IncarceratedAdult"
    t.string "PrisonDischarge"
    t.string "SexOffender"
    t.string "DisabledHoH"
    t.string "CurrentPregnant"
    t.string "SingleParent"
    t.string "DependentUnder6"
    t.string "HH5Plus"
    t.string "CoCPrioritized"
    t.string "HPScreeningScore"
    t.string "ThresholdScore"
    t.string "TranslationNeeded"
    t.string "PreferredLanguage"
    t.string "PreferredLanguageDifferent"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateDeleted", "EntryDate", "EnrollmentID", "HouseholdID", "ProjectID", "RelationshipToHoH"], name: "hmiscsv2024enrollments_c830"
    t.index ["DateDeleted", "RelationshipToHoH", "EnrollmentID", "PersonalID", "EntryDate", "HouseholdID", "DisablingCondition"], name: "hmiscsv2024enrollments_8d5c"
    t.index ["DateDeleted"], name: "hmiscsv2024enrollments_f3a2"
    t.index ["EnrollmentID", "ProjectID", "EntryDate"], name: "hmiscsv2024enrollments_34e3"
    t.index ["EnrollmentID", "data_source_id"], name: "hmis_csv_2024_enrollments-0a46"
    t.index ["EnrollmentID"], name: "hmiscsv2024enrollments_4337"
    t.index ["EntryDate", "EnrollmentID", "ProjectID", "HouseholdID", "RelationshipToHoH", "DateDeleted"], name: "hmiscsv2024enrollments_6191"
    t.index ["ExportID"], name: "hmiscsv2024enrollments_634d"
    t.index ["HouseholdID", "DateDeleted", "EntryDate", "RelationshipToHoH", "EnrollmentID", "PersonalID", "DisablingCondition"], name: "hmiscsv2024enrollments_5d40"
    t.index ["HouseholdID", "DateDeleted", "RelationshipToHoH", "EnrollmentID", "PersonalID", "EntryDate", "DisablingCondition"], name: "hmiscsv2024enrollments_89e7"
    t.index ["HouseholdID", "RelationshipToHoH", "DateDeleted", "EnrollmentID"], name: "hmiscsv2024enrollments_ea7f"
    t.index ["LengthOfStay", "EnrollmentID"], name: "hmiscsv2024enrollments_4685"
    t.index ["LivingSituation", "EnrollmentID"], name: "hmiscsv2024enrollments_821a"
    t.index ["MonthsHomelessPastThreeYears", "EnrollmentID", "LivingSituation", "PreviousStreetESSH"], name: "hmiscsv2024enrollments_44c4"
    t.index ["MoveInDate", "EnrollmentID"], name: "hmiscsv2024enrollments_fbbd"
    t.index ["PreviousStreetESSH", "LengthOfStay"], name: "hmiscsv2024enrollments_3085"
    t.index ["ProjectID", "RelationshipToHoH", "DateDeleted", "EnrollmentID", "PersonalID", "EntryDate", "HouseholdID", "MoveInDate"], name: "hmiscsv2024enrollments_9005"
    t.index ["ProjectID"], name: "hmiscsv2024enrollments_42af"
    t.index ["RelationshipToHoH", "DateDeleted", "EnrollmentID", "PersonalID", "ProjectID", "EntryDate", "HouseholdID", "MoveInDate", "DisablingCondition"], name: "hmiscsv2024enrollments_c3b4"
    t.index ["TimesHomelessPastThreeYears", "MonthsHomelessPastThreeYears", "EnrollmentID"], name: "hmiscsv2024enrollments_c321"
  end

  create_table "hmis_csv_2024_events", force: :cascade do |t|
    t.string "EventID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "EventDate"
    t.string "Event"
    t.string "ProbSolDivRRResult"
    t.string "ReferralCaseManageAfter"
    t.string "LocationCrisisOrPHHousing"
    t.string "ReferralResult"
    t.string "ResultDate"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["EnrollmentID"], name: "hmiscsv2024events_4337"
    t.index ["EventDate"], name: "hmiscsv2024events_ab19"
    t.index ["EventID"], name: "hmiscsv2024events_5251"
    t.index ["ExportID"], name: "hmiscsv2024events_634d"
  end

  create_table "hmis_csv_2024_exits", force: :cascade do |t|
    t.string "ExitID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "ExitDate"
    t.string "Destination"
    t.string "DestinationSubsidyType"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateDeleted", "EnrollmentID", "ExitDate"], name: "hmiscsv2024exits_f3a2"
    t.index ["DateUpdated"], name: "hmiscsv2024exits_42d5"
    t.index ["ExitDate", "Destination", "EnrollmentID"], name: "hmiscsv2024exits_13dc"
    t.index ["ExitDate"], name: "hmiscsv2024exits_fa9a"
    t.index ["ExitID", "data_source_id"], name: "hmis_csv_2024_exits-cfdd"
    t.index ["ExitID"], name: "hmiscsv2024exits_6f2b"
    t.index ["ExportID"], name: "hmiscsv2024exits_634d"
  end

  create_table "hmis_csv_2024_exports", force: :cascade do |t|
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
    t.string "CSVVersion"
    t.string "ExportPeriodType"
    t.string "ExportDirective"
    t.string "HashStatus"
    t.string "ImplementationID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
  end

  create_table "hmis_csv_2024_funders", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmiscsv2024funders_634d"
    t.index ["FunderID", "data_source_id"], name: "hmis_csv_2024_funders-4ad5"
    t.index ["FunderID"], name: "hmiscsv2024funders_4657"
  end

  create_table "hmis_csv_2024_health_and_dvs", force: :cascade do |t|
    t.string "HealthAndDVID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "InformationDate"
    t.string "DomesticViolenceSurvivor"
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmiscsv2024healthanddvs_634d"
    t.index ["HealthAndDVID", "data_source_id"], name: "hmis_csv_2024_health_and_dvs-e384"
    t.index ["HealthAndDVID"], name: "hmiscsv2024healthanddvs_1329"
  end

  create_table "hmis_csv_2024_hmis_participations", force: :cascade do |t|
    t.string "HMISParticipationID"
    t.string "ProjectID"
    t.string "HMISParticipationType"
    t.string "HMISParticipationStatusStartDate"
    t.string "HMISParticipationStatusEndDate"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmiscsv2024hmisparticipations_634d"
    t.index ["HMISParticipationID", "data_source_id"], name: "hmis_csv_2024_hmis_participations-0f0d"
    t.index ["ProjectID"], name: "hmiscsv2024hmisparticipations_42af"
  end

  create_table "hmis_csv_2024_income_benefits", force: :cascade do |t|
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
    t.string "VHAServices"
    t.string "NoVHAReason"
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
    t.string "ADAP"
    t.string "NoADAPReason"
    t.string "RyanWhiteMedDent"
    t.string "NoRyanWhiteReason"
    t.string "ConnectionWithSOAR"
    t.string "DataCollectionStage"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["Earned", "DataCollectionStage"], name: "hmiscsv2024incomebenefits_16c2"
    t.index ["ExportID"], name: "hmiscsv2024incomebenefits_634d"
    t.index ["IncomeBenefitsID", "data_source_id"], name: "hmis_csv_2024_income_benefits-200d"
    t.index ["IncomeBenefitsID"], name: "hmiscsv2024incomebenefits_f5f5"
    t.index ["IncomeFromAnySource", "DataCollectionStage"], name: "hmiscsv2024incomebenefits_ae8d"
  end

  create_table "hmis_csv_2024_inventories", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmiscsv2024inventories_634d"
    t.index ["InventoryID", "data_source_id"], name: "hmis_csv_2024_inventories-86c0"
    t.index ["InventoryID"], name: "hmiscsv2024inventories_9529"
  end

  create_table "hmis_csv_2024_organizations", force: :cascade do |t|
    t.string "OrganizationID"
    t.string "OrganizationName"
    t.string "VictimServiceProvider"
    t.string "OrganizationCommonName"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["OrganizationID", "data_source_id"], name: "hmis_csv_2024_organizations-7580"
    t.index ["OrganizationID"], name: "hmiscsv2024organizations_b19d"
  end

  create_table "hmis_csv_2024_project_cocs", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmiscsv2024projectcocs_634d"
    t.index ["ProjectCoCID", "data_source_id"], name: "hmis_csv_2024_project_cocs-3966"
    t.index ["ProjectCoCID"], name: "hmiscsv2024projectcocs_787b"
  end

  create_table "hmis_csv_2024_projects", force: :cascade do |t|
    t.string "ProjectID"
    t.string "OrganizationID"
    t.string "ProjectName"
    t.string "ProjectCommonName"
    t.string "OperatingStartDate"
    t.string "OperatingEndDate"
    t.string "ContinuumProject"
    t.string "ProjectType"
    t.string "HousingType"
    t.string "RRHSubType"
    t.string "ResidentialAffiliation"
    t.string "TargetPopulation"
    t.string "HOPWAMedAssistedLivingFac"
    t.string "PITCount"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ProjectID", "data_source_id"], name: "hmis_csv_2024_projects-92c5"
    t.index ["ProjectID"], name: "hmiscsv2024projects_42af"
  end

  create_table "hmis_csv_2024_services", force: :cascade do |t|
    t.string "ServicesID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "DateProvided"
    t.string "RecordType"
    t.string "TypeProvided"
    t.string "OtherTypeProvided"
    t.string "MovingOnOtherType"
    t.string "SubTypeProvided"
    t.string "FAAmount"
    t.string "FAStartDate"
    t.string "FAEndDate"
    t.string "ReferralOutcome"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["DateDeleted"], name: "hmiscsv2024services_f3a2"
    t.index ["DateProvided"], name: "hmiscsv2024services_3444"
    t.index ["EnrollmentID", "RecordType", "DateDeleted", "DateProvided"], name: "hmiscsv2024services_9c1a"
    t.index ["ExportID"], name: "hmiscsv2024services_634d"
    t.index ["RecordType", "DateDeleted", "DateProvided", "EnrollmentID"], name: "hmiscsv2024services_8dbb"
    t.index ["RecordType"], name: "hmiscsv2024services_237b"
    t.index ["ServicesID", "data_source_id"], name: "hmis_csv_2024_services-7a57"
    t.index ["ServicesID"], name: "hmiscsv2024services_6415"
  end

  create_table "hmis_csv_2024_users", force: :cascade do |t|
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
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmiscsv2024users_634d"
    t.index ["UserID"], name: "hmiscsv2024users_57c7"
  end

  create_table "hmis_csv_2024_youth_education_statuses", force: :cascade do |t|
    t.string "YouthEducationStatusID"
    t.string "EnrollmentID"
    t.string "PersonalID"
    t.string "InformationDate"
    t.string "CurrentSchoolAttend"
    t.string "MostRecentEdStatus"
    t.string "CurrentEdStatus"
    t.string "DataCollectionStage"
    t.string "DateCreated"
    t.string "DateUpdated"
    t.string "UserID"
    t.string "DateDeleted"
    t.string "ExportID"
    t.integer "data_source_id", null: false
    t.datetime "loaded_at", precision: nil, null: false
    t.integer "loader_id", null: false
    t.index ["ExportID"], name: "hmiscsv2024youtheducationstatuses_634d"
    t.index ["InformationDate"], name: "hmiscsv2024youtheducationstatuses_fabe"
    t.index ["YouthEducationStatusID", "data_source_id"], name: "hmis_csv_2024_youth_education_statuses-a32f"
    t.index ["YouthEducationStatusID"], name: "hmiscsv2024youtheducationstatuses_6049"
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
    t.string "validated_column"
    t.index ["importer_log_id"], name: "index_hmis_csv_import_validations_on_importer_log_id"
    t.index ["source_type", "source_id"], name: "hmis_csv_validations-ONiu"
    t.index ["type"], name: "index_hmis_csv_import_validations_on_type"
  end

  create_table "hmis_csv_importer_logs", force: :cascade do |t|
    t.integer "data_source_id", null: false
    t.jsonb "summary"
    t.string "status"
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "upload_id"
    t.index ["created_at"], name: "index_hmis_csv_loader_logs_on_created_at"
    t.index ["data_source_id"], name: "index_hmis_csv_loader_logs_on_data_source_id"
    t.index ["importer_log_id"], name: "index_hmis_csv_loader_logs_on_importer_log_id"
    t.index ["updated_at"], name: "index_hmis_csv_loader_logs_on_updated_at"
  end

  create_table "hmis_dqt_assessments", force: :cascade do |t|
    t.bigint "assessment_id", null: false
    t.bigint "enrollment_id", null: false
    t.bigint "client_id", null: false
    t.bigint "report_id", null: false
    t.string "project_name"
    t.integer "destination_client_id"
    t.string "hmis_assessment_id"
    t.integer "data_source_id"
    t.integer "assessment_type"
    t.integer "assessment_level"
    t.integer "prioritization_status"
    t.date "assessment_date"
    t.date "project_operating_start_date"
    t.date "project_operating_end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["assessment_id"], name: "index_hmis_dqt_assessments_on_assessment_id"
    t.index ["client_id"], name: "index_hmis_dqt_assessments_on_client_id"
    t.index ["enrollment_id"], name: "index_hmis_dqt_assessments_on_enrollment_id"
    t.index ["report_id"], name: "index_hmis_dqt_assessments_on_report_id"
  end

  create_table "hmis_dqt_clients", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "report_id", null: false
    t.integer "destination_client_id"
    t.string "first_name"
    t.string "last_name"
    t.string "personal_id"
    t.integer "data_source_id"
    t.date "dob"
    t.integer "dob_data_quality"
    t.integer "male"
    t.integer "female"
    t.integer "no_single_gender"
    t.integer "transgender"
    t.integer "questioning"
    t.integer "am_ind_ak_native"
    t.integer "asian"
    t.integer "black_af_american"
    t.integer "native_hi_pacific"
    t.integer "white"
    t.integer "race_none"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.integer "gender_none"
    t.integer "overlapping_entry_exit"
    t.integer "overlapping_nbn"
    t.integer "overlapping_pre_move_in"
    t.integer "overlapping_post_move_in"
    t.boolean "ch_at_most_recent_entry", default: false
    t.boolean "ch_at_any_entry", default: false
    t.integer "veteran_status"
    t.string "ssn"
    t.integer "ssn_data_quality"
    t.integer "name_data_quality"
    t.integer "ethnicity"
    t.integer "reporting_age"
    t.integer "woman"
    t.integer "man"
    t.integer "culturally_specific"
    t.integer "different_identity"
    t.integer "non_binary"
    t.integer "hispanic_latinaeo"
    t.integer "mid_east_n_african"
    t.integer "spm_hispanic_latinaeo"
    t.integer "_all_persons__hispanic_latinaeo"
    t.integer "spm_with_children__hispanic_latinaeo"
    t.integer "spm_only_children__hispanic_latinaeo"
    t.integer "spm_without_children__hispanic_latinaeo"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__hispan"
    t.integer "spm_without_children_and_fifty_five_plus__hispanic_latinaeo"
    t.integer "spm_mid_east_n_african"
    t.integer "_all_persons__mid_east_n_african"
    t.integer "spm_with_children__mid_east_n_african"
    t.integer "spm_only_children__mid_east_n_african"
    t.integer "spm_without_children__mid_east_n_african"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__mid_ea"
    t.integer "spm_without_children_and_fifty_five_plus__mid_east_n_african"
    t.jsonb "overlapping_entry_exit_details"
    t.jsonb "overlapping_nbn_details"
    t.jsonb "overlapping_pre_move_in_details"
    t.jsonb "overlapping_post_move_in_details"
    t.index ["client_id"], name: "index_hmis_dqt_clients_on_client_id"
    t.index ["report_id"], name: "index_hmis_dqt_clients_on_report_id"
  end

  create_table "hmis_dqt_current_living_situations", force: :cascade do |t|
    t.bigint "current_living_situation_id", null: false
    t.bigint "enrollment_id", null: false
    t.bigint "client_id", null: false
    t.bigint "report_id", null: false
    t.string "project_name"
    t.integer "destination_client_id"
    t.string "hmis_current_living_situation_id"
    t.integer "data_source_id"
    t.integer "situation"
    t.date "information_date"
    t.date "project_operating_start_date"
    t.date "project_operating_end_date"
    t.integer "project_tracking_method"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.integer "project_id"
    t.string "first_name"
    t.string "last_name"
    t.string "personal_id"
    t.index ["client_id"], name: "index_hmis_dqt_current_living_situations_on_client_id"
    t.index ["enrollment_id"], name: "index_hmis_dqt_current_living_situations_on_enrollment_id"
    t.index ["report_id"], name: "index_hmis_dqt_current_living_situations_on_report_id"
    t.index ["situation"], name: "hmis_dqt_cls_cls_id"
  end

  create_table "hmis_dqt_enrollments", force: :cascade do |t|
    t.bigint "enrollment_id", null: false
    t.bigint "client_id", null: false
    t.bigint "report_id", null: false
    t.string "personal_id"
    t.string "project_name"
    t.integer "destination_client_id"
    t.string "hmis_enrollment_id"
    t.string "exit_id"
    t.integer "data_source_id"
    t.date "entry_date"
    t.date "move_in_date"
    t.date "exit_date"
    t.integer "age"
    t.integer "household_max_age"
    t.string "household_id"
    t.integer "head_of_household_count"
    t.integer "disabling_condition"
    t.integer "living_situation"
    t.integer "relationship_to_hoh"
    t.string "coc_code"
    t.integer "destination"
    t.date "project_operating_start_date"
    t.date "project_operating_end_date"
    t.integer "project_tracking_method"
    t.integer "lot"
    t.integer "days_since_last_service"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.integer "project_type"
    t.boolean "ch_at_entry", default: false
    t.integer "project_id"
    t.string "household_type"
    t.integer "household_min_age"
    t.boolean "ch_details_expected", default: false
    t.integer "los_under_threshold"
    t.date "date_to_street_essh"
    t.integer "times_homeless_past_three_years"
    t.integer "months_homeless_past_three_years"
    t.string "enrollment_coc"
    t.boolean "has_disability", default: false
    t.integer "days_between_entry_and_create"
    t.boolean "health_dv_at_entry_expected", default: false
    t.integer "domestic_violence_victim_at_entry"
    t.boolean "income_at_entry_expected", default: false
    t.boolean "income_at_annual_expected", default: false
    t.boolean "income_at_exit_expected", default: false
    t.boolean "insurance_at_entry_expected", default: false
    t.boolean "insurance_at_annual_expected", default: false
    t.boolean "insurance_at_exit_expected", default: false
    t.integer "income_from_any_source_at_entry"
    t.integer "income_from_any_source_at_annual"
    t.integer "income_from_any_source_at_exit"
    t.boolean "cash_income_as_expected_at_entry", default: false
    t.boolean "cash_income_as_expected_at_annual", default: false
    t.boolean "cash_income_as_expected_at_exit", default: false
    t.integer "ncb_from_any_source_at_entry_remove"
    t.integer "ncb_from_any_source_at_annual_remove"
    t.integer "ncb_from_any_source_at_exit_remove"
    t.boolean "ncb_as_expected_at_entry", default: false
    t.boolean "ncb_as_expected_at_annual", default: false
    t.boolean "ncb_as_expected_at_exit", default: false
    t.integer "insurance_from_any_source_at_entry_remove"
    t.integer "insurance_from_any_source_at_annual_remove"
    t.integer "insurance_from_any_source_at_exit_remove"
    t.boolean "insurance_as_expected_at_entry", default: false
    t.boolean "insurance_as_expected_at_annual", default: false
    t.boolean "insurance_as_expected_at_exit", default: false
    t.boolean "disability_at_entry_collected", default: false
    t.integer "previous_street_es_sh"
    t.datetime "entry_date_entered_at", precision: nil
    t.datetime "exit_date_entered_at", precision: nil
    t.integer "days_to_enter_entry_date"
    t.integer "days_to_enter_exit_date"
    t.integer "days_before_entry"
    t.string "first_name"
    t.string "last_name"
    t.boolean "annual_expected"
    t.date "enrollment_anniversary_date"
    t.json "annual_assessment_status"
    t.jsonb "funders"
    t.integer "percent_ami"
    t.string "vamc_station"
    t.integer "veteran"
    t.integer "hoh_veteran"
    t.integer "hh_veteran_count"
    t.integer "target_screen_required"
    t.boolean "target_screen_completed"
    t.decimal "total_monthly_income_at_entry"
    t.decimal "total_monthly_income_from_source_at_entry"
    t.decimal "total_monthly_income_at_exit"
    t.decimal "total_monthly_income_from_source_at_exit"
    t.integer "afghanistan_oef"
    t.integer "iraq_oif"
    t.integer "iraq_ond"
    t.integer "military_branch"
    t.integer "discharge_status"
    t.integer "employed"
    t.integer "employment_type"
    t.integer "not_employed_reason"
    t.integer "ncb_from_any_source_at_entry"
    t.integer "ncb_from_any_source_at_annual"
    t.integer "ncb_from_any_source_at_exit"
    t.integer "insurance_from_any_source_at_entry"
    t.integer "insurance_from_any_source_at_annual"
    t.integer "insurance_from_any_source_at_exit"
    t.index ["client_id"], name: "index_hmis_dqt_enrollments_on_client_id"
    t.index ["enrollment_id"], name: "index_hmis_dqt_enrollments_on_enrollment_id"
    t.index ["project_id"], name: "index_hmis_dqt_enrollments_on_project_id"
    t.index ["report_id"], name: "index_hmis_dqt_enrollments_on_report_id"
  end

  create_table "hmis_dqt_events", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "enrollment_id", null: false
    t.bigint "client_id", null: false
    t.bigint "report_id", null: false
    t.string "project_name"
    t.integer "destination_client_id"
    t.string "hmis_event_id"
    t.integer "data_source_id"
    t.integer "event"
    t.date "event_date"
    t.date "project_operating_start_date"
    t.date "project_operating_end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["client_id"], name: "index_hmis_dqt_events_on_client_id"
    t.index ["enrollment_id"], name: "index_hmis_dqt_events_on_enrollment_id"
    t.index ["event_id"], name: "index_hmis_dqt_events_on_event_id"
    t.index ["report_id"], name: "index_hmis_dqt_events_on_report_id"
  end

  create_table "hmis_dqt_goals", force: :cascade do |t|
    t.string "coc_code"
    t.string "segment_0_name"
    t.string "segment_0_color"
    t.integer "segment_0_low"
    t.integer "segment_0_high"
    t.string "segment_1_name"
    t.string "segment_1_color"
    t.integer "segment_1_low"
    t.integer "segment_1_high"
    t.string "segment_2_name"
    t.string "segment_2_color"
    t.integer "segment_2_low"
    t.integer "segment_2_high"
    t.string "segment_3_name"
    t.string "segment_3_color"
    t.integer "segment_3_low"
    t.integer "segment_3_high"
    t.string "segment_4_name"
    t.string "segment_4_color"
    t.integer "segment_4_low"
    t.integer "segment_4_high"
    t.string "segment_5_name"
    t.string "segment_5_color"
    t.integer "segment_5_low"
    t.integer "segment_5_high"
    t.string "segment_6_name"
    t.string "segment_6_color"
    t.integer "segment_6_low"
    t.integer "segment_6_high"
    t.string "segment_7_name"
    t.string "segment_7_color"
    t.integer "segment_7_low"
    t.integer "segment_7_high"
    t.string "segment_8_name"
    t.string "segment_8_color"
    t.integer "segment_8_low"
    t.integer "segment_8_high"
    t.string "segment_9_name"
    t.string "segment_9_color"
    t.integer "segment_9_low"
    t.integer "segment_9_high"
    t.integer "es_stay_length"
    t.integer "es_missed_exit_length"
    t.integer "so_missed_exit_length"
    t.integer "ph_missed_exit_length"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.integer "entry_date_entered_length", default: 6
    t.integer "exit_date_entered_length", default: 6
    t.boolean "expose_ch_calculations", default: true, null: false
    t.boolean "show_annual_assessments", default: true
  end

  create_table "hmis_dqt_inventories", force: :cascade do |t|
    t.bigint "inventory_id", null: false
    t.bigint "project_id", null: false
    t.bigint "report_id", null: false
    t.string "project_name"
    t.string "hmis_inventory_id"
    t.integer "data_source_id"
    t.integer "project_type"
    t.date "project_operating_start_date"
    t.date "project_operating_end_date"
    t.integer "unit_inventory"
    t.integer "bed_inventory"
    t.integer "ch_vet_bed_inventory"
    t.integer "youth_vet_bed_inventory"
    t.integer "vet_bed_inventory"
    t.integer "ch_youth_bed_inventory"
    t.integer "youth_bed_inventory"
    t.integer "ch_bed_inventory"
    t.integer "other_bed_inventory"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.date "inventory_start_date"
    t.date "inventory_end_date"
    t.index ["inventory_id"], name: "index_hmis_dqt_inventories_on_inventory_id"
    t.index ["project_id"], name: "index_hmis_dqt_inventories_on_project_id"
    t.index ["report_id"], name: "index_hmis_dqt_inventories_on_report_id"
  end

  create_table "hmis_external_form_publications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "definition_id", null: false
    t.string "object_key", null: false
    t.jsonb "content_definition", null: false
    t.text "content"
    t.string "content_digest"
    t.index ["definition_id"], name: "index_hmis_external_form_publications_on_definition_id"
  end

  create_table "hmis_external_form_submissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "submitted_at", precision: nil
    t.float "spam_score"
    t.string "status", default: "new", null: false
    t.bigint "definition_id", null: false
    t.string "object_key", null: false
    t.jsonb "raw_data", null: false
    t.text "notes"
    t.bigint "enrollment_id"
    t.index ["definition_id"], name: "index_hmis_external_form_submissions_on_definition_id"
    t.index ["enrollment_id"], name: "index_hmis_external_form_submissions_on_enrollment_id"
  end

  create_table "hmis_external_referral_household_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "relationship_to_hoh", null: false
    t.bigint "referral_id", null: false
    t.bigint "client_id", null: false
    t.string "mci_id"
    t.index ["client_id", "referral_id"], name: "uidx_hmis_external_referral_hms_1", unique: true
    t.index ["referral_id"], name: "idx_hmis_external_referral_hms_on_referral_id"
  end

  create_table "hmis_external_referral_postings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
    t.integer "status", null: false
    t.bigint "referral_id", null: false
    t.bigint "project_id", null: false
    t.bigint "referral_request_id"
    t.bigint "unit_type_id"
    t.string "HouseholdID"
    t.text "resource_coordinator_notes"
    t.datetime "status_updated_at", precision: nil, null: false
    t.bigint "status_updated_by_id"
    t.text "status_note"
    t.bigint "status_note_updated_by_id"
    t.integer "denial_reason"
    t.integer "referral_result"
    t.text "denial_note"
    t.datetime "status_note_updated_at", precision: nil
    t.integer "data_source_id", null: false
    t.index ["identifier"], name: "uidx_hmis_external_referral_posting_identifier", unique: true
    t.index ["project_id"], name: "index_hmis_external_referral_postings_on_project_id"
    t.index ["referral_id", "referral_request_id"], name: "uidx_hmis_external_referral_postings_1", unique: true
    t.index ["referral_request_id"], name: "idx_hmis_external_referral_postings_on_request_id"
    t.index ["status_note_updated_by_id"], name: "idx_hmis_external_referral_postings_user_2"
    t.index ["status_updated_by_id"], name: "idx_hmis_external_referral_postings_user_1"
    t.index ["unit_type_id"], name: "index_hmis_external_referral_postings_on_unit_type_id"
  end

  create_table "hmis_external_referral_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
    t.bigint "project_id", null: false
    t.bigint "unit_type_id", null: false
    t.datetime "requested_on", precision: nil, null: false
    t.date "needed_by", null: false
    t.bigint "requested_by_id"
    t.string "requestor_name", null: false
    t.string "requestor_phone", null: false
    t.string "requestor_email", null: false
    t.datetime "voided_at", precision: nil
    t.bigint "voided_by_id"
    t.index ["identifier"], name: "uidx_hmis_external_referral_requests_identifier", unique: true
    t.index ["project_id"], name: "index_hmis_external_referral_requests_on_project_id"
    t.index ["requested_by_id"], name: "index_hmis_external_referral_requests_on_requested_by_id"
    t.index ["unit_type_id"], name: "index_hmis_external_referral_requests_on_unit_type_id"
    t.index ["voided_by_id"], name: "index_hmis_external_referral_requests_on_voided_by_id"
  end

  create_table "hmis_external_referrals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "identifier"
    t.date "referral_date", null: false
    t.string "service_coordinator", null: false
    t.bigint "enrollment_id"
    t.text "referral_notes"
    t.boolean "chronic"
    t.integer "score"
    t.boolean "needs_wheelchair_accessible_unit"
    t.index ["enrollment_id"], name: "index_hmis_external_referrals_on_enrollment_id"
    t.index ["identifier"], name: "uidx_hmis_external_referrals_identifier", unique: true
  end

  create_table "hmis_external_unit_availability_syncs", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "unit_type_id", null: false
    t.bigint "user_id", null: false
    t.integer "local_version", default: 0, null: false
    t.integer "synced_version", default: 0, null: false
    t.index ["project_id", "unit_type_id"], name: "uidx_hmis_external_unit_availability_syncs", unique: true
    t.index ["unit_type_id"], name: "index_hmis_external_unit_availability_syncs_on_unit_type_id"
    t.index ["user_id"], name: "index_hmis_external_unit_availability_syncs_on_user_id"
  end

  create_table "hmis_form_definitions", force: :cascade do |t|
    t.integer "version", null: false
    t.string "identifier", null: false
    t.string "role", null: false, comment: "Usually one of INTAKE, UPDATE, ANNUAL, EXIT, POST_EXIT, CE, CUSTOM"
    t.string "status", null: false, comment: "Usually one of active, draft, retired"
    t.jsonb "definition", comment: "Based on FHIR format"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title", null: false
    t.string "external_form_object_key"
    t.datetime "deleted_at", precision: nil
    t.jsonb "backup_definition"
    t.boolean "managed_in_version_control", default: false
    t.index ["identifier", "version"], name: "uidx_hmis_form_definitions_identifier", unique: true, where: "(deleted_at IS NULL)"
    t.index ["identifier"], name: "uidx_hmis_form_definitions_one_draft_per_identifier", unique: true, where: "(((status)::text = 'draft'::text) AND (deleted_at IS NULL))"
    t.index ["identifier"], name: "uidx_hmis_form_definitions_one_published_per_identifier", unique: true, where: "(((status)::text = 'published'::text) AND (deleted_at IS NULL))"
  end

  create_table "hmis_form_instances", force: :cascade do |t|
    t.string "entity_type"
    t.bigint "entity_id"
    t.string "definition_identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "custom_service_type_id"
    t.integer "custom_service_category_id"
    t.integer "funder"
    t.integer "project_type"
    t.string "other_funder"
    t.string "data_collected_about"
    t.boolean "system", default: false, null: false
    t.boolean "active", default: true, null: false
    t.index ["entity_type", "entity_id"], name: "index_hmis_form_instances_on_entity"
  end

  create_table "hmis_form_processors", force: :cascade do |t|
    t.bigint "enrollment_coc_id"
    t.bigint "health_and_dv_id"
    t.bigint "income_benefit_id"
    t.bigint "physical_disability_id"
    t.bigint "developmental_disability_id"
    t.bigint "chronic_health_condition_id"
    t.bigint "hiv_aids_id"
    t.bigint "mental_health_disorder_id"
    t.bigint "substance_use_disorder_id"
    t.bigint "exit_id"
    t.integer "custom_assessment_id"
    t.integer "definition_id"
    t.jsonb "values"
    t.jsonb "hud_values"
    t.integer "youth_education_status_id"
    t.integer "employment_education_id"
    t.integer "current_living_situation_id"
    t.bigint "ce_assessment_id"
    t.bigint "ce_event_id"
    t.jsonb "backup_values"
    t.string "owner_type", null: false
    t.bigint "owner_id", null: false
    t.bigint "clh_location_id"
    t.index ["ce_assessment_id"], name: "index_hmis_form_processors_on_ce_assessment_id"
    t.index ["ce_event_id"], name: "index_hmis_form_processors_on_ce_event_id"
    t.index ["chronic_health_condition_id"], name: "index_hmis_form_processors_on_chronic_health_condition_id"
    t.index ["clh_location_id"], name: "index_hmis_form_processors_on_clh_location_id"
    t.index ["developmental_disability_id"], name: "index_hmis_form_processors_on_developmental_disability_id"
    t.index ["enrollment_coc_id"], name: "index_hmis_form_processors_on_enrollment_coc_id"
    t.index ["exit_id"], name: "index_hmis_form_processors_on_exit_id"
    t.index ["health_and_dv_id"], name: "index_hmis_form_processors_on_health_and_dv_id"
    t.index ["hiv_aids_id"], name: "index_hmis_form_processors_on_hiv_aids_id"
    t.index ["income_benefit_id"], name: "index_hmis_form_processors_on_income_benefit_id"
    t.index ["mental_health_disorder_id"], name: "index_hmis_form_processors_on_mental_health_disorder_id"
    t.index ["owner_id", "owner_type"], name: "one_form_processor_per_owner", unique: true
    t.index ["physical_disability_id"], name: "index_hmis_form_processors_on_physical_disability_id"
    t.index ["substance_use_disorder_id"], name: "index_hmis_form_processors_on_substance_use_disorder_id"
  end

  create_table "hmis_forms", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.text "api_response"
    t.string "name"
    t.text "answers"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "response_id"
    t.integer "subject_id"
    t.datetime "collected_at", precision: nil
    t.string "staff"
    t.string "assessment_type"
    t.string "collection_location"
    t.integer "assessment_id"
    t.integer "data_source_id", null: false
    t.integer "site_id"
    t.datetime "vispdat_score_updated_at", precision: nil
    t.float "vispdat_total_score"
    t.float "vispdat_youth_score"
    t.float "vispdat_family_score"
    t.float "vispdat_months_homeless"
    t.float "vispdat_times_homeless"
    t.string "staff_email"
    t.datetime "eto_last_updated", precision: nil
    t.string "housing_status"
    t.string "vispdat_pregnant"
    t.date "vispdat_pregnant_updated_at"
    t.datetime "housing_status_updated_at", precision: nil
    t.datetime "pathways_updated_at", precision: nil
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
    t.datetime "vispdat_physical_disability_updated_at", precision: nil
    t.datetime "covid_impact_updated_at", precision: nil
    t.integer "number_of_bedrooms"
    t.integer "subsidy_months"
    t.integer "total_subsidy"
    t.integer "monthly_rent_total"
    t.integer "percent_ami"
    t.string "household_type"
    t.integer "household_size"
    t.datetime "location_processed_at", precision: nil
    t.index ["assessment_id"], name: "index_hmis_forms_on_assessment_id"
    t.index ["client_id", "assessment_id"], name: "index_hmis_forms_on_client_id_and_assessment_id"
    t.index ["collected_at"], name: "index_hmis_forms_on_collected_at"
    t.index ["name"], name: "index_hmis_forms_on_name"
  end

  create_table "hmis_group_viewable_entities", force: :cascade do |t|
    t.string "entity_type", null: false
    t.bigint "entity_id", null: false
    t.bigint "collection_id", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["collection_id"], name: "index_hmis_group_viewable_entities_on_collection_id"
    t.index ["entity_type", "entity_id"], name: "index_hmis_group_viewable_entities_on_entity"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "file_count", default: 1, null: false
    t.string "s3_role_arn"
    t.string "s3_external_id"
    t.index ["data_source_id"], name: "index_hmis_import_configs_on_data_source_id"
  end

  create_table "hmis_project_configs", force: :cascade do |t|
    t.string "type", null: false
    t.boolean "enabled", default: true, null: false
    t.jsonb "config_options"
    t.integer "project_type"
    t.bigint "organization_id"
    t.bigint "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_hmis_project_configs_on_organization_id"
    t.index ["project_id"], name: "index_hmis_project_configs_on_project_id"
  end

  create_table "hmis_project_unit_type_mappings", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "unit_type_id", null: false
    t.integer "unit_capacity"
    t.boolean "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "unit_type_id"], name: "uidx_hmis_project_unit_type_mappings", unique: true
    t.index ["project_id"], name: "index_hmis_project_unit_type_mappings_on_project_id"
    t.index ["unit_type_id"], name: "index_hmis_project_unit_type_mappings_on_unit_type_id"
  end

  create_table "hmis_scan_card_codes", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.string "value", null: false, comment: "code to embed in scan card"
    t.bigint "created_by_id", comment: "user that generated code"
    t.bigint "deleted_by_id", comment: "user that deleted code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.datetime "expires_at", precision: nil, comment: "when scan card should expire"
    t.index ["client_id"], name: "index_hmis_scan_card_codes_on_client_id"
    t.index ["created_by_id"], name: "index_hmis_scan_card_codes_on_created_by_id"
    t.index ["deleted_by_id"], name: "index_hmis_scan_card_codes_on_deleted_by_id"
    t.index ["value"], name: "index_hmis_scan_card_codes_on_value", unique: true
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

  create_table "hmis_staff_assignment_relationships", force: :cascade do |t|
    t.string "name", null: false, comment: "name of role, such as \"Case Manager\" or \"Housing Navigator\""
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["name"], name: "index_hmis_staff_assignment_relationships_on_name", unique: true
  end

  create_table "hmis_staff_assignments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "household_id"
    t.bigint "hmis_staff_assignment_relationship_id", null: false
    t.bigint "data_source_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["data_source_id", "household_id", "user_id", "hmis_staff_assignment_relationship_id"], name: "uidx_hmis_staff_assignments", unique: true, where: "(deleted_at IS NULL)"
    t.index ["data_source_id"], name: "index_hmis_staff_assignments_on_data_source_id"
    t.index ["user_id"], name: "index_hmis_staff_assignments_on_user_id"
  end

  create_table "hmis_staff_x_clients", id: :serial, force: :cascade do |t|
    t.integer "staff_id"
    t.integer "client_id"
    t.integer "relationship_id"
    t.string "source_class"
    t.string "source_id"
    t.index ["staff_id", "client_id", "relationship_id"], name: "index_staff_x_client_s_id_c_id_r_id", unique: true
  end

  create_table "hmis_supplemental_data_sets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "data_source_id", null: false
    t.bigint "remote_credential_id"
    t.string "owner_type", null: false
    t.string "object_key", null: false
    t.string "name", null: false
    t.string "field_config", null: false
    t.boolean "sync_enabled", default: false
    t.index ["data_source_id"], name: "index_hmis_supplemental_data_sets_on_data_source_id"
    t.index ["remote_credential_id"], name: "index_hmis_supplemental_data_sets_on_remote_credential_id"
  end

  create_table "hmis_supplemental_field_values", force: :cascade do |t|
    t.bigint "data_set_id", null: false
    t.string "field_key", null: false
    t.string "owner_key", null: false
    t.jsonb "data", null: false
    t.index ["data_set_id", "owner_key", "field_key"], name: "uidx_hmis_supplemental_field_values_on_key", unique: true
  end

  create_table "hmis_unit_occupancy", force: :cascade do |t|
    t.bigint "unit_id", null: false
    t.bigint "enrollment_id", null: false
    t.bigint "hmis_service_id"
    t.index ["enrollment_id"], name: "index_hmis_unit_occupancy_on_enrollment_id"
    t.index ["hmis_service_id"], name: "index_hmis_unit_occupancy_on_hmis_service_id"
    t.index ["unit_id"], name: "index_hmis_unit_occupancy_on_unit_id"
  end

  create_table "hmis_unit_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.integer "bed_type"
    t.integer "unit_size"
  end

  create_table "hmis_units", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.string "user_id", null: false
    t.integer "unit_type_id"
    t.integer "unit_size"
    t.integer "project_id", null: false
  end

  create_table "homeless_summary_report_clients", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "report_id"
    t.string "first_name"
    t.string "last_name"
    t.integer "spm_m1a_es_sh_days"
    t.integer "spm_m1a_es_sh_th_days"
    t.integer "spm_m1b_es_sh_ph_days"
    t.integer "spm_m1b_es_sh_th_ph_days"
    t.integer "spm_m2_reentry_days"
    t.integer "spm_m7a1_destination"
    t.integer "spm_m7b1_destination"
    t.integer "spm_m7b2_destination"
    t.boolean "spm_m7a1_c2", default: false
    t.boolean "spm_m7a1_c3", default: false
    t.boolean "spm_m7a1_c4", default: false
    t.boolean "spm_m7b1_c2", default: false
    t.boolean "spm_m7b1_c3", default: false
    t.boolean "spm_m7b2_c2", default: false
    t.boolean "spm_m7b2_c3", default: false
    t.integer "spm_all_persons"
    t.integer "spm_without_children"
    t.integer "spm_with_children"
    t.integer "spm_only_children"
    t.integer "spm_without_children_and_fifty_five_plus"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24"
    t.integer "spm_white_non_hispanic_latino"
    t.integer "spm_hispanic_latino"
    t.integer "spm_black_african_american"
    t.integer "spm_asian"
    t.integer "spm_american_indian_alaskan_native"
    t.integer "spm_native_hawaiian_other_pacific_islander"
    t.integer "spm_multi_racial"
    t.integer "spm_fleeing_dv"
    t.integer "spm_veteran"
    t.integer "spm_has_disability"
    t.integer "spm_has_rrh_move_in_date"
    t.integer "spm_has_psh_move_in_date"
    t.integer "spm_first_time_homeless"
    t.integer "spm_returned_to_homelessness_from_permanent_destination"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "spm_exited_from_homeless_system", default: false
    t.integer "spm_all_persons__all"
    t.integer "spm_all_persons__white_non_hispanic_latino"
    t.integer "spm_all_persons__hispanic_latino"
    t.integer "spm_all_persons__black_african_american"
    t.integer "spm_all_persons__asian"
    t.integer "spm_all_persons__american_indian_alaskan_native"
    t.integer "spm_all_persons__native_hawaiian_other_pacific_islander"
    t.integer "spm_all_persons__multi_racial"
    t.integer "spm_all_persons__fleeing_dv"
    t.integer "spm_all_persons__veteran"
    t.integer "spm_all_persons__has_disability"
    t.integer "spm_all_persons__has_rrh_move_in_date"
    t.integer "spm_all_persons__has_psh_move_in_date"
    t.integer "spm_all_persons__first_time_homeless"
    t.integer "spm_all_persons__returned_to_homelessness_from_permanent_destin"
    t.integer "spm_without_children__all"
    t.integer "spm_without_children__white_non_hispanic_latino"
    t.integer "spm_without_children__hispanic_latino"
    t.integer "spm_without_children__black_african_american"
    t.integer "spm_without_children__asian"
    t.integer "spm_without_children__american_indian_alaskan_native"
    t.integer "spm_without_children__native_hawaiian_other_pacific_islander"
    t.integer "spm_without_children__multi_racial"
    t.integer "spm_without_children__fleeing_dv"
    t.integer "spm_without_children__veteran"
    t.integer "spm_without_children__has_disability"
    t.integer "spm_without_children__has_rrh_move_in_date"
    t.integer "spm_without_children__has_psh_move_in_date"
    t.integer "spm_without_children__first_time_homeless"
    t.integer "spm_without_children__returned_to_homelessness_from_permanent_d"
    t.integer "spm_with_children__all"
    t.integer "spm_with_children__white_non_hispanic_latino"
    t.integer "spm_with_children__hispanic_latino"
    t.integer "spm_with_children__black_african_american"
    t.integer "spm_with_children__asian"
    t.integer "spm_with_children__american_indian_alaskan_native"
    t.integer "spm_with_children__native_hawaiian_other_pacific_islander"
    t.integer "spm_with_children__multi_racial"
    t.integer "spm_with_children__fleeing_dv"
    t.integer "spm_with_children__veteran"
    t.integer "spm_with_children__has_disability"
    t.integer "spm_with_children__has_rrh_move_in_date"
    t.integer "spm_with_children__has_psh_move_in_date"
    t.integer "spm_with_children__first_time_homeless"
    t.integer "spm_with_children__returned_to_homelessness_from_permanent_dest"
    t.integer "spm_only_children__all"
    t.integer "spm_only_children__white_non_hispanic_latino"
    t.integer "spm_only_children__hispanic_latino"
    t.integer "spm_only_children__black_african_american"
    t.integer "spm_only_children__asian"
    t.integer "spm_only_children__american_indian_alaskan_native"
    t.integer "spm_only_children__native_hawaiian_other_pacific_islander"
    t.integer "spm_only_children__multi_racial"
    t.integer "spm_only_children__fleeing_dv"
    t.integer "spm_only_children__veteran"
    t.integer "spm_only_children__has_disability"
    t.integer "spm_only_children__has_rrh_move_in_date"
    t.integer "spm_only_children__has_psh_move_in_date"
    t.integer "spm_only_children__first_time_homeless"
    t.integer "spm_only_children__returned_to_homelessness_from_permanent_dest"
    t.integer "spm_without_children_and_fifty_five_plus__all"
    t.integer "spm_without_children_and_fifty_five_plus__white_non_hispanic_la"
    t.integer "spm_without_children_and_fifty_five_plus__hispanic_latino"
    t.integer "spm_without_children_and_fifty_five_plus__black_african_america"
    t.integer "spm_without_children_and_fifty_five_plus__asian"
    t.integer "spm_without_children_and_fifty_five_plus__american_indian_alask"
    t.integer "spm_without_children_and_fifty_five_plus__native_hawaiian_other"
    t.integer "spm_without_children_and_fifty_five_plus__multi_racial"
    t.integer "spm_without_children_and_fifty_five_plus__fleeing_dv"
    t.integer "spm_without_children_and_fifty_five_plus__veteran"
    t.integer "spm_without_children_and_fifty_five_plus__has_disability"
    t.integer "spm_without_children_and_fifty_five_plus__has_rrh_move_in_date"
    t.integer "spm_without_children_and_fifty_five_plus__has_psh_move_in_date"
    t.integer "spm_without_children_and_fifty_five_plus__first_time_homeless"
    t.integer "spm_without_children_and_fifty_five_plus__returned_to_homelessn"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__all"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__white_"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__hispan"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__black_"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__asian"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__americ"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__native"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__multi_"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__fleein"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__vetera"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__has_di"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__has_rr"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__has_ps"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__first_"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__return"
    t.integer "spm_all_persons__white"
    t.integer "spm_all_persons__race_none"
    t.integer "spm_without_children__white"
    t.integer "spm_without_children__race_none"
    t.integer "spm_with_children__white"
    t.integer "spm_with_children__race_none"
    t.integer "spm_only_children__white"
    t.integer "spm_only_children__race_none"
    t.integer "spm_without_children_and_fifty_five_plus__white"
    t.integer "spm_without_children_and_fifty_five_plus__race_none"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__white"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__race_n"
    t.integer "spm_all_persons__non_hispanic_latino"
    t.integer "spm_all_persons__b_n_h_l"
    t.integer "spm_all_persons__a_n_h_l"
    t.integer "spm_all_persons__n_n_h_l"
    t.integer "spm_all_persons__h_n_h_l"
    t.integer "spm_without_children__non_hispanic_latino"
    t.integer "spm_without_children__b_n_h_l"
    t.integer "spm_without_children__a_n_h_l"
    t.integer "spm_without_children__n_n_h_l"
    t.integer "spm_without_children__h_n_h_l"
    t.integer "spm_with_children__non_hispanic_latino"
    t.integer "spm_with_children__b_n_h_l"
    t.integer "spm_with_children__a_n_h_l"
    t.integer "spm_with_children__n_n_h_l"
    t.integer "spm_with_children__h_n_h_l"
    t.integer "spm_only_children__non_hispanic_latino"
    t.integer "spm_only_children__b_n_h_l"
    t.integer "spm_only_children__a_n_h_l"
    t.integer "spm_only_children__n_n_h_l"
    t.integer "spm_only_children__h_n_h_l"
    t.integer "spm_without_children_and_fifty_five_plus__non_hispanic_latino"
    t.integer "spm_without_children_and_fifty_five_plus__b_n_h_l"
    t.integer "spm_without_children_and_fifty_five_plus__a_n_h_l"
    t.integer "spm_without_children_and_fifty_five_plus__n_n_h_l"
    t.integer "spm_without_children_and_fifty_five_plus__h_n_h_l"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__non_hi"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__b_n_h_"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__a_n_h_"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__n_n_h_"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__h_n_h_"
    t.integer "spm_all_persons__mid_east_n_african"
    t.integer "spm_all_persons__hispanic_latinaeo"
    t.integer "spm_without_children__mid_east_n_african"
    t.integer "spm_without_children__hispanic_latinaeo"
    t.integer "spm_with_children__mid_east_n_african"
    t.integer "spm_with_children__hispanic_latinaeo"
    t.integer "spm_only_children__mid_east_n_african"
    t.integer "spm_only_children__hispanic_latinaeo"
    t.integer "spm_without_children_and_fifty_five_plus__mid_east_n_african"
    t.integer "spm_without_children_and_fifty_five_plus__hispanic_latinaeo"
    t.integer "spm_adults_with_children_where_parenting_adult_18_to_24__mid_ea"
    t.integer "spm_all_persons__am_ind_ak_native"
    t.integer "spm_all_persons__am_ind_ak_native_hispanic_latinaeo"
    t.integer "spm_all_persons__asian_hispanic_latinaeo"
    t.integer "spm_all_persons__black_af_american"
    t.integer "spm_all_persons__black_af_american_hispanic_latinaeo"
    t.integer "spm_all_persons__mid_east_n_african_hispanic_latinaeo"
    t.integer "spm_all_persons__native_hi_pacific"
    t.integer "spm_all_persons__native_hi_pacific_hispanic_latinaeo"
    t.integer "spm_all_persons__white_hispanic_latinaeo"
    t.integer "spm_all_persons__multi_racial_hispanic_latinaeo"
    t.integer "spm_all_persons__returned"
    t.integer "spm_without_children__am_ind_ak_native"
    t.integer "spm_without_children__am_ind_ak_native_hispanic_latinaeo"
    t.integer "spm_without_children__asian_hispanic_latinaeo"
    t.integer "spm_without_children__black_af_american"
    t.integer "spm_without_children__black_af_american_hispanic_latinaeo"
    t.integer "spm_without_children__mid_east_n_african_hispanic_latinaeo"
    t.integer "spm_without_children__native_hi_pacific"
    t.integer "spm_without_children__native_hi_pacific_hispanic_latinaeo"
    t.integer "spm_without_children__white_hispanic_latinaeo"
    t.integer "spm_without_children__multi_racial_hispanic_latinaeo"
    t.integer "spm_without_children__returned"
    t.integer "spm_with_children__am_ind_ak_native"
    t.integer "spm_with_children__am_ind_ak_native_hispanic_latinaeo"
    t.integer "spm_with_children__asian_hispanic_latinaeo"
    t.integer "spm_with_children__black_af_american"
    t.integer "spm_with_children__black_af_american_hispanic_latinaeo"
    t.integer "spm_with_children__mid_east_n_african_hispanic_latinaeo"
    t.integer "spm_with_children__native_hi_pacific"
    t.integer "spm_with_children__native_hi_pacific_hispanic_latinaeo"
    t.integer "spm_with_children__white_hispanic_latinaeo"
    t.integer "spm_with_children__multi_racial_hispanic_latinaeo"
    t.integer "spm_with_children__returned"
    t.integer "spm_only_children__am_ind_ak_native"
    t.integer "spm_only_children__am_ind_ak_native_hispanic_latinaeo"
    t.integer "spm_only_children__asian_hispanic_latinaeo"
    t.integer "spm_only_children__black_af_american"
    t.integer "spm_only_children__black_af_american_hispanic_latinaeo"
    t.integer "spm_only_children__mid_east_n_african_hispanic_latinaeo"
    t.integer "spm_only_children__native_hi_pacific"
    t.integer "spm_only_children__native_hi_pacific_hispanic_latinaeo"
    t.integer "spm_only_children__white_hispanic_latinaeo"
    t.integer "spm_only_children__multi_racial_hispanic_latinaeo"
    t.integer "spm_only_children__returned"
    t.integer "spm_without_children_and_fifty_five_plus__am_ind_ak_native"
    t.integer "spm_nc_55__am_ind_ak_native_hispanic_latinaeo"
    t.integer "spm_nc_55__asian_hispanic_latinaeo"
    t.integer "spm_without_children_and_fifty_five_plus__black_af_american"
    t.integer "spm_nc_55__black_af_american_hispanic_latinaeo"
    t.integer "spm_nc_55__mid_east_n_african_hispanic_latinaeo"
    t.integer "spm_without_children_and_fifty_five_plus__native_hi_pacific"
    t.integer "spm_nc_55__native_hi_pacific_hispanic_latinaeo"
    t.integer "spm_nc_55__white_hispanic_latinaeo"
    t.integer "spm_nc_55__multi_racial_hispanic_latinaeo"
    t.integer "spm_nc_55__returned_to_homelessness_from_permanent_destination"
    t.integer "spm_wc_18_to_24__am_ind_ak_native"
    t.integer "spm_wc_18_to_24__am_ind_ak_native_hispanic_latinaeo"
    t.integer "spm_wc_18_to_24__asian_hispanic_latinaeo"
    t.integer "spm_wc_18_to_24__black_af_american"
    t.integer "spm_wc_18_to_24__black_af_american_hispanic_latinaeo"
    t.integer "spm_wc_18_to_24__hispanic_latinaeo"
    t.integer "spm_wc_18_to_24__mid_east_n_african"
    t.integer "spm_wc_18_to_24__mid_east_n_african_hispanic_latinaeo"
    t.integer "spm_wc_18_to_24__native_hi_pacific"
    t.integer "spm_wc_18_to_24__native_hi_pacific_hispanic_latinaeo"
    t.integer "spm_wc_18_to_24__white_hispanic_latinaeo"
    t.integer "spm_wc_18_to_24__multi_racial"
    t.integer "spm_wc_18_to_24__multi_racial_hispanic_latinaeo"
    t.integer "spm_wc_18_to_24__race_none"
    t.integer "spm_wc_18_to_24__fleeing_dv"
    t.integer "spm_wc_18_to_24__veteran"
    t.integer "spm_wc_18_to_24__has_disability"
    t.integer "spm_wc_18_to_24__has_rrh_move_in_date"
    t.integer "spm_wc_18_to_24__has_psh_move_in_date"
    t.integer "spm_wc_18_to_24__first_time_homeless"
    t.integer "spm_wc_18_to_24__returned"
    t.index ["client_id"], name: "index_homeless_summary_report_clients_on_client_id"
    t.index ["created_at"], name: "index_homeless_summary_report_clients_on_created_at"
    t.index ["deleted_at"], name: "index_homeless_summary_report_clients_on_deleted_at"
    t.index ["report_id"], name: "index_homeless_summary_report_clients_on_report_id"
    t.index ["updated_at"], name: "index_homeless_summary_report_clients_on_updated_at"
  end

  create_table "homeless_summary_report_results", force: :cascade do |t|
    t.bigint "report_id"
    t.string "section"
    t.string "household_category"
    t.string "demographic_category"
    t.string "field"
    t.string "destination"
    t.string "characteristic"
    t.string "calculation"
    t.float "value"
    t.string "format"
    t.jsonb "details"
    t.string "detail_link_slug"
    t.datetime "deleted_at", precision: nil
    t.index ["report_id"], name: "index_homeless_summary_report_results_on_report_id"
  end

  create_table "hopwa_caper_enrollments", force: :cascade do |t|
    t.bigint "report_instance_id", null: false
    t.bigint "destination_client_id", null: false
    t.bigint "enrollment_id", null: false
    t.string "report_household_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "personal_id", null: false
    t.integer "age"
    t.date "dob"
    t.integer "dob_quality"
    t.integer "genders", array: true
    t.integer "races", array: true
    t.boolean "veteran", default: false, null: false
    t.date "entry_date"
    t.date "exit_date"
    t.integer "relationship_to_hoh", null: false
    t.integer "project_funders", array: true
    t.string "project_type"
    t.string "income_benefit_source_types", array: true
    t.string "medical_insurance_types", array: true
    t.boolean "hiv_positive", default: false, null: false
    t.boolean "hopwa_eligible", default: false, null: false
    t.boolean "chronically_homeless", default: false, null: false
    t.integer "prior_living_situation"
    t.integer "rental_subsidy_type"
    t.integer "exit_destination"
    t.integer "housing_assessment_at_exit"
    t.integer "subsidy_information"
    t.boolean "ever_prescribed_anti_retroviral_therapy", default: false, null: false
    t.boolean "viral_load_suppression", default: false, null: false
    t.decimal "percent_ami"
    t.index ["destination_client_id"], name: "index_hopwa_caper_enrollments_on_destination_client_id"
    t.index ["report_household_id"], name: "index_hopwa_caper_enrollments_on_report_household_id"
    t.index ["report_instance_id", "enrollment_id"], name: "uidx_hopwa_caper_enrollments", unique: true
    t.index ["report_instance_id"], name: "index_hopwa_caper_enrollments_on_report_instance_id"
  end

  create_table "hopwa_caper_services", force: :cascade do |t|
    t.bigint "report_instance_id", null: false
    t.bigint "destination_client_id", null: false
    t.bigint "enrollment_id", null: false
    t.bigint "service_id", null: false
    t.string "report_household_id", null: false
    t.string "personal_id", null: false
    t.date "date_provided"
    t.integer "record_type"
    t.integer "type_provided"
    t.decimal "fa_amount"
    t.index ["destination_client_id"], name: "index_hopwa_caper_services_on_destination_client_id"
    t.index ["report_household_id"], name: "index_hopwa_caper_services_on_report_household_id"
    t.index ["report_instance_id", "service_id"], name: "uidx_hopwa_caper_services", unique: true
    t.index ["report_instance_id"], name: "index_hopwa_caper_services_on_report_instance_id"
  end

  create_table "housing_resolution_plans", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "user_id"
    t.string "pronouns"
    t.date "planned_on"
    t.string "staff_name"
    t.string "location"
    t.string "chosen_resolution"
    t.string "temporary_resolution"
    t.string "plan_description"
    t.string "action_steps"
    t.string "backup_plan"
    t.date "next_checkin"
    t.string "how_to_contact"
    t.string "psc_attempted"
    t.string "psc_why_not"
    t.string "resolution_achieved"
    t.string "resolution_why_not"
    t.string "problem_solving_point"
    t.jsonb "housing_crisis_causes"
    t.string "housing_crisis_cause_other"
    t.string "factor_employment_income"
    t.string "factor_family_supports"
    t.string "factor_social_supports"
    t.string "factor_life_skills"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["client_id"], name: "index_housing_resolution_plans_on_client_id"
    t.index ["user_id"], name: "index_housing_resolution_plans_on_user_id"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "days_in_last_three_years"
    t.index ["client_id"], name: "index_hud_chronics_on_client_id"
  end

  create_table "hud_create_logs", id: :serial, force: :cascade do |t|
    t.string "hud_key", null: false
    t.string "personal_id", null: false
    t.string "type", null: false
    t.datetime "imported_at", precision: nil, null: false
    t.date "effective_date", null: false
    t.integer "data_source_id", null: false
    t.index ["effective_date"], name: "index_hud_create_logs_on_effective_date"
    t.index ["imported_at"], name: "index_hud_create_logs_on_imported_at"
  end

  create_table "hud_lsa_summary_results", force: :cascade do |t|
    t.bigint "hud_report_instance_id"
    t.jsonb "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hud_report_instance_id"], name: "index_hud_lsa_summary_results_on_hud_report_instance_id"
  end

  create_table "hud_report_apr_ce_assessments", force: :cascade do |t|
    t.bigint "hud_report_apr_client_id"
    t.bigint "project_id"
    t.date "assessment_date"
    t.integer "assessment_level"
    t.datetime "deleted_at", precision: nil
    t.index ["hud_report_apr_client_id"], name: "index_hud_report_apr_ce_assessments_on_hud_report_apr_client_id"
    t.index ["project_id"], name: "index_hud_report_apr_ce_assessments_on_project_id"
  end

  create_table "hud_report_apr_ce_events", force: :cascade do |t|
    t.bigint "hud_report_apr_client_id"
    t.bigint "project_id"
    t.date "event_date"
    t.integer "event"
    t.integer "problem_sol_div_rr_result"
    t.integer "referral_case_manage_after"
    t.integer "referral_result"
    t.datetime "deleted_at", precision: nil
    t.index ["hud_report_apr_client_id"], name: "index_hud_report_apr_ce_events_on_hud_report_apr_client_id"
    t.index ["project_id"], name: "index_hud_report_apr_ce_events_on_project_id"
  end

  create_table "hud_report_apr_clients", force: :cascade do |t|
    t.integer "age"
    t.boolean "head_of_household"
    t.string "head_of_household_id"
    t.boolean "parenting_youth"
    t.date "first_date_in_program"
    t.date "last_date_in_program"
    t.integer "veteran_status"
    t.integer "length_of_stay"
    t.boolean "chronically_homeless"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "first_name"
    t.string "last_name"
    t.integer "name_quality"
    t.string "ssn"
    t.integer "ssn_quality"
    t.date "dob"
    t.integer "dob_quality"
    t.date "enrollment_created"
    t.integer "ethnicity"
    t.integer "gender"
    t.jsonb "overlapping_enrollments"
    t.integer "relationship_to_hoh"
    t.string "household_id"
    t.string "enrollment_coc"
    t.integer "disabling_condition"
    t.boolean "developmental_disability"
    t.boolean "hiv_aids"
    t.boolean "physical_disability"
    t.boolean "chronic_disability"
    t.boolean "mental_health_problem"
    t.boolean "substance_abuse"
    t.boolean "indefinite_and_impairs"
    t.integer "client_id"
    t.integer "data_source_id"
    t.integer "report_instance_id"
    t.integer "destination"
    t.date "income_date_at_start"
    t.integer "income_from_any_source_at_start"
    t.jsonb "income_sources_at_start"
    t.boolean "annual_assessment_expected"
    t.date "income_date_at_annual_assessment"
    t.integer "income_from_any_source_at_annual_assessment"
    t.jsonb "income_sources_at_annual_assessment"
    t.date "income_date_at_exit"
    t.integer "income_from_any_source_at_exit"
    t.jsonb "income_sources_at_exit"
    t.integer "project_type"
    t.integer "prior_living_situation"
    t.integer "prior_length_of_stay"
    t.date "date_homeless"
    t.integer "times_homeless"
    t.integer "months_homeless"
    t.integer "came_from_street_last_night"
    t.date "exit_created"
    t.integer "project_tracking_method"
    t.date "date_of_last_bed_night"
    t.boolean "other_clients_over_25"
    t.date "move_in_date"
    t.string "household_type"
    t.integer "race"
    t.integer "developmental_disability_entry"
    t.integer "hiv_aids_entry"
    t.integer "physical_disability_entry"
    t.integer "chronic_disability_entry"
    t.integer "mental_health_problem_entry"
    t.integer "substance_abuse_entry"
    t.boolean "alcohol_abuse_entry"
    t.boolean "drug_abuse_entry"
    t.integer "developmental_disability_exit"
    t.integer "hiv_aids_exit"
    t.integer "physical_disability_exit"
    t.integer "chronic_disability_exit"
    t.integer "mental_health_problem_exit"
    t.integer "substance_abuse_exit"
    t.boolean "alcohol_abuse_exit"
    t.boolean "drug_abuse_exit"
    t.integer "developmental_disability_latest"
    t.integer "hiv_aids_latest"
    t.integer "physical_disability_latest"
    t.integer "chronic_disability_latest"
    t.integer "mental_health_problem_latest"
    t.integer "substance_abuse_latest"
    t.boolean "alcohol_abuse_latest"
    t.boolean "drug_abuse_latest"
    t.integer "domestic_violence"
    t.integer "currently_fleeing"
    t.float "income_total_at_start"
    t.float "income_total_at_annual_assessment"
    t.float "income_total_at_exit"
    t.integer "non_cash_benefits_from_any_source_at_start"
    t.integer "non_cash_benefits_from_any_source_at_annual_assessment"
    t.integer "non_cash_benefits_from_any_source_at_exit"
    t.integer "insurance_from_any_source_at_start"
    t.integer "insurance_from_any_source_at_annual_assessment"
    t.integer "insurance_from_any_source_at_exit"
    t.integer "time_to_move_in"
    t.integer "approximate_length_of_stay"
    t.integer "approximate_time_to_move_in"
    t.date "date_to_street"
    t.integer "housing_assessment"
    t.integer "subsidy_information"
    t.date "date_of_engagement"
    t.jsonb "household_members"
    t.boolean "parenting_juvenile"
    t.datetime "deleted_at", precision: nil
    t.integer "destination_client_id"
    t.boolean "annual_assessment_in_window"
    t.string "chronically_homeless_detail"
    t.date "ce_assessment_date"
    t.integer "ce_assessment_type"
    t.integer "ce_assessment_prioritization_status"
    t.date "ce_event_date"
    t.integer "ce_event_event"
    t.integer "ce_event_problem_sol_div_rr_result"
    t.integer "ce_event_referral_case_manage_after"
    t.integer "ce_event_referral_result"
    t.string "gender_multi"
    t.integer "bed_nights"
    t.jsonb "pit_enrollments", default: []
    t.integer "source_enrollment_id"
    t.integer "los_under_threshold"
    t.integer "project_id"
    t.datetime "client_created_at", precision: nil
    t.string "personal_id"
    t.string "race_multi"
    t.integer "exit_destination_subsidy_type"
    t.integer "domestic_violence_occurred"
    t.integer "translation_needed"
    t.integer "preferred_language"
    t.string "preferred_language_different"
    t.integer "sexual_orientation"
    t.integer "move_on_assistance_provided"
    t.integer "current_school_attend_at_entry"
    t.integer "most_recent_ed_status_at_entry"
    t.integer "current_ed_status_at_entry"
    t.integer "current_school_attend_at_exit"
    t.integer "most_recent_ed_status_at_exit"
    t.integer "current_ed_status_at_exit"
    t.boolean "pay_for_success", default: false
    t.jsonb "race_multi_include_race_none"
    t.date "hoh_move_in_date"
    t.date "adjusted_move_in_date"
    t.index ["client_id", "data_source_id", "report_instance_id"], name: "apr_client_conflict_columns", unique: true
  end

  create_table "hud_report_apr_living_situations", force: :cascade do |t|
    t.bigint "hud_report_apr_client_id"
    t.date "information_date"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "living_situation"
    t.datetime "deleted_at", precision: nil
    t.index ["hud_report_apr_client_id"], name: "index_hud_apr_client_liv_sit"
  end

  create_table "hud_report_cells", force: :cascade do |t|
    t.bigint "report_instance_id"
    t.string "question", null: false
    t.string "cell_name"
    t.boolean "universe", default: false
    t.json "metadata"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.json "summary"
    t.string "status"
    t.text "error_messages"
    t.datetime "deleted_at", precision: nil
    t.boolean "any_members", default: false, null: false
    t.index ["report_instance_id"], name: "index_hud_report_cells_on_report_instance_id"
  end

  create_table "hud_report_dq_clients", force: :cascade do |t|
    t.integer "client_id"
    t.integer "data_source_id"
    t.integer "report_instance_id"
    t.integer "destination_client_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "age"
    t.boolean "alcohol_abuse_entry"
    t.boolean "alcohol_abuse_exit"
    t.boolean "alcohol_abuse_latest"
    t.boolean "annual_assessment_expected"
    t.integer "approximate_length_of_stay"
    t.integer "approximate_time_to_move_in"
    t.integer "came_from_street_last_night"
    t.boolean "chronic_disability"
    t.integer "chronic_disability_entry"
    t.integer "chronic_disability_exit"
    t.integer "chronic_disability_latest"
    t.boolean "chronically_homeless"
    t.integer "currently_fleeing"
    t.date "date_homeless"
    t.date "date_of_engagement"
    t.date "date_of_last_bed_night"
    t.date "date_to_street"
    t.integer "destination"
    t.boolean "developmental_disability"
    t.integer "developmental_disability_entry"
    t.integer "developmental_disability_exit"
    t.integer "developmental_disability_latest"
    t.integer "disabling_condition"
    t.date "dob"
    t.integer "dob_quality"
    t.integer "domestic_violence"
    t.boolean "drug_abuse_entry"
    t.boolean "drug_abuse_exit"
    t.boolean "drug_abuse_latest"
    t.string "enrollment_coc"
    t.date "enrollment_created"
    t.integer "ethnicity"
    t.date "exit_created"
    t.date "first_date_in_program"
    t.string "first_name"
    t.integer "gender"
    t.boolean "head_of_household"
    t.string "head_of_household_id"
    t.boolean "hiv_aids"
    t.integer "hiv_aids_entry"
    t.integer "hiv_aids_exit"
    t.integer "hiv_aids_latest"
    t.string "household_id"
    t.jsonb "household_members"
    t.string "household_type"
    t.integer "housing_assessment"
    t.date "income_date_at_annual_assessment"
    t.date "income_date_at_exit"
    t.date "income_date_at_start"
    t.integer "income_from_any_source_at_annual_assessment"
    t.integer "income_from_any_source_at_exit"
    t.integer "income_from_any_source_at_start"
    t.jsonb "income_sources_at_annual_assessment"
    t.jsonb "income_sources_at_exit"
    t.jsonb "income_sources_at_start"
    t.integer "income_total_at_annual_assessment"
    t.integer "income_total_at_exit"
    t.integer "income_total_at_start"
    t.boolean "indefinite_and_impairs"
    t.integer "insurance_from_any_source_at_annual_assessment"
    t.integer "insurance_from_any_source_at_exit"
    t.integer "insurance_from_any_source_at_start"
    t.date "last_date_in_program"
    t.string "last_name"
    t.integer "length_of_stay"
    t.boolean "mental_health_problem"
    t.integer "mental_health_problem_entry"
    t.integer "mental_health_problem_exit"
    t.integer "mental_health_problem_latest"
    t.integer "months_homeless"
    t.date "move_in_date"
    t.integer "name_quality"
    t.integer "non_cash_benefits_from_any_source_at_annual_assessment"
    t.integer "non_cash_benefits_from_any_source_at_exit"
    t.integer "non_cash_benefits_from_any_source_at_start"
    t.boolean "other_clients_over_25"
    t.jsonb "overlapping_enrollments"
    t.boolean "parenting_juvenil"
    t.boolean "parenting_youth"
    t.boolean "physical_disability"
    t.integer "physical_disability_entry"
    t.integer "physical_disability_exit"
    t.integer "physical_disability_latest"
    t.integer "prior_length_of_stay"
    t.integer "prior_living_situation"
    t.integer "project_tracking_method"
    t.integer "project_type"
    t.integer "race"
    t.integer "relationship_to_hoh"
    t.string "ssn"
    t.integer "ssn_quality"
    t.integer "subsidy_information"
    t.boolean "substance_abuse"
    t.integer "substance_abuse_entry"
    t.integer "substance_abuse_exit"
    t.integer "substance_abuse_latest"
    t.integer "time_to_move_in"
    t.integer "times_homeless"
    t.integer "veteran_status"
    t.boolean "annual_assessment_in_window"
    t.string "gender_multi"
    t.string "personal_id"
    t.index ["client_id", "data_source_id", "report_instance_id"], name: "dq_client_conflict_columns", unique: true
  end

  create_table "hud_report_dq_living_situations", force: :cascade do |t|
    t.bigint "hud_report_dq_client_id"
    t.integer "living_situation"
    t.date "information_date"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["hud_report_dq_client_id"], name: "index_hud_dq_client_liv_sit"
  end

  create_table "hud_report_hic_funders", force: :cascade do |t|
    t.string "FunderID"
    t.string "ProjectID"
    t.integer "Funder"
    t.string "OtherFunder"
    t.string "GrantID"
    t.date "StartDate"
    t.date "EndDate"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "report_instance_id", null: false
    t.integer "data_source_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["FunderID", "data_source_id", "report_instance_id"], name: "hud_report_hic_funders_uniqueness_constraint", unique: true
    t.index ["data_source_id"], name: "index_hud_report_hic_funders_on_data_source_id"
    t.index ["report_instance_id"], name: "index_hud_report_hic_funders_on_report_instance_id"
  end

  create_table "hud_report_hic_inventories", force: :cascade do |t|
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "report_instance_id", null: false
    t.integer "data_source_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["InventoryID", "data_source_id", "report_instance_id"], name: "hud_report_hic_inventories_uniqueness_constraint", unique: true
    t.index ["data_source_id"], name: "index_hud_report_hic_inventories_on_data_source_id"
    t.index ["report_instance_id"], name: "index_hud_report_hic_inventories_on_report_instance_id"
  end

  create_table "hud_report_hic_organizations", force: :cascade do |t|
    t.string "OrganizationID"
    t.string "OrganizationName"
    t.integer "VictimServiceProvider"
    t.string "OrganizationCommonName"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "report_instance_id", null: false
    t.integer "data_source_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["OrganizationID", "data_source_id", "report_instance_id"], name: "hud_report_hic_organizations_uniqueness_constraint", unique: true
    t.index ["data_source_id"], name: "index_hud_report_hic_organizations_on_data_source_id"
    t.index ["report_instance_id"], name: "index_hud_report_hic_organizations_on_report_instance_id"
  end

  create_table "hud_report_hic_project_cocs", force: :cascade do |t|
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "report_instance_id", null: false
    t.integer "data_source_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["ProjectCoCID", "data_source_id", "report_instance_id"], name: "hud_report_hic_project_cocs_uniqueness_constraint", unique: true
    t.index ["data_source_id"], name: "index_hud_report_hic_project_cocs_on_data_source_id"
    t.index ["report_instance_id"], name: "index_hud_report_hic_project_cocs_on_report_instance_id"
  end

  create_table "hud_report_hic_projects", force: :cascade do |t|
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
    t.integer "HOPWAMedAssistedLivingFac"
    t.integer "PITCount"
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID"
    t.datetime "DateDeleted", precision: nil
    t.string "ExportID"
    t.integer "report_instance_id", null: false
    t.integer "data_source_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["ProjectID", "data_source_id", "report_instance_id"], name: "hud_report_hic_projects_uniqueness_constraint", unique: true
    t.index ["data_source_id"], name: "index_hud_report_hic_projects_on_data_source_id"
    t.index ["report_instance_id"], name: "index_hud_report_hic_projects_on_report_instance_id"
  end

  create_table "hud_report_instances", force: :cascade do |t|
    t.bigint "user_id"
    t.string "coc_code"
    t.string "report_name"
    t.date "start_date"
    t.date "end_date"
    t.json "options"
    t.string "state"
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.json "project_ids"
    t.json "question_names", null: false
    t.binary "zip_file"
    t.datetime "deleted_at", precision: nil
    t.jsonb "build_for_questions"
    t.jsonb "remaining_questions"
    t.jsonb "coc_codes"
    t.boolean "manual", default: true, null: false
    t.datetime "failed_at", precision: nil
    t.float "percent_complete"
    t.bigint "export_id"
    t.string "type", default: "HudReports::ReportInstance", null: false
    t.text "error_details"
    t.index ["export_id"], name: "index_hud_report_instances_on_export_id"
    t.index ["user_id"], name: "index_hud_report_instances_on_user_id"
  end

  create_table "hud_report_path_clients", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "data_source_id"
    t.bigint "report_instance_id"
    t.string "first_name"
    t.string "last_name"
    t.integer "age"
    t.date "dob"
    t.integer "dob_quality"
    t.integer "gender"
    t.integer "am_ind_ak_native"
    t.integer "asian"
    t.integer "black_af_american"
    t.integer "native_hi_other_pacific"
    t.integer "white"
    t.integer "race_none"
    t.integer "ethnicity"
    t.integer "veteran"
    t.integer "substance_use_disorder"
    t.integer "soar"
    t.integer "prior_living_situation"
    t.integer "length_of_stay"
    t.string "chronically_homeless"
    t.integer "domestic_violence"
    t.boolean "active_client"
    t.boolean "new_client"
    t.boolean "enrolled_client"
    t.date "date_of_determination"
    t.integer "reason_not_enrolled"
    t.integer "project_type"
    t.date "first_date_in_program"
    t.date "last_date_in_program"
    t.date "contacts", array: true
    t.jsonb "services"
    t.jsonb "referrals"
    t.integer "income_from_any_source_entry"
    t.jsonb "incomes_at_entry"
    t.integer "income_from_any_source_exit"
    t.jsonb "incomes_at_exit"
    t.integer "income_from_any_source_report_end"
    t.jsonb "incomes_at_report_end"
    t.integer "benefits_from_any_source_entry"
    t.integer "benefits_from_any_source_exit"
    t.integer "benefits_from_any_source_report_end"
    t.integer "insurance_from_any_source_entry"
    t.integer "insurance_from_any_source_exit"
    t.integer "insurance_from_any_source_report_end"
    t.integer "destination"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "gender_multi"
    t.integer "destination_client_id"
    t.string "personal_id"
    t.string "race_multi"
    t.boolean "newly_enrolled_client", default: false
    t.boolean "cmh_service_provided", default: false, null: false
    t.boolean "cmh_referral_provided_and_attained", default: false, null: false
    t.index ["client_id"], name: "index_hud_report_path_clients_on_client_id"
    t.index ["data_source_id"], name: "index_hud_report_path_clients_on_data_source_id"
    t.index ["incomes_at_entry"], name: "index_hud_report_path_clients_on_incomes_at_entry", using: :gin
    t.index ["incomes_at_exit"], name: "index_hud_report_path_clients_on_incomes_at_exit", using: :gin
    t.index ["incomes_at_report_end"], name: "index_hud_report_path_clients_on_incomes_at_report_end", using: :gin
    t.index ["referrals"], name: "index_hud_report_path_clients_on_referrals", using: :gin
    t.index ["report_instance_id", "data_source_id", "client_id"], name: "hud_path_client_conflict_columns", unique: true
    t.index ["report_instance_id"], name: "index_hud_report_path_clients_on_report_instance_id"
    t.index ["services"], name: "index_hud_report_path_clients_on_services", using: :gin
  end

  create_table "hud_report_pit_clients", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "data_source_id"
    t.bigint "report_instance_id"
    t.string "first_name"
    t.string "last_name"
    t.integer "destination_client_id"
    t.integer "age"
    t.date "dob"
    t.string "household_type"
    t.integer "max_age"
    t.boolean "hoh_veteran"
    t.boolean "head_of_household"
    t.integer "relationship_to_hoh"
    t.integer "female"
    t.integer "male"
    t.integer "no_single_gender"
    t.integer "transgender"
    t.integer "questioning"
    t.integer "gender_none"
    t.string "pit_gender"
    t.integer "am_ind_ak_native"
    t.integer "asian"
    t.integer "black_af_american"
    t.integer "native_hi_other_pacific"
    t.integer "white"
    t.integer "race_none"
    t.string "pit_race"
    t.integer "ethnicity"
    t.integer "veteran"
    t.boolean "chronically_homeless"
    t.boolean "chronically_homeless_household"
    t.integer "substance_use"
    t.integer "substance_use_indefinite_impairing"
    t.integer "domestic_violence"
    t.integer "domestic_violence_currently_fleeing"
    t.integer "hiv_aids"
    t.integer "hiv_aids_indefinite_impairing"
    t.integer "mental_illness"
    t.integer "mental_illness_indefinite_impairing"
    t.integer "project_id"
    t.integer "project_type"
    t.string "project_name"
    t.integer "project_hmis_pit_count"
    t.date "entry_date"
    t.date "exit_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.string "personal_id"
    t.integer "hoh_age"
    t.integer "household_member_count"
    t.integer "culturally_specific"
    t.integer "different_identity"
    t.integer "non_binary"
    t.boolean "more_than_one_gender"
    t.integer "mid_east_n_african"
    t.index ["client_id"], name: "index_hud_report_pit_clients_on_client_id"
    t.index ["data_source_id"], name: "index_hud_report_pit_clients_on_data_source_id"
    t.index ["report_instance_id", "data_source_id", "client_id"], name: "hud_pit_client_conflict_columns", unique: true
    t.index ["report_instance_id"], name: "index_hud_report_pit_clients_on_report_instance_id"
  end

  create_table "hud_report_spm_bed_nights", force: :cascade do |t|
    t.date "date"
    t.bigint "episode_id"
    t.bigint "service_id"
    t.bigint "enrollment_id"
    t.bigint "client_id"
    t.index ["client_id"], name: "index_hud_report_spm_bed_nights_on_client_id"
    t.index ["enrollment_id"], name: "index_hud_report_spm_bed_nights_on_enrollment_id"
    t.index ["episode_id"], name: "index_hud_report_spm_bed_nights_on_episode_id"
    t.index ["service_id"], name: "index_hud_report_spm_bed_nights_on_service_id"
  end

  create_table "hud_report_spm_clients", force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "data_source_id", null: false
    t.integer "report_instance_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.date "dob"
    t.string "first_name"
    t.string "last_name"
    t.integer "m1a_es_sh_days"
    t.integer "m1a_es_sh_th_days"
    t.integer "m1b_es_sh_ph_days"
    t.integer "m1b_es_sh_th_ph_days"
    t.jsonb "m1_history"
    t.integer "m2_exit_from_project_type"
    t.integer "m2_exit_to_destination"
    t.integer "m2_reentry_days"
    t.jsonb "m2_history"
    t.integer "m3_active_project_types", array: true
    t.boolean "m4_stayer"
    t.decimal "m4_latest_income"
    t.decimal "m4_latest_earned_income"
    t.decimal "m4_latest_non_earned_income"
    t.decimal "m4_earliest_income"
    t.decimal "m4_earliest_earned_income"
    t.decimal "m4_earliest_non_earned_income"
    t.jsonb "m4_history"
    t.integer "m5_active_project_types", array: true
    t.integer "m5_recent_project_types", array: true
    t.jsonb "m5_history"
    t.integer "m6_exit_from_project_type"
    t.integer "m6_exit_to_destination"
    t.integer "m6_reentry_days"
    t.integer "m6c1_destination"
    t.integer "m6c2_destination"
    t.jsonb "m6_history"
    t.integer "m7a1_destination"
    t.integer "m7b1_destination"
    t.integer "m7b2_destination"
    t.jsonb "m7_history"
    t.jsonb "m3_history"
    t.boolean "veteran", default: false, null: false
    t.boolean "m1_head_of_household", default: false, null: false
    t.integer "m1_reporting_age"
    t.boolean "m2_head_of_household", default: false, null: false
    t.integer "m2_reporting_age"
    t.boolean "m3_head_of_household", default: false, null: false
    t.integer "m3_reporting_age"
    t.boolean "m4_head_of_household", default: false, null: false
    t.integer "m4_reporting_age"
    t.boolean "m5_head_of_household", default: false, null: false
    t.integer "m5_reporting_age"
    t.boolean "m6_head_of_household", default: false, null: false
    t.integer "m6_reporting_age"
    t.boolean "m7_head_of_household", default: false, null: false
    t.integer "m7_reporting_age"
    t.jsonb "m7b_history"
    t.integer "m2_project_id"
    t.integer "m3_project_id"
    t.integer "m4_project_id"
    t.integer "m5_project_id"
    t.integer "m7a1_project_id"
    t.integer "m7b_project_id"
    t.string "personal_id"
    t.string "data_lab_public_id"
    t.string "source_client_personal_ids"
    t.index ["report_instance_id", "client_id", "data_source_id"], name: "spm_client_conflict_columns", unique: true
  end

  create_table "hud_report_spm_enrollment_links", force: :cascade do |t|
    t.bigint "enrollment_id"
    t.bigint "episode_id"
    t.index ["enrollment_id"], name: "index_hud_report_spm_enrollment_links_on_enrollment_id"
    t.index ["episode_id"], name: "index_hud_report_spm_enrollment_links_on_episode_id"
  end

  create_table "hud_report_spm_enrollments", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "personal_id"
    t.integer "data_source_id"
    t.date "start_of_homelessness"
    t.date "entry_date"
    t.date "exit_date"
    t.date "move_in_date"
    t.integer "project_type"
    t.boolean "eligible_funding"
    t.integer "prior_living_situation"
    t.integer "length_of_stay"
    t.boolean "los_under_threshold"
    t.boolean "previous_street_essh"
    t.integer "destination"
    t.integer "age"
    t.decimal "previous_earned_income"
    t.decimal "previous_non_employment_income"
    t.decimal "previous_total_income"
    t.decimal "current_earned_income"
    t.decimal "current_non_employment_income"
    t.decimal "current_total_income"
    t.bigint "report_instance_id"
    t.bigint "client_id"
    t.bigint "previous_income_benefits_id"
    t.bigint "current_income_benefits_id"
    t.bigint "enrollment_id"
    t.integer "days_enrolled"
    t.index ["client_id"], name: "index_hud_report_spm_enrollments_on_client_id"
    t.index ["enrollment_id"], name: "index_hud_report_spm_enrollments_on_enrollment_id"
    t.index ["personal_id", "data_source_id"], name: "spm_p_id_ds_id"
    t.index ["report_instance_id"], name: "index_hud_report_spm_enrollments_on_report_instance_id"
  end

  create_table "hud_report_spm_episodes", force: :cascade do |t|
    t.date "first_date"
    t.date "last_date"
    t.integer "days_homeless"
    t.boolean "literally_homeless_at_entry"
    t.bigint "client_id"
    t.index ["client_id"], name: "index_hud_report_spm_episodes_on_client_id"
  end

  create_table "hud_report_spm_returns", force: :cascade do |t|
    t.date "exit_date"
    t.date "return_date"
    t.integer "exit_destination"
    t.bigint "exit_enrollment_id"
    t.bigint "return_enrollment_id"
    t.bigint "client_id"
    t.bigint "report_instance_id"
    t.integer "days_to_return"
    t.integer "project_type"
    t.index ["client_id"], name: "index_hud_report_spm_returns_on_client_id"
    t.index ["exit_enrollment_id"], name: "index_hud_report_spm_returns_on_exit_enrollment_id"
    t.index ["report_instance_id"], name: "index_hud_report_spm_returns_on_report_instance_id"
    t.index ["return_enrollment_id"], name: "index_hud_report_spm_returns_on_return_enrollment_id"
  end

  create_table "hud_report_universe_members", force: :cascade do |t|
    t.bigint "report_cell_id"
    t.string "universe_membership_type"
    t.bigint "universe_membership_id"
    t.bigint "client_id"
    t.string "first_name"
    t.string "last_name"
    t.datetime "deleted_at", precision: nil
    t.index ["client_id"], name: "index_hud_report_universe_members_on_client_id"
    t.index ["report_cell_id", "universe_membership_id", "universe_membership_type"], name: "uniq_hud_report_universe_members", unique: true, where: "(deleted_at IS NULL)"
    t.index ["report_cell_id"], name: "index_hud_report_universe_members_on_report_cell_id", where: "(deleted_at IS NULL)"
    t.index ["universe_membership_type", "universe_membership_id"], name: "index_universe_type_and_id"
  end

  create_table "identify_duplicates_log", id: :serial, force: :cascade do |t|
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.integer "to_match"
    t.integer "matched"
    t.integer "new_created"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "import_logs", id: :serial, force: :cascade do |t|
    t.integer "data_source_id"
    t.string "files"
    t.text "import_errors"
    t.string "summary"
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "zip"
    t.integer "upload_id"
    t.text "encrypted_import_errors"
    t.string "encrypted_import_errors_iv"
    t.string "type", default: "GrdaWarehouse::ImportLog"
    t.bigint "loader_log_id"
    t.bigint "importer_log_id"
    t.index ["completed_at"], name: "index_import_logs_on_completed_at"
    t.index ["created_at"], name: "index_import_logs_on_created_at"
    t.index ["data_source_id"], name: "index_import_logs_on_data_source_id"
    t.index ["importer_log_id"], name: "index_import_logs_on_importer_log_id"
    t.index ["loader_log_id"], name: "index_import_logs_on_loader_log_id"
    t.index ["updated_at"], name: "index_import_logs_on_updated_at"
  end

  create_table "import_overrides", force: :cascade do |t|
    t.string "file_name", null: false
    t.string "matched_hud_key"
    t.string "replaces_column", null: false
    t.string "replaces_value"
    t.string "replacement_value", null: false
    t.bigint "data_source_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.string "description"
    t.index "data_source_id, file_name, replaces_column, COALESCE(matched_hud_key, 'ALL'::character varying), COALESCE(replaces_value, 'ALL'::character varying)", name: "uidx_import_overrides_rules", unique: true, where: "(deleted_at IS NULL)"
    t.index ["data_source_id"], name: "index_import_overrides_on_data_source_id"
  end

  create_table "inbound_api_configurations", force: :cascade do |t|
    t.string "external_system_name", null: false
    t.string "hashed_api_key", null: false
    t.string "plain_text_reminder", null: false
    t.integer "version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "internal_system_id"
    t.index ["hashed_api_key"], name: "index_inbound_api_configurations_on_hashed_api_key", unique: true
    t.index ["internal_system_id", "external_system_name", "version"], name: "idx_inbound_api_configurations_uniq", unique: true
    t.index ["internal_system_id"], name: "index_inbound_api_configurations_on_internal_system_id"
    t.index ["plain_text_reminder"], name: "index_inbound_api_configurations_on_plain_text_reminder"
  end

  create_table "income_benefits_report_clients", force: :cascade do |t|
    t.bigint "report_id", null: false
    t.bigint "client_id", null: false
    t.string "date_range", null: false
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.integer "ethnicity"
    t.string "race"
    t.date "dob"
    t.integer "age"
    t.integer "gender"
    t.string "household_id"
    t.boolean "head_of_household"
    t.bigint "enrollment_id", null: false
    t.date "entry_date"
    t.date "exit_date"
    t.date "move_in_date"
    t.string "project_name"
    t.bigint "project_id"
    t.bigint "earlier_income_record_id"
    t.bigint "later_income_record_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["client_id"], name: "index_income_benefits_report_clients_on_client_id"
    t.index ["created_at"], name: "index_income_benefits_report_clients_on_created_at"
    t.index ["earlier_income_record_id"], name: "index_income_benefits_report_clients_earlier"
    t.index ["enrollment_id"], name: "index_income_benefits_report_clients_on_enrollment_id"
    t.index ["later_income_record_id"], name: "index_income_benefits_report_clients_later"
    t.index ["project_id"], name: "index_income_benefits_report_clients_on_project_id"
    t.index ["report_id"], name: "index_income_benefits_report_clients_on_report_id"
    t.index ["updated_at"], name: "index_income_benefits_report_clients_on_updated_at"
  end

  create_table "income_benefits_report_incomes", force: :cascade do |t|
    t.bigint "report_id", null: false
    t.bigint "client_id", null: false
    t.bigint "income_benefits_id", null: false
    t.string "stage", null: false
    t.string "date_range", null: false
    t.date "InformationDate", null: false
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
    t.index ["Earned"], name: "index_income_benefits_report_incomes_on_Earned"
    t.index ["IncomeFromAnySource"], name: "index_income_benefits_report_incomes_on_IncomeFromAnySource"
    t.index ["client_id"], name: "index_income_benefits_report_incomes_on_client_id"
    t.index ["income_benefits_id"], name: "index_income_benefits_report_incomes_on_income_benefits_id"
    t.index ["report_id"], name: "index_income_benefits_report_incomes_on_report_id"
  end

  create_table "income_benefits_reports", force: :cascade do |t|
    t.bigint "user_id"
    t.jsonb "options"
    t.string "report_date_range", null: false
    t.string "comparison_date_range", null: false
    t.string "processing_errors"
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["created_at"], name: "index_income_benefits_reports_on_created_at"
    t.index ["deleted_at"], name: "index_income_benefits_reports_on_deleted_at"
    t.index ["updated_at"], name: "index_income_benefits_reports_on_updated_at"
    t.index ["user_id"], name: "index_income_benefits_reports_on_user_id"
  end

  create_table "internal_systems", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: true, null: false
    t.string "auth_type", default: "apikey", null: false
    t.index ["name"], name: "index_internal_systems_on_name", unique: true
  end

  create_table "involved_in_imports", force: :cascade do |t|
    t.bigint "importer_log_id"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.string "hud_key", null: false
    t.enum "record_action", enum_type: "record_action"
    t.index ["hud_key", "importer_log_id", "record_type", "record_action"], name: "involved_in_imports_by_hud_key", unique: true
    t.index ["importer_log_id", "record_type", "record_action"], name: "involved_in_imports_by_importer_log"
    t.index ["importer_log_id"], name: "index_involved_in_imports_on_importer_log_id"
    t.index ["record_id", "importer_log_id", "record_type", "record_action"], name: "involved_in_imports_by_id", unique: true
  end

  create_table "lftp_s3_syncs", force: :cascade do |t|
    t.bigint "data_source_id", null: false
    t.string "ftp_host", null: false
    t.string "ftp_user", null: false
    t.string "encrypted_ftp_pass", null: false
    t.string "encrypted_ftp_pass_iv", null: false
    t.string "ftp_path", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["created_at"], name: "index_lftp_s3_syncs_on_created_at"
    t.index ["data_source_id"], name: "index_lftp_s3_syncs_on_data_source_id"
    t.index ["updated_at"], name: "index_lftp_s3_syncs_on_updated_at"
  end

  create_table "longitudinal_spm_results", force: :cascade do |t|
    t.bigint "report_id", null: false
    t.bigint "spm_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.string "measure"
    t.string "table"
    t.string "cell"
    t.float "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["report_id"], name: "index_longitudinal_spm_results_on_report_id"
    t.index ["spm_id"], name: "index_longitudinal_spm_results_on_spm_id"
  end

  create_table "longitudinal_spm_spms", force: :cascade do |t|
    t.bigint "report_id", null: false
    t.bigint "spm_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["report_id"], name: "index_longitudinal_spm_spms_on_report_id"
    t.index ["spm_id"], name: "index_longitudinal_spm_spms_on_spm_id"
  end

  create_table "longitudinal_spms", force: :cascade do |t|
    t.bigint "user_id"
    t.jsonb "options"
    t.string "processing_errors"
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["user_id"], name: "index_longitudinal_spms_on_user_id"
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

  create_table "lsa_rds_state_logs", force: :cascade do |t|
    t.string "state"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "ma_monthly_performance_enrollments", force: :cascade do |t|
    t.bigint "report_id"
    t.bigint "client_id"
    t.bigint "enrollment_id"
    t.bigint "project_id"
    t.bigint "project_coc_id"
    t.string "personal_id"
    t.string "city"
    t.string "coc_code"
    t.date "entry_date", null: false
    t.date "exit_date"
    t.boolean "latest_for_client"
    t.boolean "chronically_homeless_at_entry"
    t.integer "stay_length_in_days"
    t.boolean "am_ind_ak_native"
    t.boolean "asian"
    t.boolean "black_af_american"
    t.boolean "native_hi_pacific"
    t.boolean "ethnicity"
    t.boolean "white"
    t.boolean "male"
    t.boolean "female"
    t.boolean "gender_other"
    t.boolean "transgender"
    t.boolean "questioning"
    t.boolean "no_single_gender"
    t.boolean "disabling_condition"
    t.integer "reporting_age"
    t.integer "relationship_to_hoh"
    t.string "household_id"
    t.string "household_type"
    t.jsonb "household_members"
    t.integer "prior_living_situation"
    t.integer "months_homeless_past_three_years"
    t.integer "times_homeless_past_three_years"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.string "first_name"
    t.string "last_name"
    t.boolean "woman"
    t.boolean "man"
    t.boolean "culturally_specific"
    t.boolean "different_identity"
    t.boolean "non_binary"
    t.boolean "hispanic_latinaeo"
    t.boolean "mid_east_n_african"
    t.index ["client_id"], name: "index_ma_monthly_performance_enrollments_on_client_id"
    t.index ["enrollment_id"], name: "index_ma_monthly_performance_enrollments_on_enrollment_id"
    t.index ["project_coc_id"], name: "index_ma_monthly_performance_enrollments_on_project_coc_id"
    t.index ["project_id"], name: "index_ma_monthly_performance_enrollments_on_project_id"
    t.index ["report_id"], name: "index_ma_monthly_performance_enrollments_on_report_id"
  end

  create_table "ma_monthly_performance_projects", force: :cascade do |t|
    t.bigint "report_id"
    t.bigint "project_id"
    t.bigint "project_coc_id"
    t.string "project_name"
    t.string "organization_name"
    t.string "coc_code"
    t.date "month_start"
    t.integer "available_beds"
    t.integer "average_length_of_stay_in_days"
    t.integer "number_chronically_homeless_at_entry"
    t.string "city"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.integer "enrolled_client_count"
    t.index ["project_coc_id"], name: "index_ma_monthly_performance_projects_on_project_coc_id"
    t.index ["project_id"], name: "index_ma_monthly_performance_projects_on_project_id"
    t.index ["report_id"], name: "index_ma_monthly_performance_projects_on_report_id"
  end

  create_table "ma_yya_report_clients", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "service_history_enrollment_id"
    t.date "entry_date"
    t.integer "referral_source"
    t.boolean "currently_homeless"
    t.boolean "at_risk_of_homelessness"
    t.boolean "initial_contact"
    t.boolean "direct_assistance"
    t.integer "current_school_attendance"
    t.integer "current_educational_status"
    t.integer "age"
    t.integer "gender"
    t.integer "race"
    t.integer "ethnicity"
    t.boolean "mental_health_disorder"
    t.boolean "substance_use_disorder"
    t.boolean "physical_disability"
    t.boolean "developmental_disability"
    t.boolean "pregnant"
    t.date "due_date"
    t.boolean "head_of_household"
    t.jsonb "household_ages"
    t.integer "sexual_orientation"
    t.integer "most_recent_education_status"
    t.boolean "health_insurance"
    t.jsonb "subsequent_current_living_situations"
    t.boolean "reported_previous_period"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "education_status_date"
    t.date "rehoused_on"
    t.jsonb "flex_funds", default: []
    t.jsonb "zip_codes", default: []
    t.string "language"
    t.boolean "followup_previous_period"
    t.index ["client_id"], name: "index_ma_yya_report_clients_on_client_id"
    t.index ["service_history_enrollment_id"], name: "index_ma_yya_report_clients_on_service_history_enrollment_id"
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

  create_table "nightly_census_by_projects", force: :cascade do |t|
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "juveniles", default: 0
    t.integer "unaccompanied_minors", default: 0
    t.integer "youth_families", default: 0
    t.integer "family_parents", default: 0
    t.index ["date"], name: "index_nightly_census_by_projects_on_date"
    t.index ["project_id"], name: "index_nightly_census_by_projects_on_project_id"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_non_hmis_uploads_on_deleted_at"
  end

  create_table "organization_47_tes", id: false, force: :cascade do |t|
    t.integer "source_id"
  end

  create_table "organization_48_tes", id: false, force: :cascade do |t|
    t.integer "source_id"
  end

  create_table "organization_49_tes", id: false, force: :cascade do |t|
    t.integer "source_id"
  end

  create_table "performance_measurement_goals", force: :cascade do |t|
    t.string "coc_code", null: false
    t.integer "people", default: 3, null: false
    t.integer "capacity", default: 90, null: false
    t.integer "time_time", default: 90, null: false
    t.integer "time_stay", default: 60, null: false
    t.integer "time_move_in", default: 30, null: false
    t.integer "destination", default: 85, null: false
    t.integer "recidivism_6_months", default: 15, null: false
    t.integer "recidivism_24_months", default: 25, null: false
    t.integer "income", default: 3, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "always_run_for_coc", default: false
    t.integer "recidivism_12_months", default: 20, null: false
    t.boolean "active", default: true, null: false
    t.string "label"
    t.integer "destination_so", default: 85, null: false
    t.integer "destination_homeless_plus", default: 85, null: false
    t.integer "destination_permanent", default: 85, null: false
    t.integer "time_time_homeless_and_ph", default: 90, null: false
    t.boolean "equity_analysis_visible", default: false, null: false
  end

  create_table "performance_metrics_clients", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "report_id"
    t.boolean "include_in_current_period"
    t.integer "current_period_age"
    t.integer "current_period_earned_income_at_start"
    t.integer "current_period_earned_income_at_exit"
    t.integer "current_period_other_income_at_start"
    t.integer "current_period_other_income_at_exit"
    t.boolean "current_caper_leaver"
    t.integer "current_period_days_in_es"
    t.integer "current_period_days_in_rrh"
    t.integer "current_period_days_in_psh"
    t.integer "current_period_days_to_return"
    t.boolean "current_period_spm_leaver"
    t.boolean "current_period_first_time"
    t.boolean "current_period_reentering"
    t.boolean "current_period_in_outflow"
    t.boolean "current_period_entering_housing"
    t.boolean "current_period_inactive"
    t.bigint "current_period_caper_id"
    t.bigint "current_period_spm_id"
    t.boolean "include_in_prior_period"
    t.integer "prior_period_age"
    t.integer "prior_period_earned_income_at_start"
    t.integer "prior_period_earned_income_at_exit"
    t.integer "prior_period_other_income_at_start"
    t.integer "prior_period_other_income_at_exit"
    t.boolean "prior_caper_leaver"
    t.integer "prior_period_days_in_es"
    t.integer "prior_period_days_in_rrh"
    t.integer "prior_period_days_in_psh"
    t.integer "prior_period_days_to_return"
    t.boolean "prior_period_spm_leaver"
    t.boolean "prior_period_first_time"
    t.boolean "prior_period_reentering"
    t.boolean "prior_period_in_outflow"
    t.boolean "prior_period_entering_housing"
    t.boolean "prior_period_inactive"
    t.bigint "prior_period_caper_id"
    t.bigint "prior_period_spm_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.string "first_name"
    t.string "last_name"
    t.index ["client_id"], name: "index_performance_metrics_clients_on_client_id"
    t.index ["created_at"], name: "index_performance_metrics_clients_on_created_at"
    t.index ["current_period_caper_id"], name: "index_performance_metrics_clients_on_current_period_caper_id"
    t.index ["current_period_spm_id"], name: "index_performance_metrics_clients_on_current_period_spm_id"
    t.index ["deleted_at"], name: "index_performance_metrics_clients_on_deleted_at"
    t.index ["prior_period_caper_id"], name: "index_performance_metrics_clients_on_prior_period_caper_id"
    t.index ["prior_period_spm_id"], name: "index_performance_metrics_clients_on_prior_period_spm_id"
    t.index ["report_id"], name: "index_performance_metrics_clients_on_report_id"
    t.index ["updated_at"], name: "index_performance_metrics_clients_on_updated_at"
  end

  create_table "places", force: :cascade do |t|
    t.string "location", null: false
    t.jsonb "lat_lon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "city"
    t.string "state"
    t.string "zipcode"
    t.float "lat"
    t.float "lon"
    t.index ["lat", "lon"], name: "index_places_on_lat_and_lon"
    t.index ["location"], name: "index_places_on_location"
  end

  create_table "pm_client_projects", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "project_id"
    t.datetime "deleted_at", precision: nil
    t.integer "report_id"
    t.string "for_question"
    t.string "period"
    t.integer "household_type", comment: "2.07.4"
    t.index ["client_id", "for_question", "report_id", "period"], name: "pm_clients_c_id_fq_r_id_p"
    t.index ["client_id", "project_id", "report_id"], name: "pm_clients_c_id_p_id_r_id"
    t.index ["client_id", "report_id"], name: "index_pm_client_projects_on_client_id_and_report_id"
    t.index ["deleted_at"], name: "index_pm_client_projects_on_deleted_at"
    t.index ["for_question", "report_id", "period"], name: "fq_r_id_p"
    t.index ["project_id", "report_id"], name: "index_pm_client_projects_on_project_id_and_report_id"
    t.index ["project_id"], name: "index_pm_client_projects_on_project_id"
  end

  create_table "pm_clients", force: :cascade do |t|
    t.bigint "report_id"
    t.bigint "client_id"
    t.date "dob"
    t.boolean "veteran", default: false, null: false
    t.integer "reporting_age"
    t.boolean "reporting_hoh", default: false, null: false
    t.boolean "reporting_stayer", default: false, null: false
    t.boolean "reporting_leaver", default: false, null: false
    t.boolean "reporting_first_time", default: false, null: false
    t.integer "reporting_days_homeless_es_sh_th"
    t.integer "reporting_days_homeless_before_move_in"
    t.integer "reporting_destination"
    t.integer "reporting_days_to_return"
    t.boolean "reporting_increased_income", default: false, null: false
    t.integer "reporting_pit_project_id"
    t.integer "reporting_pit_project_type"
    t.boolean "reporting_served_on_pit_date", default: false, null: false
    t.boolean "reporting_served_in_so", default: false, null: false
    t.integer "reporting_current_project_types", array: true
    t.integer "reporting_prior_project_types", array: true
    t.integer "reporting_so_destination"
    t.integer "reporting_es_sh_th_rrh_destination"
    t.integer "reporting_moved_in_destination"
    t.integer "reporting_moved_in_stayer"
    t.boolean "reporting_so_es_sh_th_2_yr_permanent_dest", default: false, null: false
    t.boolean "reporting_so_es_sh_th_return_6_mo", default: false, null: false
    t.boolean "reporting_so_es_sh_th_return_2_yr", default: false, null: false
    t.integer "reporting_prior_living_situation"
    t.integer "reporting_prevention_tool_score"
    t.boolean "reporting_ce_enrollment", default: false, null: false
    t.boolean "reporting_ce_diversion", default: false, null: false
    t.integer "reporting_days_in_ce"
    t.integer "reporting_days_since_assessment"
    t.integer "reporting_days_ce_to_assessment"
    t.integer "reporting_days_ce_to_referral"
    t.integer "reporting_days_referral_to_ph_entry"
    t.integer "reporting_ce_assessment_score"
    t.integer "comparison_age"
    t.boolean "comparison_hoh", default: false, null: false
    t.boolean "comparison_stayer", default: false, null: false
    t.boolean "comparison_leaver", default: false, null: false
    t.boolean "comparison_first_time", default: false, null: false
    t.integer "comparison_days_homeless_es_sh_th"
    t.integer "comparison_days_homeless_before_move_in"
    t.integer "comparison_destination"
    t.integer "comparison_days_to_return"
    t.boolean "comparison_increased_income", default: false, null: false
    t.integer "comparison_pit_project_id"
    t.integer "comparison_pit_project_type"
    t.boolean "comparison_served_on_pit_date", default: false, null: false
    t.boolean "comparison_served_in_so", default: false, null: false
    t.integer "comparison_current_project_types", array: true
    t.integer "comparison_prior_project_types", array: true
    t.integer "comparison_so_destination"
    t.integer "comparison_es_sh_th_rrh_destination"
    t.integer "comparison_moved_in_destination"
    t.integer "comparison_moved_in_stayer"
    t.boolean "comparison_so_es_sh_th_2_yr_permanent_dest", default: false, null: false
    t.boolean "comparison_so_es_sh_th_return_6_mo", default: false, null: false
    t.boolean "comparison_so_es_sh_th_return_2_yr", default: false, null: false
    t.integer "comparison_prior_living_situation"
    t.integer "comparison_prevention_tool_score"
    t.boolean "comparison_ce_enrollment", default: false, null: false
    t.boolean "comparison_ce_diversion", default: false, null: false
    t.integer "comparison_days_in_ce"
    t.integer "comparison_days_since_assessment"
    t.integer "comparison_days_ce_to_assessment"
    t.integer "comparison_days_ce_to_referral"
    t.integer "comparison_days_referral_to_ph_entry"
    t.integer "comparison_ce_assessment_score"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "reporting_spm_id"
    t.integer "comparison_spm_id"
    t.integer "reporting_days_homeless_es_sh_th_ph"
    t.boolean "reporting_income_stayer"
    t.boolean "comparison_income_stayer"
    t.boolean "reporting_income_leaver"
    t.boolean "comparison_income_leaver"
    t.boolean "reporting_served_on_pit_date_sheltered", default: false, null: false
    t.boolean "comparison_served_on_pit_date_sheltered", default: false, null: false
    t.boolean "reporting_served_on_pit_date_unsheltered", default: false, null: false
    t.boolean "comparison_served_on_pit_date_unsheltered", default: false, null: false
    t.integer "comparison_days_homeless_es_sh_th_ph"
    t.integer "reporting_days_in_es_bed"
    t.jsonb "reporting_days_in_es_bed_details"
    t.integer "reporting_days_in_es_bed_in_period"
    t.jsonb "reporting_days_in_es_bed_details_in_period"
    t.integer "reporting_days_in_sh_bed"
    t.jsonb "reporting_days_in_sh_bed_details"
    t.integer "reporting_days_in_sh_bed_in_period"
    t.jsonb "reporting_days_in_sh_bed_details_in_period"
    t.integer "reporting_days_in_so_bed"
    t.jsonb "reporting_days_in_so_bed_details"
    t.integer "reporting_days_in_so_bed_in_period"
    t.jsonb "reporting_days_in_so_bed_details_in_period"
    t.integer "reporting_days_in_th_bed"
    t.jsonb "reporting_days_in_th_bed_details"
    t.integer "reporting_days_in_th_bed_in_period"
    t.jsonb "reporting_days_in_th_bed_details_in_period"
    t.integer "comparison_days_in_es_bed"
    t.jsonb "comparison_days_in_es_bed_details"
    t.integer "comparison_days_in_es_bed_in_period"
    t.jsonb "comparison_days_in_es_bed_details_in_period"
    t.integer "comparison_days_in_sh_bed"
    t.jsonb "comparison_days_in_sh_bed_details"
    t.integer "comparison_days_in_sh_bed_in_period"
    t.jsonb "comparison_days_in_sh_bed_details_in_period"
    t.integer "comparison_days_in_so_bed"
    t.jsonb "comparison_days_in_so_bed_details"
    t.integer "comparison_days_in_so_bed_in_period"
    t.jsonb "comparison_days_in_so_bed_details_in_period"
    t.integer "comparison_days_in_th_bed"
    t.jsonb "comparison_days_in_th_bed_details"
    t.integer "comparison_days_in_th_bed_in_period"
    t.jsonb "comparison_days_in_th_bed_details_in_period"
    t.integer "reporting_days_in_homeless_bed"
    t.jsonb "reporting_days_in_homeless_bed_details"
    t.integer "reporting_days_in_homeless_bed_in_period"
    t.jsonb "reporting_days_in_homeless_bed_details_in_period"
    t.integer "comparison_days_in_homeless_bed"
    t.jsonb "comparison_days_in_homeless_bed_details"
    t.integer "comparison_days_in_homeless_bed_in_period"
    t.jsonb "comparison_days_in_homeless_bed_details_in_period"
    t.integer "reporting_days_in_psh_bed"
    t.jsonb "reporting_days_in_psh_bed_details"
    t.integer "reporting_days_in_psh_bed_in_period"
    t.jsonb "reporting_days_in_psh_bed_details_in_period"
    t.integer "reporting_days_in_oph_bed"
    t.jsonb "reporting_days_in_oph_bed_details"
    t.integer "reporting_days_in_oph_bed_in_period"
    t.jsonb "reporting_days_in_oph_bed_details_in_period"
    t.integer "reporting_days_in_rrh_bed"
    t.jsonb "reporting_days_in_rrh_bed_details"
    t.integer "reporting_days_in_rrh_bed_in_period"
    t.jsonb "reporting_days_in_rrh_bed_details_in_period"
    t.integer "comparison_days_in_psh_bed"
    t.jsonb "comparison_days_in_psh_bed_details"
    t.integer "comparison_days_in_psh_bed_in_period"
    t.jsonb "comparison_days_in_psh_bed_details_in_period"
    t.integer "comparison_days_in_oph_bed"
    t.jsonb "comparison_days_in_oph_bed_details"
    t.integer "comparison_days_in_oph_bed_in_period"
    t.jsonb "comparison_days_in_oph_bed_details_in_period"
    t.integer "comparison_days_in_rrh_bed"
    t.jsonb "comparison_days_in_rrh_bed_details"
    t.integer "comparison_days_in_rrh_bed_in_period"
    t.jsonb "comparison_days_in_rrh_bed_details_in_period"
    t.boolean "reporting_seen_in_range", default: false, null: false
    t.boolean "reporting_retention_or_positive_destination", default: false, null: false
    t.boolean "reporting_earned_income_stayer", default: false, null: false
    t.boolean "reporting_earned_income_leaver", default: false, null: false
    t.boolean "reporting_non_employment_income_stayer", default: false, null: false
    t.boolean "reporting_non_employment_income_leaver", default: false, null: false
    t.boolean "comparison_seen_in_range", default: false, null: false
    t.boolean "comparison_retention_or_positive_destination", default: false, null: false
    t.boolean "comparison_earned_income_stayer", default: false, null: false
    t.boolean "comparison_earned_income_leaver", default: false, null: false
    t.boolean "comparison_non_employment_income_stayer", default: false, null: false
    t.boolean "comparison_non_employment_income_leaver", default: false, null: false
    t.string "source_client_personal_ids"
    t.integer "reporting_prior_destination"
    t.integer "comparison_prior_destination"
    t.index ["client_id", "report_id"], name: "index_pm_clients_on_client_id_and_report_id"
    t.index ["deleted_at"], name: "index_pm_clients_on_deleted_at"
  end

  create_table "pm_coc_static_spms", force: :cascade do |t|
    t.bigint "goal_id", null: false
    t.date "report_start", null: false
    t.date "report_end", null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["goal_id"], name: "index_pm_coc_static_spms_on_goal_id"
  end

  create_table "pm_projects", force: :cascade do |t|
    t.bigint "report_id"
    t.float "reporting_ave_bed_capacity_per_night"
    t.float "reporting_ave_clients_per_night"
    t.float "comparison_ave_bed_capacity_per_night"
    t.float "comparison_ave_clients_per_night"
    t.datetime "deleted_at", precision: nil
    t.integer "project_id"
    t.string "period"
    t.index ["deleted_at"], name: "index_pm_projects_on_deleted_at"
    t.index ["project_id", "report_id"], name: "index_pm_projects_on_project_id_and_report_id"
    t.index ["report_id"], name: "index_pm_projects_on_report_id"
  end

  create_table "pm_results", force: :cascade do |t|
    t.bigint "report_id"
    t.string "field", null: false
    t.string "title", null: false
    t.boolean "passed", default: false, null: false
    t.string "direction"
    t.integer "primary_value"
    t.string "primary_unit"
    t.integer "secondary_value"
    t.string "secondary_unit"
    t.string "value_label"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "comparison_primary_value"
    t.boolean "system_level", default: false, null: false
    t.integer "project_id"
    t.float "goal"
    t.float "goal_progress"
    t.integer "reporting_numerator"
    t.integer "reporting_denominator"
    t.integer "comparison_numerator"
    t.integer "comparison_denominator"
    t.index ["field"], name: "index_pm_results_on_field"
    t.index ["report_id"], name: "index_pm_results_on_report_id"
  end

  create_table "project_data_quality", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.string "type"
    t.date "start"
    t.date "end"
    t.json "report"
    t.datetime "sent_at", precision: nil
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.text "processing_errors"
    t.integer "project_group_id"
    t.json "support"
    t.integer "requestor_id"
    t.boolean "notify_contacts", default: false
    t.index ["project_id"], name: "index_project_data_quality_on_project_id"
  end

  create_table "project_groups", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.jsonb "options", default: {}
  end

  create_table "project_pass_fails", force: :cascade do |t|
    t.bigint "user_id"
    t.jsonb "options", default: {}
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.text "processing_errors"
    t.float "utilization_rate"
    t.integer "projects_failing_universal_data_elements"
    t.float "average_days_to_enter_entry_date"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.jsonb "thresholds", default: {}
    t.float "unit_utilization_rate"
    t.index ["created_at"], name: "index_project_pass_fails_on_created_at"
    t.index ["deleted_at"], name: "index_project_pass_fails_on_deleted_at"
    t.index ["updated_at"], name: "index_project_pass_fails_on_updated_at"
    t.index ["user_id"], name: "index_project_pass_fails_on_user_id"
  end

  create_table "project_pass_fails_clients", force: :cascade do |t|
    t.bigint "project_pass_fail_id"
    t.bigint "project_id"
    t.bigint "client_id"
    t.string "first_name"
    t.string "last_name"
    t.date "first_date_in_program"
    t.date "last_date_in_program"
    t.integer "disabling_condition"
    t.integer "dob_quality"
    t.date "dob"
    t.integer "ethnicity"
    t.integer "gender"
    t.integer "name_quality"
    t.integer "race"
    t.integer "ssn_quality"
    t.string "ssn"
    t.integer "veteran_status"
    t.integer "relationship_to_hoh"
    t.date "enrollment_created"
    t.string "enrollment_coc"
    t.integer "days_to_enter_entry_date"
    t.integer "days_served"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "income_at_entry"
    t.string "gender_multi"
    t.string "household_id"
    t.index ["client_id"], name: "index_project_pass_fails_clients_on_client_id"
    t.index ["created_at"], name: "index_project_pass_fails_clients_on_created_at"
    t.index ["deleted_at"], name: "index_project_pass_fails_clients_on_deleted_at"
    t.index ["project_id"], name: "ppfc_ppfp_idx"
    t.index ["project_pass_fail_id"], name: "index_project_pass_fails_clients_on_project_pass_fail_id"
    t.index ["updated_at"], name: "index_project_pass_fails_clients_on_updated_at"
  end

  create_table "project_pass_fails_projects", force: :cascade do |t|
    t.bigint "project_pass_fail_id"
    t.bigint "project_id"
    t.bigint "apr_id"
    t.float "available_beds"
    t.float "utilization_rate"
    t.float "name_error_rate"
    t.float "ssn_error_rate"
    t.float "race_error_rate"
    t.float "ethnicity_error_rate"
    t.float "gender_error_rate"
    t.float "dob_error_rate"
    t.float "veteran_status_error_rate"
    t.float "start_date_error_rate"
    t.float "relationship_to_hoh_error_rate"
    t.float "location_error_rate"
    t.float "disabling_condition_error_rate"
    t.float "utilization_count"
    t.float "name_error_count"
    t.float "ssn_error_count"
    t.float "race_error_count"
    t.float "ethnicity_error_count"
    t.float "gender_error_count"
    t.float "dob_error_count"
    t.float "veteran_status_error_count"
    t.float "start_date_error_count"
    t.float "relationship_to_hoh_error_count"
    t.float "location_error_count"
    t.float "disabling_condition_error_count"
    t.float "average_days_to_enter_entry_date"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.float "income_at_entry_error_rate"
    t.integer "income_at_entry_error_count"
    t.integer "available_units"
    t.float "unit_utilization_rate"
    t.integer "unit_utilization_count"
    t.index ["apr_id"], name: "index_project_pass_fails_projects_on_apr_id"
    t.index ["created_at"], name: "index_project_pass_fails_projects_on_created_at"
    t.index ["deleted_at"], name: "index_project_pass_fails_projects_on_deleted_at"
    t.index ["project_id"], name: "index_project_pass_fails_projects_on_project_id"
    t.index ["project_pass_fail_id"], name: "index_project_pass_fails_projects_on_project_pass_fail_id"
    t.index ["updated_at"], name: "index_project_pass_fails_projects_on_updated_at"
  end

  create_table "project_project_groups", id: :serial, force: :cascade do |t|
    t.integer "project_group_id"
    t.integer "project_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "deleted_at", precision: nil
  end

  create_table "project_scorecard_reports", force: :cascade do |t|
    t.bigint "project_id"
    t.bigint "project_group_id"
    t.string "status", default: "pending"
    t.bigint "user_id"
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "sent_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "recipient"
    t.string "subrecipient"
    t.date "start_date"
    t.date "end_date"
    t.string "funding_year"
    t.string "grant_term"
    t.integer "utilization_jan"
    t.integer "utilization_apr"
    t.integer "utilization_jul"
    t.integer "utilization_oct"
    t.integer "utilization_proposed"
    t.integer "chronic_households_served"
    t.integer "total_households_served"
    t.integer "total_persons_served"
    t.integer "total_persons_with_positive_exit"
    t.integer "total_persons_exited"
    t.integer "excluded_exits"
    t.integer "average_los_leavers"
    t.integer "percent_increased_employment_income_at_exit"
    t.integer "percent_increased_other_cash_income_at_exit"
    t.integer "percent_returns_to_homelessness"
    t.integer "percent_pii_errors"
    t.integer "percent_ude_errors"
    t.integer "percent_income_and_housing_errors"
    t.integer "days_to_lease_up"
    t.integer "number_referrals"
    t.integer "accepted_referrals"
    t.integer "funds_expended"
    t.integer "amount_awarded"
    t.integer "months_since_start"
    t.boolean "pit_participation"
    t.integer "coc_meetings"
    t.integer "coc_meetings_attended"
    t.string "improvement_plan"
    t.string "financial_plan"
    t.string "site_monitoring"
    t.integer "total_ces_referrals"
    t.integer "accepted_ces_referrals"
    t.integer "clients_with_vispdats"
    t.integer "average_vispdat_score"
    t.integer "budget_plus_match"
    t.integer "prior_amount_awarded"
    t.integer "prior_funds_expended"
    t.string "archive"
    t.boolean "expansion_year"
    t.string "special_population_only"
    t.boolean "project_less_than_two"
    t.string "geographic_location"
    t.bigint "apr_id"
    t.integer "spm_id"
    t.index ["apr_id"], name: "index_project_scorecard_reports_on_apr_id"
    t.index ["project_group_id"], name: "index_project_scorecard_reports_on_project_group_id"
    t.index ["project_id"], name: "index_project_scorecard_reports_on_project_id"
    t.index ["user_id"], name: "index_project_scorecard_reports_on_user_id"
  end

  create_table "psc_feedback_surveys", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "user_id"
    t.date "conversation_on"
    t.string "location"
    t.string "listened_to_me"
    t.string "cared_about_me"
    t.string "knowledgeable"
    t.string "i_was_included"
    t.string "i_decided"
    t.string "supporting_my_needs"
    t.string "sensitive_to_culture"
    t.string "would_return"
    t.string "more_calm_and_control"
    t.string "satisfied"
    t.string "comments"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["client_id"], name: "index_psc_feedback_surveys_on_client_id"
    t.index ["user_id"], name: "index_psc_feedback_surveys_on_user_id"
  end

  create_table "public_report_reports", force: :cascade do |t|
    t.bigint "user_id"
    t.string "type"
    t.date "start_date"
    t.date "end_date"
    t.jsonb "filter"
    t.string "state"
    t.text "html"
    t.string "published_url"
    t.string "embed_code"
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.text "precalculated_data"
    t.string "version_slug"
    t.index ["created_at"], name: "index_public_report_reports_on_created_at"
    t.index ["updated_at"], name: "index_public_report_reports_on_updated_at"
    t.index ["user_id"], name: "index_public_report_reports_on_user_id"
  end

  create_table "public_report_settings", force: :cascade do |t|
    t.string "s3_region"
    t.string "s3_bucket"
    t.string "s3_prefix"
    t.string "encrypted_s3_access_key_id"
    t.string "encrypted_s3_access_key_id_iv"
    t.string "encrypted_s3_secret"
    t.string "encrypted_s3_secret_iv"
    t.string "color_0"
    t.string "color_1"
    t.string "color_2"
    t.string "color_3"
    t.string "color_4"
    t.string "color_5"
    t.string "color_6"
    t.string "color_7"
    t.string "color_8"
    t.string "color_9"
    t.string "color_10"
    t.string "color_11"
    t.string "color_12"
    t.string "color_13"
    t.string "color_14"
    t.string "color_15"
    t.string "color_16"
    t.string "font_url"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "font_family_0"
    t.string "font_family_1"
    t.string "font_family_2"
    t.string "font_family_3"
    t.string "font_size_0"
    t.string "font_size_1"
    t.string "font_size_2"
    t.string "font_size_3"
    t.string "font_weight_0"
    t.string "font_weight_1"
    t.string "font_weight_2"
    t.string "font_weight_3"
    t.string "gender_color_0"
    t.string "gender_color_1"
    t.string "gender_color_2"
    t.string "gender_color_3"
    t.string "gender_color_4"
    t.string "gender_color_5"
    t.string "gender_color_6"
    t.string "gender_color_7"
    t.string "gender_color_8"
    t.string "age_color_0"
    t.string "age_color_1"
    t.string "age_color_2"
    t.string "age_color_3"
    t.string "age_color_4"
    t.string "age_color_5"
    t.string "age_color_6"
    t.string "age_color_7"
    t.string "age_color_8"
    t.string "household_composition_color_0"
    t.string "household_composition_color_1"
    t.string "household_composition_color_2"
    t.string "household_composition_color_3"
    t.string "household_composition_color_4"
    t.string "household_composition_color_5"
    t.string "household_composition_color_6"
    t.string "household_composition_color_7"
    t.string "household_composition_color_8"
    t.string "race_color_0"
    t.string "race_color_1"
    t.string "race_color_2"
    t.string "race_color_3"
    t.string "race_color_4"
    t.string "race_color_5"
    t.string "race_color_6"
    t.string "race_color_7"
    t.string "race_color_8"
    t.string "time_color_0"
    t.string "time_color_1"
    t.string "time_color_2"
    t.string "time_color_3"
    t.string "time_color_4"
    t.string "time_color_5"
    t.string "time_color_6"
    t.string "time_color_7"
    t.string "time_color_8"
    t.string "housing_type_color_0"
    t.string "housing_type_color_1"
    t.string "housing_type_color_2"
    t.string "housing_type_color_3"
    t.string "housing_type_color_4"
    t.string "housing_type_color_5"
    t.string "housing_type_color_6"
    t.string "housing_type_color_7"
    t.string "housing_type_color_8"
    t.string "population_color_0"
    t.string "population_color_1"
    t.string "population_color_2"
    t.string "population_color_3"
    t.string "population_color_4"
    t.string "population_color_5"
    t.string "population_color_6"
    t.string "population_color_7"
    t.string "population_color_8"
    t.string "location_type_color_0"
    t.string "location_type_color_1"
    t.string "location_type_color_2"
    t.string "location_type_color_3"
    t.string "location_type_color_4"
    t.string "location_type_color_5"
    t.string "location_type_color_6"
    t.string "location_type_color_7"
    t.string "location_type_color_8"
    t.string "summary_color"
    t.string "homeless_primary_color"
    t.string "youth_primary_color"
    t.string "adults_only_primary_color"
    t.string "adults_with_children_primary_color"
    t.string "children_only_primary_color"
    t.string "veterans_primary_color"
    t.string "map_type", default: "coc", null: false
    t.string "map_overall_population_method", default: "state", null: false
    t.string "iteration_type", default: "quarter", null: false
  end

  create_table "published_reports", force: :cascade do |t|
    t.string "report_type", null: false
    t.bigint "report_id", null: false
    t.bigint "user_id", null: false
    t.string "state"
    t.string "published_url"
    t.string "path"
    t.text "embed_code"
    t.text "html"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["report_type", "report_id"], name: "index_published_reports_on_report"
    t.index ["user_id"], name: "index_published_reports_on_user_id"
  end

  create_table "recent_items", force: :cascade do |t|
    t.string "owner_type", null: false
    t.bigint "owner_id", null: false
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_type", "item_id"], name: "index_recent_items_on_item"
    t.index ["owner_type", "owner_id"], name: "index_recent_items_on_owner"
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
    t.datetime "DateCreated", precision: nil
    t.datetime "DateUpdated", precision: nil
    t.string "UserID", limit: 100
    t.datetime "DateDeleted", precision: nil
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
    t.datetime "pending_date_deleted", precision: nil
    t.string "SexualOrientationOther", limit: 100
    t.date "history_generated_on"
    t.string "original_household_id"
    t.bigint "service_history_processing_job_id"
    t.integer "MentalHealthDisorderFam"
    t.integer "AlcoholDrugUseDisorderFam"
    t.integer "ClientLeaseholder"
    t.integer "HOHLeasesholder"
    t.integer "IncarceratedAdult"
    t.integer "PrisonDischarge"
    t.integer "CurrentPregnant"
    t.integer "CoCPrioritized"
    t.integer "TargetScreenReqd"
    t.integer "HOHLeaseholder"
    t.integer "demographic_id"
    t.integer "client_id"
    t.index ["EntryDate"], name: "entrydate_ret_index"
    t.index ["client_id"], name: "client_id_ret_index"
    t.index ["id"], name: "id_ret_index", unique: true
  end

  create_table "recent_service_history", id: false, force: :cascade do |t|
    t.bigint "id"
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
    t.integer "user_id"
    t.string "project_ids"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "s3_region"
    t.string "s3_bucket"
    t.string "s3_prefix"
    t.string "encrypted_s3_access_key_id"
    t.string "encrypted_s3_access_key_id_iv"
    t.string "encrypted_s3_secret"
    t.string "encrypted_s3_secret_iv"
    t.datetime "deleted_at", precision: nil
    t.string "encrypted_zip_password"
    t.string "encrypted_zip_password_iv"
    t.string "encryption_type"
    t.jsonb "options"
    t.index ["encrypted_s3_access_key_id_iv"], name: "index_recurring_hmis_exports_on_encrypted_s3_access_key_id_iv", unique: true
    t.index ["encrypted_s3_secret_iv"], name: "index_recurring_hmis_exports_on_encrypted_s3_secret_iv", unique: true
  end

  create_table "remote_configs", force: :cascade do |t|
    t.string "type", null: false
    t.bigint "remote_credential_id"
    t.boolean "active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["remote_credential_id"], name: "index_remote_configs_on_remote_credential_id"
  end

  create_table "remote_credentials", force: :cascade do |t|
    t.string "type", null: false
    t.boolean "active", default: false
    t.string "username", null: false, comment: "username or equivalent eg. s3_access_key_id"
    t.string "encrypted_password", null: false, comment: "password or equivalent eg. s3_secret_access_key"
    t.string "encrypted_password_iv"
    t.string "region"
    t.string "bucket"
    t.string "path"
    t.string "endpoint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.jsonb "additional_headers", default: {}
    t.string "slug"
    t.index ["slug"], name: "index_remote_credentials_on_slug", unique: true
  end

  create_table "report_definitions", id: :serial, force: :cascade do |t|
    t.string "report_group"
    t.text "url"
    t.text "name"
    t.text "description"
    t.integer "weight", default: 0, null: false
    t.boolean "enabled", default: true, null: false
    t.boolean "limitable", default: true, null: false
    t.boolean "health", default: false
    t.datetime "created_at", precision: nil, default: -> { "now()" }, null: false
    t.datetime "updated_at", precision: nil, default: -> { "now()" }, null: false
    t.datetime "deleted_at", precision: nil
  end

  create_table "report_tokens", id: :serial, force: :cascade do |t|
    t.integer "report_id", null: false
    t.integer "contact_id", null: false
    t.string "token", null: false
    t.datetime "expires_at", precision: nil, null: false
    t.datetime "accessed_at", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
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
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "deleted_at", precision: nil
  end

  create_table "service_history_enrollments", force: :cascade do |t|
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
    t.string "project_name"
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

  create_table "service_history_services", primary_key: ["id", "date"], options: "PARTITION BY RANGE (date)", force: :cascade do |t|
    t.bigserial "id", null: false
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["date", "service_history_enrollment_id"], name: "service_history_services_part_date_service_history_enrollme_idx", unique: true
  end

  create_table "service_history_services_was_for_inheritance", id: :bigint, default: -> { "nextval('service_history_services_id_seq'::regclass)" }, force: :cascade do |t|
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", limit: 50, null: false
    t.date "date", null: false
    t.integer "age", limit: 2
    t.integer "service_type", limit: 2
    t.integer "client_id"
    t.integer "project_type", limit: 2
    t.boolean "homeless"
    t.boolean "literally_homeless"
    t.index ["date", "service_history_enrollment_id"], name: "shs_unique_date_she_id", unique: true
  end

  create_table "service_scanning_scanner_ids", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.string "source_type", null: false
    t.string "scanned_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
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
    t.datetime "provided_at", precision: nil
    t.string "note"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.index ["client_id"], name: "index_service_scanning_services_on_client_id"
    t.index ["created_at"], name: "index_service_scanning_services_on_created_at"
    t.index ["project_id"], name: "index_service_scanning_services_on_project_id"
    t.index ["type"], name: "index_service_scanning_services_on_type"
    t.index ["updated_at"], name: "index_service_scanning_services_on_updated_at"
    t.index ["user_id"], name: "index_service_scanning_services_on_user_id"
  end

  create_table "shape_block_groups", force: :cascade do |t|
    t.string "statefp"
    t.string "countyfp"
    t.string "tractce"
    t.string "blkgrpce"
    t.string "geoid"
    t.string "namelsad"
    t.string "mtfcc"
    t.string "funcstat"
    t.float "aland"
    t.float "awater"
    t.string "intptlat"
    t.string "intptlon"
    t.string "full_geoid"
    t.geometry "simplified_geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.geometry "geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.index ["full_geoid"], name: "index_shape_block_groups_on_full_geoid"
    t.index ["geoid"], name: "index_shape_block_groups_on_geoid", unique: true
    t.index ["geom"], name: "index_shape_block_groups_on_geom", using: :gist
    t.index ["simplified_geom"], name: "index_shape_block_groups_on_simplified_geom", using: :gist
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
    t.geometry "geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.geometry "simplified_geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.string "full_geoid"
    t.index ["cocname"], name: "index_shape_cocs_on_cocname"
    t.index ["full_geoid"], name: "index_shape_cocs_on_full_geoid", unique: true
    t.index ["geom"], name: "index_shape_cocs_on_geom", using: :gist
    t.index ["simplified_geom"], name: "index_shape_cocs_on_simplified_geom", using: :gist
    t.index ["st"], name: "index_shape_cocs_on_st"
  end

  create_table "shape_counties", force: :cascade do |t|
    t.string "statefp"
    t.string "countyfp"
    t.string "countyns"
    t.string "full_geoid"
    t.string "geoid"
    t.string "name"
    t.string "namelsad"
    t.string "lsad"
    t.string "classfp"
    t.string "mtfcc"
    t.string "csafp"
    t.string "cbsafp"
    t.string "metdivfp"
    t.string "funcstat"
    t.float "aland"
    t.float "awater"
    t.string "intptlat"
    t.string "intptlon"
    t.geometry "simplified_geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.geometry "geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.index "lower((namelsad)::text)", name: "shape_counties_namelsad_lower"
    t.index ["full_geoid"], name: "index_shape_counties_on_full_geoid"
    t.index ["geoid"], name: "index_shape_counties_on_geoid", unique: true
    t.index ["geom"], name: "index_shape_counties_on_geom", using: :gist
    t.index ["simplified_geom"], name: "index_shape_counties_on_simplified_geom", using: :gist
    t.index ["statefp"], name: "index_shape_counties_on_statefp"
  end

  create_table "shape_places", force: :cascade do |t|
    t.string "statefp"
    t.string "placefp"
    t.string "placens"
    t.string "full_geoid"
    t.string "geoid"
    t.string "name"
    t.string "namelsad"
    t.string "lsad"
    t.string "classfp"
    t.string "pcicbsa"
    t.string "pcinecta"
    t.string "mtfcc"
    t.string "funcstat"
    t.float "aland"
    t.float "awater"
    t.string "intptlat"
    t.string "intptlon"
    t.geometry "simplified_geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.geometry "geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.index ["full_geoid"], name: "index_shape_places_on_full_geoid"
    t.index ["geoid"], name: "index_shape_places_on_geoid", unique: true
    t.index ["geom"], name: "index_shape_places_on_geom", using: :gist
    t.index ["simplified_geom"], name: "index_shape_places_on_simplified_geom", using: :gist
  end

  create_table "shape_states", force: :cascade do |t|
    t.string "region"
    t.string "division"
    t.string "statefp"
    t.string "statens"
    t.string "full_geoid"
    t.string "geoid"
    t.string "stusps"
    t.string "name"
    t.string "lsad"
    t.string "mtfcc"
    t.string "funcstat"
    t.float "aland"
    t.float "awater"
    t.string "intptlat"
    t.string "intptlon"
    t.geometry "simplified_geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.geometry "geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.index ["full_geoid"], name: "index_shape_states_on_full_geoid"
    t.index ["geoid"], name: "index_shape_states_on_geoid", unique: true
    t.index ["geom"], name: "index_shape_states_on_geom", using: :gist
    t.index ["simplified_geom"], name: "index_shape_states_on_simplified_geom", using: :gist
    t.index ["statefp"], name: "index_shape_states_on_statefp"
    t.index ["stusps"], name: "index_shape_states_on_stusps"
  end

  create_table "shape_towns", force: :cascade do |t|
    t.string "statefp"
    t.integer "fy"
    t.integer "town_id"
    t.string "town"
    t.decimal "shape_area"
    t.decimal "shape_len"
    t.string "full_geoid"
    t.string "geoid"
    t.geometry "simplified_geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.geometry "geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.index ["full_geoid"], name: "index_shape_towns_on_full_geoid"
    t.index ["geoid"], name: "index_shape_towns_on_geoid", unique: true
    t.index ["geom"], name: "index_shape_towns_on_geom", using: :gist
    t.index ["simplified_geom"], name: "index_shape_towns_on_simplified_geom", using: :gist
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
    t.geometry "geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.geometry "simplified_geom", limit: {:srid=>4326, :type=>"multi_polygon"}
    t.string "full_geoid"
    t.string "st_geoid"
    t.string "county_name_lower"
    t.index ["county_name_lower"], name: "index_shape_zip_codes_on_county_name_lower"
    t.index ["full_geoid"], name: "index_shape_zip_codes_on_full_geoid"
    t.index ["geom"], name: "index_shape_zip_codes_on_geom", using: :gist
    t.index ["simplified_geom"], name: "index_shape_zip_codes_on_simplified_geom", using: :gist
    t.index ["st_geoid"], name: "index_shape_zip_codes_on_st_geoid"
    t.index ["zcta5ce10"], name: "index_shape_zip_codes_on_zcta5ce10", unique: true
  end

  create_table "simple_report_cells", force: :cascade do |t|
    t.bigint "report_instance_id"
    t.string "name"
    t.boolean "universe", default: false
    t.integer "summary"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.jsonb "structured_data"
    t.index ["report_instance_id"], name: "index_simple_report_cells_on_report_instance_id"
  end

  create_table "simple_report_instances", force: :cascade do |t|
    t.string "type"
    t.json "options"
    t.bigint "user_id"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.bigint "goal_configuration_id"
    t.string "path"
    t.index ["goal_configuration_id"], name: "index_simple_report_instances_on_goal_configuration_id"
    t.index ["user_id"], name: "index_simple_report_instances_on_user_id"
  end

  create_table "simple_report_universe_members", force: :cascade do |t|
    t.bigint "report_cell_id"
    t.string "universe_membership_type"
    t.bigint "universe_membership_id"
    t.bigint "client_id"
    t.string "first_name"
    t.string "last_name"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["client_id"], name: "index_simple_report_universe_members_on_client_id"
    t.index ["report_cell_id", "universe_membership_id", "universe_membership_type"], name: "uniq_simple_report_universe_members", unique: true, where: "(deleted_at IS NULL)"
    t.index ["report_cell_id"], name: "index_simple_report_universe_members_on_report_cell_id"
    t.index ["universe_membership_type", "universe_membership_id"], name: "simple_report_univ_type_and_id"
  end

  create_table "synthetic_assessments", force: :cascade do |t|
    t.bigint "enrollment_id"
    t.bigint "client_id"
    t.string "type"
    t.string "source_type"
    t.bigint "source_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "hud_assessment_assessment_id"
    t.index ["client_id"], name: "index_synthetic_assessments_on_client_id"
    t.index ["enrollment_id"], name: "index_synthetic_assessments_on_enrollment_id"
    t.index ["source_type", "source_id"], name: "index_synthetic_assessments_on_source_type_and_source_id"
  end

  create_table "synthetic_ce_assessment_project_configs", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.boolean "active", default: false, null: false
    t.integer "assessment_type", null: false
    t.integer "assessment_level", null: false
    t.integer "prioritization_status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_synthetic_ce_assessment_project_configs_on_project_id"
  end

  create_table "synthetic_events", force: :cascade do |t|
    t.bigint "enrollment_id"
    t.bigint "client_id"
    t.string "type"
    t.string "source_type"
    t.bigint "source_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "hud_event_event_id"
    t.integer "calculated_referral_result"
    t.date "calculated_referral_date"
    t.index ["client_id"], name: "index_synthetic_events_on_client_id"
    t.index ["enrollment_id"], name: "index_synthetic_events_on_enrollment_id"
    t.index ["source_id", "source_type"], name: "index_synthetic_events_on_source_id_and_source_type", unique: true
    t.index ["source_type", "source_id"], name: "index_synthetic_events_on_source_type_and_source_id"
  end

  create_table "synthetic_youth_education_statuses", force: :cascade do |t|
    t.bigint "enrollment_id"
    t.bigint "client_id"
    t.string "type"
    t.string "source_type"
    t.bigint "source_id"
    t.string "hud_youth_education_status_youth_education_status_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_synthetic_youth_education_statuses_on_client_id"
    t.index ["enrollment_id"], name: "index_synthetic_youth_education_statuses_on_enrollment_id"
    t.index ["source_type", "source_id"], name: "index_synthetic_youth_education_statuses_on_source"
  end

  create_table "system_colors", force: :cascade do |t|
    t.string "slug", null: false
    t.string "background_color", null: false
    t.string "foreground_color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "system_pathways_clients", force: :cascade do |t|
    t.bigint "client_id"
    t.string "first_name"
    t.string "last_name"
    t.string "personal_ids"
    t.date "dob"
    t.integer "age"
    t.boolean "am_ind_ak_native"
    t.boolean "asian"
    t.boolean "black_af_american"
    t.boolean "native_hi_pacific"
    t.boolean "white"
    t.integer "ethnicity"
    t.boolean "male"
    t.boolean "female"
    t.boolean "gender_other"
    t.boolean "transgender"
    t.boolean "questioning"
    t.boolean "no_single_gender"
    t.integer "veteran_status"
    t.boolean "involves_ce"
    t.boolean "system"
    t.integer "destination"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "destination_homeless", default: false
    t.boolean "destination_temporary", default: false
    t.boolean "destination_institutional", default: false
    t.boolean "destination_other", default: false
    t.boolean "destination_permanent", default: false
    t.integer "returned_project_type"
    t.string "returned_project_name"
    t.date "returned_project_entry_date"
    t.bigint "returned_project_enrollment_id"
    t.bigint "returned_project_project_id"
    t.bigint "report_id"
    t.datetime "deleted_at", precision: nil
    t.integer "days_to_return"
    t.boolean "ce_assessment", default: false, null: false
    t.boolean "woman"
    t.boolean "man"
    t.boolean "culturally_specific"
    t.boolean "different_identity"
    t.boolean "non_binary"
    t.boolean "hispanic_latinaeo"
    t.boolean "mid_east_n_african"
    t.index ["client_id", "report_id"], name: "c_r_system_pathways_clients_idx"
  end

  create_table "system_pathways_enrollments", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.integer "from_project_type", comment: "null for System"
    t.bigint "project_id", null: false
    t.bigint "enrollment_id", null: false
    t.integer "project_type", null: false
    t.integer "destination", comment: "Only stored for final enrollment"
    t.string "project_name"
    t.date "entry_date"
    t.date "exit_date"
    t.integer "stay_length"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "relationship_to_hoh"
    t.string "household_id"
    t.string "household_type"
    t.bigint "report_id"
    t.datetime "deleted_at", precision: nil
    t.boolean "final_enrollment", default: false, null: false
    t.date "move_in_date"
    t.integer "days_to_move_in"
    t.boolean "chronic_at_entry"
    t.integer "disabling_condition"
    t.integer "days_to_exit_after_move_in"
    t.index ["client_id", "report_id"], name: "c_r_system_pathways_enrollments_idx"
    t.index ["enrollment_id"], name: "index_system_pathways_enrollments_on_enrollment_id"
    t.index ["project_id"], name: "index_system_pathways_enrollments_on_project_id"
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.integer "taggable_id"
    t.string "taggable_type"
    t.integer "tagger_id"
    t.string "tagger_type"
    t.string "context", limit: 128
    t.datetime "created_at", precision: nil
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

  create_table "talentlms_completed_trainings", force: :cascade do |t|
    t.bigint "login_id", null: false
    t.bigint "config_id", null: false
    t.date "completion_date", null: false
    t.bigint "course_id"
    t.index ["config_id"], name: "index_talentlms_completed_trainings_on_config_id"
    t.index ["course_id"], name: "index_talentlms_completed_trainings_on_course_id"
    t.index ["login_id"], name: "index_talentlms_completed_trainings_on_login_id"
  end

  create_table "talentlms_configs", force: :cascade do |t|
    t.string "subdomain"
    t.string "encrypted_api_key"
    t.string "encrypted_api_key_iv"
    t.boolean "create_new_accounts", default: true
  end

  create_table "talentlms_courses", force: :cascade do |t|
    t.bigint "config_id"
    t.integer "courseid"
    t.integer "months_to_expiration"
    t.string "name"
    t.boolean "default", default: false
    t.date "start_date"
    t.date "end_date"
    t.index ["config_id"], name: "index_talentlms_courses_on_config_id"
  end

  create_table "talentlms_logins", force: :cascade do |t|
    t.bigint "user_id"
    t.string "login"
    t.string "encrypted_password"
    t.string "encrypted_password_iv"
    t.integer "lms_user_id"
    t.bigint "config_id"
    t.index ["config_id"], name: "index_talentlms_logins_on_config_id"
    t.index ["user_id"], name: "index_talentlms_logins_on_user_id"
  end

  create_table "text_message_messages", force: :cascade do |t|
    t.bigint "topic_id"
    t.bigint "subscriber_id"
    t.date "send_on_or_after"
    t.datetime "sent_at", precision: nil
    t.string "sent_to"
    t.string "content"
    t.integer "source_id"
    t.string "source_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.string "delivery_status"
    t.index ["created_at"], name: "index_text_message_messages_on_created_at"
    t.index ["subscriber_id"], name: "index_text_message_messages_on_subscriber_id"
    t.index ["topic_id"], name: "index_text_message_messages_on_topic_id"
    t.index ["updated_at"], name: "index_text_message_messages_on_updated_at"
  end

  create_table "text_message_topic_subscribers", force: :cascade do |t|
    t.bigint "topic_id"
    t.datetime "subscribed_at", precision: nil
    t.datetime "unsubscribed_at", precision: nil
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number"
    t.string "preferred_language"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "client_id"
    t.index ["created_at"], name: "index_text_message_topic_subscribers_on_created_at"
    t.index ["topic_id"], name: "index_text_message_topic_subscribers_on_topic_id"
    t.index ["updated_at"], name: "index_text_message_topic_subscribers_on_updated_at"
  end

  create_table "text_message_topics", force: :cascade do |t|
    t.string "arn"
    t.string "title"
    t.boolean "active_topic", default: true, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "send_hour"
    t.index ["created_at"], name: "index_text_message_topics_on_created_at"
    t.index ["title"], name: "index_text_message_topics_on_title"
    t.index ["updated_at"], name: "index_text_message_topics_on_updated_at"
  end

  create_table "themes", force: :cascade do |t|
    t.string "client", null: false
    t.string "hmis_origin"
    t.jsonb "hmis_value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "remote_credential_id"
    t.text "css_file_contents"
    t.text "scss_file_contents"
    t.index ["remote_credential_id"], name: "index_themes_on_remote_credential_id"
  end

  create_table "tx_research_exports", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "export_id"
    t.jsonb "options", default: {}
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.text "processing_errors"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.index ["export_id"], name: "index_tx_research_exports_on_export_id"
    t.index ["user_id"], name: "index_tx_research_exports_on_user_id"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "deleted_at", precision: nil
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["client_id"], name: "index_user_client_permissions_on_client_id"
    t.index ["user_id"], name: "index_user_client_permissions_on_user_id"
  end

  create_table "user_clients", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "client_id", null: false
    t.boolean "confidential", default: false, null: false
    t.string "relationship"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
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
    t.datetime "deleted_at", precision: nil
    t.index ["user_id", "entity_id", "entity_type", "deleted_at"], name: "one_entity_per_type_per_user_allows_delete", unique: true
  end

  create_table "va_check_histories", force: :cascade do |t|
    t.bigint "client_id"
    t.string "response"
    t.date "check_date"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_va_check_histories_on_client_id"
    t.index ["user_id"], name: "index_va_check_histories_on_user_id"
  end

  create_table "verification_sources", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.string "location"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "verified_at", precision: nil
    t.string "type"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.jsonb "object"
    t.jsonb "object_changes"
    t.datetime "created_at", precision: nil
    t.string "session_id"
    t.string "request_id"
    t.bigint "user_id"
    t.bigint "referenced_user_id"
    t.string "referenced_entity_name"
    t.bigint "migrated_app_version_id", comment: "app database version record"
    t.bigint "true_user_id"
    t.bigint "client_id"
    t.bigint "enrollment_id"
    t.bigint "project_id"
    t.index ["client_id"], name: "index_versions_on_client_id"
    t.index ["enrollment_id"], name: "index_versions_on_enrollment_id"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["project_id"], name: "index_versions_on_project_id"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "submitted_at", precision: nil
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
    t.string "contact_method"
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
    t.datetime "proposed_at", precision: nil
    t.datetime "reviewed_at", precision: nil
    t.string "reviewd_by"
    t.datetime "approved_at", precision: nil
    t.datetime "rejected_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "source_id"
    t.integer "destination_id"
    t.integer "client_match_id"
    t.string "source_hash"
    t.index ["data_source_id"], name: "index_warehouse_clients_on_data_source_id"
    t.index ["deleted_at"], name: "index_warehouse_clients_on_deleted_at"
    t.index ["destination_id"], name: "index_warehouse_clients_on_destination_id"
    t.index ["id_in_source"], name: "index_warehouse_clients_on_id_in_source"
    t.index ["source_id"], name: "index_warehouse_clients_on_source_id", unique: true
  end

  create_table "warehouse_clients_processed", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.string "routine"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "last_service_updated_at", precision: nil
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
    t.datetime "last_cas_match_date", precision: nil
    t.string "lgbtq_from_hmis"
    t.integer "days_homeless_plus_overrides"
    t.jsonb "cohorts_ongoing_enrollments_es"
    t.jsonb "cohorts_ongoing_enrollments_sh"
    t.jsonb "cohorts_ongoing_enrollments_th"
    t.jsonb "cohorts_ongoing_enrollments_so"
    t.jsonb "cohorts_ongoing_enrollments_psh"
    t.jsonb "cohorts_ongoing_enrollments_rrh"
    t.string "last_intentional_contacts"
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
    t.datetime "started_at", precision: nil
    t.datetime "finished_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "client_count"
    t.json "support"
    t.string "token"
    t.integer "user_id"
    t.datetime "deleted_at", precision: nil
  end

  create_table "weather", id: :serial, force: :cascade do |t|
    t.string "url", null: false
    t.text "body", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["url"], name: "index_weather_on_url"
  end

  create_table "whitelisted_projects_for_clients", id: :serial, force: :cascade do |t|
    t.integer "data_source_id", null: false
    t.string "ProjectID", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
  end

  create_table "youth_case_managements", id: :serial, force: :cascade do |t|
    t.integer "client_id"
    t.integer "user_id"
    t.date "engaged_on"
    t.text "activity"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.string "housing_status"
    t.string "other_housing_status"
    t.boolean "imported", default: false
    t.string "zip_code"
    t.index ["deleted_at"], name: "index_youth_case_managements_on_deleted_at"
  end

  create_table "youth_exports", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.jsonb "options"
    t.jsonb "headers"
    t.jsonb "rows"
    t.integer "client_count"
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.string "action"
    t.date "action_on"
    t.date "required_on"
    t.integer "case_management_id"
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
    t.integer "client_ethnicity"
    t.string "client_primary_language", null: false
    t.string "pregnant_or_parenting", null: false
    t.jsonb "disabilities", null: false
    t.string "how_hear"
    t.string "needs_shelter", null: false
    t.string "referred_to_shelter", default: "f", null: false
    t.string "in_stable_housing", null: false
    t.string "stable_housing_zipcode"
    t.string "youth_experiencing_homelessness_at_start"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "imported", default: false
    t.string "notes"
    t.index ["deleted_at"], name: "index_youth_referrals_on_deleted_at"
  end

  add_foreign_key "Affiliation", "data_sources"
  add_foreign_key "Client", "data_sources"
  add_foreign_key "CurrentLivingSituation", "Project", column: "verified_by_project_id"
  add_foreign_key "CustomAssessments", "User", column: "created_by_hud_user_id"
  add_foreign_key "CustomAssessments", "User", column: "updated_by_hud_user_id"
  add_foreign_key "Disabilities", "data_sources"
  add_foreign_key "EmploymentEducation", "data_sources"
  add_foreign_key "Enrollment", "Project", column: "project_pk", name: "fk_rails_enrollment_project_pk"
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
  add_foreign_key "external_ids", "external_request_logs"
  add_foreign_key "external_ids", "remote_credentials"
  add_foreign_key "files", "vispdats"
  add_foreign_key "hmis_external_referral_household_members", "Client", column: "client_id"
  add_foreign_key "hmis_external_referral_household_members", "hmis_external_referrals", column: "referral_id"
  add_foreign_key "hmis_external_referral_postings", "Project", column: "project_id"
  add_foreign_key "hmis_external_referral_postings", "hmis_external_referral_requests", column: "referral_request_id"
  add_foreign_key "hmis_external_referral_postings", "hmis_external_referrals", column: "referral_id"
  add_foreign_key "hmis_external_referral_postings", "hmis_unit_types", column: "unit_type_id"
  add_foreign_key "hmis_external_referral_requests", "Project", column: "project_id"
  add_foreign_key "hmis_external_referral_requests", "hmis_unit_types", column: "unit_type_id"
  add_foreign_key "hmis_external_unit_availability_syncs", "Project", column: "project_id"
  add_foreign_key "hmis_external_unit_availability_syncs", "hmis_unit_types", column: "unit_type_id"
  add_foreign_key "hmis_project_unit_type_mappings", "Project", column: "project_id"
  add_foreign_key "hmis_project_unit_type_mappings", "hmis_unit_types", column: "unit_type_id"
  add_foreign_key "hmis_staff_assignments", "hmis_staff_assignment_relationships"
  add_foreign_key "import_logs", "data_sources"
  add_foreign_key "import_overrides", "data_sources"
  add_foreign_key "inbound_api_configurations", "internal_systems"
  add_foreign_key "project_pass_fails_clients", "project_pass_fails", on_delete: :cascade
  add_foreign_key "project_pass_fails_projects", "project_pass_fails", on_delete: :cascade
  add_foreign_key "service_history_services_was_for_inheritance", "service_history_enrollments", on_delete: :cascade
  add_foreign_key "talentlms_completed_trainings", "talentlms_courses", column: "course_id"
  add_foreign_key "talentlms_courses", "talentlms_configs", column: "config_id"
  add_foreign_key "talentlms_logins", "talentlms_configs", column: "config_id"
  add_foreign_key "warehouse_clients", "Client", column: "destination_id"
  add_foreign_key "warehouse_clients", "Client", column: "source_id"
  add_foreign_key "warehouse_clients", "data_sources"
  add_foreign_key "warehouse_clients_processed", "Client", column: "client_id"

  create_view "Site", sql_definition: <<-SQL
      SELECT "GeographyID",
      "ProjectID",
      "CoCCode",
      "PrincipalSite",
      "Geocode",
      "Address1",
      "City",
      "State",
      "ZIP",
      "DateCreated",
      "DateUpdated",
      "UserID",
      "DateDeleted",
      "ExportID",
      data_source_id,
      id,
      "InformationDate",
      "Address2",
      "GeographyType",
      source_hash
     FROM "Geography";
  SQL
  create_view "bi_lookups_ethnicities", sql_definition: <<-SQL
      SELECT id,
      value,
      text
     FROM lookups_ethnicities;
  SQL
  create_view "census_reviews", sql_definition: <<-SQL
      WITH locs AS (
           SELECT shape_cocs.cocname AS name,
              shape_cocs.full_geoid
             FROM shape_cocs
          UNION ALL
           SELECT shape_zip_codes.zcta5ce10 AS name,
              shape_zip_codes.full_geoid
             FROM shape_zip_codes
          UNION ALL
           SELECT shape_counties.name,
              shape_counties.full_geoid
             FROM shape_counties
          UNION ALL
           SELECT shape_states.name,
              shape_states.full_geoid
             FROM shape_states
          )
   SELECT locs.name AS geometry_name,
      vals.census_level,
      vars.internal_name,
      vals.value,
      vars.year,
      vars.dataset,
      vars.name AS variable,
      vars.census_group,
      g.description AS group_description,
      vals.id,
      locs.full_geoid
     FROM (((locs
       LEFT JOIN census_values vals ON (((locs.full_geoid)::text = (vals.full_geoid)::text)))
       LEFT JOIN census_variables vars ON (((vals.census_variable_id = vars.id) AND (vars.internal_name IS NOT NULL))))
       LEFT JOIN census_groups g ON ((((vars.census_group)::text = (g.name)::text) AND (vars.year = g.year) AND ((vars.dataset)::text = (g.dataset)::text))));
  SQL
  create_view "client_searchable_names", sql_definition: <<-SQL
      SELECT "Client".id AS client_id,
      "Client".search_name_full AS full_name,
      "Client".search_name_last AS last_name,
      'primary'::text AS name_type
     FROM "Client"
    WHERE ("Client"."DateDeleted" IS NULL)
  UNION
   SELECT "Client".id AS client_id,
      "CustomClientName".search_name_full AS full_name,
      "CustomClientName".search_name_last AS last_name,
          CASE
              WHEN "CustomClientName"."primary" THEN 'primary'::text
              ELSE 'secondary'::text
          END AS name_type
     FROM ("CustomClientName"
       JOIN "Client" ON (((("Client"."PersonalID")::text = ("CustomClientName"."PersonalID")::text) AND ("Client".data_source_id = "CustomClientName".data_source_id))))
    WHERE ("CustomClientName"."DateDeleted" IS NULL);
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
  create_view "hmis_group_viewable_entity_projects", sql_definition: <<-SQL
      SELECT hmis_group_viewable_entities.id AS group_viewable_entity_id,
      NULL::integer AS organization_id,
      hmis_group_viewable_entities.entity_id AS project_id
     FROM hmis_group_viewable_entities
    WHERE (((hmis_group_viewable_entities.entity_type)::text = 'Hmis::Hud::Project'::text) AND (hmis_group_viewable_entities.deleted_at IS NULL))
  UNION
   SELECT hmis_group_viewable_entities.id AS group_viewable_entity_id,
      "Organization".id AS organization_id,
      "Project".id AS project_id
     FROM ((hmis_group_viewable_entities
       JOIN "Organization" ON ((("Organization"."DateDeleted" IS NULL) AND ("Organization".id = hmis_group_viewable_entities.entity_id))))
       JOIN "Project" ON ((("Project"."DateDeleted" IS NULL) AND ("Organization".data_source_id = "Project".data_source_id) AND (("Organization"."OrganizationID")::text = ("Project"."OrganizationID")::text))))
    WHERE (((hmis_group_viewable_entities.entity_type)::text = 'Hmis::Hud::Organization'::text) AND (hmis_group_viewable_entities.deleted_at IS NULL))
  UNION
   SELECT hmis_group_viewable_entities.id AS group_viewable_entity_id,
      "Organization".id AS organization_id,
      "Project".id AS project_id
     FROM (((hmis_group_viewable_entities
       JOIN data_sources ON (((data_sources.deleted_at IS NULL) AND (data_sources.id = hmis_group_viewable_entities.entity_id))))
       LEFT JOIN "Project" ON ((("Project"."DateDeleted" IS NULL) AND (data_sources.id = "Project".data_source_id))))
       LEFT JOIN "Organization" ON ((("Organization"."DateDeleted" IS NULL) AND (data_sources.id = "Organization".data_source_id))))
    WHERE (((hmis_group_viewable_entities.entity_type)::text = 'GrdaWarehouse::DataSource'::text) AND (hmis_group_viewable_entities.deleted_at IS NULL));
  SQL
  create_view "hmis_households", sql_definition: <<-SQL
      SELECT concat("Enrollment"."HouseholdID", ':', "Project"."ProjectID", ':', "Project".data_source_id) AS id,
      "Enrollment"."HouseholdID",
      "Enrollment".project_pk,
      "Project"."ProjectID",
      "Project".data_source_id,
      min("Enrollment"."EntryDate") AS earliest_entry,
          CASE
              WHEN bool_or(("Exit"."ExitDate" IS NULL)) THEN NULL::date
              ELSE max("Exit"."ExitDate")
          END AS latest_exit,
      bool_or(("Enrollment"."ProjectID" IS NULL)) AS any_wip,
      NULL::text AS "DateDeleted",
      max("Enrollment"."DateUpdated") AS "DateUpdated",
      min("Enrollment"."DateCreated") AS "DateCreated"
     FROM (("Enrollment"
       LEFT JOIN "Exit" ON (((("Exit"."EnrollmentID")::text = ("Enrollment"."EnrollmentID")::text) AND ("Exit".data_source_id = "Enrollment".data_source_id) AND ("Exit"."DateDeleted" IS NULL))))
       JOIN "Project" ON ((("Project"."DateDeleted" IS NULL) AND ("Project".id = "Enrollment".project_pk))))
    WHERE ("Enrollment"."DateDeleted" IS NULL)
    GROUP BY "Project".data_source_id, "Project"."ProjectID", "Enrollment".project_pk, "Enrollment"."HouseholdID";
  SQL
  create_view "hmis_services", sql_definition: <<-SQL
      SELECT (concat('1', ("Services".id)::character varying))::integer AS id,
      "Services".id AS owner_id,
      'Hmis::Hud::Service'::text AS owner_type,
      "Services"."RecordType",
      "Services"."TypeProvided",
      NULL::bigint AS custom_service_type_id,
      "Services"."EnrollmentID",
      "Services"."PersonalID",
      "Services"."DateProvided",
      ("Services"."UserID")::character varying AS "UserID",
      "Services"."DateCreated",
      "Services"."DateUpdated",
      "Services"."DateDeleted",
      "Services".data_source_id
     FROM "Services"
    WHERE ("Services"."DateDeleted" IS NULL)
  UNION ALL
   SELECT (concat('2', ("CustomServices".id)::character varying))::integer AS id,
      ("CustomServices".id)::integer AS owner_id,
      'Hmis::Hud::CustomService'::text AS owner_type,
      NULL::integer AS "RecordType",
      NULL::integer AS "TypeProvided",
      "CustomServices".custom_service_type_id,
      "CustomServices"."EnrollmentID",
      "CustomServices"."PersonalID",
      "CustomServices"."DateProvided",
      "CustomServices"."UserID",
      "CustomServices"."DateCreated",
      "CustomServices"."DateUpdated",
      "CustomServices"."DateDeleted",
      "CustomServices".data_source_id
     FROM "CustomServices"
    WHERE ("CustomServices"."DateDeleted" IS NULL);
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
  create_view "project_access_group_members", sql_definition: <<-SQL
      SELECT targets.project_id,
      group_viewable_entities.access_group_id
     FROM (group_viewable_entities
       JOIN ( SELECT "Project".data_source_id,
              "Project".id AS project_id,
              "Organization".id AS organization_id,
              project_groups.id AS project_group_id
             FROM ((("Project"
               LEFT JOIN "Organization" ON ((("Organization"."DateDeleted" IS NULL) AND ("Organization".data_source_id = "Project".data_source_id) AND (("Organization"."OrganizationID")::text = ("Project"."OrganizationID")::text))))
               LEFT JOIN project_project_groups ON ((project_project_groups.project_id = "Project".id)))
               LEFT JOIN project_groups ON (((project_groups.deleted_at IS NULL) AND (project_groups.id = project_project_groups.project_group_id))))
            WHERE ("Project"."DateDeleted" IS NULL)) targets ON (((group_viewable_entities.deleted_at IS NULL) AND ((((group_viewable_entities.entity_type)::text = 'GrdaWarehouse::DataSource'::text) AND (group_viewable_entities.entity_id = targets.data_source_id)) OR (((group_viewable_entities.entity_type)::text = 'GrdaWarehouse::Hud::Project'::text) AND (group_viewable_entities.entity_id = targets.project_id)) OR (((group_viewable_entities.entity_type)::text = 'GrdaWarehouse::Hud::Organization'::text) AND (group_viewable_entities.entity_id = targets.organization_id)) OR ((((group_viewable_entities.entity_type)::text = 'GrdaWarehouse::ProjectAccessGroup'::text) OR ((group_viewable_entities.entity_type)::text = 'GrdaWarehouse::ProjectGroup'::text)) AND (group_viewable_entities.entity_id = targets.project_group_id))))))
    WHERE ((group_viewable_entities.deleted_at IS NULL) AND (group_viewable_entities.collection_id IS NULL))
    GROUP BY targets.project_id, group_viewable_entities.access_group_id;
  SQL
  create_view "project_collection_members", sql_definition: <<-SQL
      SELECT targets.project_id,
      group_viewable_entities.collection_id
     FROM (group_viewable_entities
       JOIN ( SELECT "Project".data_source_id,
              "Project".id AS project_id,
              "Organization".id AS organization_id,
              project_groups.id AS project_group_id
             FROM ((("Project"
               LEFT JOIN "Organization" ON ((("Organization"."DateDeleted" IS NULL) AND ("Organization".data_source_id = "Project".data_source_id) AND (("Organization"."OrganizationID")::text = ("Project"."OrganizationID")::text))))
               LEFT JOIN project_project_groups ON ((project_project_groups.project_id = "Project".id)))
               LEFT JOIN project_groups ON (((project_groups.deleted_at IS NULL) AND (project_groups.id = project_project_groups.project_group_id))))
            WHERE ("Project"."DateDeleted" IS NULL)) targets ON (((group_viewable_entities.deleted_at IS NULL) AND ((((group_viewable_entities.entity_type)::text = 'GrdaWarehouse::DataSource'::text) AND (group_viewable_entities.entity_id = targets.data_source_id)) OR (((group_viewable_entities.entity_type)::text = 'GrdaWarehouse::Hud::Project'::text) AND (group_viewable_entities.entity_id = targets.project_id)) OR (((group_viewable_entities.entity_type)::text = 'GrdaWarehouse::Hud::Organization'::text) AND (group_viewable_entities.entity_id = targets.organization_id)) OR ((((group_viewable_entities.entity_type)::text = 'GrdaWarehouse::ProjectAccessGroup'::text) OR ((group_viewable_entities.entity_type)::text = 'GrdaWarehouse::ProjectGroup'::text)) AND (group_viewable_entities.entity_id = targets.project_group_id))))))
    WHERE ((group_viewable_entities.deleted_at IS NULL) AND (group_viewable_entities.collection_id IS NOT NULL))
    GROUP BY targets.project_id, group_viewable_entities.collection_id;
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
      "Enrollment"."VAMCStation_deleted" AS "VAMCStation",
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
      SELECT relname,
      round((
          CASE
              WHEN ((n_live_tup + n_dead_tup) = 0) THEN (0)::double precision
              ELSE ((n_dead_tup)::double precision / ((n_dead_tup + n_live_tup))::double precision)
          END * (100.0)::double precision)) AS "Frag %",
      n_live_tup AS "Live rows",
      n_dead_tup AS "Dead rows",
      n_mod_since_analyze AS "Rows modified since analyze",
          CASE
              WHEN (COALESCE(last_vacuum, '1999-01-01 00:00:00+00'::timestamp with time zone) > COALESCE(last_autovacuum, '1999-01-01 00:00:00+00'::timestamp with time zone)) THEN last_vacuum
              ELSE COALESCE(last_autovacuum, '1999-01-01 00:00:00+00'::timestamp with time zone)
          END AS last_vacuum,
          CASE
              WHEN (COALESCE(last_analyze, '1999-01-01 00:00:00+00'::timestamp with time zone) > COALESCE(last_autoanalyze, '1999-01-01 00:00:00+00'::timestamp with time zone)) THEN last_analyze
              ELSE COALESCE(last_autoanalyze, '1999-01-01 00:00:00+00'::timestamp with time zone)
          END AS last_analyze,
      (vacuum_count + autovacuum_count) AS vacuum_count,
      (analyze_count + autoanalyze_count) AS analyze_count
     FROM pg_stat_all_tables
    WHERE (schemaname <> ALL (ARRAY['pg_toast'::name, 'information_schema'::name, 'pg_catalog'::name]));
  SQL
  create_view "service_history_services_materialized", materialized: true, sql_definition: <<-SQL
      SELECT id,
      service_history_enrollment_id,
      record_type,
      date,
      age,
      service_type,
      client_id,
      project_type,
      homeless,
      literally_homeless
     FROM service_history_services;
  SQL
  add_index "service_history_services_materialized", ["client_id", "date"], name: "index_shsm_c_id_date"
  add_index "service_history_services_materialized", ["client_id", "project_type", "record_type"], name: "index_shsm_c_id_p_type_r_type"
  add_index "service_history_services_materialized", ["homeless", "project_type", "client_id"], name: "index_shsm_homeless_p_type_c_id"
  add_index "service_history_services_materialized", ["id"], name: "index_service_history_services_materialized_on_id", unique: true
  add_index "service_history_services_materialized", ["literally_homeless", "project_type", "client_id"], name: "index_shsm_literally_homeless_p_type_c_id"
  add_index "service_history_services_materialized", ["service_history_enrollment_id"], name: "index_shsm_shse_id"


  create_trigger :service_history_service_insert_trigger, sql_definition: <<-SQL
      CREATE TRIGGER service_history_service_insert_trigger BEFORE INSERT ON public.service_history_services_was_for_inheritance FOR EACH ROW EXECUTE FUNCTION service_history_service_insert_trigger()
  SQL
end
