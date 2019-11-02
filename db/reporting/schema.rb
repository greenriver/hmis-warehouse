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

ActiveRecord::Schema.define(version: 20191102185806) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "warehouse_data_quality_report_enrollments", force: :cascade do |t|
    t.integer  "report_id"
    t.integer  "client_id"
    t.integer  "project_id"
    t.string   "project_name"
    t.integer  "project_type"
    t.integer  "enrollment_id"
    t.boolean  "enrolled"
    t.boolean  "active"
    t.boolean  "entered"
    t.boolean  "exited"
    t.boolean  "adult"
    t.boolean  "head_of_household"
    t.string   "household_id"
    t.string   "household_type"
    t.integer  "age"
    t.date     "dob"
    t.date     "entry_date"
    t.date     "exit_date"
    t.integer  "days_to_add_entry_date"
    t.integer  "days_to_add_exit_date"
    t.boolean  "dob_after_entry_date"
    t.date     "most_recent_service_within_range"
    t.boolean  "service_within_last_30_days"
    t.boolean  "service_after_exit"
    t.integer  "days_of_service"
    t.integer  "destination_id"
    t.boolean  "name_complete",                             default: false
    t.boolean  "name_missing",                              default: false
    t.boolean  "name_refused",                              default: false
    t.boolean  "name_not_collected",                        default: false
    t.boolean  "name_partial",                              default: false
    t.boolean  "ssn_complete",                              default: false
    t.boolean  "ssn_missing",                               default: false
    t.boolean  "ssn_refused",                               default: false
    t.boolean  "ssn_not_collected",                         default: false
    t.boolean  "ssn_partial",                               default: false
    t.boolean  "gender_complete",                           default: false
    t.boolean  "gender_missing",                            default: false
    t.boolean  "gender_refused",                            default: false
    t.boolean  "gender_not_collected",                      default: false
    t.boolean  "gender_partial",                            default: false
    t.boolean  "dob_complete",                              default: false
    t.boolean  "dob_missing",                               default: false
    t.boolean  "dob_refused",                               default: false
    t.boolean  "dob_not_collected",                         default: false
    t.boolean  "dob_partial",                               default: false
    t.boolean  "veteran_complete",                          default: false
    t.boolean  "veteran_missing",                           default: false
    t.boolean  "veteran_refused",                           default: false
    t.boolean  "veteran_not_collected",                     default: false
    t.boolean  "veteran_partial",                           default: false
    t.boolean  "ethnicity_complete",                        default: false
    t.boolean  "ethnicity_missing",                         default: false
    t.boolean  "ethnicity_refused",                         default: false
    t.boolean  "ethnicity_not_collected",                   default: false
    t.boolean  "ethnicity_partial",                         default: false
    t.boolean  "race_complete",                             default: false
    t.boolean  "race_missing",                              default: false
    t.boolean  "race_refused",                              default: false
    t.boolean  "race_not_collected",                        default: false
    t.boolean  "race_partial",                              default: false
    t.boolean  "disabling_condition_complete",              default: false
    t.boolean  "disabling_condition_missing",               default: false
    t.boolean  "disabling_condition_refused",               default: false
    t.boolean  "disabling_condition_not_collected",         default: false
    t.boolean  "disabling_condition_partial",               default: false
    t.boolean  "destination_complete",                      default: false
    t.boolean  "destination_missing",                       default: false
    t.boolean  "destination_refused",                       default: false
    t.boolean  "destination_not_collected",                 default: false
    t.boolean  "destination_partial",                       default: false
    t.boolean  "prior_living_situation_complete",           default: false
    t.boolean  "prior_living_situation_missing",            default: false
    t.boolean  "prior_living_situation_refused",            default: false
    t.boolean  "prior_living_situation_not_collected",      default: false
    t.boolean  "prior_living_situation_partial",            default: false
    t.boolean  "income_at_entry_complete",                  default: false
    t.boolean  "income_at_entry_missing",                   default: false
    t.boolean  "income_at_entry_refused",                   default: false
    t.boolean  "income_at_entry_not_collected",             default: false
    t.boolean  "income_at_entry_partial",                   default: false
    t.boolean  "income_at_exit_complete",                   default: false
    t.boolean  "income_at_exit_missing",                    default: false
    t.boolean  "income_at_exit_refused",                    default: false
    t.boolean  "income_at_exit_not_collected",              default: false
    t.boolean  "income_at_exit_partial",                    default: false
    t.boolean  "income_at_annual_assessment_complete",      default: false
    t.boolean  "income_at_annual_assessment_missing",       default: false
    t.boolean  "income_at_annual_assessment_refused",       default: false
    t.boolean  "income_at_annual_assessment_not_collected", default: false
    t.boolean  "income_at_annual_assessment_partial",       default: false
    t.boolean  "should_have_income_annual_assessment",      default: false
    t.boolean  "include_in_income_change_calculation"
    t.integer  "income_at_entry_earned"
    t.integer  "income_at_entry_non_employment_cash"
    t.integer  "income_at_entry_overall"
    t.integer  "income_at_entry_response"
    t.integer  "income_at_annual_earned"
    t.integer  "income_at_annual_non_employment_cash"
    t.integer  "income_at_annual_overall"
    t.integer  "income_at_later_date_response"
    t.integer  "income_at_later_date_earned"
    t.integer  "income_at_later_date_non_employment_cash"
    t.integer  "income_at_later_date_overall"
    t.integer  "income_at_annual_response"
    t.integer  "days_to_move_in_date"
    t.integer  "days_ph_before_move_in_date"
    t.boolean  "incorrect_household_type",                  default: false
    t.string   "first_name"
    t.string   "last_name"
    t.string   "ssn"
    t.integer  "gender"
    t.integer  "name_data_quality"
    t.integer  "ssn_data_quality"
    t.integer  "dob_data_quality"
    t.integer  "veteran_status"
    t.integer  "disabling_condition"
    t.integer  "prior_living_situation"
    t.integer  "ethnicity"
    t.string   "race"
    t.date     "enrollment_date_created"
    t.date     "exit_date_created"
    t.date     "move_in_date"
    t.datetime "calculated_at",                                             null: false
    t.integer  "income_at_penultimate_earned"
    t.integer  "income_at_penultimate_non_employment_cash"
    t.integer  "income_at_penultimate_overall"
    t.integer  "income_at_penultimate_response"
  end

  add_index "warehouse_data_quality_report_enrollments", ["report_id", "active", "entered", "head_of_household", "enrolled"], name: "pdq_rep_act_ent_head_enr", using: :btree
  add_index "warehouse_data_quality_report_enrollments", ["report_id", "active", "exited", "head_of_household", "enrolled"], name: "pdq_rep_act_ext_head_enr", using: :btree

  create_table "warehouse_data_quality_report_project_groups", force: :cascade do |t|
    t.integer  "report_id"
    t.integer  "unit_inventory"
    t.integer  "bed_inventory"
    t.integer  "average_nightly_clients"
    t.integer  "average_nightly_households"
    t.integer  "average_bed_utilization"
    t.integer  "average_unit_utilization"
    t.jsonb    "nightly_client_census"
    t.jsonb    "nightly_household_census"
    t.datetime "calculated_at",              null: false
  end

  add_index "warehouse_data_quality_report_project_groups", ["report_id"], name: "pdq_p_groups_report_id", using: :btree

  create_table "warehouse_data_quality_report_projects", force: :cascade do |t|
    t.integer  "report_id"
    t.integer  "project_id"
    t.string   "project_name"
    t.string   "organization_name"
    t.integer  "project_type"
    t.date     "operating_start_date"
    t.string   "coc_code"
    t.string   "funder"
    t.string   "inventory_information_dates"
    t.string   "geocode"
    t.string   "geography_type"
    t.integer  "unit_inventory"
    t.integer  "bed_inventory"
    t.integer  "housing_type"
    t.integer  "average_nightly_clients"
    t.integer  "average_nightly_households"
    t.integer  "average_bed_utilization"
    t.integer  "average_unit_utilization"
    t.jsonb    "nightly_client_census"
    t.jsonb    "nightly_household_census"
    t.datetime "calculated_at",               null: false
  end

  add_index "warehouse_data_quality_report_projects", ["report_id", "project_id"], name: "pdq_projects_report_id_project_id", using: :btree

  create_table "warehouse_houseds", force: :cascade do |t|
    t.date    "search_start"
    t.date    "search_end"
    t.date    "housed_date"
    t.date    "housing_exit"
    t.integer "project_type"
    t.integer "destination"
    t.string  "service_project"
    t.string  "residential_project"
    t.integer "client_id",                               null: false
    t.string  "source"
    t.date    "dob"
    t.string  "race"
    t.integer "ethnicity"
    t.integer "gender"
    t.integer "veteran_status"
    t.date    "month_year"
    t.string  "ph_destination"
    t.integer "project_id"
    t.boolean "presented_as_individual", default: false
    t.boolean "children_only",           default: false
    t.boolean "individual_adult",        default: false
    t.integer "age_at_search_start"
    t.integer "age_at_search_end"
    t.integer "age_at_housed_date"
    t.integer "age_at_housing_exit"
  end

  add_index "warehouse_houseds", ["client_id"], name: "index_warehouse_houseds_on_client_id", using: :btree
  add_index "warehouse_houseds", ["housed_date"], name: "index_warehouse_houseds_on_housed_date", using: :btree
  add_index "warehouse_houseds", ["housing_exit"], name: "index_warehouse_houseds_on_housing_exit", using: :btree
  add_index "warehouse_houseds", ["project_type", "housed_date", "housing_exit", "project_id"], name: "housed_p_type_h_dates_p_id", using: :btree
  add_index "warehouse_houseds", ["project_type", "search_start", "search_end", "service_project", "housed_date", "housing_exit", "project_id"], name: "housed_p_type_s_dates_h_dates_p_id", using: :btree
  add_index "warehouse_houseds", ["project_type", "search_start", "search_end", "service_project", "project_id"], name: "housed_p_type_s_dates_p_id", using: :btree
  add_index "warehouse_houseds", ["search_end"], name: "index_warehouse_houseds_on_search_end", using: :btree
  add_index "warehouse_houseds", ["search_start"], name: "index_warehouse_houseds_on_search_start", using: :btree

  create_table "warehouse_monthly_client_ids", force: :cascade do |t|
    t.string  "report_type", null: false
    t.integer "client_id",   null: false
  end

  add_index "warehouse_monthly_client_ids", ["report_type", "client_id"], name: "index_warehouse_monthly_client_ids_on_report_type_and_client_id", using: :btree

  create_table "warehouse_monthly_reports", force: :cascade do |t|
    t.integer  "month",                                     null: false
    t.integer  "year",                                      null: false
    t.string   "type"
    t.integer  "client_id",                                 null: false
    t.integer  "head_of_household",         default: 0,     null: false
    t.string   "household_id"
    t.integer  "project_id",                                null: false
    t.integer  "organization_id",                           null: false
    t.integer  "destination_id"
    t.boolean  "first_enrollment",          default: false, null: false
    t.boolean  "enrolled",                  default: false, null: false
    t.boolean  "active",                    default: false, null: false
    t.boolean  "entered",                   default: false, null: false
    t.boolean  "exited",                    default: false, null: false
    t.integer  "project_type",                              null: false
    t.date     "entry_date"
    t.date     "exit_date"
    t.integer  "days_since_last_exit"
    t.integer  "prior_exit_project_type"
    t.integer  "prior_exit_destination_id"
    t.datetime "calculated_at",                             null: false
    t.integer  "enrollment_id"
  end

  add_index "warehouse_monthly_reports", ["active"], name: "index_warehouse_monthly_reports_on_active", using: :btree
  add_index "warehouse_monthly_reports", ["client_id"], name: "index_warehouse_monthly_reports_on_client_id", using: :btree
  add_index "warehouse_monthly_reports", ["enrolled"], name: "index_warehouse_monthly_reports_on_enrolled", using: :btree
  add_index "warehouse_monthly_reports", ["entered"], name: "index_warehouse_monthly_reports_on_entered", using: :btree
  add_index "warehouse_monthly_reports", ["exited"], name: "index_warehouse_monthly_reports_on_exited", using: :btree
  add_index "warehouse_monthly_reports", ["head_of_household"], name: "index_warehouse_monthly_reports_on_head_of_household", using: :btree
  add_index "warehouse_monthly_reports", ["household_id"], name: "index_warehouse_monthly_reports_on_household_id", using: :btree
  add_index "warehouse_monthly_reports", ["month"], name: "index_warehouse_monthly_reports_on_month", using: :btree
  add_index "warehouse_monthly_reports", ["organization_id"], name: "index_warehouse_monthly_reports_on_organization_id", using: :btree
  add_index "warehouse_monthly_reports", ["project_id"], name: "index_warehouse_monthly_reports_on_project_id", using: :btree
  add_index "warehouse_monthly_reports", ["type", "destination_id", "enrolled"], name: "idx_dest_type_enr", using: :btree
  add_index "warehouse_monthly_reports", ["type", "month", "year", "active", "entered", "head_of_household"], name: "idx_year_month_type_act_ent", using: :btree
  add_index "warehouse_monthly_reports", ["type", "month", "year", "active", "exited", "head_of_household"], name: "idx_year_month_type_act_ext", using: :btree
  add_index "warehouse_monthly_reports", ["type", "month", "year", "enrolled"], name: "idx_year_month_type_enr", using: :btree
  add_index "warehouse_monthly_reports", ["type", "month", "year", "head_of_household"], name: "idx_year_month_type_head", using: :btree
  add_index "warehouse_monthly_reports", ["type", "month", "year", "project_type", "active", "entered", "head_of_household"], name: "idx_year_month_type_proj_act_ent", using: :btree
  add_index "warehouse_monthly_reports", ["type", "month", "year", "project_type", "active", "exited", "head_of_household"], name: "idx_year_month_type_proj_act_ext", using: :btree
  add_index "warehouse_monthly_reports", ["type", "month", "year", "project_type", "enrolled"], name: "idx_year_month_type_proj_enr", using: :btree
  add_index "warehouse_monthly_reports", ["type", "month", "year", "project_type", "head_of_household"], name: "idx_year_month_type_proj_head", using: :btree
  add_index "warehouse_monthly_reports", ["type"], name: "index_warehouse_monthly_reports_on_type", using: :btree
  add_index "warehouse_monthly_reports", ["year"], name: "index_warehouse_monthly_reports_on_year", using: :btree

  create_table "warehouse_returns", force: :cascade do |t|
    t.integer "service_history_enrollment_id", null: false
    t.string  "record_type",                   null: false
    t.integer "age"
    t.integer "service_type"
    t.integer "client_id",                     null: false
    t.integer "project_type"
    t.date    "first_date_in_program",         null: false
    t.date    "last_date_in_program"
    t.integer "project_id"
    t.integer "destination"
    t.string  "project_name"
    t.integer "organization_id"
    t.boolean "unaccompanied_youth"
    t.boolean "parenting_youth"
    t.date    "start_date"
    t.date    "end_date"
    t.integer "length_of_stay"
    t.boolean "juvenile"
  end

  add_index "warehouse_returns", ["client_id"], name: "index_warehouse_returns_on_client_id", using: :btree
  add_index "warehouse_returns", ["first_date_in_program"], name: "index_warehouse_returns_on_first_date_in_program", using: :btree
  add_index "warehouse_returns", ["project_type"], name: "index_warehouse_returns_on_project_type", using: :btree
  add_index "warehouse_returns", ["record_type"], name: "index_warehouse_returns_on_record_type", using: :btree
  add_index "warehouse_returns", ["service_history_enrollment_id"], name: "index_warehouse_returns_on_service_history_enrollment_id", using: :btree
  add_index "warehouse_returns", ["service_type"], name: "index_warehouse_returns_on_service_type", using: :btree

end
