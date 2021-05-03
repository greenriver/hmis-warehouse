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

ActiveRecord::Schema.define(version: 2021_04_19_174757) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accountable_care_organizations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "short_name"
    t.integer "mco_pid"
    t.string "mco_sl"
    t.boolean "active", default: true, null: false
    t.string "edi_name"
    t.string "e_d_receiver_text"
    t.string "e_d_file_prefix"
    t.string "vpr_name"
  end

  create_table "agencies", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string "acceptable_domains"
  end

  create_table "agency_patient_referrals", id: :serial, force: :cascade do |t|
    t.integer "agency_id", null: false
    t.integer "patient_referral_id", null: false
    t.boolean "claimed", default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
  end

  create_table "agency_users", id: :serial, force: :cascade do |t|
    t.integer "agency_id", null: false
    t.integer "user_id", null: false
  end

  create_table "appointments", id: :serial, force: :cascade do |t|
    t.string "appointment_type"
    t.text "notes"
    t.string "doctor"
    t.string "department"
    t.string "sa"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "appointment_time"
    t.string "id_in_source"
    t.string "patient_id"
    t.integer "data_source_id", default: 6, null: false
  end

  create_table "backup_plans", force: :cascade do |t|
    t.bigint "patient_id"
    t.string "description"
    t.string "backup_plan"
    t.string "person"
    t.string "phone"
    t.text "address"
    t.date "plan_created_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["patient_id"], name: "index_backup_plans_on_patient_id"
  end

  create_table "careplan_equipment", id: :serial, force: :cascade do |t|
    t.integer "careplan_id"
    t.integer "equipment_id"
  end

  create_table "careplan_services", id: :serial, force: :cascade do |t|
    t.integer "careplan_id"
    t.integer "service_id"
  end

  create_table "careplans", id: :serial, force: :cascade do |t|
    t.integer "patient_id"
    t.integer "user_id"
    t.date "sdh_enroll_date"
    t.date "first_meeting_with_case_manager_date"
    t.date "self_sufficiency_baseline_due_date"
    t.date "self_sufficiency_final_due_date"
    t.date "self_sufficiency_baseline_completed_date"
    t.date "self_sufficiency_final_completed_date"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "patient_signed_on"
    t.datetime "provider_signed_on"
    t.boolean "locked", default: false, null: false
    t.datetime "initial_date"
    t.datetime "review_date"
    t.text "patient_health_problems"
    t.text "patient_strengths"
    t.text "patient_goals"
    t.text "patient_barriers"
    t.string "status"
    t.integer "responsible_team_member_id"
    t.integer "provider_id"
    t.integer "representative_id"
    t.datetime "responsible_team_member_signed_on"
    t.datetime "representative_signed_on"
    t.text "service_archive"
    t.text "equipment_archive"
    t.text "team_members_archive"
    t.text "goals_archive"
    t.datetime "patient_signature_requested_at"
    t.datetime "provider_signature_requested_at"
    t.integer "health_file_id"
    t.boolean "member_understands_contingency"
    t.boolean "member_verbalizes_understanding"
    t.text "backup_plan_archive"
    t.string "future_issues_0"
    t.string "future_issues_1"
    t.string "future_issues_2"
    t.string "future_issues_3"
    t.string "future_issues_4"
    t.string "future_issues_5"
    t.string "future_issues_6"
    t.string "future_issues_7"
    t.string "future_issues_8"
    t.string "future_issues_9"
    t.string "future_issues_10"
    t.string "patient_signature_mode"
    t.string "provider_signature_mode"
    t.index ["patient_id"], name: "index_careplans_on_patient_id"
    t.index ["user_id"], name: "index_careplans_on_user_id"
  end

  create_table "claims", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.date "max_date"
    t.integer "job_id"
    t.integer "max_isa_control_number"
    t.integer "max_group_control_number"
    t.integer "max_st_number"
    t.text "claims_file"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.datetime "submitted_at"
    t.datetime "precalculated_at"
    t.string "result"
    t.integer "transaction_acknowledgement_id"
    t.boolean "test_file", default: false
    t.index ["deleted_at"], name: "index_claims_on_deleted_at"
  end

  create_table "claims_amount_paid_location_month", id: :serial, force: :cascade do |t|
    t.string "medicaid_id", null: false
    t.integer "year"
    t.integer "month"
    t.integer "ip"
    t.integer "emerg"
    t.integer "respite"
    t.integer "op"
    t.integer "rx"
    t.integer "other"
    t.integer "total"
    t.string "year_month"
    t.string "study_period"
    t.index ["medicaid_id"], name: "index_claims_amount_paid_location_month_on_medicaid_id"
  end

  create_table "claims_claim_volume_location_month", id: :serial, force: :cascade do |t|
    t.string "medicaid_id", null: false
    t.integer "year"
    t.integer "month"
    t.integer "ip"
    t.integer "emerg"
    t.integer "respite"
    t.integer "op"
    t.integer "rx"
    t.integer "other"
    t.integer "total"
    t.string "year_month"
    t.string "study_period"
    t.index ["medicaid_id"], name: "index_claims_claim_volume_location_month_on_medicaid_id"
  end

  create_table "claims_ed_nyu_severity", id: :serial, force: :cascade do |t|
    t.string "medicaid_id", null: false
    t.string "category"
    t.float "indiv_pct"
    t.float "sdh_pct"
    t.float "baseline_visits"
    t.float "implementation_visits"
    t.index ["medicaid_id"], name: "index_claims_ed_nyu_severity_on_medicaid_id"
  end

  create_table "claims_reporting_ccs_lookups", force: :cascade do |t|
    t.string "hcpcs_start", null: false
    t.string "hcpcs_end", null: false
    t.integer "ccs_id", null: false
    t.string "ccs_label", null: false
    t.date "effective_start", null: false
    t.date "effective_end", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["effective_start", "hcpcs_start", "hcpcs_end"], name: "unk_code_range", unique: true
  end

  create_table "claims_reporting_cp_payment_details", force: :cascade do |t|
    t.bigint "cp_payment_upload_id", null: false
    t.string "medicaid_id", null: false
    t.date "cp_enrollment_start_date", null: false
    t.date "paid_dos", null: false
    t.date "payment_date", null: false
    t.decimal "amount_paid", precision: 10, scale: 2
    t.decimal "adjustment_amount", precision: 10, scale: 2
    t.string "member_cp_assignment_plan"
    t.string "cp_name_dsrip"
    t.string "cp_name_official"
    t.string "cp_pid"
    t.string "cp_sl"
    t.string "month_payment_issued"
    t.string "paid_num_icn"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cp_payment_upload_id"], name: "idx_cpd_on_cp_payment_upload_id"
    t.index ["paid_dos"], name: "index_claims_reporting_cp_payment_details_on_paid_dos"
    t.index ["payment_date"], name: "index_claims_reporting_cp_payment_details_on_payment_date"
  end

  create_table "claims_reporting_cp_payment_uploads", force: :cascade do |t|
    t.bigint "user_id"
    t.string "original_filename"
    t.binary "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_claims_reporting_cp_payment_uploads_on_deleted_at"
    t.index ["user_id"], name: "index_claims_reporting_cp_payment_uploads_on_user_id"
  end

  create_table "claims_reporting_engagement_trends", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "options"
    t.jsonb "results"
    t.string "processing_errors"
    t.datetime "completed_at"
    t.datetime "started_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["user_id"], name: "index_claims_reporting_engagement_trends_on_user_id"
  end

  create_table "claims_reporting_imports", force: :cascade do |t|
    t.string "source_url", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.boolean "successful"
    t.string "status_message"
    t.string "content_hash"
    t.binary "content"
    t.string "importer"
    t.string "method"
    t.jsonb "args"
    t.jsonb "env"
    t.jsonb "results"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "claims_reporting_medical_claims", force: :cascade do |t|
    t.string "member_id", limit: 50, null: false
    t.string "claim_number", limit: 30, null: false
    t.string "line_number", limit: 10, null: false
    t.string "cp_pidsl", limit: 50
    t.string "cp_name", limit: 255
    t.string "aco_pidsl", limit: 50
    t.string "aco_name", limit: 255
    t.string "pcc_pidsl", limit: 50
    t.string "pcc_name", limit: 255
    t.string "pcc_npi", limit: 50
    t.string "pcc_taxid", limit: 50
    t.string "mco_pidsl", limit: 50
    t.string "mco_name", limit: 50
    t.string "source", limit: 50
    t.string "claim_type", limit: 255
    t.date "member_dob"
    t.string "patient_status", limit: 255
    t.date "service_start_date"
    t.date "service_end_date"
    t.date "admit_date"
    t.date "discharge_date"
    t.string "type_of_bill", limit: 255
    t.string "admit_source", limit: 255
    t.string "admit_type", limit: 255
    t.string "frequency_code", limit: 255
    t.date "paid_date"
    t.decimal "billed_amount", precision: 19, scale: 4
    t.decimal "allowed_amount", precision: 19, scale: 4
    t.decimal "paid_amount", precision: 19, scale: 4
    t.string "admit_diagnosis", limit: 50
    t.string "dx_1", limit: 50
    t.string "dx_2", limit: 50
    t.string "dx_3", limit: 50
    t.string "dx_4", limit: 50
    t.string "dx_5", limit: 50
    t.string "dx_6", limit: 50
    t.string "dx_7", limit: 50
    t.string "dx_8", limit: 50
    t.string "dx_9", limit: 50
    t.string "dx_10", limit: 50
    t.string "dx_11", limit: 50
    t.string "dx_12", limit: 50
    t.string "dx_13", limit: 50
    t.string "dx_14", limit: 50
    t.string "dx_15", limit: 50
    t.string "dx_16", limit: 50
    t.string "dx_17", limit: 50
    t.string "dx_18", limit: 50
    t.string "dx_19", limit: 50
    t.string "dx_20", limit: 50
    t.string "dx_21", limit: 50
    t.string "dx_22", limit: 50
    t.string "dx_23", limit: 50
    t.string "dx_24", limit: 50
    t.string "dx_25", limit: 50
    t.string "e_dx_1", limit: 50
    t.string "e_dx_2", limit: 50
    t.string "e_dx_3", limit: 50
    t.string "e_dx_4", limit: 50
    t.string "e_dx_5", limit: 50
    t.string "e_dx_6", limit: 50
    t.string "e_dx_7", limit: 50
    t.string "e_dx_8", limit: 50
    t.string "e_dx_9", limit: 50
    t.string "e_dx_10", limit: 50
    t.string "e_dx_11", limit: 50
    t.string "e_dx_12", limit: 50
    t.string "icd_version", limit: 50
    t.string "surgical_procedure_code_1", limit: 50
    t.string "surgical_procedure_code_2", limit: 50
    t.string "surgical_procedure_code_3", limit: 50
    t.string "surgical_procedure_code_4", limit: 50
    t.string "surgical_procedure_code_5", limit: 50
    t.string "surgical_procedure_code_6", limit: 50
    t.string "revenue_code", limit: 50
    t.string "place_of_service_code", limit: 50
    t.string "procedure_code", limit: 50
    t.string "procedure_modifier_1", limit: 50
    t.string "procedure_modifier_2", limit: 50
    t.string "procedure_modifier_3", limit: 50
    t.string "procedure_modifier_4", limit: 50
    t.string "drg_code", limit: 50
    t.string "drg_version_code", limit: 50
    t.string "severity_of_illness", limit: 50
    t.string "service_provider_npi", limit: 50
    t.string "id_provider_servicing", limit: 50
    t.string "servicing_taxid", limit: 50
    t.string "servicing_provider_name", limit: 512
    t.string "servicing_provider_type", limit: 255
    t.string "servicing_provider_taxonomy", limit: 255
    t.string "servicing_address", limit: 512
    t.string "servicing_city", limit: 255
    t.string "servicing_state", limit: 255
    t.string "servicing_zip", limit: 50
    t.string "billing_npi", limit: 50
    t.string "id_provider_billing", limit: 50
    t.string "billing_taxid", limit: 50
    t.string "billing_provider_name", limit: 512
    t.string "billing_provider_type", limit: 50
    t.string "billing_provider_taxonomy", limit: 50
    t.string "billing_address", limit: 512
    t.string "billing_city", limit: 255
    t.string "billing_state", limit: 255
    t.string "billing_zip", limit: 50
    t.string "claim_status", limit: 255
    t.string "disbursement_code", limit: 255
    t.string "enrolled_flag", limit: 50
    t.string "referral_circle_ind", limit: 50
    t.string "mbhp_flag", limit: 50
    t.string "present_on_admission_1", limit: 50
    t.string "present_on_admission_2", limit: 50
    t.string "present_on_admission_3", limit: 50
    t.string "present_on_admission_4", limit: 50
    t.string "present_on_admission_5", limit: 50
    t.string "present_on_admission_6", limit: 50
    t.string "present_on_admission_7", limit: 50
    t.string "present_on_admission_8", limit: 50
    t.string "present_on_admission_9", limit: 50
    t.string "present_on_admission_10", limit: 50
    t.string "present_on_admission_11", limit: 50
    t.string "present_on_admission_12", limit: 50
    t.string "present_on_admission_13", limit: 50
    t.string "present_on_admission_14", limit: 50
    t.string "present_on_admission_15", limit: 50
    t.string "present_on_admission_16", limit: 50
    t.string "present_on_admission_17", limit: 50
    t.string "present_on_admission_18", limit: 50
    t.string "present_on_admission_19", limit: 50
    t.string "present_on_admission_20", limit: 50
    t.string "present_on_admission_21", limit: 50
    t.string "present_on_admission_22", limit: 50
    t.string "present_on_admission_23", limit: 50
    t.string "present_on_admission_24", limit: 50
    t.string "present_on_admission_25", limit: 50
    t.string "e_dx_present_on_admission_1", limit: 50
    t.string "e_dx_present_on_admission_2", limit: 50
    t.string "e_dx_present_on_admission_3", limit: 50
    t.string "e_dx_present_on_admission_4", limit: 50
    t.string "e_dx_present_on_admission_5", limit: 50
    t.string "e_dx_present_on_admission_6", limit: 50
    t.string "e_dx_present_on_admission_7", limit: 50
    t.string "e_dx_present_on_admission_8", limit: 50
    t.string "e_dx_present_on_admission_9", limit: 50
    t.string "e_dx_present_on_admission_10", limit: 50
    t.string "e_dx_present_on_admission_11", limit: 50
    t.string "e_dx_present_on_admission_12", limit: 50
    t.decimal "quantity", precision: 12, scale: 4
    t.string "price_method", limit: 50
    t.string "ccs_id"
    t.string "cde_cos_rollup", limit: 50
    t.string "cde_cos_category", limit: 50
    t.string "cde_cos_subcategory", limit: 50
    t.string "ind_mco_aco_cvd_svc", limit: 50
    t.integer "enrolled_days", default: 0, comment: "Est. number of days the member has been enrolled as of the service start date."
    t.integer "engaged_days", default: 0, comment: "Est. number of days the member has been engaged by a CP as of the service start date."
    t.index "daterange(service_start_date, service_end_date, '[]'::text)", name: "claims_reporting_medical_claims_service_daterange", using: :gist
    t.index ["aco_name"], name: "index_claims_reporting_medical_claims_on_aco_name"
    t.index ["aco_pidsl"], name: "index_claims_reporting_medical_claims_on_aco_pidsl"
    t.index ["member_id", "claim_number", "line_number"], name: "unk_cr_medical_claim", unique: true
    t.index ["member_id", "service_start_date"], name: "idx_crmc_member_service_start_date"
    t.index ["service_start_date"], name: "index_claims_reporting_medical_claims_on_service_start_date"
  end

  create_table "claims_reporting_member_diagnosis_classifications", force: :cascade do |t|
    t.string "member_id", null: false
    t.boolean "currently_assigned"
    t.boolean "currently_engaged"
    t.boolean "ast", comment: "asthma"
    t.boolean "cpd", comment: "copd"
    t.boolean "cir", comment: "cardiac disease"
    t.boolean "dia", comment: "diabetes"
    t.boolean "spn", comment: "degenerative spinal disease/chronic pain"
    t.boolean "gbt", comment: "gi and biliary tract disease"
    t.boolean "obs", comment: "obesity"
    t.boolean "hyp", comment: "hypertension"
    t.boolean "hep", comment: "hepatitis"
    t.boolean "sch", comment: "schizophrenia"
    t.boolean "pbd", comment: "psychoses/bipolar disorders"
    t.boolean "das", comment: "depression/anxiety/stress reactions"
    t.boolean "pid", comment: "personality/impulse disorder"
    t.boolean "sia", comment: "suicidal ideation/attempt"
    t.boolean "sud", comment: "substance Abuse Disorder"
    t.boolean "other_bh", comment: "other behavioral health"
    t.boolean "coi", comment: "cohort of interest"
    t.boolean "high_er", comment: "5+ ER Visits with No IP Psych Admission"
    t.boolean "psychoses", comment: "1+ Psychoses Admissions"
    t.boolean "other_ip_psych", comment: "+ IP Psych Admissions"
    t.boolean "high_util", comment: "3+ inpatient stays or 5+ emergency room visits throughout their claims experience"
    t.integer "er_visits"
    t.integer "ip_admits"
    t.integer "ip_admits_psychoses"
    t.integer "antipsy_day"
    t.integer "engaged_member_days"
    t.integer "engaged_member_months"
    t.integer "antipsy_denom"
    t.integer "antidep_day"
    t.integer "antidep_denom"
    t.integer "moodstab_day"
    t.integer "moodstab_denom"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "unk_crmd"
  end

  create_table "claims_reporting_member_enrollment_rosters", force: :cascade do |t|
    t.string "member_id", limit: 50, null: false
    t.string "performance_year", limit: 50
    t.string "region", limit: 50
    t.string "service_area", limit: 50
    t.string "aco_pidsl", limit: 50
    t.string "aco_name", limit: 255
    t.string "pcc_pidsl", limit: 50
    t.string "pcc_name", limit: 255
    t.string "pcc_npi", limit: 50
    t.string "pcc_taxid", limit: 50
    t.string "mco_pidsl", limit: 50
    t.string "mco_name", limit: 50
    t.string "enrolled_flag", limit: 50
    t.string "enroll_type", limit: 50
    t.string "enroll_stop_reason", limit: 50
    t.string "rating_category_char_cd", limit: 255
    t.string "ind_dds", limit: 50
    t.string "ind_dmh", limit: 50
    t.string "ind_dta", limit: 50
    t.string "ind_dss", limit: 50
    t.string "cde_hcb_waiver", limit: 50
    t.string "cde_waiver_category", limit: 50
    t.date "span_start_date", null: false
    t.date "span_end_date"
    t.integer "span_mem_days"
    t.string "cp_prov_type", limit: 255
    t.string "cp_plan_type", limit: 255
    t.string "cp_pidsl", limit: 50
    t.string "cp_prov_name", limit: 512
    t.date "cp_enroll_dt"
    t.date "cp_disenroll_dt"
    t.string "cp_start_rsn", limit: 255
    t.string "cp_stop_rsn", limit: 255
    t.string "ind_medicare_a", limit: 50
    t.string "ind_medicare_b", limit: 50
    t.string "tpl_coverage_cat", limit: 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date "engagement_date"
    t.integer "engaged_days"
    t.date "enrollment_end_at_engagement_calculation"
    t.date "first_claim_date"
    t.integer "pre_engagement_days", default: 0
    t.index ["member_id", "span_start_date"], name: "unk_cr_member_enrollment_roster", unique: true
  end

  create_table "claims_reporting_member_rosters", force: :cascade do |t|
    t.string "member_id", limit: 50, null: false
    t.string "nam_first", limit: 255
    t.string "nam_last", limit: 255
    t.string "cp_pidsl", limit: 50
    t.string "cp_name", limit: 255
    t.string "aco_pidsl", limit: 50
    t.string "aco_name", limit: 255
    t.string "mco_pidsl", limit: 50
    t.string "mco_name", limit: 50
    t.string "sex", limit: 50
    t.date "date_of_birth"
    t.string "mailing_address_1", limit: 512
    t.string "mailing_address_2", limit: 512
    t.string "mailing_city", limit: 255
    t.string "mailing_state", limit: 255
    t.string "mailing_zip", limit: 50
    t.string "residential_address_1", limit: 512
    t.string "residential_address_2", limit: 512
    t.string "residential_city", limit: 255
    t.string "residential_state", limit: 255
    t.string "residential_zip", limit: 50
    t.string "race", limit: 50
    t.string "phone_number", limit: 50
    t.string "primary_language_s", limit: 255
    t.string "primary_language_w", limit: 255
    t.string "sdh_nss7_score", limit: 50
    t.string "sdh_homelessness", limit: 50
    t.string "sdh_addresses_flag", limit: 50
    t.string "sdh_other_disabled", limit: 50
    t.string "sdh_spmi", limit: 50
    t.string "raw_risk_score", limit: 50
    t.string "normalized_risk_score", limit: 50
    t.string "raw_dxcg_risk_score", limit: 50
    t.date "last_office_visit"
    t.date "last_ed_visit"
    t.date "last_ip_visit"
    t.string "enrolled_flag", limit: 50
    t.string "enrollment_status", limit: 50
    t.date "cp_claim_dt"
    t.string "qualifying_hcpcs", limit: 50
    t.string "qualifying_hcpcs_nm", limit: 255
    t.string "qualifying_dsc", limit: 512
    t.string "email", limit: 512
    t.string "head_of_household", limit: 512
    t.string "sdh_smi", limit: 50
    t.index ["aco_name"], name: "index_claims_reporting_member_rosters_on_aco_name"
    t.index ["date_of_birth"], name: "index_claims_reporting_member_rosters_on_date_of_birth"
    t.index ["member_id"], name: "index_claims_reporting_member_rosters_on_member_id", unique: true
    t.index ["member_id"], name: "unk_cr_member_roster", unique: true
    t.index ["race"], name: "index_claims_reporting_member_rosters_on_race"
    t.index ["sex"], name: "index_claims_reporting_member_rosters_on_sex"
  end

  create_table "claims_reporting_rx_claims", force: :cascade do |t|
    t.string "member_id", limit: 50, null: false
    t.string "claim_number", limit: 30, null: false
    t.string "line_number", limit: 10, null: false
    t.string "cp_pidsl", limit: 50
    t.string "cp_name", limit: 255
    t.string "aco_pidsl", limit: 50
    t.string "aco_name", limit: 255
    t.string "pcc_pidsl", limit: 50
    t.string "pcc_name", limit: 255
    t.string "pcc_npi", limit: 50
    t.string "pcc_taxid", limit: 50
    t.string "mco_pidsl", limit: 50
    t.string "mco_name", limit: 50
    t.string "source", limit: 50
    t.string "claim_type", limit: 255
    t.date "member_dob"
    t.string "refill_quantity", limit: 20
    t.date "service_start_date"
    t.date "service_end_date"
    t.date "paid_date"
    t.integer "days_supply"
    t.decimal "billed_amount", precision: 19, scale: 4
    t.decimal "allowed_amount", precision: 19, scale: 4
    t.decimal "paid_amount", precision: 19, scale: 4
    t.string "prescriber_npi", limit: 50
    t.string "id_prescriber_servicing", limit: 50
    t.string "prescriber_taxid", limit: 50
    t.string "prescriber_name", limit: 255
    t.string "prescriber_type", limit: 50
    t.string "prescriber_taxonomy", limit: 50
    t.string "prescriber_address", limit: 512
    t.string "prescriber_city", limit: 255
    t.string "prescriber_state", limit: 255
    t.string "prescriber_zip", limit: 50
    t.string "billing_npi", limit: 50
    t.string "id_provider_billing", limit: 50
    t.string "billing_taxid", limit: 50
    t.string "billing_provider_name", limit: 255
    t.string "billing_provider_type", limit: 50
    t.string "billing_provider_taxonomy", limit: 50
    t.string "billing_address", limit: 512
    t.string "billing_city", limit: 255
    t.string "billing_state", limit: 255
    t.string "billing_zip", limit: 50
    t.string "ndc_code", limit: 50
    t.string "dosage_form_code", limit: 50
    t.string "therapeutic_class", limit: 50
    t.string "daw_ind", limit: 50
    t.string "gcn", limit: 50
    t.string "claim_status", limit: 50
    t.string "disbursement_code", limit: 50
    t.string "enrolled_flag", limit: 50
    t.string "drug_name", limit: 512
    t.integer "brand_vs_generic_indicator"
    t.string "price_method", limit: 50
    t.decimal "quantity", precision: 12, scale: 4
    t.string "route_of_administration", limit: 255
    t.string "cde_cos_rollup", limit: 50
    t.string "cde_cos_category", limit: 50
    t.string "cde_cos_subcategory", limit: 50
    t.string "ind_mco_aco_cvd_svc", limit: 50
    t.index ["member_id", "claim_number", "line_number"], name: "unk_cr_rx_claims", unique: true
    t.index ["service_start_date"], name: "index_claims_reporting_rx_claims_on_service_start_date"
  end

  create_table "claims_roster", id: :serial, force: :cascade do |t|
    t.string "medicaid_id", null: false
    t.string "last_name"
    t.string "first_name"
    t.string "gender"
    t.date "dob"
    t.string "race"
    t.string "primary_language"
    t.boolean "disability_flag"
    t.float "norm_risk_score"
    t.integer "mbr_months"
    t.integer "total_ty"
    t.integer "ed_visits"
    t.integer "acute_ip_admits"
    t.integer "average_days_to_readmit"
    t.string "pcp"
    t.string "epic_team"
    t.integer "member_months_baseline"
    t.integer "member_months_implementation"
    t.integer "cost_rank_ty"
    t.float "average_ed_visits_baseline"
    t.float "average_ed_visits_implementation"
    t.float "average_ip_admits_baseline"
    t.float "average_ip_admits_implementation"
    t.float "average_days_to_readmit_baseline"
    t.float "average_days_to_implementation"
    t.string "case_manager"
    t.string "housing_status"
    t.integer "baseline_admits"
    t.integer "implementation_admits"
    t.index ["medicaid_id"], name: "index_claims_roster_on_medicaid_id"
  end

  create_table "claims_top_conditions", id: :serial, force: :cascade do |t|
    t.string "medicaid_id", null: false
    t.integer "rank"
    t.string "description"
    t.float "indiv_pct"
    t.float "sdh_pct"
    t.float "baseline_paid"
    t.float "implementation_paid"
    t.index ["medicaid_id"], name: "index_claims_top_conditions_on_medicaid_id"
  end

  create_table "claims_top_ip_conditions", id: :serial, force: :cascade do |t|
    t.string "medicaid_id", null: false
    t.integer "rank"
    t.string "description"
    t.float "indiv_pct"
    t.float "sdh_pct"
    t.float "baseline_paid"
    t.float "implementation_paid"
    t.index ["medicaid_id"], name: "index_claims_top_ip_conditions_on_medicaid_id"
  end

  create_table "claims_top_providers", id: :serial, force: :cascade do |t|
    t.string "medicaid_id", null: false
    t.integer "rank"
    t.string "provider_name"
    t.float "indiv_pct"
    t.float "sdh_pct"
    t.float "baseline_paid"
    t.float "implementation_paid"
    t.index ["medicaid_id"], name: "index_claims_top_providers_on_medicaid_id"
  end

  create_table "comprehensive_health_assessments", id: :serial, force: :cascade do |t|
    t.integer "patient_id"
    t.integer "user_id"
    t.integer "health_file_id"
    t.integer "status", default: 0
    t.integer "reviewed_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.json "answers"
    t.datetime "completed_at"
    t.datetime "reviewed_at"
    t.string "reviewer"
    t.datetime "deleted_at"
    t.index ["health_file_id"], name: "index_comprehensive_health_assessments_on_health_file_id"
    t.index ["patient_id"], name: "index_comprehensive_health_assessments_on_patient_id"
    t.index ["reviewed_by_id"], name: "index_comprehensive_health_assessments_on_reviewed_by_id"
    t.index ["user_id"], name: "index_comprehensive_health_assessments_on_user_id"
  end

  create_table "cp_member_files", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "file"
    t.string "content"
    t.integer "user_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cps", id: :serial, force: :cascade do |t|
    t.string "pid"
    t.string "sl"
    t.string "mmis_enrollment_name"
    t.string "short_name"
    t.string "pt_part_1"
    t.string "pt_part_2"
    t.string "address_1"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "key_contact_first_name"
    t.string "key_contact_last_name"
    t.string "key_contact_email"
    t.string "key_contact_phone"
    t.boolean "sender", default: false, null: false
    t.string "receiver_name"
    t.string "receiver_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string "npi"
    t.string "ein"
    t.string "trace_id", limit: 10
    t.string "cp_name_official"
    t.string "cp_assignment_plan"
  end

  create_table "data_sources", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "disenrollment_reasons", force: :cascade do |t|
    t.string "reason_code"
    t.string "reason_description"
    t.string "referral_reason_code"
    t.index ["reason_code"], name: "index_disenrollment_reasons_on_reason_code"
  end

  create_table "document_exports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "type", null: false
    t.bigint "user_id", null: false
    t.string "export_version", null: false
    t.string "status", null: false
    t.string "query_string"
    t.binary "file_data"
    t.string "filename"
    t.string "mime_type"
    t.index ["type"], name: "index_document_exports_on_type"
    t.index ["user_id"], name: "index_document_exports_on_user_id"
  end

  create_table "ed_ip_visit_files", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "file"
    t.string "content"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "failed_at"
    t.index ["created_at"], name: "index_ed_ip_visit_files_on_created_at"
    t.index ["deleted_at"], name: "index_ed_ip_visit_files_on_deleted_at"
    t.index ["updated_at"], name: "index_ed_ip_visit_files_on_updated_at"
    t.index ["user_id"], name: "index_ed_ip_visit_files_on_user_id"
  end

  create_table "ed_ip_visits", id: :serial, force: :cascade do |t|
    t.integer "ed_ip_visit_file_id", null: false
    t.string "medicaid_id"
    t.string "last_name"
    t.string "first_name"
    t.string "gender"
    t.date "dob"
    t.date "admit_date"
    t.date "discharge_date"
    t.string "discharge_disposition"
    t.string "encounter_major_class"
    t.string "visit_type"
    t.string "encounter_facility"
    t.string "chief_complaint"
    t.string "diagnosis"
    t.string "attending_physician"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_ed_ip_visits_on_created_at"
    t.index ["deleted_at"], name: "index_ed_ip_visits_on_deleted_at"
    t.index ["ed_ip_visit_file_id"], name: "index_ed_ip_visits_on_ed_ip_visit_file_id"
    t.index ["medicaid_id"], name: "index_ed_ip_visits_on_medicaid_id"
    t.index ["updated_at"], name: "index_ed_ip_visits_on_updated_at"
  end

  create_table "eligibility_inquiries", id: :serial, force: :cascade do |t|
    t.date "service_date", null: false
    t.string "inquiry"
    t.string "result"
    t.integer "isa_control_number", null: false
    t.integer "group_control_number", null: false
    t.integer "transaction_control_number", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "internal", default: false
    t.integer "batch_id"
    t.boolean "has_batch", default: false
    t.index ["batch_id"], name: "index_eligibility_inquiries_on_batch_id"
  end

  create_table "eligibility_responses", id: :serial, force: :cascade do |t|
    t.integer "eligibility_inquiry_id"
    t.string "response"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "num_eligible"
    t.integer "num_ineligible"
    t.integer "user_id"
    t.string "original_filename"
    t.datetime "deleted_at"
    t.integer "num_errors"
    t.json "patient_aco_changes"
  end

  create_table "encounter_records", force: :cascade do |t|
    t.bigint "encounter_report_id"
    t.string "medicaid_id"
    t.date "date"
    t.string "provider_name"
    t.boolean "contact_reached"
    t.string "mode_of_contact"
    t.date "dob"
    t.string "gender"
    t.string "race"
    t.string "ethnicity"
    t.string "veteran_status"
    t.string "housing_status"
    t.string "source"
    t.string "encounter_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["encounter_report_id"], name: "index_encounter_records_on_encounter_report_id"
  end

  create_table "encounter_reports", force: :cascade do |t|
    t.datetime "start_date"
    t.datetime "end_date"
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "completed_at"
    t.datetime "started_at"
    t.index ["user_id"], name: "index_encounter_reports_on_user_id"
  end

  create_table "enrollment_reasons", force: :cascade do |t|
    t.string "file"
    t.string "name"
    t.string "size"
    t.string "content_type"
    t.binary "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "enrollment_rosters", id: :serial, force: :cascade do |t|
    t.integer "roster_file_id"
    t.string "member_id"
    t.string "performance_year"
    t.string "region"
    t.string "service_area"
    t.string "aco_pidsl"
    t.string "aco_name"
    t.string "pcc_pidsl"
    t.string "pcc_name"
    t.string "pcc_npi"
    t.string "pcc_taxid"
    t.string "mco_pidsl"
    t.string "mco_name"
    t.string "enrolled_flag"
    t.string "enroll_type"
    t.string "enroll_stop_reason"
    t.string "rating_category_char_cd"
    t.string "ind_dds"
    t.string "ind_dmh"
    t.string "ind_dta"
    t.string "ind_dss"
    t.string "cde_hcb_waiver"
    t.string "cde_waiver_category"
    t.date "span_start_date"
    t.date "span_end_date"
    t.integer "span_mem_days"
    t.string "cp_prov_type"
    t.string "cp_plan_type"
    t.string "cp_pidsl"
    t.string "cp_prov_name"
    t.date "cp_enroll_dt"
    t.date "cp_disenroll_dt"
    t.string "cp_start_rsn"
    t.string "cp_stop_rsn"
    t.string "ind_medicare_a"
    t.string "ind_medicare_b"
    t.string "tpl_coverage_cat"
  end

  create_table "enrollments", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "content"
    t.string "original_filename"
    t.string "status"
    t.integer "new_patients"
    t.integer "returning_patients"
    t.integer "disenrolled_patients"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "updated_patients"
    t.jsonb "processing_errors", default: []
    t.jsonb "audit_actions", default: {}
  end

  create_table "epic_careplans", id: :serial, force: :cascade do |t|
    t.string "patient_id"
    t.string "id_in_source"
    t.string "encounter_id"
    t.string "encounter_type"
    t.datetime "careplan_updated_at"
    t.string "staff"
    t.text "part_1"
    t.text "part_2"
    t.text "part_3"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "data_source_id"
  end

  create_table "epic_case_note_qualifying_activities", id: :serial, force: :cascade do |t|
    t.string "patient_id"
    t.string "id_in_source"
    t.string "epic_case_note_source_id"
    t.string "encounter_type"
    t.datetime "update_date"
    t.string "staff"
    t.text "part_1"
    t.text "part_2"
    t.text "part_3"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "data_source_id"
  end

  create_table "epic_case_notes", id: :serial, force: :cascade do |t|
    t.string "patient_id", null: false
    t.string "id_in_source", null: false
    t.datetime "contact_date"
    t.string "closed"
    t.string "encounter_type"
    t.string "provider_name"
    t.string "location"
    t.string "chief_complaint_1"
    t.string "chief_complaint_1_comment"
    t.string "chief_complaint_2"
    t.string "chief_complaint_2_comment"
    t.string "dx_1_icd10"
    t.string "dx_1_name"
    t.string "dx_2_icd10"
    t.string "dx_2_name"
    t.string "homeless_status"
    t.integer "data_source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "epic_chas", id: :serial, force: :cascade do |t|
    t.string "patient_id"
    t.string "id_in_source"
    t.string "encounter_id"
    t.string "encounter_type"
    t.datetime "cha_updated_at"
    t.string "staff"
    t.string "provider_type"
    t.string "reviewer_name"
    t.string "reviewer_provider_type"
    t.text "part_1"
    t.text "part_2"
    t.text "part_3"
    t.text "part_4"
    t.text "part_5"
    t.text "part_6"
    t.text "part_7"
    t.text "part_8"
    t.text "part_9"
    t.text "part_10"
    t.text "part_11"
    t.text "part_12"
    t.text "part_13"
    t.text "part_14"
    t.text "part_15"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "data_source_id"
  end

  create_table "epic_goals", id: :serial, force: :cascade do |t|
    t.string "patient_id", null: false
    t.string "entered_by"
    t.string "title"
    t.string "contents"
    t.string "id_in_source"
    t.string "received_valid_complaint"
    t.datetime "goal_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "data_source_id", default: 6, null: false
  end

  create_table "epic_housing_statuses", force: :cascade do |t|
    t.string "patient_id", null: false
    t.date "collected_on", null: false
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collected_on"], name: "index_epic_housing_statuses_on_collected_on"
    t.index ["patient_id"], name: "index_epic_housing_statuses_on_patient_id"
  end

  create_table "epic_patients", id: :serial, force: :cascade do |t|
    t.string "id_in_source", null: false
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.text "aliases"
    t.date "birthdate"
    t.text "allergy_list"
    t.string "primary_care_physician"
    t.string "transgender"
    t.string "race"
    t.string "ethnicity"
    t.string "veteran_status"
    t.string "ssn"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "gender"
    t.datetime "consent_revoked"
    t.string "medicaid_id"
    t.string "housing_status"
    t.datetime "housing_status_timestamp"
    t.boolean "pilot", default: false, null: false
    t.integer "data_source_id", default: 6, null: false
    t.datetime "deleted_at"
    t.date "death_date"
    t.index ["deleted_at"], name: "index_epic_patients_on_deleted_at"
  end

  create_table "epic_qualifying_activities", id: :serial, force: :cascade do |t|
    t.string "patient_id", null: false
    t.string "id_in_source", null: false
    t.string "patient_encounter_id"
    t.string "entered_by"
    t.string "role"
    t.date "date_of_activity"
    t.string "activity"
    t.string "mode"
    t.string "reached"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "data_source_id"
  end

  create_table "epic_ssms", id: :serial, force: :cascade do |t|
    t.string "patient_id"
    t.string "id_in_source"
    t.string "encounter_id"
    t.string "encounter_type"
    t.datetime "ssm_updated_at"
    t.string "staff"
    t.text "part_1"
    t.text "part_2"
    t.text "part_3"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "data_source_id"
  end

  create_table "epic_team_members", id: :serial, force: :cascade do |t|
    t.string "patient_id", null: false
    t.string "id_in_source"
    t.string "name"
    t.string "pcp_type"
    t.string "relationship"
    t.string "email"
    t.string "phone"
    t.datetime "processed"
    t.integer "data_source_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "equipment", id: :serial, force: :cascade do |t|
    t.string "item"
    t.string "provider"
    t.integer "quantity"
    t.date "effective_date"
    t.string "comments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer "patient_id"
    t.string "status"
  end

  create_table "health_files", id: :serial, force: :cascade do |t|
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
    t.float "size"
    t.integer "parent_id"
    t.index ["deleted_at"], name: "index_health_files_on_deleted_at"
    t.index ["type"], name: "index_health_files_on_type"
  end

  create_table "health_flexible_service_follow_ups", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "user_id", null: false
    t.date "completed_on"
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.date "dob"
    t.string "delivery_first_name"
    t.string "delivery_last_name"
    t.string "delivery_organization"
    t.string "delivery_phone"
    t.string "delivery_email"
    t.string "reviewer_first_name"
    t.string "reviewer_last_name"
    t.string "reviewer_organization"
    t.string "reviewer_phone"
    t.string "reviewer_email"
    t.text "services_completed"
    t.text "goal_status"
    t.boolean "additional_flex_services_requested"
    t.text "additional_flex_services_requested_detail"
    t.boolean "agreement_to_flex_services"
    t.string "agreement_to_flex_services_detail"
    t.boolean "aco_approved_flex_services"
    t.string "aco_approved_flex_services_detail"
    t.date "aco_approved_flex_services_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_health_flexible_service_follow_ups_on_created_at"
    t.index ["patient_id"], name: "index_health_flexible_service_follow_ups_on_patient_id"
    t.index ["updated_at"], name: "index_health_flexible_service_follow_ups_on_updated_at"
    t.index ["user_id"], name: "index_health_flexible_service_follow_ups_on_user_id"
  end

  create_table "health_flexible_service_vprs", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "user_id", null: false
    t.date "planned_on"
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.date "dob"
    t.string "accommodations_needed"
    t.string "contact_type"
    t.string "phone"
    t.string "email"
    t.text "additional_contact_details"
    t.string "main_contact_first_name"
    t.string "main_contact_last_name"
    t.string "main_contact_organization"
    t.string "main_contact_phone"
    t.string "main_contact_email"
    t.string "reviewer_first_name"
    t.string "reviewer_last_name"
    t.string "reviewer_organization"
    t.string "reviewer_phone"
    t.string "reviewer_email"
    t.string "representative_first_name"
    t.string "representative_last_name"
    t.string "representative_organization"
    t.string "representative_phone"
    t.string "representative_email"
    t.boolean "member_agrees_to_plan"
    t.text "member_agreement_notes"
    t.boolean "aco_approved"
    t.date "aco_approved_on"
    t.text "aco_rejection_notes"
    t.date "health_needs_screened_on"
    t.boolean "complex_physical_health_need"
    t.string "complex_physical_health_need_detail"
    t.boolean "behavioral_health_need"
    t.string "behavioral_health_need_detail"
    t.boolean "activities_of_daily_living"
    t.string "activities_of_daily_living_detail"
    t.boolean "ed_utilization"
    t.string "ed_utilization_detail"
    t.boolean "high_risk_pregnancy"
    t.string "high_risk_pregnancy_detail"
    t.date "risk_factors_screened_on"
    t.boolean "experiencing_homelessness"
    t.string "experiencing_homelessness_detail"
    t.boolean "at_risk_of_homelessness"
    t.string "at_risk_of_homelessness_detail"
    t.boolean "at_risk_of_nutritional_deficiency"
    t.string "at_risk_of_nutritional_deficiency_detail"
    t.text "health_and_risk_notes"
    t.boolean "receives_snap"
    t.boolean "receives_wic"
    t.boolean "receives_csp"
    t.boolean "receives_other"
    t.string "receives_other_detail"
    t.date "service_1_added_on"
    t.string "service_1_goals"
    t.string "service_1_category"
    t.string "service_1_flex_services"
    t.string "service_1_units"
    t.string "service_1_delivering_entity"
    t.string "service_1_steps"
    t.string "service_1_aco_plan"
    t.date "service_2_added_on"
    t.string "service_2_goals"
    t.string "service_2_category"
    t.string "service_2_flex_services"
    t.string "service_2_units"
    t.string "service_2_delivering_entity"
    t.string "service_2_steps"
    t.string "service_2_aco_plan"
    t.date "service_3_added_on"
    t.string "service_3_goals"
    t.string "service_3_category"
    t.string "service_3_flex_services"
    t.string "service_3_units"
    t.string "service_3_delivering_entity"
    t.string "service_3_steps"
    t.string "service_3_aco_plan"
    t.date "service_4_added_on"
    t.string "service_4_goals"
    t.string "service_4_category"
    t.string "service_4_flex_services"
    t.string "service_4_units"
    t.string "service_4_delivering_entity"
    t.string "service_4_steps"
    t.string "service_4_aco_plan"
    t.date "service_5_added_on"
    t.string "service_5_goals"
    t.string "service_5_category"
    t.string "service_5_flex_services"
    t.string "service_5_units"
    t.string "service_5_delivering_entity"
    t.string "service_5_steps"
    t.string "service_5_aco_plan"
    t.date "service_6_added_on"
    t.string "service_6_goals"
    t.string "service_6_category"
    t.string "service_6_flex_services"
    t.string "service_6_units"
    t.string "service_6_delivering_entity"
    t.string "service_6_steps"
    t.string "service_6_aco_plan"
    t.date "service_7_added_on"
    t.string "service_7_goals"
    t.string "service_7_category"
    t.string "service_7_flex_services"
    t.string "service_7_units"
    t.string "service_7_delivering_entity"
    t.string "service_7_steps"
    t.string "service_7_aco_plan"
    t.date "service_8_added_on"
    t.string "service_8_goals"
    t.string "service_8_category"
    t.string "service_8_flex_services"
    t.string "service_8_units"
    t.string "service_8_delivering_entity"
    t.string "service_8_steps"
    t.string "service_8_aco_plan"
    t.date "service_9_added_on"
    t.string "service_9_goals"
    t.string "service_9_category"
    t.string "service_9_flex_services"
    t.string "service_9_units"
    t.string "service_9_delivering_entity"
    t.string "service_9_steps"
    t.string "service_9_aco_plan"
    t.date "service_10_added_on"
    t.string "service_10_goals"
    t.string "service_10_category"
    t.string "service_10_flex_services"
    t.string "service_10_units"
    t.string "service_10_delivering_entity"
    t.string "service_10_steps"
    t.string "service_10_aco_plan"
    t.string "gender"
    t.string "gender_detail"
    t.string "sexual_orientation"
    t.string "sexual_orientation_detail"
    t.jsonb "race"
    t.string "race_detail"
    t.string "primary_language"
    t.boolean "primary_language_refused"
    t.string "education"
    t.string "education_detail"
    t.string "employment_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_health_flexible_service_vprs_on_created_at"
    t.index ["patient_id"], name: "index_health_flexible_service_vprs_on_patient_id"
    t.index ["updated_at"], name: "index_health_flexible_service_vprs_on_updated_at"
    t.index ["user_id"], name: "index_health_flexible_service_vprs_on_user_id"
  end

  create_table "health_goals", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "type"
    t.integer "number"
    t.string "name"
    t.string "associated_dx"
    t.string "barriers"
    t.string "provider_plan"
    t.string "case_manager_plan"
    t.string "rn_plan"
    t.string "bh_plan"
    t.string "other_plan"
    t.integer "confidence"
    t.string "az_housing"
    t.string "az_income"
    t.string "az_non_cash_benefits"
    t.string "az_disabilities"
    t.string "az_food"
    t.string "az_employment"
    t.string "az_training"
    t.string "az_transportation"
    t.string "az_life_skills"
    t.string "az_health_care_coverage"
    t.string "az_physical_health"
    t.string "az_mental_health"
    t.string "az_substance_use"
    t.string "az_criminal_justice"
    t.string "az_legal"
    t.string "az_safety"
    t.string "az_risk"
    t.string "az_family"
    t.string "az_community"
    t.string "az_time_management"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "goal_details"
    t.text "problem"
    t.date "start_date"
    t.text "intervention"
    t.string "status"
    t.integer "responsible_team_member_id"
    t.integer "patient_id"
    t.text "timeframe"
    t.string "action_step_0"
    t.string "timeframe_0"
    t.string "action_step_1"
    t.string "timeframe_1"
    t.string "action_step_2"
    t.string "timeframe_2"
    t.string "action_step_3"
    t.string "timeframe_3"
    t.string "action_step_4"
    t.string "timeframe_4"
    t.string "action_step_5"
    t.string "timeframe_5"
    t.string "action_step_6"
    t.string "timeframe_6"
    t.string "action_step_7"
    t.string "timeframe_7"
    t.string "action_step_8"
    t.string "timeframe_8"
    t.string "action_step_9"
    t.string "timeframe_9"
    t.index ["patient_id"], name: "index_health_goals_on_patient_id"
    t.index ["user_id"], name: "index_health_goals_on_user_id"
  end

  create_table "medications", id: :serial, force: :cascade do |t|
    t.date "start_date"
    t.date "ordered_date"
    t.text "name"
    t.text "instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "id_in_source"
    t.string "patient_id"
    t.integer "data_source_id", default: 6, null: false
  end

  create_table "member_status_report_patients", id: :serial, force: :cascade do |t|
    t.integer "member_status_report_id"
    t.string "medicaid_id", limit: 12
    t.string "member_first_name", limit: 100
    t.string "member_last_name", limit: 100
    t.string "member_middle_initial", limit: 1
    t.string "member_suffix", limit: 20
    t.date "member_date_of_birth"
    t.string "member_sex", limit: 1
    t.string "aco_mco_name", limit: 100
    t.string "aco_mco_pid", limit: 9
    t.string "aco_mco_sl", limit: 10
    t.string "cp_name_official", limit: 100
    t.string "cp_pid", limit: 9
    t.string "cp_sl", limit: 10
    t.string "cp_outreach_status", limit: 30
    t.date "cp_last_contact_date"
    t.string "cp_last_contact_face", limit: 1
    t.string "cp_contact_face"
    t.date "cp_participation_form_date"
    t.date "cp_care_plan_sent_pcp_date"
    t.date "cp_care_plan_returned_pcp_date"
    t.string "key_contact_name_first", limit: 100
    t.string "key_contact_name_last", limit: 100
    t.string "key_contact_phone", limit: 10
    t.string "key_contact_email", limit: 60
    t.string "care_coordinator_first_name", limit: 100
    t.string "care_coordinator_last_name", limit: 100
    t.string "care_coordinator_phone", limit: 10
    t.string "care_coordinator_email", limit: 60
    t.string "record_status", limit: 1
    t.date "record_update_date"
    t.date "export_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_member_status_report_patients_on_deleted_at"
  end

  create_table "member_status_reports", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "job_id"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.string "sender", limit: 100
    t.integer "sent_row_num"
    t.integer "sent_column_num"
    t.datetime "sent_export_time_stamp"
    t.string "receiver"
    t.date "report_start_date"
    t.date "report_end_date"
    t.string "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.date "effective_date"
    t.index ["deleted_at"], name: "index_member_status_reports_on_deleted_at"
  end

  create_table "participation_forms", id: :serial, force: :cascade do |t|
    t.integer "patient_id"
    t.date "signature_on"
    t.integer "case_manager_id"
    t.integer "reviewed_by_id"
    t.string "location"
    t.integer "health_file_id"
    t.datetime "reviewed_at"
    t.string "reviewer"
    t.index ["case_manager_id"], name: "index_participation_forms_on_case_manager_id"
    t.index ["health_file_id"], name: "index_participation_forms_on_health_file_id"
    t.index ["patient_id"], name: "index_participation_forms_on_patient_id"
    t.index ["reviewed_by_id"], name: "index_participation_forms_on_reviewed_by_id"
  end

  create_table "patient_referral_imports", id: :serial, force: :cascade do |t|
    t.string "file_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "patient_referrals", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.date "birthdate"
    t.string "ssn"
    t.string "medicaid_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "agency_id"
    t.boolean "rejected", default: false, null: false
    t.integer "rejected_reason", default: 0, null: false
    t.integer "patient_id"
    t.integer "accountable_care_organization_id"
    t.string "middle_initial"
    t.string "suffix"
    t.string "gender"
    t.string "aco_name"
    t.integer "aco_mco_pid"
    t.string "aco_mco_sl"
    t.string "health_plan_id"
    t.string "cp_assignment_plan"
    t.string "cp_name_dsrip"
    t.string "cp_name_official"
    t.integer "cp_pid"
    t.string "cp_sl"
    t.date "enrollment_start_date"
    t.string "start_reason_description"
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "address_city"
    t.string "address_state"
    t.string "address_zip"
    t.string "address_zip_plus_4"
    t.string "email"
    t.string "phone_cell"
    t.string "phone_day"
    t.string "phone_night"
    t.string "primary_language"
    t.string "primary_diagnosis"
    t.string "secondary_diagnosis"
    t.string "pcp_last_name"
    t.string "pcp_first_name"
    t.string "pcp_npi"
    t.string "pcp_address_line_1"
    t.string "pcp_address_line_2"
    t.string "pcp_address_city"
    t.string "pcp_address_state"
    t.string "pcp_address_zip"
    t.string "pcp_address_phone"
    t.string "dmh"
    t.string "dds"
    t.string "eoea"
    t.string "ed_visits"
    t.string "snf_discharge"
    t.string "identification"
    t.string "record_status"
    t.date "record_updated_on"
    t.date "exported_on"
    t.boolean "removal_acknowledged", default: false, null: false
    t.datetime "effective_date"
    t.date "disenrollment_date"
    t.string "stop_reason_description"
    t.date "pending_disenrollment_date"
    t.boolean "current", default: false, null: false
    t.boolean "contributing", default: false, null: false
    t.boolean "derived_referral", default: false
    t.datetime "deleted_at"
    t.string "change_description"
    t.index ["contributing"], name: "index_patient_referrals_on_contributing"
    t.index ["deleted_at"], name: "index_patient_referrals_on_deleted_at"
  end

  create_table "patients", id: :serial, force: :cascade do |t|
    t.string "id_in_source", null: false
    t.string "first_name"
    t.string "middle_name"
    t.string "last_name"
    t.text "aliases"
    t.date "birthdate"
    t.text "allergy_list"
    t.string "primary_care_physician"
    t.string "transgender"
    t.string "race"
    t.string "ethnicity"
    t.string "veteran_status"
    t.string "ssn"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "client_id"
    t.string "gender"
    t.datetime "consent_revoked"
    t.string "medicaid_id"
    t.string "housing_status"
    t.datetime "housing_status_timestamp"
    t.boolean "pilot", default: false, null: false
    t.integer "data_source_id", default: 6, null: false
    t.date "engagement_date"
    t.integer "care_coordinator_id"
    t.datetime "deleted_at"
    t.date "death_date"
    t.string "coverage_level"
    t.date "coverage_inquiry_date"
    t.datetime "eligibility_notification"
    t.string "aco_name"
    t.string "previous_aco_name"
    t.boolean "invalid_id", default: false
    t.bigint "nurse_care_manager_id"
    t.index ["client_id"], name: "patients_client_id_constraint", unique: true, where: "(deleted_at IS NULL)"
    t.index ["deleted_at"], name: "index_patients_on_deleted_at"
    t.index ["medicaid_id"], name: "index_patients_on_medicaid_id"
    t.index ["nurse_care_manager_id"], name: "index_patients_on_nurse_care_manager_id"
  end

  create_table "premium_payments", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.text "content"
    t.string "original_filename"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.jsonb "converted_content"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.index ["deleted_at"], name: "index_premium_payments_on_deleted_at"
  end

  create_table "problems", id: :serial, force: :cascade do |t|
    t.date "onset_date"
    t.date "last_assessed"
    t.text "name"
    t.text "comment"
    t.string "icd10_list"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "id_in_source"
    t.string "patient_id"
    t.integer "data_source_id", default: 6, null: false
  end

  create_table "qualifying_activities", id: :serial, force: :cascade do |t|
    t.string "mode_of_contact"
    t.string "mode_of_contact_other"
    t.string "reached_client"
    t.string "reached_client_collateral_contact"
    t.string "activity"
    t.string "source_type"
    t.integer "source_id"
    t.datetime "claim_submitted_on"
    t.date "date_of_activity"
    t.integer "user_id"
    t.string "user_full_name"
    t.string "follow_up"
    t.integer "patient_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "claim_id"
    t.boolean "force_payable", default: false, null: false
    t.boolean "naturally_payable", default: false, null: false
    t.datetime "sent_at"
    t.integer "duplicate_id"
    t.string "epic_source_id"
    t.boolean "valid_unpayable", default: false, null: false
    t.boolean "procedure_valid", default: false, null: false
    t.boolean "ignored", default: false
    t.index ["claim_id"], name: "index_qualifying_activities_on_claim_id"
    t.index ["date_of_activity"], name: "index_qualifying_activities_on_date_of_activity"
    t.index ["patient_id"], name: "index_qualifying_activities_on_patient_id"
    t.index ["source_id"], name: "index_qualifying_activities_on_source_id"
    t.index ["source_type"], name: "index_qualifying_activities_on_source_type"
  end

  create_table "release_forms", id: :serial, force: :cascade do |t|
    t.integer "patient_id"
    t.integer "user_id"
    t.date "signature_on"
    t.string "file_location"
    t.integer "health_file_id"
    t.integer "reviewed_by_id"
    t.datetime "reviewed_at"
    t.string "reviewer"
    t.index ["health_file_id"], name: "index_release_forms_on_health_file_id"
    t.index ["patient_id"], name: "index_release_forms_on_patient_id"
    t.index ["reviewed_by_id"], name: "index_release_forms_on_reviewed_by_id"
    t.index ["user_id"], name: "index_release_forms_on_user_id"
  end

  create_table "rosters", id: :serial, force: :cascade do |t|
    t.integer "roster_file_id"
    t.string "member_id"
    t.string "nam_first"
    t.string "nam_last"
    t.string "cp_pidsl"
    t.string "cp_name"
    t.string "aco_pidsl"
    t.string "aco_name"
    t.string "mco_pidsl"
    t.string "mco_name"
    t.string "sex"
    t.date "date_of_birth"
    t.string "mailing_address_1"
    t.string "mailing_address_2"
    t.string "mailing_city"
    t.string "mailing_state"
    t.string "mailing_zip"
    t.string "residential_address_1"
    t.string "residential_address_2"
    t.string "residential_city"
    t.string "residential_state"
    t.string "residential_zip"
    t.string "race"
    t.string "phone_number"
    t.string "primary_language_s"
    t.string "primary_language_w"
    t.string "sdh_nss7_score"
    t.string "sdh_homelessness"
    t.string "sdh_addresses_flag"
    t.string "sdh_other_disabled"
    t.string "sdh_spmi"
    t.string "raw_risk_score"
    t.string "normalized_risk_score"
    t.string "raw_dxcg_risk_score"
    t.date "last_office_visit"
    t.date "last_ed_visit"
    t.date "last_ip_visit"
    t.string "enrolled_flag"
    t.string "enrollment_status"
    t.date "cp_claim_dt"
    t.string "qualifying_hcpcs"
    t.string "qualifying_hcpcs_nm"
    t.string "qualifying_dsc"
    t.string "email"
    t.string "head_of_household"
  end

  create_table "sdh_case_management_notes", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "patient_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "topics"
    t.string "title"
    t.integer "total_time_spent_in_minutes"
    t.datetime "date_of_contact"
    t.string "place_of_contact"
    t.string "housing_status"
    t.string "place_of_contact_other"
    t.string "housing_status_other"
    t.datetime "housing_placement_date"
    t.text "client_action"
    t.text "notes_from_encounter"
    t.string "client_phone_number"
    t.datetime "completed_on"
    t.integer "health_file_id"
    t.string "client_action_medication_reconciliation_clinician"
    t.index ["health_file_id"], name: "index_sdh_case_management_notes_on_health_file_id"
  end

  create_table "self_sufficiency_matrix_forms", id: :serial, force: :cascade do |t|
    t.integer "patient_id"
    t.integer "user_id"
    t.string "point_completed"
    t.integer "housing_score"
    t.text "housing_notes"
    t.integer "income_score"
    t.text "income_notes"
    t.integer "benefits_score"
    t.text "benefits_notes"
    t.integer "disabilities_score"
    t.text "disabilities_notes"
    t.integer "food_score"
    t.text "food_notes"
    t.integer "employment_score"
    t.text "employment_notes"
    t.integer "education_score"
    t.text "education_notes"
    t.integer "mobility_score"
    t.text "mobility_notes"
    t.integer "life_score"
    t.text "life_notes"
    t.integer "healthcare_score"
    t.text "healthcare_notes"
    t.integer "physical_health_score"
    t.text "physical_health_notes"
    t.integer "mental_health_score"
    t.text "mental_health_notes"
    t.integer "substance_abuse_score"
    t.text "substance_abuse_notes"
    t.integer "criminal_score"
    t.text "criminal_notes"
    t.integer "legal_score"
    t.text "legal_notes"
    t.integer "safety_score"
    t.text "safety_notes"
    t.integer "risk_score"
    t.text "risk_notes"
    t.integer "family_score"
    t.text "family_notes"
    t.integer "community_score"
    t.text "community_notes"
    t.integer "time_score"
    t.text "time_notes"
    t.datetime "completed_at"
    t.string "collection_location"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "health_file_id"
  end

  create_table "services", id: :serial, force: :cascade do |t|
    t.string "service_type"
    t.string "provider"
    t.string "hours"
    t.string "days"
    t.date "date_requested"
    t.date "effective_date"
    t.date "end_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer "patient_id"
    t.string "status"
  end

  create_table "signable_documents", id: :serial, force: :cascade do |t|
    t.integer "signable_id", null: false
    t.string "signable_type", null: false
    t.boolean "primary", default: true, null: false
    t.integer "user_id", null: false
    t.jsonb "hs_initial_request"
    t.jsonb "hs_initial_response"
    t.datetime "hs_initial_response_at"
    t.jsonb "hs_last_response"
    t.datetime "hs_last_response_at"
    t.string "hs_subject", default: "Signature Request", null: false
    t.string "hs_title", default: "Signature Request", null: false
    t.text "hs_message", default: "You've been asked to sign a document."
    t.jsonb "signers", default: [], null: false
    t.jsonb "signed_by", default: [], null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "expires_at"
    t.integer "health_file_id"
    t.index ["signable_id", "signable_type"], name: "index_signable_documents_on_signable_id_and_signable_type"
  end

  create_table "signature_requests", id: :serial, force: :cascade do |t|
    t.string "type", null: false
    t.integer "patient_id", null: false
    t.integer "careplan_id", null: false
    t.string "to_email", null: false
    t.string "to_name", null: false
    t.string "requestor_email", null: false
    t.string "requestor_name", null: false
    t.datetime "expires_at", null: false
    t.datetime "sent_at"
    t.datetime "completed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer "signable_document_id"
    t.index ["careplan_id"], name: "index_signature_requests_on_careplan_id"
    t.index ["deleted_at"], name: "index_signature_requests_on_deleted_at"
    t.index ["patient_id"], name: "index_signature_requests_on_patient_id"
    t.index ["type"], name: "index_signature_requests_on_type"
  end

  create_table "soap_configs", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "user"
    t.string "encrypted_pass"
    t.string "encrypted_pass_iv"
    t.string "sender"
    t.string "receiver"
    t.string "test_url"
    t.string "production_url"
  end

  create_table "ssm_exports", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.jsonb "options"
    t.jsonb "headers"
    t.jsonb "rows"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["created_at"], name: "index_ssm_exports_on_created_at"
    t.index ["updated_at"], name: "index_ssm_exports_on_updated_at"
    t.index ["user_id"], name: "index_ssm_exports_on_user_id"
  end

  create_table "status_dates", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.date "date", null: false
    t.boolean "engaged", null: false
    t.boolean "enrolled", null: false
    t.index ["date"], name: "index_status_dates_on_date"
    t.index ["patient_id"], name: "index_status_dates_on_patient_id"
  end

  create_table "team_members", id: :serial, force: :cascade do |t|
    t.string "type", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "organization"
    t.string "title"
    t.date "last_contact"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.string "phone"
    t.integer "patient_id"
    t.index ["patient_id"], name: "index_team_members_on_patient_id"
    t.index ["type"], name: "index_team_members_on_type"
  end

  create_table "teams", id: :serial, force: :cascade do |t|
    t.integer "patient_id"
    t.datetime "deleted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.integer "careplan_id"
    t.index ["careplan_id"], name: "index_teams_on_careplan_id"
  end

  create_table "tracing_cases", force: :cascade do |t|
    t.integer "client_id"
    t.string "health_emergency", null: false
    t.string "investigator"
    t.date "date_listed"
    t.string "alert_in_epic"
    t.string "complete"
    t.date "date_interviewed"
    t.date "infectious_start_date"
    t.date "testing_date"
    t.date "isolation_start_date"
    t.string "first_name"
    t.string "last_name"
    t.string "aliases"
    t.date "dob"
    t.integer "gender"
    t.jsonb "race"
    t.integer "ethnicity"
    t.string "preferred_language"
    t.string "occupation"
    t.string "recent_incarceration"
    t.string "notes"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "day_two"
    t.string "phone"
    t.jsonb "symptoms"
    t.string "other_symptoms"
    t.index ["aliases"], name: "index_tracing_cases_on_aliases"
    t.index ["client_id"], name: "index_tracing_cases_on_client_id"
    t.index ["first_name", "last_name"], name: "index_tracing_cases_on_first_name_and_last_name"
  end

  create_table "tracing_contacts", force: :cascade do |t|
    t.bigint "case_id"
    t.date "date_interviewed"
    t.string "first_name"
    t.string "last_name"
    t.string "aliases"
    t.string "phone_number"
    t.string "address"
    t.date "dob"
    t.string "estimated_age"
    t.integer "gender"
    t.jsonb "race"
    t.integer "ethnicity"
    t.string "preferred_language"
    t.string "relationship_to_index_case"
    t.string "location_of_exposure"
    t.string "nature_of_exposure"
    t.string "location_of_contact"
    t.string "sleeping_location"
    t.string "symptomatic"
    t.date "symptom_onset_date"
    t.string "referred_for_testing"
    t.string "test_result"
    t.string "isolated"
    t.string "isolation_location"
    t.string "quarantine"
    t.string "quarantine_location"
    t.string "notes"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "investigator"
    t.string "alert_in_epic"
    t.string "notified"
    t.jsonb "symptoms"
    t.string "other_symptoms"
    t.index ["aliases"], name: "index_tracing_contacts_on_aliases"
    t.index ["case_id"], name: "index_tracing_contacts_on_case_id"
    t.index ["first_name", "last_name"], name: "index_tracing_contacts_on_first_name_and_last_name"
  end

  create_table "tracing_locations", force: :cascade do |t|
    t.bigint "case_id"
    t.string "location"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["case_id"], name: "index_tracing_locations_on_case_id"
  end

  create_table "tracing_results", force: :cascade do |t|
    t.bigint "contact_id"
    t.string "test_result"
    t.string "isolated"
    t.string "isolation_location"
    t.string "quarantine"
    t.string "quarantine_location"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_tracing_results_on_contact_id"
  end

  create_table "tracing_site_leaders", force: :cascade do |t|
    t.bigint "case_id"
    t.string "site_name"
    t.string "site_leader_name"
    t.date "contacted_on"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "investigator"
    t.index ["case_id"], name: "index_tracing_site_leaders_on_case_id"
  end

  create_table "tracing_staffs", force: :cascade do |t|
    t.bigint "case_id"
    t.date "date_interviewed"
    t.string "first_name"
    t.string "last_name"
    t.string "site_name"
    t.string "nature_of_exposure"
    t.string "symptomatic"
    t.string "referred_for_testing"
    t.string "test_result"
    t.string "notes"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notified"
    t.date "dob"
    t.string "estimated_age"
    t.integer "gender"
    t.string "address"
    t.string "phone_number"
    t.jsonb "symptoms"
    t.string "other_symptoms"
    t.string "investigator"
    t.index ["case_id"], name: "index_tracing_staffs_on_case_id"
  end

  create_table "transaction_acknowledgements", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.text "content"
    t.string "original_filename"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_transaction_acknowledgements_on_deleted_at"
  end

  create_table "user_care_coordinators", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "care_coordinator_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  create_table "vaccinations", force: :cascade do |t|
    t.integer "client_id"
    t.string "epic_patient_id", null: false
    t.string "medicaid_id"
    t.string "first_name"
    t.string "last_name"
    t.date "dob"
    t.string "ssn"
    t.date "vaccinated_on", null: false
    t.string "vaccinated_at"
    t.string "vaccination_type", null: false
    t.string "follow_up_cell_phone"
    t.boolean "existed_previously", default: false, null: false
    t.integer "data_source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "preferred_language", default: "en"
    t.datetime "epic_row_created"
    t.datetime "epic_row_updated"
    t.index ["created_at"], name: "index_vaccinations_on_created_at"
    t.index ["epic_patient_id", "vaccinated_on"], name: "index_vaccinations_on_epic_patient_id_and_vaccinated_on", unique: true
    t.index ["updated_at"], name: "index_vaccinations_on_updated_at"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.integer "user_id"
    t.string "session_id"
    t.string "request_id"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "visits", id: :serial, force: :cascade do |t|
    t.string "department"
    t.string "visit_type"
    t.string "provider"
    t.string "id_in_source"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "patient_id"
    t.datetime "date_of_service"
    t.integer "data_source_id", default: 6, null: false
  end

  add_foreign_key "claims_reporting_cp_payment_details", "claims_reporting_cp_payment_uploads", column: "cp_payment_upload_id"
  add_foreign_key "comprehensive_health_assessments", "health_files"
  add_foreign_key "comprehensive_health_assessments", "patients"
  add_foreign_key "health_goals", "patients"
  add_foreign_key "participation_forms", "health_files"
  add_foreign_key "release_forms", "health_files"
  add_foreign_key "sdh_case_management_notes", "health_files"
  add_foreign_key "team_members", "patients"
end
