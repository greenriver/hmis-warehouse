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

ActiveRecord::Schema.define(version: 2020_03_30_180135) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "hstore"
  enable_extension "plpgsql"

  create_table "access_group_members", id: :serial, force: :cascade do |t|
    t.integer "access_group_id"
    t.integer "user_id"
    t.datetime "deleted_at"
  end

  create_table "access_groups", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "user_id"
    t.string "coc_codes", default: [], array: true
    t.datetime "deleted_at"
  end

  create_table "activity_logs", id: :serial, force: :cascade do |t|
    t.string "item_model"
    t.integer "item_id"
    t.string "title"
    t.integer "user_id", null: false
    t.string "controller_name", null: false
    t.string "action_name", null: false
    t.string "method"
    t.string "path"
    t.string "ip_address", null: false
    t.string "session_hash"
    t.text "referrer"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["controller_name"], name: "index_activity_logs_on_controller_name"
    t.index ["created_at", "item_model", "user_id"], name: "index_activity_logs_on_created_at_and_item_model_and_user_id"
    t.index ["item_model", "user_id", "created_at"], name: "index_activity_logs_on_item_model_and_user_id_and_created_at"
    t.index ["item_model", "user_id"], name: "index_activity_logs_on_item_model_and_user_id"
    t.index ["item_model"], name: "index_activity_logs_on_item_model"
    t.index ["user_id", "item_model", "created_at"], name: "index_activity_logs_on_user_id_and_item_model_and_created_at"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "agencies", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "expose_publically", default: false, null: false
  end

  create_table "agencies_consent_limits", id: false, force: :cascade do |t|
    t.bigint "consent_limit_id", null: false
    t.bigint "agency_id", null: false
    t.index ["agency_id"], name: "index_agencies_consent_limits_on_agency_id"
    t.index ["consent_limit_id"], name: "index_agencies_consent_limits_on_consent_limit_id"
  end

  create_table "client_service_history", id: false, force: :cascade do |t|
    t.integer "unduplicated_client_id"
    t.date "date"
    t.date "first_date_in_program"
    t.date "last_date_in_program"
    t.string "program_group_id"
    t.integer "program_type"
    t.integer "program_id"
    t.integer "age"
    t.decimal "income"
    t.integer "income_type"
    t.integer "income_source_code"
    t.integer "destination"
    t.string "head_of_household_id"
    t.string "household_id"
    t.string "database_id"
    t.string "program_name"
    t.integer "program_tracking_method"
    t.string "record_type"
    t.integer "dc_id"
    t.integer "housing_status_at_entry"
    t.integer "housing_status_at_exit"
  end

  create_table "clients_unduplicated", id: :serial, force: :cascade do |t|
    t.string "client_unique_id", null: false
    t.integer "unduplicated_client_id", null: false
    t.integer "dc_id"
    t.index ["unduplicated_client_id"], name: "unduplicated_clients_unduplicated_client_id"
  end

  create_table "consent_limits", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "color"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_consent_limits_on_name"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "glacier_archives", id: :serial, force: :cascade do |t|
    t.integer "glacier_vault_id", null: false
    t.text "upload_id", null: false
    t.text "archive_id"
    t.text "checksum"
    t.text "location"
    t.string "status", default: "initialized", null: false
    t.boolean "verified", default: false, null: false
    t.bigint "size_in_bytes"
    t.datetime "upload_started_at"
    t.datetime "upload_finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.string "job_id"
    t.string "archive_name"
    t.index ["glacier_vault_id"], name: "index_glacier_archives_on_glacier_vault_id"
    t.index ["upload_id"], name: "index_glacier_archives_on_upload_id", unique: true
  end

  create_table "glacier_vaults", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "vault_created_at"
    t.datetime "last_upload_attempt_at"
    t.datetime "last_upload_success_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_glacier_vaults_on_name", unique: true
  end

  create_table "imports", id: :serial, force: :cascade do |t|
    t.string "file"
    t.string "source"
    t.float "percent_complete"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "completed_at"
    t.datetime "deleted_at"
    t.json "unzipped_files"
    t.json "import_errors"
    t.index ["deleted_at"], name: "index_imports_on_deleted_at"
  end

  create_table "letsencrypt_plugin_challenges", id: :serial, force: :cascade do |t|
    t.text "response"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "letsencrypt_plugin_settings", id: :serial, force: :cascade do |t|
    t.text "private_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "login_activities", id: :serial, force: :cascade do |t|
    t.string "scope"
    t.string "strategy"
    t.string "identity"
    t.boolean "success"
    t.string "failure_reason"
    t.integer "user_id"
    t.string "user_type"
    t.string "context"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "city"
    t.string "region"
    t.string "country"
    t.datetime "created_at"
    t.index ["identity"], name: "index_login_activities_on_identity"
    t.index ["ip"], name: "index_login_activities_on_ip"
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "from", null: false
    t.string "subject", null: false
    t.text "body", null: false
    t.boolean "html", default: false, null: false
    t.datetime "seen_at"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "nicknames", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "nickname_id"
  end

  create_table "old_passwords", id: :serial, force: :cascade do |t|
    t.string "encrypted_password", null: false
    t.string "password_archivable_type", null: false
    t.integer "password_archivable_id", null: false
    t.string "password_salt"
    t.datetime "created_at"
    t.index ["password_archivable_type", "password_archivable_id"], name: "index_password_archivable"
  end

  create_table "report_results", id: :serial, force: :cascade do |t|
    t.integer "report_id"
    t.integer "import_id"
    t.float "percent_complete"
    t.json "results"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.datetime "completed_at"
    t.integer "user_id"
    t.json "original_results"
    t.json "options"
    t.string "job_status"
    t.json "validations"
    t.json "support"
    t.integer "delayed_job_id"
    t.integer "file_id"
    t.index ["deleted_at"], name: "index_report_results_on_deleted_at"
    t.index ["report_id"], name: "index_report_results_on_report_id"
  end

  create_table "report_results_summaries", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "weight", default: 0, null: false
  end

  create_table "reports", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "weight", default: 0, null: false
    t.integer "report_results_summary_id"
    t.boolean "enabled", default: true, null: false
    t.index ["report_results_summary_id"], name: "index_reports_on_report_results_summary_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "verb"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "can_edit_anything_super_user", default: false
    t.boolean "can_view_clients", default: false
    t.boolean "can_edit_clients", default: false
    t.boolean "can_view_censuses", default: false
    t.boolean "can_view_census_details", default: false
    t.boolean "can_edit_users", default: false
    t.boolean "can_edit_roles", default: false
    t.boolean "can_audit_users", default: false
    t.boolean "can_view_full_ssn", default: false
    t.boolean "can_view_full_dob", default: false
    t.boolean "can_view_hiv_status", default: false
    t.boolean "can_view_dmh_status", default: false
    t.boolean "can_view_imports", default: false
    t.boolean "can_view_projects", default: false
    t.boolean "can_edit_projects", default: false
    t.boolean "can_edit_project_groups", default: false
    t.boolean "can_view_organizations", default: false
    t.boolean "can_edit_organizations", default: false
    t.boolean "can_edit_data_sources", default: false
    t.boolean "can_search_window", default: false
    t.boolean "can_view_client_window", default: false
    t.boolean "can_upload_hud_zips", default: false
    t.boolean "can_edit_translations", default: false
    t.boolean "can_manage_assessments", default: false
    t.boolean "can_manage_client_files", default: false
    t.boolean "can_manage_window_client_files", default: false
    t.boolean "can_see_own_file_uploads", default: false
    t.boolean "can_manage_config", default: false
    t.boolean "can_edit_dq_grades", default: false
    t.boolean "can_view_vspdat", default: false
    t.boolean "can_edit_vspdat", default: false
    t.boolean "can_submit_vspdat", default: false
    t.boolean "can_create_clients", default: false
    t.boolean "can_view_client_history_calendar", default: false
    t.boolean "can_edit_client_notes", default: false
    t.boolean "can_edit_window_client_notes", default: false
    t.boolean "can_see_own_window_client_notes", default: false
    t.boolean "can_manage_cohorts", default: false
    t.boolean "can_edit_cohort_clients", default: false
    t.boolean "can_edit_assigned_cohorts", default: false
    t.boolean "can_view_assigned_cohorts", default: false
    t.boolean "can_assign_users_to_clients", default: false
    t.boolean "can_view_client_user_assignments", default: false
    t.boolean "can_export_hmis_data", default: false
    t.boolean "can_confirm_housing_release", default: false
    t.boolean "can_track_anomalies", default: false
    t.boolean "can_view_all_reports", default: false
    t.boolean "can_assign_reports", default: false
    t.boolean "can_view_assigned_reports", default: false
    t.boolean "can_view_project_data_quality_client_details", default: false
    t.boolean "can_manage_organization_users", default: false
    t.boolean "can_view_all_user_client_assignments", default: false
    t.boolean "can_add_administrative_event", default: false
    t.boolean "can_see_clients_in_window_for_assigned_data_sources", default: false
    t.boolean "can_upload_deidentified_hud_hmis_files", default: false
    t.boolean "can_upload_whitelisted_hud_hmis_files", default: false
    t.boolean "can_edit_warehouse_alerts", default: false
    t.boolean "can_upload_dashboard_extras", default: false
    t.boolean "can_administer_health", default: false
    t.boolean "can_edit_client_health", default: false
    t.boolean "can_view_client_health", default: false
    t.boolean "can_view_aggregate_health", default: false
    t.boolean "can_manage_health_agency", default: false
    t.boolean "can_approve_patient_assignments", default: false
    t.boolean "can_manage_claims", default: false
    t.boolean "can_manage_all_patients", default: false
    t.boolean "can_manage_patients_for_own_agency", default: false
    t.boolean "can_manage_care_coordinators", default: false
    t.boolean "can_approve_cha", default: false
    t.boolean "can_approve_ssm", default: false
    t.boolean "can_approve_release", default: false
    t.boolean "can_approve_participation", default: false
    t.boolean "can_edit_all_patient_items", default: false
    t.boolean "can_edit_patient_items_for_own_agency", default: false
    t.boolean "can_create_care_plans_for_own_agency", default: false
    t.boolean "can_view_all_patients", default: false
    t.boolean "can_view_patients_for_own_agency", default: false
    t.boolean "can_add_case_management_notes", default: false
    t.boolean "can_manage_accountable_care_organizations", default: false
    t.boolean "can_view_member_health_reports", default: false
    t.boolean "health_role", default: false, null: false
    t.boolean "can_audit_clients", default: false
    t.boolean "can_export_anonymous_hmis_data", default: false
    t.boolean "can_view_youth_intake", default: false
    t.boolean "can_edit_youth_intake", default: false
    t.boolean "can_view_all_secure_uploads", default: false
    t.boolean "can_unsubmit_submitted_claims", default: false
    t.boolean "can_view_assigned_secure_uploads", default: false
    t.boolean "can_manage_agency", default: false
    t.boolean "can_manage_all_agencies", default: false
    t.boolean "can_view_own_agency_youth_intake", default: false
    t.boolean "can_edit_own_agency_youth_intake", default: false
    t.boolean "can_view_clients_with_roi_in_own_coc", default: false
    t.boolean "can_enable_2fa", default: false
    t.boolean "can_edit_help", default: false
    t.boolean "can_view_ce_assessment", default: false
    t.boolean "can_edit_ce_assessment", default: false
    t.boolean "can_submit_ce_assessment", default: false
    t.boolean "can_edit_access_groups", default: false
    t.boolean "enforced_2fa", default: false
    t.boolean "can_view_all_hud_reports", default: false
    t.boolean "can_view_own_hud_reports", default: false
    t.boolean "can_view_confidential_enrollment_details", default: false
    t.boolean "can_impersonate_users", default: false
    t.boolean "can_manage_ad_hoc_data_sources", default: false
    t.boolean "can_view_client_ad_hoc_data_sources", default: false
    t.boolean "can_use_strict_search", default: false
    t.boolean "can_use_separated_consent", default: false
    t.boolean "training_required", default: false
    t.boolean "can_delete_projects", default: false
    t.boolean "can_delete_data_sources", default: false
    t.boolean "can_edit_health_emergency_triage", default: false
    t.boolean "can_edit_health_emergency_clinical", default: false
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "similarity_metrics", id: :serial, force: :cascade do |t|
    t.string "type", null: false
    t.float "mean", default: 0.0, null: false
    t.float "standard_deviation", default: 0.0, null: false
    t.float "weight", default: 1.0, null: false
    t.integer "n", default: 0, null: false
    t.hstore "other_state", default: {}, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["type"], name: "index_similarity_metrics_on_type", unique: true
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
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

  create_table "tokens", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "token", null: false
    t.string "path", null: false
    t.datetime "expires_at"
    t.index ["created_at"], name: "index_tokens_on_created_at"
    t.index ["expires_at"], name: "index_tokens_on_expires_at"
    t.index ["token"], name: "index_tokens_on_token"
    t.index ["updated_at"], name: "index_tokens_on_updated_at"
  end

  create_table "translation_keys", id: :serial, force: :cascade do |t|
    t.string "key", default: "", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["key"], name: "index_translation_keys_on_key"
  end

  create_table "translation_texts", id: :serial, force: :cascade do |t|
    t.text "text"
    t.string "locale"
    t.integer "translation_key_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["translation_key_id"], name: "index_translation_texts_on_translation_key_id"
  end

  create_table "unique_names", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "double_metaphone"
  end

  create_table "uploads", id: :serial, force: :cascade do |t|
    t.integer "data_source_id"
    t.string "file", null: false
    t.float "percent_complete"
    t.string "unzipped_path"
    t.json "unzipped_files"
    t.json "summary"
    t.json "import_errors"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "deleted_at"
    t.integer "user_id"
    t.index ["deleted_at"], name: "index_uploads_on_deleted_at"
  end

  create_table "user_roles", id: :serial, force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "invitation_token"
    t.datetime "invitation_created_at"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "first_name"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer "invitation_limit"
    t.integer "invited_by_id"
    t.string "invited_by_type"
    t.integer "invitations_count", default: 0
    t.boolean "receive_file_upload_notifications", default: false
    t.string "phone"
    t.string "deprecated_agency"
    t.boolean "notify_on_vispdat_completed", default: false
    t.boolean "notify_on_client_added", default: false
    t.boolean "notify_on_anomaly_identified", default: false, null: false
    t.string "coc_codes", default: [], array: true
    t.string "email_schedule", default: "immediate", null: false
    t.boolean "active", default: true, null: false
    t.integer "agency_id"
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login", default: false, null: false
    t.string "unique_session_id"
    t.datetime "last_activity_at"
    t.datetime "expired_at"
    t.integer "confirmed_2fa", default: 0, null: false
    t.string "otp_backup_codes", array: true
    t.datetime "password_changed_at"
    t.boolean "training_completed", default: false
    t.date "last_training_completed"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invitations_count"], name: "index_users_on_invitations_count"
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
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
    t.text "object_changes"
    t.integer "referenced_user_id"
    t.string "referenced_entity_name"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "warehouse_alerts", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "html"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
  end

  add_foreign_key "glacier_archives", "glacier_vaults"
  add_foreign_key "report_results", "users"
  add_foreign_key "reports", "report_results_summaries"
  add_foreign_key "user_roles", "roles", on_delete: :cascade
  add_foreign_key "user_roles", "users", on_delete: :cascade
end
