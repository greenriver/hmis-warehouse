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

ActiveRecord::Schema.define(version: 2020_01_28_142909) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "warehouse_data_quality_report_enrollments", id: :serial, force: :cascade do |t|
    t.integer "report_id"
    t.integer "client_id"
    t.integer "project_id"
    t.string "project_name"
    t.integer "project_type"
    t.integer "enrollment_id"
    t.boolean "enrolled"
    t.boolean "active"
    t.boolean "entered"
    t.boolean "exited"
    t.boolean "adult"
    t.boolean "head_of_household"
    t.string "household_id"
    t.string "household_type"
    t.integer "age"
    t.date "dob"
    t.date "entry_date"
    t.date "exit_date"
    t.integer "days_to_add_entry_date"
    t.integer "days_to_add_exit_date"
    t.boolean "dob_after_entry_date"
    t.date "most_recent_service_within_range"
    t.boolean "service_within_last_30_days"
    t.boolean "service_after_exit"
    t.integer "days_of_service"
    t.integer "destination_id"
    t.boolean "name_complete", default: false
    t.boolean "name_missing", default: false
    t.boolean "name_refused", default: false
    t.boolean "name_not_collected", default: false
    t.boolean "name_partial", default: false
    t.boolean "ssn_complete", default: false
    t.boolean "ssn_missing", default: false
    t.boolean "ssn_refused", default: false
    t.boolean "ssn_not_collected", default: false
    t.boolean "ssn_partial", default: false
    t.boolean "gender_complete", default: false
    t.boolean "gender_missing", default: false
    t.boolean "gender_refused", default: false
    t.boolean "gender_not_collected", default: false
    t.boolean "gender_partial", default: false
    t.boolean "dob_complete", default: false
    t.boolean "dob_missing", default: false
    t.boolean "dob_refused", default: false
    t.boolean "dob_not_collected", default: false
    t.boolean "dob_partial", default: false
    t.boolean "veteran_complete", default: false
    t.boolean "veteran_missing", default: false
    t.boolean "veteran_refused", default: false
    t.boolean "veteran_not_collected", default: false
    t.boolean "veteran_partial", default: false
    t.boolean "ethnicity_complete", default: false
    t.boolean "ethnicity_missing", default: false
    t.boolean "ethnicity_refused", default: false
    t.boolean "ethnicity_not_collected", default: false
    t.boolean "ethnicity_partial", default: false
    t.boolean "race_complete", default: false
    t.boolean "race_missing", default: false
    t.boolean "race_refused", default: false
    t.boolean "race_not_collected", default: false
    t.boolean "race_partial", default: false
    t.boolean "disabling_condition_complete", default: false
    t.boolean "disabling_condition_missing", default: false
    t.boolean "disabling_condition_refused", default: false
    t.boolean "disabling_condition_not_collected", default: false
    t.boolean "disabling_condition_partial", default: false
    t.boolean "destination_complete", default: false
    t.boolean "destination_missing", default: false
    t.boolean "destination_refused", default: false
    t.boolean "destination_not_collected", default: false
    t.boolean "destination_partial", default: false
    t.boolean "prior_living_situation_complete", default: false
    t.boolean "prior_living_situation_missing", default: false
    t.boolean "prior_living_situation_refused", default: false
    t.boolean "prior_living_situation_not_collected", default: false
    t.boolean "prior_living_situation_partial", default: false
    t.boolean "income_at_entry_complete", default: false
    t.boolean "income_at_entry_missing", default: false
    t.boolean "income_at_entry_refused", default: false
    t.boolean "income_at_entry_not_collected", default: false
    t.boolean "income_at_entry_partial", default: false
    t.boolean "income_at_exit_complete", default: false
    t.boolean "income_at_exit_missing", default: false
    t.boolean "income_at_exit_refused", default: false
    t.boolean "income_at_exit_not_collected", default: false
    t.boolean "income_at_exit_partial", default: false
    t.boolean "income_at_annual_assessment_complete", default: false
    t.boolean "income_at_annual_assessment_missing", default: false
    t.boolean "income_at_annual_assessment_refused", default: false
    t.boolean "income_at_annual_assessment_not_collected", default: false
    t.boolean "income_at_annual_assessment_partial", default: false
    t.boolean "should_have_income_annual_assessment", default: false
    t.boolean "include_in_income_change_calculation"
    t.integer "income_at_entry_earned"
    t.integer "income_at_entry_non_employment_cash"
    t.integer "income_at_entry_overall"
    t.integer "income_at_entry_response"
    t.integer "income_at_annual_earned"
    t.integer "income_at_annual_non_employment_cash"
    t.integer "income_at_annual_overall"
    t.integer "income_at_later_date_response"
    t.integer "income_at_later_date_earned"
    t.integer "income_at_later_date_non_employment_cash"
    t.integer "income_at_later_date_overall"
    t.integer "income_at_annual_response"
    t.integer "days_to_move_in_date"
    t.integer "days_ph_before_move_in_date"
    t.boolean "incorrect_household_type", default: false
    t.string "first_name"
    t.string "last_name"
    t.string "ssn"
    t.integer "gender"
    t.integer "name_data_quality"
    t.integer "ssn_data_quality"
    t.integer "dob_data_quality"
    t.integer "veteran_status"
    t.integer "disabling_condition"
    t.integer "prior_living_situation"
    t.integer "ethnicity"
    t.string "race"
    t.date "enrollment_date_created"
    t.date "exit_date_created"
    t.date "move_in_date"
    t.datetime "calculated_at", null: false
    t.integer "income_at_penultimate_earned"
    t.integer "income_at_penultimate_non_employment_cash"
    t.integer "income_at_penultimate_overall"
    t.integer "income_at_penultimate_response"
    t.index ["report_id", "active", "entered", "head_of_household", "enrolled"], name: "pdq_rep_act_ent_head_enr"
    t.index ["report_id", "active", "exited", "head_of_household", "enrolled"], name: "pdq_rep_act_ext_head_enr"
  end

  create_table "warehouse_data_quality_report_project_groups", id: :serial, force: :cascade do |t|
    t.integer "report_id"
    t.integer "unit_inventory"
    t.integer "bed_inventory"
    t.integer "average_nightly_clients"
    t.integer "average_nightly_households"
    t.integer "average_bed_utilization"
    t.integer "average_unit_utilization"
    t.jsonb "nightly_client_census"
    t.jsonb "nightly_household_census"
    t.datetime "calculated_at", null: false
    t.index ["report_id"], name: "pdq_p_groups_report_id"
  end

  create_table "warehouse_data_quality_report_projects", id: :serial, force: :cascade do |t|
    t.integer "report_id"
    t.integer "project_id"
    t.string "project_name"
    t.string "organization_name"
    t.integer "project_type"
    t.date "operating_start_date"
    t.string "coc_code"
    t.string "funder"
    t.string "inventory_information_dates"
    t.string "geocode"
    t.string "geography_type"
    t.integer "unit_inventory"
    t.integer "bed_inventory"
    t.integer "housing_type"
    t.integer "average_nightly_clients"
    t.integer "average_nightly_households"
    t.integer "average_bed_utilization"
    t.integer "average_unit_utilization"
    t.jsonb "nightly_client_census"
    t.jsonb "nightly_household_census"
    t.datetime "calculated_at", null: false
    t.index ["report_id", "project_id"], name: "pdq_projects_report_id_project_id"
  end

  create_table "warehouse_houseds", id: :serial, force: :cascade do |t|
    t.date "search_start"
    t.date "search_end"
    t.date "housed_date"
    t.date "housing_exit"
    t.integer "project_type"
    t.integer "destination"
    t.string "service_project"
    t.string "residential_project"
    t.integer "client_id", null: false
    t.string "source"
    t.date "dob"
    t.string "race"
    t.integer "ethnicity"
    t.integer "gender"
    t.integer "veteran_status"
    t.date "month_year"
    t.string "ph_destination"
    t.integer "project_id"
    t.boolean "presented_as_individual", default: false
    t.boolean "children_only", default: false
    t.boolean "individual_adult", default: false
    t.integer "age_at_search_start"
    t.integer "age_at_search_end"
    t.integer "age_at_housed_date"
    t.integer "age_at_housing_exit"
    t.boolean "head_of_household", default: false
    t.index ["client_id"], name: "index_warehouse_houseds_on_client_id"
    t.index ["housed_date"], name: "index_warehouse_houseds_on_housed_date"
    t.index ["housing_exit"], name: "index_warehouse_houseds_on_housing_exit"
    t.index ["project_type", "housed_date", "housing_exit", "project_id"], name: "housed_p_type_h_dates_p_id"
    t.index ["project_type", "search_start", "search_end", "service_project", "housed_date", "housing_exit", "project_id"], name: "housed_p_type_s_dates_h_dates_p_id"
    t.index ["project_type", "search_start", "search_end", "service_project", "project_id"], name: "housed_p_type_s_dates_p_id"
    t.index ["search_end"], name: "index_warehouse_houseds_on_search_end"
    t.index ["search_start"], name: "index_warehouse_houseds_on_search_start"
  end

  create_table "warehouse_monthly_client_ids", id: :serial, force: :cascade do |t|
    t.string "report_type", null: false
    t.integer "client_id", null: false
    t.index ["report_type", "client_id"], name: "index_warehouse_monthly_client_ids_on_report_type_and_client_id"
  end

  create_table "warehouse_partitioned_monthly_reports", force: :cascade do |t|
    t.integer "month", null: false
    t.integer "year", null: false
    t.string "type"
    t.integer "client_id", null: false
    t.integer "head_of_household", default: 0, null: false
    t.string "household_id"
    t.integer "project_id", null: false
    t.integer "organization_id", null: false
    t.integer "destination_id"
    t.boolean "first_enrollment", default: false, null: false
    t.boolean "enrolled", default: false, null: false
    t.boolean "active", default: false, null: false
    t.boolean "entered", default: false, null: false
    t.boolean "exited", default: false, null: false
    t.integer "project_type", null: false
    t.date "entry_date"
    t.date "exit_date"
    t.integer "days_since_last_exit"
    t.integer "prior_exit_project_type"
    t.integer "prior_exit_destination_id"
    t.datetime "calculated_at", null: false
    t.integer "enrollment_id"
    t.date "mid_month"
  end

  create_table "warehouse_partitioned_monthly_reports_all_clients", id: false, force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('warehouse_partitioned_monthly_reports_id_seq'::regclass)" }, null: false
    t.integer "month", null: false
    t.integer "year", null: false
    t.string "type"
    t.integer "client_id", null: false
    t.integer "head_of_household", default: 0, null: false
    t.string "household_id"
    t.integer "project_id", null: false
    t.integer "organization_id", null: false
    t.integer "destination_id"
    t.boolean "first_enrollment", default: false, null: false
    t.boolean "enrolled", default: false, null: false
    t.boolean "active", default: false, null: false
    t.boolean "entered", default: false, null: false
    t.boolean "exited", default: false, null: false
    t.integer "project_type", null: false
    t.date "entry_date"
    t.date "exit_date"
    t.integer "days_since_last_exit"
    t.integer "prior_exit_project_type"
    t.integer "prior_exit_destination_id"
    t.datetime "calculated_at", null: false
    t.integer "enrollment_id"
    t.date "mid_month"
    t.index ["client_id"], name: "index_month_all_clients_client_id"
    t.index ["id"], name: "index_month_all_clients_id", unique: true
    t.index ["mid_month", "active", "entered"], name: "index_month_all_clients_act_enter"
    t.index ["mid_month", "active", "exited"], name: "index_month_all_clients_act_exit"
    t.index ["mid_month", "destination_id", "enrolled"], name: "index_month_all_clients_dest_enr"
    t.index ["mid_month", "project_type", "head_of_household"], name: "index_month_all_clients_p_type_hoh"
  end

  create_table "warehouse_partitioned_monthly_reports_children", id: false, force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('warehouse_partitioned_monthly_reports_id_seq'::regclass)" }, null: false
    t.integer "month", null: false
    t.integer "year", null: false
    t.string "type"
    t.integer "client_id", null: false
    t.integer "head_of_household", default: 0, null: false
    t.string "household_id"
    t.integer "project_id", null: false
    t.integer "organization_id", null: false
    t.integer "destination_id"
    t.boolean "first_enrollment", default: false, null: false
    t.boolean "enrolled", default: false, null: false
    t.boolean "active", default: false, null: false
    t.boolean "entered", default: false, null: false
    t.boolean "exited", default: false, null: false
    t.integer "project_type", null: false
    t.date "entry_date"
    t.date "exit_date"
    t.integer "days_since_last_exit"
    t.integer "prior_exit_project_type"
    t.integer "prior_exit_destination_id"
    t.datetime "calculated_at", null: false
    t.integer "enrollment_id"
    t.date "mid_month"
    t.index ["client_id"], name: "index_month_children_client_id"
    t.index ["id"], name: "index_month_children_id", unique: true
    t.index ["mid_month", "active", "entered"], name: "index_month_children_act_enter"
    t.index ["mid_month", "active", "exited"], name: "index_month_children_act_exit"
    t.index ["mid_month", "destination_id", "enrolled"], name: "index_month_children_dest_enr"
    t.index ["mid_month", "project_type", "head_of_household"], name: "index_month_children_p_type_hoh"
  end

  create_table "warehouse_partitioned_monthly_reports_family", id: false, force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('warehouse_partitioned_monthly_reports_id_seq'::regclass)" }, null: false
    t.integer "month", null: false
    t.integer "year", null: false
    t.string "type"
    t.integer "client_id", null: false
    t.integer "head_of_household", default: 0, null: false
    t.string "household_id"
    t.integer "project_id", null: false
    t.integer "organization_id", null: false
    t.integer "destination_id"
    t.boolean "first_enrollment", default: false, null: false
    t.boolean "enrolled", default: false, null: false
    t.boolean "active", default: false, null: false
    t.boolean "entered", default: false, null: false
    t.boolean "exited", default: false, null: false
    t.integer "project_type", null: false
    t.date "entry_date"
    t.date "exit_date"
    t.integer "days_since_last_exit"
    t.integer "prior_exit_project_type"
    t.integer "prior_exit_destination_id"
    t.datetime "calculated_at", null: false
    t.integer "enrollment_id"
    t.date "mid_month"
    t.index ["client_id"], name: "index_month_family_client_id"
    t.index ["id"], name: "index_month_family_id", unique: true
    t.index ["mid_month", "active", "entered"], name: "index_month_family_act_enter"
    t.index ["mid_month", "active", "exited"], name: "index_month_family_act_exit"
    t.index ["mid_month", "destination_id", "enrolled"], name: "index_month_family_dest_enr"
    t.index ["mid_month", "project_type", "head_of_household"], name: "index_month_family_p_type_hoh"
  end

  create_table "warehouse_partitioned_monthly_reports_individual_adults", id: false, force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('warehouse_partitioned_monthly_reports_id_seq'::regclass)" }, null: false
    t.integer "month", null: false
    t.integer "year", null: false
    t.string "type"
    t.integer "client_id", null: false
    t.integer "head_of_household", default: 0, null: false
    t.string "household_id"
    t.integer "project_id", null: false
    t.integer "organization_id", null: false
    t.integer "destination_id"
    t.boolean "first_enrollment", default: false, null: false
    t.boolean "enrolled", default: false, null: false
    t.boolean "active", default: false, null: false
    t.boolean "entered", default: false, null: false
    t.boolean "exited", default: false, null: false
    t.integer "project_type", null: false
    t.date "entry_date"
    t.date "exit_date"
    t.integer "days_since_last_exit"
    t.integer "prior_exit_project_type"
    t.integer "prior_exit_destination_id"
    t.datetime "calculated_at", null: false
    t.integer "enrollment_id"
    t.date "mid_month"
    t.index ["client_id"], name: "index_month_individual_adults_client_id"
    t.index ["id"], name: "index_month_individual_adults_id", unique: true
    t.index ["mid_month", "active", "entered"], name: "index_month_individual_adults_act_enter"
    t.index ["mid_month", "active", "exited"], name: "index_month_individual_adults_act_exit"
    t.index ["mid_month", "destination_id", "enrolled"], name: "index_month_individual_adults_dest_enr"
    t.index ["mid_month", "project_type", "head_of_household"], name: "index_month_individual_adults_p_type_hoh"
  end

  create_table "warehouse_partitioned_monthly_reports_non_veteran", id: false, force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('warehouse_partitioned_monthly_reports_id_seq'::regclass)" }, null: false
    t.integer "month", null: false
    t.integer "year", null: false
    t.string "type"
    t.integer "client_id", null: false
    t.integer "head_of_household", default: 0, null: false
    t.string "household_id"
    t.integer "project_id", null: false
    t.integer "organization_id", null: false
    t.integer "destination_id"
    t.boolean "first_enrollment", default: false, null: false
    t.boolean "enrolled", default: false, null: false
    t.boolean "active", default: false, null: false
    t.boolean "entered", default: false, null: false
    t.boolean "exited", default: false, null: false
    t.integer "project_type", null: false
    t.date "entry_date"
    t.date "exit_date"
    t.integer "days_since_last_exit"
    t.integer "prior_exit_project_type"
    t.integer "prior_exit_destination_id"
    t.datetime "calculated_at", null: false
    t.integer "enrollment_id"
    t.date "mid_month"
    t.index ["client_id"], name: "index_month_non_veteran_client_id"
    t.index ["id"], name: "index_month_non_veteran_id", unique: true
    t.index ["mid_month", "active", "entered"], name: "index_month_non_veteran_act_enter"
    t.index ["mid_month", "active", "exited"], name: "index_month_non_veteran_act_exit"
    t.index ["mid_month", "destination_id", "enrolled"], name: "index_month_non_veteran_dest_enr"
    t.index ["mid_month", "project_type", "head_of_household"], name: "index_month_non_veteran_p_type_hoh"
  end

  create_table "warehouse_partitioned_monthly_reports_parenting_children", id: false, force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('warehouse_partitioned_monthly_reports_id_seq'::regclass)" }, null: false
    t.integer "month", null: false
    t.integer "year", null: false
    t.string "type"
    t.integer "client_id", null: false
    t.integer "head_of_household", default: 0, null: false
    t.string "household_id"
    t.integer "project_id", null: false
    t.integer "organization_id", null: false
    t.integer "destination_id"
    t.boolean "first_enrollment", default: false, null: false
    t.boolean "enrolled", default: false, null: false
    t.boolean "active", default: false, null: false
    t.boolean "entered", default: false, null: false
    t.boolean "exited", default: false, null: false
    t.integer "project_type", null: false
    t.date "entry_date"
    t.date "exit_date"
    t.integer "days_since_last_exit"
    t.integer "prior_exit_project_type"
    t.integer "prior_exit_destination_id"
    t.datetime "calculated_at", null: false
    t.integer "enrollment_id"
    t.date "mid_month"
    t.index ["client_id"], name: "index_month_parenting_children_client_id"
    t.index ["id"], name: "index_month_parenting_children_id", unique: true
    t.index ["mid_month", "active", "entered"], name: "index_month_parenting_children_act_enter"
    t.index ["mid_month", "active", "exited"], name: "index_month_parenting_children_act_exit"
    t.index ["mid_month", "destination_id", "enrolled"], name: "index_month_parenting_children_dest_enr"
    t.index ["mid_month", "project_type", "head_of_household"], name: "index_month_parenting_children_p_type_hoh"
  end

  create_table "warehouse_partitioned_monthly_reports_parenting_youth", id: false, force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('warehouse_partitioned_monthly_reports_id_seq'::regclass)" }, null: false
    t.integer "month", null: false
    t.integer "year", null: false
    t.string "type"
    t.integer "client_id", null: false
    t.integer "head_of_household", default: 0, null: false
    t.string "household_id"
    t.integer "project_id", null: false
    t.integer "organization_id", null: false
    t.integer "destination_id"
    t.boolean "first_enrollment", default: false, null: false
    t.boolean "enrolled", default: false, null: false
    t.boolean "active", default: false, null: false
    t.boolean "entered", default: false, null: false
    t.boolean "exited", default: false, null: false
    t.integer "project_type", null: false
    t.date "entry_date"
    t.date "exit_date"
    t.integer "days_since_last_exit"
    t.integer "prior_exit_project_type"
    t.integer "prior_exit_destination_id"
    t.datetime "calculated_at", null: false
    t.integer "enrollment_id"
    t.date "mid_month"
    t.index ["client_id"], name: "index_month_parenting_youth_client_id"
    t.index ["id"], name: "index_month_parenting_youth_id", unique: true
    t.index ["mid_month", "active", "entered"], name: "index_month_parenting_youth_act_enter"
    t.index ["mid_month", "active", "exited"], name: "index_month_parenting_youth_act_exit"
    t.index ["mid_month", "destination_id", "enrolled"], name: "index_month_parenting_youth_dest_enr"
    t.index ["mid_month", "project_type", "head_of_household"], name: "index_month_parenting_youth_p_type_hoh"
  end

  create_table "warehouse_partitioned_monthly_reports_unaccompanied_minors", id: false, force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('warehouse_partitioned_monthly_reports_id_seq'::regclass)" }, null: false
    t.integer "month", null: false
    t.integer "year", null: false
    t.string "type"
    t.integer "client_id", null: false
    t.integer "head_of_household", default: 0, null: false
    t.string "household_id"
    t.integer "project_id", null: false
    t.integer "organization_id", null: false
    t.integer "destination_id"
    t.boolean "first_enrollment", default: false, null: false
    t.boolean "enrolled", default: false, null: false
    t.boolean "active", default: false, null: false
    t.boolean "entered", default: false, null: false
    t.boolean "exited", default: false, null: false
    t.integer "project_type", null: false
    t.date "entry_date"
    t.date "exit_date"
    t.integer "days_since_last_exit"
    t.integer "prior_exit_project_type"
    t.integer "prior_exit_destination_id"
    t.datetime "calculated_at", null: false
    t.integer "enrollment_id"
    t.date "mid_month"
    t.index ["client_id"], name: "index_month_unaccompanied_minors_client_id"
    t.index ["id"], name: "index_month_unaccompanied_minors_id", unique: true
    t.index ["mid_month", "active", "entered"], name: "index_month_unaccompanied_minors_act_enter"
    t.index ["mid_month", "active", "exited"], name: "index_month_unaccompanied_minors_act_exit"
    t.index ["mid_month", "destination_id", "enrolled"], name: "index_month_unaccompanied_minors_dest_enr"
    t.index ["mid_month", "project_type", "head_of_household"], name: "index_month_unaccompanied_minors_p_type_hoh"
  end

  create_table "warehouse_partitioned_monthly_reports_unknown", id: false, force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('warehouse_partitioned_monthly_reports_id_seq'::regclass)" }, null: false
    t.integer "month", null: false
    t.integer "year", null: false
    t.string "type"
    t.integer "client_id", null: false
    t.integer "head_of_household", default: 0, null: false
    t.string "household_id"
    t.integer "project_id", null: false
    t.integer "organization_id", null: false
    t.integer "destination_id"
    t.boolean "first_enrollment", default: false, null: false
    t.boolean "enrolled", default: false, null: false
    t.boolean "active", default: false, null: false
    t.boolean "entered", default: false, null: false
    t.boolean "exited", default: false, null: false
    t.integer "project_type", null: false
    t.date "entry_date"
    t.date "exit_date"
    t.integer "days_since_last_exit"
    t.integer "prior_exit_project_type"
    t.integer "prior_exit_destination_id"
    t.datetime "calculated_at", null: false
    t.integer "enrollment_id"
    t.date "mid_month"
    t.index ["client_id"], name: "index_month_remainder_client_id"
    t.index ["id"], name: "index_month_remainder_id", unique: true
    t.index ["mid_month", "active", "entered"], name: "index_month_remainder_act_enter"
    t.index ["mid_month", "active", "exited"], name: "index_month_remainder_act_exit"
    t.index ["mid_month", "destination_id", "enrolled"], name: "index_month_remainder_dest_enr"
    t.index ["mid_month", "project_type", "head_of_household"], name: "index_month_remainder_p_type_hoh"
  end

  create_table "warehouse_partitioned_monthly_reports_veteran", id: false, force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('warehouse_partitioned_monthly_reports_id_seq'::regclass)" }, null: false
    t.integer "month", null: false
    t.integer "year", null: false
    t.string "type"
    t.integer "client_id", null: false
    t.integer "head_of_household", default: 0, null: false
    t.string "household_id"
    t.integer "project_id", null: false
    t.integer "organization_id", null: false
    t.integer "destination_id"
    t.boolean "first_enrollment", default: false, null: false
    t.boolean "enrolled", default: false, null: false
    t.boolean "active", default: false, null: false
    t.boolean "entered", default: false, null: false
    t.boolean "exited", default: false, null: false
    t.integer "project_type", null: false
    t.date "entry_date"
    t.date "exit_date"
    t.integer "days_since_last_exit"
    t.integer "prior_exit_project_type"
    t.integer "prior_exit_destination_id"
    t.datetime "calculated_at", null: false
    t.integer "enrollment_id"
    t.date "mid_month"
    t.index ["client_id"], name: "index_month_veteran_client_id"
    t.index ["id"], name: "index_month_veteran_id", unique: true
    t.index ["mid_month", "active", "entered"], name: "index_month_veteran_act_enter"
    t.index ["mid_month", "active", "exited"], name: "index_month_veteran_act_exit"
    t.index ["mid_month", "destination_id", "enrolled"], name: "index_month_veteran_dest_enr"
    t.index ["mid_month", "project_type", "head_of_household"], name: "index_month_veteran_p_type_hoh"
  end

  create_table "warehouse_partitioned_monthly_reports_youth", id: false, force: :cascade do |t|
    t.bigint "id", default: -> { "nextval('warehouse_partitioned_monthly_reports_id_seq'::regclass)" }, null: false
    t.integer "month", null: false
    t.integer "year", null: false
    t.string "type"
    t.integer "client_id", null: false
    t.integer "head_of_household", default: 0, null: false
    t.string "household_id"
    t.integer "project_id", null: false
    t.integer "organization_id", null: false
    t.integer "destination_id"
    t.boolean "first_enrollment", default: false, null: false
    t.boolean "enrolled", default: false, null: false
    t.boolean "active", default: false, null: false
    t.boolean "entered", default: false, null: false
    t.boolean "exited", default: false, null: false
    t.integer "project_type", null: false
    t.date "entry_date"
    t.date "exit_date"
    t.integer "days_since_last_exit"
    t.integer "prior_exit_project_type"
    t.integer "prior_exit_destination_id"
    t.datetime "calculated_at", null: false
    t.integer "enrollment_id"
    t.date "mid_month"
    t.index ["client_id"], name: "index_month_youth_client_id"
    t.index ["id"], name: "index_month_youth_id", unique: true
    t.index ["mid_month", "active", "entered"], name: "index_month_youth_act_enter"
    t.index ["mid_month", "active", "exited"], name: "index_month_youth_act_exit"
    t.index ["mid_month", "destination_id", "enrolled"], name: "index_month_youth_dest_enr"
    t.index ["mid_month", "project_type", "head_of_household"], name: "index_month_youth_p_type_hoh"
  end

  create_table "warehouse_returns", id: :serial, force: :cascade do |t|
    t.integer "service_history_enrollment_id", null: false
    t.string "record_type", null: false
    t.integer "age"
    t.integer "service_type"
    t.integer "client_id", null: false
    t.integer "project_type"
    t.date "first_date_in_program", null: false
    t.date "last_date_in_program"
    t.integer "project_id"
    t.integer "destination"
    t.string "project_name"
    t.integer "organization_id"
    t.boolean "unaccompanied_youth"
    t.boolean "parenting_youth"
    t.date "start_date"
    t.date "end_date"
    t.integer "length_of_stay"
    t.boolean "juvenile"
    t.index ["client_id"], name: "index_warehouse_returns_on_client_id"
    t.index ["first_date_in_program"], name: "index_warehouse_returns_on_first_date_in_program"
    t.index ["project_type"], name: "index_warehouse_returns_on_project_type"
    t.index ["record_type"], name: "index_warehouse_returns_on_record_type"
    t.index ["service_history_enrollment_id"], name: "index_warehouse_returns_on_service_history_enrollment_id"
    t.index ["service_type"], name: "index_warehouse_returns_on_service_type"
  end

end
