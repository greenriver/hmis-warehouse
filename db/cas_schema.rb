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

ActiveRecord::Schema[7.0].define(version: 2016_05_03_172539) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "building_contacts", id: :serial, force: :cascade do |t|
    t.integer "building_id", null: false
    t.integer "contact_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["building_id"], name: "index_building_contacts_on_building_id"
    t.index ["contact_id"], name: "index_building_contacts_on_contact_id"
    t.index ["deleted_at"], name: "index_building_contacts_on_deleted_at"
  end

  create_table "building_services", id: :serial, force: :cascade do |t|
    t.integer "building_id"
    t.integer "service_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["building_id"], name: "index_building_services_on_building_id"
    t.index ["deleted_at"], name: "index_building_services_on_deleted_at"
    t.index ["service_id"], name: "index_building_services_on_service_id"
  end

  create_table "buildings", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "building_type"
    t.integer "subgrantee_id"
    t.integer "id_in_data_source"
    t.integer "federal_program_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "data_source_id"
    t.string "data_source_id_column_name"
    t.string "address"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.string "geo_code"
    t.index ["id_in_data_source"], name: "index_buildings_on_id_in_data_source"
    t.index ["subgrantee_id"], name: "index_buildings_on_subgrantee_id"
  end

  create_table "client_contacts", id: :serial, force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "contact_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "shelter_agency", default: false, null: false
    t.boolean "regular", default: false, null: false
    t.index ["client_id"], name: "index_client_contacts_on_client_id"
    t.index ["contact_id"], name: "index_client_contacts_on_contact_id"
    t.index ["deleted_at"], name: "index_client_contacts_on_deleted_at"
  end

  create_table "client_opportunity_match_contacts", id: :serial, force: :cascade do |t|
    t.integer "match_id", null: false
    t.integer "contact_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "dnd_staff", default: false, null: false
    t.boolean "housing_subsidy_admin", default: false, null: false
    t.boolean "client", default: false, null: false
    t.boolean "housing_search_worker", default: false, null: false
    t.boolean "shelter_agency", default: false, null: false
    t.index ["contact_id"], name: "index_client_opportunity_match_contacts_on_contact_id"
    t.index ["deleted_at"], name: "index_client_opportunity_match_contacts_on_deleted_at"
    t.index ["match_id"], name: "index_client_opportunity_match_contacts_on_match_id"
  end

  create_table "client_opportunity_matches", id: :serial, force: :cascade do |t|
    t.integer "score"
    t.integer "client_id", null: false
    t.integer "opportunity_id", null: false
    t.integer "contact_id"
    t.datetime "proposed_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "selected"
    t.boolean "active", default: false, null: false
    t.boolean "closed", default: false, null: false
    t.string "closed_reason"
    t.index ["active"], name: "index_client_opportunity_matches_on_active"
    t.index ["client_id"], name: "index_client_opportunity_matches_on_client_id"
    t.index ["closed"], name: "index_client_opportunity_matches_on_closed"
    t.index ["closed_reason"], name: "index_client_opportunity_matches_on_closed_reason"
    t.index ["contact_id"], name: "index_client_opportunity_matches_on_contact_id"
    t.index ["deleted_at"], name: "index_client_opportunity_matches_on_deleted_at", where: "(deleted_at IS NULL)"
    t.index ["opportunity_id"], name: "index_client_opportunity_matches_on_opportunity_id"
  end

  create_table "clients", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.string "name_suffix"
    t.string "name_quality", limit: 4
    t.string "ssn", limit: 9
    t.date "date_of_birth"
    t.string "gender_other", limit: 50
    t.boolean "veteran"
    t.string "disabling_condition", limit: 50
    t.boolean "chronic_homeless"
    t.date "income_information_date"
    t.string "income_from_any_source", limit: 20
    t.integer "income_total_montly"
    t.boolean "income_earned"
    t.boolean "income_unimployment"
    t.boolean "income_ssi"
    t.boolean "income_va_service"
    t.boolean "income_va_non_service"
    t.boolean "income_private_disability"
    t.boolean "income_workers_comp"
    t.boolean "income_tnaf"
    t.boolean "income_general_assistance"
    t.boolean "income_ss_retirement"
    t.boolean "income_pension"
    t.boolean "income_child_support"
    t.boolean "income_spousal_support"
    t.boolean "income_other"
    t.string "income_other_sources"
    t.integer "income_earned_monthly"
    t.integer "income_unimployment_monthly"
    t.integer "income_ssi_monthly"
    t.integer "income_va_service_monthly"
    t.integer "income_va_non_service_monthly"
    t.integer "income_private_disability_monthly"
    t.integer "income_workers_comp_monthly"
    t.integer "income_tnaf_monthly"
    t.integer "income_general_assistance_monthly"
    t.integer "income_ss_retirement_monthly"
    t.integer "income_pension_monthly"
    t.integer "income_child_support_monthly"
    t.integer "income_spousal_support_monthly"
    t.integer "income_other_monthly"
    t.integer "income_total_monthly"
    t.date "non_cash_benefits_information_date"
    t.string "non_cash_benefits", limit: 20
    t.boolean "snap"
    t.boolean "wic"
    t.boolean "tnaf_child_care"
    t.boolean "tnaf_transportaion"
    t.boolean "tnaf_other_benefit"
    t.boolean "ongoing_rental_assistance"
    t.boolean "other_benefit_sources"
    t.boolean "temporary_rental_assistance"
    t.date "health_insurance_information_date"
    t.string "health_insurance", limit: 4
    t.boolean "health_insurance_medicaid"
    t.string "health_insurance_medicaid_reason", limit: 4
    t.boolean "health_insurance_medicare"
    t.string "health_insurance_medicare_reason", limit: 4
    t.boolean "health_insurance_state_childrens"
    t.string "health_insurance_state_childrens_reason", limit: 4
    t.boolean "health_insurance_va"
    t.string "health_insurance_va_reason", limit: 4
    t.boolean "health_insurance_employer"
    t.string "health_insurance_employer_reason", limit: 4
    t.boolean "health_insurance_cobra"
    t.string "health_insurance_cobra_reason", limit: 4
    t.boolean "health_insurance_private_pay"
    t.string "health_insurance_private_pay_reason", limit: 4
    t.boolean "health_insurance_state_adults"
    t.string "health_insurance_state_adults_reason", limit: 4
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "merged_into"
    t.integer "split_from"
    t.integer "ssn_quality"
    t.integer "date_of_birth_quality"
    t.integer "race_id"
    t.integer "ethnicity_id"
    t.integer "gender_id"
    t.integer "veteran_status_id"
    t.integer "hiv_aids"
    t.integer "physical_disability"
    t.integer "developmental_disability"
    t.integer "chronic_health_problem"
    t.integer "mental_health_problem"
    t.integer "substance_abuse_problem"
    t.integer "domestic_violence"
    t.date "calculated_first_homeless_night"
    t.boolean "available", default: true, null: false
    t.boolean "available_candidate", default: true
    t.string "homephone"
    t.string "cellphone"
    t.string "workphone"
    t.string "pager"
    t.string "email"
    t.index ["deleted_at"], name: "index_clients_on_deleted_at"
  end

  create_table "contacts", id: :serial, force: :cascade do |t|
    t.string "email"
    t.string "phone"
    t.string "first_name"
    t.string "last_name"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.string "role"
    t.integer "id_in_data_source"
    t.integer "data_source_id"
    t.string "data_source_id_column_name"
    t.integer "role_id"
    t.string "role_in_organization"
    t.string "cell_phone"
    t.index ["deleted_at"], name: "index_contacts_on_deleted_at"
    t.index ["user_id"], name: "index_contacts_on_user_id"
  end

  create_table "data_sources", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "db_itentifier"
  end

  create_table "date_of_birth_quality_codes", id: :serial, force: :cascade do |t|
    t.integer "numeric"
    t.string "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "disabling_conditions", id: :serial, force: :cascade do |t|
    t.integer "numeric"
    t.string "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "discharge_statuses", id: :serial, force: :cascade do |t|
    t.integer "numeric"
    t.string "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "domestic_violence_survivors", id: :serial, force: :cascade do |t|
    t.integer "numeric"
    t.string "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "ethnicities", id: :serial, force: :cascade do |t|
    t.integer "numeric"
    t.string "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "funding_source_services", id: :serial, force: :cascade do |t|
    t.integer "funding_source_id"
    t.integer "service_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_funding_source_services_on_deleted_at"
    t.index ["funding_source_id"], name: "index_funding_source_services_on_funding_source_id"
    t.index ["service_id"], name: "index_funding_source_services_on_service_id"
  end

  create_table "funding_sources", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "abbreviation"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "id_in_data_source"
    t.integer "data_source_id"
    t.string "data_source_id_column_name"
    t.datetime "deleted_at", precision: nil
  end

  create_table "genders", id: :serial, force: :cascade do |t|
    t.integer "numeric"
    t.string "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "has_developmental_disabilities", id: :serial, force: :cascade do |t|
    t.integer "numeric"
    t.string "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "has_hivaids", id: :serial, force: :cascade do |t|
    t.integer "numeric"
    t.string "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "has_mental_health_problems", id: :serial, force: :cascade do |t|
    t.integer "numeric"
    t.string "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "match_decisions", id: :serial, force: :cascade do |t|
    t.integer "match_id"
    t.string "type"
    t.string "status"
    t.integer "contact_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.datetime "client_last_seen_date", precision: nil
    t.datetime "criminal_hearing_date", precision: nil
    t.datetime "client_move_in_date", precision: nil
    t.index ["match_id"], name: "index_match_decisions_on_match_id"
  end

  create_table "match_events", id: :serial, force: :cascade do |t|
    t.string "type"
    t.integer "match_id"
    t.integer "notification_id"
    t.integer "decision_id"
    t.integer "contact_id"
    t.string "action"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "note"
    t.index ["decision_id"], name: "index_match_events_on_decision_id"
    t.index ["match_id"], name: "index_match_events_on_match_id"
    t.index ["notification_id"], name: "index_match_events_on_notification_id"
  end

  create_table "name_quality_codes", id: :serial, force: :cascade do |t|
    t.integer "numeric"
    t.string "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "code"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "client_opportunity_match_id"
    t.integer "recipient_id"
    t.datetime "expires_at", precision: nil
  end

  create_table "opportunities", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "available", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "unit_id"
    t.float "matchability"
    t.boolean "available_candidate", default: true
    t.integer "voucher_id"
    t.boolean "success", default: false
    t.index ["deleted_at"], name: "index_opportunities_on_deleted_at", where: "(deleted_at IS NULL)"
    t.index ["unit_id"], name: "index_opportunities_on_unit_id"
    t.index ["voucher_id"], name: "index_opportunities_on_voucher_id"
  end

  create_table "opportunity_contacts", id: :serial, force: :cascade do |t|
    t.integer "opportunity_id", null: false
    t.integer "contact_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "housing_subsidy_admin", default: false, null: false
    t.index ["contact_id"], name: "index_opportunity_contacts_on_contact_id"
    t.index ["deleted_at"], name: "index_opportunity_contacts_on_deleted_at"
    t.index ["opportunity_id"], name: "index_opportunity_contacts_on_opportunity_id"
  end

  create_table "opportunity_properties", id: :serial, force: :cascade do |t|
    t.integer "opportunity_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["opportunity_id"], name: "index_opportunity_properties_on_opportunity_id"
  end

  create_table "physical_disabilities", id: :serial, force: :cascade do |t|
    t.integer "numeric"
    t.string "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "primary_races", id: :serial, force: :cascade do |t|
    t.integer "numeric"
    t.string "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "program_services", id: :serial, force: :cascade do |t|
    t.integer "program_id"
    t.integer "service_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_program_services_on_deleted_at"
    t.index ["program_id"], name: "index_program_services_on_program_id"
    t.index ["service_id"], name: "index_program_services_on_service_id"
  end

  create_table "programs", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "contract_start_date"
    t.integer "funding_source_id"
    t.integer "subgrantee_id"
    t.integer "contact_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["contact_id"], name: "index_programs_on_contact_id"
    t.index ["deleted_at"], name: "index_programs_on_deleted_at"
    t.index ["funding_source_id"], name: "index_programs_on_funding_source_id"
    t.index ["subgrantee_id"], name: "index_programs_on_subgrantee_id"
  end

  create_table "project_clients", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "ssn"
    t.date "date_of_birth"
    t.string "veteran_status"
    t.string "substance_abuse_problem"
    t.date "entry_date"
    t.date "exit_date"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.uuid "clientguid"
    t.string "middle_name"
    t.integer "ssn_quality_code"
    t.integer "dob_quality_code"
    t.string "primary_race"
    t.string "secondary_race"
    t.integer "gender"
    t.integer "ethnicity"
    t.integer "disabling_condition"
    t.integer "hud_chronic_homelessness"
    t.integer "calculated_chronic_homelessness"
    t.integer "chronic_health_condition"
    t.integer "physical_disability"
    t.integer "hivaids_status"
    t.integer "mental_health_problem"
    t.integer "domestic_violence"
    t.integer "discharge_type"
    t.integer "developmental_disability"
    t.float "income_total_monthly"
    t.datetime "income_total_monthly_last_collected", precision: nil
    t.boolean "us_citizen"
    t.boolean "assylee"
    t.boolean "lifetime_sex_offender"
    t.boolean "on_parole"
    t.date "on_parole_end_date"
    t.boolean "on_probation"
    t.date "on_probation_end_date"
    t.boolean "meth_production_conviction"
    t.integer "id_in_data_source"
    t.integer "calculated_bed_nights_in_last_three_years"
    t.integer "calculated_episodes_in_last_three_years"
    t.integer "calculated_months_continously_homeless_in_last_three_years"
    t.date "calculated_first_homeless_night"
    t.string "reported_episodes_in_last_three_years"
    t.string "reported_continuously_homeless_for_last_year"
    t.string "reported_months_homeless_in_last_three_years"
    t.string "reported_months_continuously_homeless_immediately_prior"
    t.string "reported_months_continuously_homeless_documented"
    t.string "project_exit_destination"
    t.string "project_exit_destination_specific"
    t.string "project_exit_destination_generic"
    t.string "project_exit_housing_disposition"
    t.date "calculated_last_homeless_night"
    t.datetime "source_last_changed", precision: nil
    t.integer "last_homeless_night_programid"
    t.integer "last_homeless_night_roomid"
    t.integer "data_source_id"
    t.string "data_source_id_column_name"
    t.integer "client_id"
    t.string "homephone"
    t.string "cellphone"
    t.string "workphone"
    t.string "pager"
    t.string "email"
    t.index ["calculated_chronic_homelessness"], name: "index_project_clients_on_calculated_chronic_homelessness"
    t.index ["client_id"], name: "index_project_clients_on_client_id"
    t.index ["date_of_birth"], name: "index_project_clients_on_date_of_birth"
    t.index ["source_last_changed"], name: "index_project_clients_on_source_last_changed"
  end

  create_table "project_programs", id: :serial, force: :cascade do |t|
    t.string "id_in_data_source"
    t.string "program_name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "data_source_id"
    t.string "data_source_id_column_name"
  end

  create_table "reissue_requests", id: :serial, force: :cascade do |t|
    t.integer "notification_id"
    t.integer "reissued_by"
    t.datetime "reissued_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["deleted_at"], name: "index_reissue_requests_on_deleted_at"
    t.index ["notification_id"], name: "index_reissue_requests_on_notification_id"
    t.index ["reissued_by"], name: "index_reissue_requests_on_reissued_by"
  end

  create_table "rejected_matches", id: :serial, force: :cascade do |t|
    t.integer "client_id", null: false
    t.integer "opportunity_id", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["client_id"], name: "index_rejected_matches_on_client_id"
    t.index ["opportunity_id"], name: "index_rejected_matches_on_opportunity_id"
  end

  create_table "requirements", id: :serial, force: :cascade do |t|
    t.integer "rule_id"
    t.string "requirer_type"
    t.integer "requirer_id"
    t.boolean "positive"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["deleted_at"], name: "index_requirements_on_deleted_at"
    t.index ["requirer_type", "requirer_id"], name: "index_requirements_on_requirer_type_and_requirer_id"
    t.index ["rule_id"], name: "index_requirements_on_rule_id"
  end

  create_table "rules", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.string "type"
    t.string "verb"
    t.index ["deleted_at"], name: "index_rules_on_deleted_at"
  end

  create_table "secondary_races", id: :serial, force: :cascade do |t|
    t.integer "numeric"
    t.string "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "service_rules", id: :serial, force: :cascade do |t|
    t.integer "rule_id"
    t.integer "service_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_service_rules_on_deleted_at"
    t.index ["rule_id"], name: "index_service_rules_on_rule_id"
    t.index ["service_id"], name: "index_service_rules_on_service_id"
  end

  create_table "services", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
  end

  create_table "social_security_number_quality_codes", id: :serial, force: :cascade do |t|
    t.integer "numeric"
    t.string "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "sub_programs", id: :serial, force: :cascade do |t|
    t.string "program_type"
    t.integer "program_id"
    t.integer "building_id"
    t.integer "contact_id"
    t.integer "subgrantee_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "matched", default: 0
    t.integer "in_progress", default: 0
    t.integer "vacancies", default: 0
    t.string "name"
    t.index ["building_id"], name: "index_sub_programs_on_building_id"
    t.index ["contact_id"], name: "index_sub_programs_on_contact_id"
    t.index ["deleted_at"], name: "index_sub_programs_on_deleted_at"
    t.index ["program_id"], name: "index_sub_programs_on_program_id"
    t.index ["subgrantee_id"], name: "index_sub_programs_on_subgrantee_id"
  end

  create_table "subgrantee_contacts", id: :serial, force: :cascade do |t|
    t.integer "subgrantee_id", null: false
    t.integer "contact_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["contact_id"], name: "index_subgrantee_contacts_on_contact_id"
    t.index ["deleted_at"], name: "index_subgrantee_contacts_on_deleted_at"
    t.index ["subgrantee_id"], name: "index_subgrantee_contacts_on_subgrantee_id"
  end

  create_table "subgrantee_services", id: :serial, force: :cascade do |t|
    t.integer "subgrantee_id"
    t.integer "service_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_subgrantee_services_on_deleted_at"
    t.index ["service_id"], name: "index_subgrantee_services_on_service_id"
    t.index ["subgrantee_id"], name: "index_subgrantee_services_on_subgrantee_id"
  end

  create_table "subgrantees", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "abbreviation"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "id_in_data_source"
    t.integer "disabled"
    t.integer "data_source_id"
    t.string "data_source_id_column_name"
    t.datetime "deleted_at", precision: nil
  end

  create_table "units", id: :serial, force: :cascade do |t|
    t.integer "id_in_data_source"
    t.string "name"
    t.boolean "available"
    t.string "target_population_a"
    t.string "target_population_b"
    t.boolean "mc_kinney_vento"
    t.integer "chronic"
    t.integer "veteran"
    t.integer "adult_only"
    t.integer "family"
    t.integer "child_only"
    t.integer "building_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.integer "data_source_id"
    t.string "data_source_id_column_name"
    t.index ["building_id"], name: "index_units_on_building_id"
    t.index ["deleted_at"], name: "index_units_on_deleted_at", where: "(deleted_at IS NULL)"
    t.index ["id_in_data_source"], name: "index_units_on_id_in_data_source"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at", precision: nil
    t.boolean "admin", default: false, null: false
    t.boolean "dnd_staff", default: false, null: false
    t.boolean "housing_subsidy_admin"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["housing_subsidy_admin"], name: "index_users_on_housing_subsidy_admin"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "veteran_statuses", id: :serial, force: :cascade do |t|
    t.integer "numeric"
    t.string "text"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "vouchers", id: :serial, force: :cascade do |t|
    t.boolean "available"
    t.date "date_available"
    t.integer "sub_program_id"
    t.integer "unit_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["deleted_at"], name: "index_vouchers_on_deleted_at"
    t.index ["sub_program_id"], name: "index_vouchers_on_sub_program_id"
    t.index ["unit_id"], name: "index_vouchers_on_unit_id"
  end

  add_foreign_key "opportunities", "vouchers"
  add_foreign_key "programs", "contacts"
  add_foreign_key "programs", "funding_sources"
  add_foreign_key "programs", "subgrantees"
  add_foreign_key "reissue_requests", "notifications"
  add_foreign_key "reissue_requests", "users", column: "reissued_by"
  add_foreign_key "sub_programs", "buildings"
  add_foreign_key "sub_programs", "contacts"
  add_foreign_key "sub_programs", "programs"
  add_foreign_key "sub_programs", "subgrantees"
  add_foreign_key "vouchers", "sub_programs"
  add_foreign_key "vouchers", "units"
end
