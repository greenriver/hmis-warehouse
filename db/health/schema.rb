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

ActiveRecord::Schema.define(version: 20170713184156) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appointments", force: :cascade do |t|
    t.string   "appointment_type"
    t.text     "notes"
    t.string   "doctor"
    t.string   "department"
    t.string   "sa"
    t.datetime "created_at",       :null=>false
    t.datetime "updated_at",       :null=>false
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
  add_index "careplans", ["patient_id"], :name=>"index_careplans_on_patient_id", :using=>:btree
  add_index "careplans", ["user_id"], :name=>"index_careplans_on_user_id", :using=>:btree

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
  add_index "health_goals", ["careplan_id"], :name=>"index_health_goals_on_careplan_id", :using=>:btree
  add_index "health_goals", ["user_id"], :name=>"index_health_goals_on_user_id", :using=>:btree

  create_table "medications", force: :cascade do |t|
    t.date     "start_date"
    t.date     "ordered_date"
    t.text     "name"
    t.text     "instructions"
    t.datetime "created_at",   :null=>false
    t.datetime "updated_at",   :null=>false
    t.string   "id_in_source"
    t.string   "patient_id"
  end

  create_table "patients", force: :cascade do |t|
    t.string   "id_in_source",           :null=>false
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
    t.datetime "created_at",             :null=>false
    t.datetime "updated_at",             :null=>false
    t.integer  "client_id"
    t.string   "gender"
    t.datetime "consent_revoked"
    t.string   "medicaid_id"
  end

  create_table "problems", force: :cascade do |t|
    t.date     "onset_date"
    t.date     "last_assessed"
    t.text     "name"
    t.text     "comment"
    t.string   "icd10_list"
    t.datetime "created_at",    :null=>false
    t.datetime "updated_at",    :null=>false
    t.string   "id_in_source"
    t.string   "patient_id"
  end

  create_table "team_members", force: :cascade do |t|
    t.string   "type",         :null=>false
    t.integer  "team_id",      :null=>false
    t.string   "first_name",   :null=>false
    t.string   "last_name",    :null=>false
    t.string   "email",        :null=>false
    t.string   "organization"
    t.string   "title"
    t.date     "last_contact"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end
  add_index "team_members", ["team_id"], :name=>"index_team_members_on_team_id", :using=>:btree
  add_index "team_members", ["type"], :name=>"index_team_members_on_type", :using=>:btree

  create_table "teams", force: :cascade do |t|
    t.integer  "patient_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  :null=>false
    t.integer  "item_id",    :null=>false
    t.string   "event",      :null=>false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.integer  "user_id"
    t.string   "session_id"
    t.string   "request_id"
  end
  add_index "versions", ["item_type", "item_id"], :name=>"index_versions_on_item_type_and_item_id", :using=>:btree

  create_table "visits", force: :cascade do |t|
    t.string   "department"
    t.string   "visit_type"
    t.string   "provider"
    t.string   "id_in_source"
    t.datetime "created_at",      :null=>false
    t.datetime "updated_at",      :null=>false
    t.string   "patient_id"
    t.datetime "date_of_service"
  end

end
