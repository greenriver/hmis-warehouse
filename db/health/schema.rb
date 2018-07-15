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

ActiveRecord::Schema.define(version: 20180714180735) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accountable_care_organizations", force: :cascade do |t|
    t.string  "name"
    t.string  "short_name"
    t.integer "mco_pid"
    t.string  "mco_sl"
    t.boolean "active",     default: true, null: false
  end

  create_table "agencies", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "agency_patient_referrals", force: :cascade do |t|
    t.integer  "agency_id",                           null: false
    t.integer  "patient_referral_id",                 null: false
    t.boolean  "claimed",             default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
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
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.datetime "appointment_time"
    t.string   "id_in_source"
    t.string   "patient_id"
    t.integer  "data_source_id",   default: 6, null: false
  end

  create_table "careplan_equipment", force: :cascade do |t|
    t.integer "careplan_id"
    t.integer "equipment_id"
  end

  create_table "careplan_services", force: :cascade do |t|
    t.integer "careplan_id"
    t.integer "service_id"
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
    t.datetime "patient_signed_on"
    t.datetime "provider_signed_on"
    t.boolean  "locked",                                   default: false, null: false
    t.datetime "initial_date"
    t.datetime "review_date"
    t.text     "patient_health_problems"
    t.text     "patient_strengths"
    t.text     "patient_goals"
    t.text     "patient_barriers"
    t.string   "status"
    t.integer  "responsible_team_member_id"
    t.integer  "provider_id"
    t.integer  "representative_id"
    t.datetime "responsible_team_member_signed_on"
    t.datetime "representative_signed_on"
    t.text     "service_archive"
    t.text     "equipment_archive"
    t.text     "team_members_archive"
    t.text     "goals_archive"
    t.datetime "patient_signature_requested_at"
    t.datetime "provider_signature_requested_at"
  end

  add_index "careplans", ["patient_id"], name: "index_careplans_on_patient_id", using: :btree
  add_index "careplans", ["user_id"], name: "index_careplans_on_user_id", using: :btree

  create_table "claims", force: :cascade do |t|
    t.integer  "user_id"
    t.date     "max_date"
    t.integer  "job_id"
    t.integer  "max_isa_control_number"
    t.integer  "max_group_control_number"
    t.integer  "max_st_number"
    t.text     "claims_file"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string   "error"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.datetime "deleted_at"
    t.datetime "submitted_at"
  end

  add_index "claims", ["deleted_at"], name: "index_claims_on_deleted_at", using: :btree

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

  create_table "comprehensive_health_assessments", force: :cascade do |t|
    t.integer  "patient_id"
    t.integer  "user_id"
    t.integer  "health_file_id"
    t.integer  "status",         default: 0
    t.integer  "reviewed_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.json     "answers"
    t.datetime "completed_at"
    t.datetime "reviewed_at"
    t.string   "reviewer"
  end

  add_index "comprehensive_health_assessments", ["health_file_id"], name: "index_comprehensive_health_assessments_on_health_file_id", using: :btree
  add_index "comprehensive_health_assessments", ["patient_id"], name: "index_comprehensive_health_assessments_on_patient_id", using: :btree
  add_index "comprehensive_health_assessments", ["reviewed_by_id"], name: "index_comprehensive_health_assessments_on_reviewed_by_id", using: :btree
  add_index "comprehensive_health_assessments", ["user_id"], name: "index_comprehensive_health_assessments_on_user_id", using: :btree

  create_table "cps", force: :cascade do |t|
    t.string   "pid"
    t.string   "sl"
    t.string   "mmis_enrollment_name"
    t.string   "short_name"
    t.string   "pt_part_1"
    t.string   "pt_part_2"
    t.string   "address_1"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "key_contact_first_name"
    t.string   "key_contact_last_name"
    t.string   "key_contact_email"
    t.string   "key_contact_phone"
    t.boolean  "sender",                 default: false, null: false
    t.string   "receiver_name"
    t.string   "receiver_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string   "npi"
    t.string   "ein"
  end

  create_table "data_sources", force: :cascade do |t|
    t.string   "name"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "epic_case_notes", force: :cascade do |t|
    t.string   "patient_id",                null: false
    t.string   "id_in_source",              null: false
    t.datetime "contact_date"
    t.string   "closed"
    t.string   "encounter_type"
    t.string   "provider_name"
    t.string   "location"
    t.string   "chief_complaint_1"
    t.string   "chief_complaint_1_comment"
    t.string   "chief_complaint_2"
    t.string   "chief_complaint_2_comment"
    t.string   "dx_1_icd10"
    t.string   "dx_1_name"
    t.string   "dx_2_icd10"
    t.string   "dx_2_name"
    t.string   "homeless_status"
    t.integer  "data_source_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "epic_case_notes", ["patient_id"], name: "index_epic_case_notes_on_patient_id", using: :btree

  create_table "epic_goals", force: :cascade do |t|
    t.string   "patient_id",                           null: false
    t.string   "entered_by"
    t.string   "title"
    t.string   "contents"
    t.string   "id_in_source"
    t.string   "received_valid_complaint"
    t.datetime "goal_created_at"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "data_source_id",           default: 6, null: false
  end

  add_index "epic_goals", ["patient_id"], name: "index_epic_goals_on_patient_id", using: :btree

  create_table "epic_patients", force: :cascade do |t|
    t.string   "id_in_source",                             null: false
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
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "gender"
    t.datetime "consent_revoked"
    t.string   "medicaid_id"
    t.string   "housing_status"
    t.datetime "housing_status_timestamp"
    t.boolean  "pilot",                    default: false, null: false
    t.integer  "data_source_id",           default: 6,     null: false
    t.datetime "deleted_at"
    t.date     "death_date"
  end

  create_table "epic_team_members", force: :cascade do |t|
    t.string   "patient_id",     null: false
    t.string   "id_in_source"
    t.string   "name"
    t.string   "pcp_type"
    t.string   "relationship"
    t.string   "email"
    t.string   "phone"
    t.datetime "processed"
    t.integer  "data_source_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "equipment", force: :cascade do |t|
    t.string   "item"
    t.string   "provider"
    t.integer  "quantity"
    t.date     "effective_date"
    t.string   "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "patient_id"
    t.string   "status"
  end

  create_table "health_files", force: :cascade do |t|
    t.string   "type",         null: false
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
    t.float    "size"
  end

  add_index "health_files", ["type"], name: "index_health_files_on_type", using: :btree

  create_table "health_goals", force: :cascade do |t|
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
    t.text     "problem"
    t.date     "start_date"
    t.text     "intervention"
    t.string   "status"
    t.integer  "responsible_team_member_id"
    t.integer  "patient_id"
  end

  add_index "health_goals", ["patient_id"], name: "index_health_goals_on_patient_id", using: :btree
  add_index "health_goals", ["user_id"], name: "index_health_goals_on_user_id", using: :btree

  create_table "medications", force: :cascade do |t|
    t.date     "start_date"
    t.date     "ordered_date"
    t.text     "name"
    t.text     "instructions"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "id_in_source"
    t.string   "patient_id"
    t.integer  "data_source_id", default: 6, null: false
  end

  create_table "member_status_report_patients", force: :cascade do |t|
    t.integer  "member_status_report_id"
    t.string   "medicaid_id",                    limit: 12
    t.string   "member_first_name",              limit: 100
    t.string   "member_last_name",               limit: 100
    t.string   "member_middle_initial",          limit: 1
    t.string   "member_suffix",                  limit: 20
    t.date     "member_date_of_birth"
    t.string   "member_sex",                     limit: 1
    t.string   "aco_mco_name",                   limit: 100
    t.string   "aco_mco_pid",                    limit: 9
    t.string   "aco_mco_sl",                     limit: 10
    t.string   "cp_name_official",               limit: 100
    t.string   "cp_pid",                         limit: 9
    t.string   "cp_sl",                          limit: 10
    t.string   "cp_outreach_status",             limit: 30
    t.date     "cp_last_contact_date"
    t.string   "cp_last_contact_face",           limit: 1
    t.string   "cp_contact_face"
    t.date     "cp_participation_form_date"
    t.date     "cp_care_plan_sent_pcp_date"
    t.date     "cp_care_plan_returned_pcp_date"
    t.string   "key_contact_name_first",         limit: 100
    t.string   "key_contact_name_last",          limit: 100
    t.string   "key_contact_phone",              limit: 10
    t.string   "key_contact_email",              limit: 60
    t.string   "care_coordinator_first_name",    limit: 100
    t.string   "care_coordinator_last_name",     limit: 100
    t.string   "care_coordinator_phone",         limit: 10
    t.string   "care_coordinator_email",         limit: 60
    t.string   "record_status",                  limit: 1
    t.date     "record_update_date"
    t.date     "export_date"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.datetime "deleted_at"
  end

  add_index "member_status_report_patients", ["deleted_at"], name: "index_member_status_report_patients_on_deleted_at", using: :btree

  create_table "member_status_reports", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "job_id"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string   "sender",                 limit: 100
    t.integer  "sent_row_num"
    t.integer  "sent_column_num"
    t.datetime "sent_export_time_stamp"
    t.string   "receiver"
    t.date     "report_start_date"
    t.date     "report_end_date"
    t.string   "error"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.datetime "deleted_at"
  end

  add_index "member_status_reports", ["deleted_at"], name: "index_member_status_reports_on_deleted_at", using: :btree

  create_table "participation_forms", force: :cascade do |t|
    t.integer  "patient_id"
    t.date     "signature_on"
    t.integer  "case_manager_id"
    t.integer  "reviewed_by_id"
    t.string   "location"
    t.integer  "health_file_id"
    t.datetime "reviewed_at"
    t.string   "reviewer"
  end

  add_index "participation_forms", ["case_manager_id"], name: "index_participation_forms_on_case_manager_id", using: :btree
  add_index "participation_forms", ["health_file_id"], name: "index_participation_forms_on_health_file_id", using: :btree
  add_index "participation_forms", ["patient_id"], name: "index_participation_forms_on_patient_id", using: :btree
  add_index "participation_forms", ["reviewed_by_id"], name: "index_participation_forms_on_reviewed_by_id", using: :btree

  create_table "patient_referral_imports", force: :cascade do |t|
    t.string   "file_name",  null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "patient_referrals", force: :cascade do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.date     "birthdate"
    t.string   "ssn"
    t.string   "medicaid_id"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.integer  "agency_id"
    t.boolean  "rejected",                         default: false,   null: false
    t.integer  "rejected_reason",                  default: 0,       null: false
    t.integer  "patient_id"
    t.integer  "accountable_care_organization_id"
    t.datetime "effective_date",                   default: "now()"
    t.string   "middle_initial"
    t.string   "suffix"
    t.string   "gender"
    t.string   "aco_name"
    t.integer  "aco_mco_pid"
    t.string   "aco_mco_sl"
    t.string   "health_plan_id"
    t.string   "cp_assignment_plan"
    t.string   "cp_name_dsrip"
    t.string   "cp_name_official"
    t.integer  "cp_pid"
    t.string   "cp_sl"
    t.date     "enrollment_start_date"
    t.string   "start_reason_description"
    t.string   "address_line_1"
    t.string   "address_line_2"
    t.string   "address_city"
    t.string   "address_state"
    t.string   "address_zip"
    t.string   "address_zip_plus_4"
    t.string   "email"
    t.string   "phone_cell"
    t.string   "phone_day"
    t.string   "phone_night"
    t.string   "primary_language"
    t.string   "primary_diagnosis"
    t.string   "secondary_diagnosis"
    t.string   "pcp_last_name"
    t.string   "pcp_first_name"
    t.string   "pcp_npi"
    t.string   "pcp_address_line_1"
    t.string   "pcp_address_line_2"
    t.string   "pcp_address_city"
    t.string   "pcp_address_state"
    t.string   "pcp_address_zip"
    t.string   "pcp_address_phone"
    t.string   "dmh"
    t.string   "dds"
    t.string   "eoea"
    t.string   "ed_visits"
    t.string   "snf_discharge"
    t.string   "identification"
    t.string   "record_status"
    t.date     "updated_on"
    t.date     "exported_on"
  end

  create_table "patients", force: :cascade do |t|
    t.string   "id_in_source",                             null: false
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
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.integer  "client_id"
    t.string   "gender"
    t.datetime "consent_revoked"
    t.string   "medicaid_id"
    t.string   "housing_status"
    t.datetime "housing_status_timestamp"
    t.boolean  "pilot",                    default: false, null: false
    t.integer  "data_source_id",           default: 6,     null: false
    t.date     "engagement_date"
    t.integer  "care_coordinator_id"
    t.datetime "deleted_at"
    t.date     "death_date"
  end

  create_table "problems", force: :cascade do |t|
    t.date     "onset_date"
    t.date     "last_assessed"
    t.text     "name"
    t.text     "comment"
    t.string   "icd10_list"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.string   "id_in_source"
    t.string   "patient_id"
    t.integer  "data_source_id", default: 6, null: false
  end

  create_table "qualifying_activities", force: :cascade do |t|
    t.string   "mode_of_contact"
    t.string   "mode_of_contact_other"
    t.string   "reached_client"
    t.string   "reached_client_collateral_contact"
    t.string   "activity"
    t.string   "source_type"
    t.integer  "source_id"
    t.datetime "claim_submitted_on"
    t.date     "date_of_activity"
    t.integer  "user_id"
    t.string   "user_full_name"
    t.string   "follow_up"
    t.integer  "patient_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "claim_id"
  end

  create_table "release_forms", force: :cascade do |t|
    t.integer  "patient_id"
    t.integer  "user_id"
    t.date     "signature_on"
    t.string   "file_location"
    t.integer  "health_file_id"
    t.integer  "reviewed_by_id"
    t.datetime "reviewed_at"
    t.string   "reviewer"
  end

  add_index "release_forms", ["health_file_id"], name: "index_release_forms_on_health_file_id", using: :btree
  add_index "release_forms", ["patient_id"], name: "index_release_forms_on_patient_id", using: :btree
  add_index "release_forms", ["reviewed_by_id"], name: "index_release_forms_on_reviewed_by_id", using: :btree
  add_index "release_forms", ["user_id"], name: "index_release_forms_on_user_id", using: :btree

  create_table "sdh_case_management_notes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "patient_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "topics"
    t.string   "title"
    t.integer  "total_time_spent_in_minutes"
    t.datetime "date_of_contact"
    t.string   "place_of_contact"
    t.string   "housing_status"
    t.string   "place_of_contact_other"
    t.string   "housing_status_other"
    t.datetime "housing_placement_date"
    t.text     "client_action"
    t.text     "notes_from_encounter"
    t.string   "client_phone_number"
    t.datetime "completed_on"
    t.integer  "health_file_id"
    t.string   "client_action_medication_reconciliation_clinician"
  end

  add_index "sdh_case_management_notes", ["health_file_id"], name: "index_sdh_case_management_notes_on_health_file_id", using: :btree

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
    t.string   "collection_location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "health_file_id"
  end

  create_table "services", force: :cascade do |t|
    t.string   "service_type"
    t.string   "provider"
    t.string   "hours"
    t.string   "days"
    t.date     "date_requested"
    t.date     "effective_date"
    t.date     "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "patient_id"
    t.string   "status"
  end

  create_table "signable_documents", force: :cascade do |t|
    t.integer  "signable_id",                                                              null: false
    t.string   "signable_type",                                                            null: false
    t.boolean  "primary",                default: true,                                    null: false
    t.integer  "user_id",                                                                  null: false
    t.jsonb    "hs_initial_request"
    t.jsonb    "hs_initial_response"
    t.datetime "hs_initial_response_at"
    t.jsonb    "hs_last_response"
    t.datetime "hs_last_response_at"
    t.string   "hs_subject",             default: "Signature Request",                     null: false
    t.string   "hs_title",               default: "Signature Request",                     null: false
    t.text     "hs_message",             default: "You've been asked to sign a document."
    t.jsonb    "signers",                default: [],                                      null: false
    t.jsonb    "signed_by",              default: [],                                      null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "signable_documents", ["signable_id", "signable_type"], name: "index_signable_documents_on_signable_id_and_signable_type", using: :btree

  create_table "team_members", force: :cascade do |t|
    t.string   "type",         null: false
    t.string   "first_name",   null: false
    t.string   "last_name",    null: false
    t.string   "email"
    t.string   "organization"
    t.string   "title"
    t.date     "last_contact"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "phone"
    t.integer  "patient_id"
  end

  add_index "team_members", ["patient_id"], name: "index_team_members_on_patient_id", using: :btree
  add_index "team_members", ["type"], name: "index_team_members_on_type", using: :btree

  create_table "teams", force: :cascade do |t|
    t.integer  "patient_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "careplan_id"
  end

  add_index "teams", ["careplan_id"], name: "index_teams_on_careplan_id", using: :btree

  create_table "user_care_coordinators", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "care_coordinator_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.datetime "deleted_at"
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
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "patient_id"
    t.datetime "date_of_service"
    t.integer  "data_source_id",  default: 6, null: false
  end

  add_foreign_key "comprehensive_health_assessments", "health_files"
  add_foreign_key "comprehensive_health_assessments", "patients"
  add_foreign_key "health_goals", "patients"
  add_foreign_key "participation_forms", "health_files"
  add_foreign_key "release_forms", "health_files"
  add_foreign_key "sdh_case_management_notes", "health_files"
  add_foreign_key "team_members", "patients"
end
