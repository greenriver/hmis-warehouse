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

ActiveRecord::Schema.define(version: 20180516151527) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "agencies", force: :cascade do |t|
    t.string "name"
  end

  create_table "agency_patient_referrals", force: :cascade do |t|
    t.integer "agency_id",                           null: false
    t.integer "patient_referral_id",                 null: false
    t.boolean "claimed",             default: false, null: false
  end

  create_table "agency_users", force: :cascade do |t|
    t.integer "agency_id", null: false
    t.integer "user_id",   null: false
  end

  create_table "appointments", force: :cascade do |t|
    t.string   "appointment_type"
    t.text     "notes"
    t.string   "doctor"
    t.string   "department"
    t.string   "sa"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.datetime "appointment_time"
    t.string   "id_in_source"
    t.string   "patient_id"
  end

  create_table "careplans", force: :cascade do |t|
    t.integer  "patient_id"
    t.integer  "user_id"
    t.date     "sdh_enroll_date"
    t.date     "first_meeting_with_case_manager_date"
    t.date     "self_sufficiency_baseline_due_date"
    t.date     "self_sufficiency_final_due_date"
    t.date     "self_sufficiency_baseline_completed_date"
    t.date     "self_sufficiency_final_completed_date"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "careplans", ["patient_id"], name: "index_careplans_on_patient_id", using: :btree
  add_index "careplans", ["user_id"], name: "index_careplans_on_user_id", using: :btree

  create_table "claims_amount_paid_location_month", force: :cascade do |t|
    t.string  "medicaid_id",  null: false
    t.integer "year"
    t.integer "month"
    t.integer "ip"
    t.integer "emerg"
    t.integer "respite"
    t.integer "op"
    t.integer "rx"
    t.integer "other"
    t.integer "total"
    t.string  "year_month"
    t.string  "study_period"
  end

  add_index "claims_amount_paid_location_month", ["medicaid_id"], name: "index_claims_amount_paid_location_month_on_medicaid_id", using: :btree

  create_table "claims_claim_volume_location_month", force: :cascade do |t|
    t.string  "medicaid_id",  null: false
    t.integer "year"
    t.integer "month"
    t.integer "ip"
    t.integer "emerg"
    t.integer "respite"
    t.integer "op"
    t.integer "rx"
    t.integer "other"
    t.integer "total"
    t.string  "year_month"
    t.string  "study_period"
  end

  add_index "claims_claim_volume_location_month", ["medicaid_id"], name: "index_claims_claim_volume_location_month_on_medicaid_id", using: :btree

  create_table "claims_ed_nyu_severity", force: :cascade do |t|
    t.string "medicaid_id",           null: false
    t.string "category"
    t.float  "indiv_pct"
    t.float  "sdh_pct"
    t.float  "baseline_visits"
    t.float  "implementation_visits"
  end

  add_index "claims_ed_nyu_severity", ["medicaid_id"], name: "index_claims_ed_nyu_severity_on_medicaid_id", using: :btree

  create_table "claims_roster", force: :cascade do |t|
    t.string  "medicaid_id",                      null: false
    t.string  "last_name"
    t.string  "first_name"
    t.string  "gender"
    t.date    "dob"
    t.string  "race"
    t.string  "primary_language"
    t.boolean "disability_flag"
    t.float   "norm_risk_score"
    t.integer "mbr_months"
    t.integer "total_ty"
    t.integer "ed_visits"
    t.integer "acute_ip_admits"
    t.integer "average_days_to_readmit"
    t.string  "pcp"
    t.string  "epic_team"
    t.integer "member_months_baseline"
    t.integer "member_months_implementation"
    t.integer "cost_rank_ty"
    t.float   "average_ed_visits_baseline"
    t.float   "average_ed_visits_implementation"
    t.float   "average_ip_admits_baseline"
    t.float   "average_ip_admits_implementation"
    t.float   "average_days_to_readmit_baseline"
    t.float   "average_days_to_implementation"
    t.string  "case_manager"
    t.string  "housing_status"
    t.integer "baseline_admits"
    t.integer "implementation_admits"
  end

  add_index "claims_roster", ["medicaid_id"], name: "index_claims_roster_on_medicaid_id", using: :btree

  create_table "claims_top_conditions", force: :cascade do |t|
    t.string  "medicaid_id",         null: false
    t.integer "rank"
    t.string  "description"
    t.float   "indiv_pct"
    t.float   "sdh_pct"
    t.float   "baseline_paid"
    t.float   "implementation_paid"
  end

  add_index "claims_top_conditions", ["medicaid_id"], name: "index_claims_top_conditions_on_medicaid_id", using: :btree

  create_table "claims_top_ip_conditions", force: :cascade do |t|
    t.string  "medicaid_id",         null: false
    t.integer "rank"
    t.string  "description"
    t.float   "indiv_pct"
    t.float   "sdh_pct"
    t.float   "baseline_paid"
    t.float   "implementation_paid"
  end

  add_index "claims_top_ip_conditions", ["medicaid_id"], name: "index_claims_top_ip_conditions_on_medicaid_id", using: :btree

  create_table "claims_top_providers", force: :cascade do |t|
    t.string  "medicaid_id",         null: false
    t.integer "rank"
    t.string  "provider_name"
    t.float   "indiv_pct"
    t.float   "sdh_pct"
    t.float   "baseline_paid"
    t.float   "implementation_paid"
  end

  add_index "claims_top_providers", ["medicaid_id"], name: "index_claims_top_providers_on_medicaid_id", using: :btree

  create_table "epic_goals", force: :cascade do |t|
    t.string   "patient_id",               null: false
    t.string   "entered_by"
    t.string   "title"
    t.string   "contents"
    t.string   "id_in_source"
    t.string   "received_valid_complaint"
    t.datetime "goal_created_at"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "epic_goals", ["patient_id"], name: "index_epic_goals_on_patient_id", using: :btree

  create_table "health_goals", force: :cascade do |t|
    t.integer  "careplan_id"
    t.integer  "user_id"
    t.string   "type"
    t.integer  "number"
    t.string   "name"
    t.string   "associated_dx"
    t.string   "barriers"
    t.string   "provider_plan"
    t.string   "case_manager_plan"
    t.string   "rn_plan"
    t.string   "bh_plan"
    t.string   "other_plan"
    t.integer  "confidence"
    t.string   "az_housing"
    t.string   "az_income"
    t.string   "az_non_cash_benefits"
    t.string   "az_disabilities"
    t.string   "az_food"
    t.string   "az_employment"
    t.string   "az_training"
    t.string   "az_transportation"
    t.string   "az_life_skills"
    t.string   "az_health_care_coverage"
    t.string   "az_physical_health"
    t.string   "az_mental_health"
    t.string   "az_substance_use"
    t.string   "az_criminal_justice"
    t.string   "az_legal"
    t.string   "az_safety"
    t.string   "az_risk"
    t.string   "az_family"
    t.string   "az_community"
    t.string   "az_time_management"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "goal_details"
  end

  add_index "health_goals", ["careplan_id"], name: "index_health_goals_on_careplan_id", using: :btree
  add_index "health_goals", ["user_id"], name: "index_health_goals_on_user_id", using: :btree

  create_table "medications", force: :cascade do |t|
    t.date     "start_date"
    t.date     "ordered_date"
    t.text     "name"
    t.text     "instructions"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "id_in_source"
    t.string   "patient_id"
  end

  create_table "participation_forms", force: :cascade do |t|
    t.integer "patient_id"
    t.date    "signature_on"
    t.integer "case_manager_id"
    t.integer "reviewed_by_id"
    t.string  "location"
  end

  add_index "participation_forms", ["case_manager_id"], name: "index_participation_forms_on_case_manager_id", using: :btree
  add_index "participation_forms", ["patient_id"], name: "index_participation_forms_on_patient_id", using: :btree
  add_index "participation_forms", ["reviewed_by_id"], name: "index_participation_forms_on_reviewed_by_id", using: :btree

  create_table "patient_referrals", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.date     "birthdate"
    t.string   "ssn"
    t.string   "medicaid_id"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "agency_id"
    t.boolean  "rejected",        default: false, null: false
    t.integer  "rejected_reason", default: 0,     null: false
  end

  create_table "patients", force: :cascade do |t|
    t.string   "id_in_source",             null: false
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.text     "aliases"
    t.date     "birthdate"
    t.text     "allergy_list"
    t.string   "primary_care_physician"
    t.string   "transgender"
    t.string   "race"
    t.string   "ethnicity"
    t.string   "veteran_status"
    t.string   "ssn"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "client_id"
    t.string   "gender"
    t.datetime "consent_revoked"
    t.string   "medicaid_id"
    t.string   "housing_status"
    t.datetime "housing_status_timestamp"
  end

  create_table "problems", force: :cascade do |t|
    t.date     "onset_date"
    t.date     "last_assessed"
    t.text     "name"
    t.text     "comment"
    t.string   "icd10_list"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "id_in_source"
    t.string   "patient_id"
  end

  create_table "self_sufficiency_matrix_forms", force: :cascade do |t|
    t.integer  "patient_id"
    t.integer  "user_id"
    t.string   "point_completed"
    t.integer  "housing_score"
    t.text     "housing_notes"
    t.integer  "income_score"
    t.text     "income_notes"
    t.integer  "benefits_score"
    t.text     "benefits_notes"
    t.integer  "disabilities_score"
    t.text     "disabilities_notes"
    t.integer  "food_score"
    t.text     "food_notes"
    t.integer  "employment_score"
    t.text     "employment_notes"
    t.integer  "education_score"
    t.text     "education_notes"
    t.integer  "mobility_score"
    t.text     "mobility_notes"
    t.integer  "life_score"
    t.text     "life_notes"
    t.integer  "healthcare_score"
    t.text     "healthcare_notes"
    t.integer  "physical_health_score"
    t.text     "physical_health_notes"
    t.integer  "mental_health_score"
    t.text     "mental_health_notes"
    t.integer  "substance_abuse_score"
    t.text     "substance_abuse_notes"
    t.integer  "criminal_score"
    t.text     "criminal_notes"
    t.integer  "legal_score"
    t.text     "legal_notes"
    t.integer  "safety_score"
    t.text     "safety_notes"
    t.integer  "risk_score"
    t.text     "risk_notes"
    t.integer  "family_score"
    t.text     "family_notes"
    t.integer  "community_score"
    t.text     "community_notes"
    t.integer  "time_score"
    t.text     "time_notes"
    t.datetime "completed_at"
  end

  create_table "team_members", force: :cascade do |t|
    t.string   "type",         null: false
    t.integer  "team_id",      null: false
    t.string   "first_name",   null: false
    t.string   "last_name",    null: false
    t.string   "email",        null: false
    t.string   "organization"
    t.string   "title"
    t.date     "last_contact"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  add_index "team_members", ["team_id"], name: "index_team_members_on_team_id", using: :btree
  add_index "team_members", ["type"], name: "index_team_members_on_type", using: :btree

  create_table "teams", force: :cascade do |t|
    t.integer  "patient_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.integer  "user_id"
    t.string   "session_id"
    t.string   "request_id"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  create_table "visits", force: :cascade do |t|
    t.string   "department"
    t.string   "visit_type"
    t.string   "provider"
    t.string   "id_in_source"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "patient_id"
    t.datetime "date_of_service"
  end

end
