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

ActiveRecord::Schema[7.0].define(version: 2024_12_16_164805) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "hstore"
  enable_extension "plpgsql"

  create_function :prevent_modification, sql_definition: <<-'SQL'
      CREATE OR REPLACE FUNCTION public.prevent_modification()
       RETURNS trigger
       LANGUAGE plpgsql
      AS $function$
      BEGIN
        RETURN NULL;
      END;
      $function$
  SQL

  create_table "access_control_uploads", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "status"
    t.jsonb "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_access_control_uploads_on_user_id"
  end

  create_table "access_controls", force: :cascade do |t|
    t.bigint "collection_id"
    t.bigint "role_id"
    t.bigint "user_group_id"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.index ["collection_id"], name: "index_access_controls_on_collection_id"
    t.index ["role_id"], name: "index_access_controls_on_role_id"
    t.index ["user_group_id"], name: "index_access_controls_on_user_group_id"
  end

  create_table "access_group_members", id: :serial, force: :cascade do |t|
    t.integer "access_group_id"
    t.integer "user_id"
    t.datetime "deleted_at", precision: nil
  end

  create_table "access_groups", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "user_id"
    t.string "coc_codes", default: [], array: true
    t.datetime "deleted_at", precision: nil
    t.jsonb "system", default: []
    t.boolean "must_exist", default: false, null: false
  end

  create_table "account_requests", force: :cascade do |t|
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "status", null: false
    t.text "details"
    t.datetime "accepted_at", precision: nil
    t.integer "accepted_by"
    t.string "rejection_reason"
    t.datetime "rejected_at", precision: nil
    t.integer "rejected_by"
    t.bigint "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_account_requests_on_user_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
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
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "expose_publically", default: false, null: false
  end

  create_table "agencies_consent_limits", id: false, force: :cascade do |t|
    t.bigint "consent_limit_id", null: false
    t.bigint "agency_id", null: false
    t.index ["agency_id"], name: "index_agencies_consent_limits_on_agency_id"
    t.index ["consent_limit_id"], name: "index_agencies_consent_limits_on_consent_limit_id"
  end

  create_table "app_config_properties", force: :cascade do |t|
    t.string "key", null: false
    t.jsonb "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_app_config_properties_on_key", unique: true
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

  create_table "collections", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id"
    t.jsonb "coc_codes", default: {}
    t.jsonb "system", default: []
    t.boolean "must_exist", default: false, null: false
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.string "collection_type"
    t.index ["user_id"], name: "index_collections_on_user_id"
  end

  create_table "consent_limits", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "color"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_consent_limits_on_name"
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

  create_table "glacier_archives", id: :serial, force: :cascade do |t|
    t.integer "glacier_vault_id", null: false
    t.text "upload_id", null: false
    t.text "archive_id"
    t.text "checksum"
    t.text "location"
    t.string "status", default: "initialized", null: false
    t.boolean "verified", default: false, null: false
    t.bigint "size_in_bytes"
    t.datetime "upload_started_at", precision: nil
    t.datetime "upload_finished_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "notes"
    t.string "job_id"
    t.string "archive_name"
    t.index ["glacier_vault_id"], name: "index_glacier_archives_on_glacier_vault_id"
    t.index ["upload_id"], name: "index_glacier_archives_on_upload_id", unique: true
  end

  create_table "glacier_vaults", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "vault_created_at", precision: nil
    t.datetime "last_upload_attempt_at", precision: nil
    t.datetime "last_upload_success_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["name"], name: "index_glacier_vaults_on_name", unique: true
  end

  create_table "hmis_access_controls", force: :cascade do |t|
    t.bigint "access_group_id"
    t.bigint "role_id"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_group_id"
    t.text "description"
    t.index ["access_group_id"], name: "index_hmis_access_controls_on_access_group_id"
    t.index ["role_id"], name: "index_hmis_access_controls_on_role_id"
    t.index ["user_group_id"], name: "index_hmis_access_controls_on_user_group_id"
  end

  create_table "hmis_access_groups", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.text "description"
    t.string "collection_type"
  end

  create_table "hmis_activity_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "data_source_id", null: false
    t.jsonb "resolved_fields"
    t.string "ip_address", null: false
    t.string "session_hash"
    t.jsonb "variables", comment: "GraphQL variables"
    t.string "referer", comment: "user-provided"
    t.string "operation_name", comment: "user-provided GraphQL operation name"
    t.string "header_page_path", comment: "user-provided, decrypted path"
    t.bigint "header_client_id", comment: "user-provided"
    t.bigint "header_enrollment_id", comment: "user-provided"
    t.bigint "header_project_id", comment: "user-provided"
    t.datetime "created_at", precision: nil, null: false
    t.date "processed_at"
    t.datetime "resolved_at", precision: nil
    t.index ["user_id"], name: "index_hmis_activity_logs_on_user_id"
  end

  create_table "hmis_activity_logs_clients", id: false, force: :cascade do |t|
    t.bigint "activity_log_id", null: false
    t.bigint "client_id", null: false
    t.index ["activity_log_id"], name: "index_hmis_activity_logs_clients_on_activity_log_id"
    t.index ["client_id"], name: "index_hmis_activity_logs_clients_on_client_id"
  end

  create_table "hmis_activity_logs_enrollments", id: false, force: :cascade do |t|
    t.bigint "activity_log_id", null: false
    t.bigint "enrollment_id", null: false
    t.bigint "project_id"
    t.index ["activity_log_id"], name: "index_hmis_activity_logs_enrollments_on_activity_log_id"
    t.index ["enrollment_id"], name: "index_hmis_activity_logs_enrollments_on_enrollment_id"
    t.index ["project_id"], name: "index_hmis_activity_logs_enrollments_on_project_id"
  end

  create_table "hmis_roles", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "can_view_full_ssn", default: false, null: false
    t.boolean "can_view_clients", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at", precision: nil
    t.boolean "can_administer_hmis", default: false
    t.boolean "can_delete_assigned_project_data", default: false
    t.boolean "can_delete_enrollments", default: false
    t.boolean "can_delete_project", default: false, null: false
    t.boolean "can_edit_project_details", default: false, null: false
    t.boolean "can_edit_organization", default: false, null: false
    t.boolean "can_delete_organization", default: false, null: false
    t.boolean "can_edit_clients", default: false, null: false
    t.boolean "can_view_partial_ssn", default: false, null: false
    t.boolean "can_view_dob", default: false, null: false
    t.boolean "can_view_enrollment_details", default: false, null: false
    t.boolean "can_edit_enrollments", default: false, null: false
    t.boolean "can_manage_any_client_files", default: false, null: false
    t.boolean "can_manage_own_client_files", default: false, null: false
    t.boolean "can_view_any_nonconfidential_client_files", default: false, null: false
    t.boolean "can_view_any_confidential_client_files", default: false, null: false
    t.boolean "can_manage_client_files", default: false, null: false
    t.boolean "can_audit_clients", default: false, null: false
    t.boolean "can_delete_clients", default: false, null: false
    t.boolean "can_delete_assessments", default: false
    t.boolean "can_view_project", default: false
    t.boolean "can_manage_incoming_referrals", default: false
    t.boolean "can_manage_outgoing_referrals", default: false
    t.boolean "can_manage_denied_referrals", default: false
    t.boolean "can_impersonate_users", default: false
    t.boolean "can_audit_users", default: false
    t.boolean "can_view_client_name", default: false
    t.boolean "can_view_client_contact_info", default: false
    t.boolean "can_view_client_photo", default: false
    t.boolean "can_view_hud_chronic_status", default: false
    t.boolean "can_view_limited_enrollment_details", default: false
    t.boolean "can_view_open_enrollment_summary", default: false
    t.boolean "can_enroll_clients", default: false
    t.boolean "can_audit_enrollments", default: false
    t.boolean "can_merge_clients", default: false
    t.boolean "can_split_households", default: false
    t.boolean "can_transfer_enrollments", default: false
    t.boolean "can_manage_forms", default: false
    t.boolean "can_configure_data_collection", default: false
    t.boolean "can_administrate_config", default: false
    t.boolean "can_manage_scan_cards", default: false
    t.boolean "can_view_client_alerts", default: false
    t.boolean "can_manage_client_alerts", default: false
    t.boolean "can_manage_external_form_submissions", default: false
    t.boolean "can_view_units", default: false
    t.boolean "can_manage_units", default: false
  end

  create_table "hmis_user_access_controls", force: :cascade do |t|
    t.bigint "access_control_id"
    t.bigint "user_id"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_control_id"], name: "index_hmis_user_access_controls_on_access_control_id"
    t.index ["user_id"], name: "index_hmis_user_access_controls_on_user_id"
  end

  create_table "hmis_user_group_members", force: :cascade do |t|
    t.bigint "user_group_id"
    t.bigint "user_id"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_group_id"], name: "index_hmis_user_group_members_on_user_group_id"
    t.index ["user_id"], name: "index_hmis_user_group_members_on_user_id"
  end

  create_table "hmis_user_groups", force: :cascade do |t|
    t.string "name"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
  end

  create_table "imports", id: :serial, force: :cascade do |t|
    t.string "file"
    t.string "source"
    t.float "percent_complete"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "completed_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.json "unzipped_files"
    t.json "import_errors"
    t.index ["deleted_at"], name: "index_imports_on_deleted_at"
  end

  create_table "letsencrypt_plugin_challenges", id: :serial, force: :cascade do |t|
    t.text "response"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "letsencrypt_plugin_settings", id: :serial, force: :cascade do |t|
    t.text "private_key"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "links", force: :cascade do |t|
    t.string "location"
    t.string "url"
    t.string "label"
    t.string "subject"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "login_activities", id: :serial, force: :cascade do |t|
    t.string "scope"
    t.string "strategy"
    t.string "identity"
    t.boolean "success"
    t.string "failure_reason"
    t.string "user_type"
    t.integer "user_id"
    t.string "context"
    t.string "ip"
    t.text "user_agent"
    t.text "referrer"
    t.string "city"
    t.string "region"
    t.string "country"
    t.datetime "created_at", precision: nil
    t.index ["identity"], name: "index_login_activities_on_identity"
    t.index ["ip"], name: "index_login_activities_on_ip"
  end

  create_table "messages", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "from", null: false
    t.string "subject", null: false
    t.text "body", null: false
    t.boolean "html", default: false, null: false
    t.datetime "seen_at", precision: nil
    t.datetime "sent_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "nicknames", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "nickname_id"
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.bigint "resource_owner_id", null: false
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.integer "expires_in", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "revoked_at", precision: nil
    t.index ["application_id"], name: "index_oauth_access_grants_on_application_id"
    t.index ["resource_owner_id"], name: "index_oauth_access_grants_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_grants_on_token", unique: true
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.bigint "resource_owner_id"
    t.bigint "application_id", null: false
    t.string "token", null: false
    t.string "refresh_token"
    t.integer "expires_in"
    t.string "scopes"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "revoked_at", precision: nil
    t.string "previous_refresh_token", default: "", null: false
    t.index ["application_id"], name: "index_oauth_access_tokens_on_application_id"
    t.index ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true
    t.index ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], name: "index_oauth_access_tokens_on_token", unique: true
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string "name", null: false
    t.string "uid", null: false
    t.string "secret", null: false
    t.text "redirect_uri", null: false
    t.string "scopes", default: "", null: false
    t.boolean "confidential", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_oauth_applications_on_uid", unique: true
  end

  create_table "oauth_identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.string "provider", null: false
    t.json "raw_info"
    t.string "uid", null: false
    t.index ["provider", "uid"], name: "idx_oauth_on_provider_and_uid", unique: true
    t.index ["uid"], name: "index_oauth_identities_on_uid"
    t.index ["user_id", "provider"], name: "index_oauth_identities_on_user_id_and_provider", unique: true
  end

  create_table "old_passwords", id: :serial, force: :cascade do |t|
    t.string "encrypted_password", null: false
    t.string "password_archivable_type", null: false
    t.integer "password_archivable_id", null: false
    t.string "password_salt"
    t.datetime "created_at", precision: nil
    t.index ["password_archivable_type", "password_archivable_id"], name: "index_password_archivable"
  end

  create_table "pghero_query_stats", force: :cascade do |t|
    t.text "database"
    t.text "user"
    t.text "query"
    t.bigint "query_hash"
    t.float "total_time"
    t.bigint "calls"
    t.datetime "captured_at", precision: nil
    t.index ["database", "captured_at"], name: "index_pghero_query_stats_on_database_and_captured_at"
  end

  create_table "pghero_space_stats", force: :cascade do |t|
    t.text "database"
    t.text "schema"
    t.text "relation"
    t.bigint "size"
    t.datetime "captured_at", precision: nil
    t.index ["database", "captured_at"], name: "index_pghero_space_stats_on_database_and_captured_at"
  end

  create_table "report_results", id: :serial, force: :cascade do |t|
    t.integer "report_id"
    t.integer "import_id"
    t.float "percent_complete"
    t.json "results"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.integer "user_id"
    t.json "original_results"
    t.json "options"
    t.string "job_status"
    t.json "validations"
    t.json "support"
    t.integer "delayed_job_id"
    t.integer "file_id"
    t.integer "support_file_id"
    t.integer "export_id"
    t.index ["deleted_at"], name: "index_report_results_on_deleted_at"
    t.index ["report_id"], name: "index_report_results_on_report_id"
  end

  create_table "report_results_summaries", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "type", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "weight", default: 0, null: false
  end

  create_table "reports", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "type", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "weight", default: 0, null: false
    t.integer "report_results_summary_id"
    t.boolean "enabled", default: true, null: false
    t.index ["report_results_summary_id"], name: "index_reports_on_report_results_summary_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "verb"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "can_edit_anything_super_user", default: false
    t.boolean "can_view_clients", default: false
    t.boolean "can_edit_clients", default: false
    t.boolean "can_view_full_client_dashboard", default: false
    t.boolean "can_view_limited_client_dashboard", default: false
    t.boolean "can_audit_clients", default: false
    t.boolean "can_view_census_details", default: false
    t.boolean "can_edit_users", default: false
    t.boolean "can_enable_2fa", default: false
    t.boolean "enforced_2fa", default: false
    t.boolean "training_required", default: false
    t.boolean "can_edit_roles", default: false
    t.boolean "can_edit_access_groups", default: false
    t.boolean "can_audit_users", default: false
    t.boolean "can_view_full_ssn", default: false
    t.boolean "can_view_full_dob", default: false
    t.boolean "can_view_hiv_status", default: false
    t.boolean "can_view_dmh_status", default: false
    t.boolean "can_view_imports", default: false
    t.boolean "can_view_projects", default: false
    t.boolean "can_edit_projects", default: false
    t.boolean "can_import_project_groups", default: false
    t.boolean "can_edit_project_groups", default: false
    t.boolean "can_view_organizations", default: false
    t.boolean "can_edit_organizations", default: false
    t.boolean "can_edit_data_sources", default: false
    t.boolean "can_search_all_clients", default: false
    t.boolean "can_use_strict_search", default: false
    t.boolean "can_search_window", default: false
    t.boolean "can_view_cached_client_enrollments", default: false
    t.boolean "can_view_client_window", default: false
    t.boolean "can_upload_hud_zips", default: false
    t.boolean "can_edit_translations", default: false
    t.boolean "can_manage_assessments", default: false
    t.boolean "can_manage_client_files", default: false
    t.boolean "can_manage_window_client_files", default: false
    t.boolean "can_generate_homeless_verification_pdfs", default: false
    t.boolean "can_see_own_file_uploads", default: false
    t.boolean "can_use_separated_consent", default: false
    t.boolean "can_manage_config", default: false
    t.boolean "can_manage_sessions", default: false
    t.boolean "can_edit_dq_grades", default: false
    t.boolean "can_view_vspdat", default: false
    t.boolean "can_edit_vspdat", default: false
    t.boolean "can_submit_vspdat", default: false
    t.boolean "can_view_ce_assessment", default: false
    t.boolean "can_edit_ce_assessment", default: false
    t.boolean "can_submit_ce_assessment", default: false
    t.boolean "can_view_youth_intake", default: false
    t.boolean "can_edit_youth_intake", default: false
    t.boolean "can_delete_youth_intake", default: false
    t.boolean "can_view_own_agency_youth_intake", default: false
    t.boolean "can_edit_own_agency_youth_intake", default: false
    t.boolean "can_create_clients", default: false
    t.boolean "can_view_client_history_calendar", default: false
    t.boolean "can_view_client_locations", default: false
    t.boolean "can_view_enrollment_details", default: false
    t.boolean "can_edit_client_notes", default: false
    t.boolean "can_edit_window_client_notes", default: false
    t.boolean "can_see_own_window_client_notes", default: false
    t.boolean "can_view_all_window_notes", default: false
    t.boolean "can_manage_cohorts", default: false
    t.boolean "can_edit_cohort_clients", default: false
    t.boolean "can_edit_assigned_cohorts", default: false
    t.boolean "can_view_assigned_cohorts", default: false
    t.boolean "can_download_cohorts", default: false
    t.boolean "can_assign_users_to_clients", default: false
    t.boolean "can_view_client_user_assignments", default: false
    t.boolean "can_export_hmis_data", default: false
    t.boolean "can_export_anonymous_hmis_data", default: false
    t.boolean "can_confirm_housing_release", default: false
    t.boolean "can_track_anomalies", default: false
    t.boolean "can_view_all_reports", default: false
    t.boolean "can_assign_reports", default: false
    t.boolean "can_view_assigned_reports", default: false
    t.boolean "can_administer_assigned_reports", default: false
    t.boolean "can_view_project_related_filters", default: false
    t.boolean "can_view_all_user_client_assignments", default: false
    t.boolean "can_add_administrative_event", default: false
    t.boolean "can_see_clients_in_window_for_assigned_data_sources", default: false
    t.boolean "can_upload_deidentified_hud_hmis_files", default: false
    t.boolean "can_upload_whitelisted_hud_hmis_files", default: false
    t.boolean "can_edit_warehouse_alerts", default: false
    t.boolean "can_upload_dashboard_extras", default: false
    t.boolean "can_view_all_secure_uploads", default: false
    t.boolean "can_view_assigned_secure_uploads", default: false
    t.boolean "can_manage_agency", default: false
    t.boolean "can_manage_all_agencies", default: false
    t.boolean "can_view_clients_with_roi_in_own_coc", default: false
    t.boolean "can_edit_help", default: false
    t.boolean "can_view_all_hud_reports", default: false
    t.boolean "can_view_own_hud_reports", default: false
    t.boolean "can_manage_ad_hoc_data_sources", default: false
    t.boolean "can_manage_own_ad_hoc_data_sources", default: false
    t.boolean "can_view_client_ad_hoc_data_sources", default: false
    t.boolean "can_impersonate_users", default: false
    t.boolean "can_delete_projects", default: false
    t.boolean "can_delete_data_sources", default: false
    t.boolean "can_see_health_emergency", default: false
    t.boolean "can_edit_health_emergency_medical_restriction", default: false
    t.boolean "can_edit_health_emergency_screening", default: false
    t.boolean "can_edit_health_emergency_clinical", default: false
    t.boolean "can_see_health_emergency_history", default: false
    t.boolean "can_see_health_emergency_medical_restriction", default: false
    t.boolean "can_see_health_emergency_screening", default: false
    t.boolean "can_see_health_emergency_clinical", default: false
    t.boolean "receives_medical_restriction_notifications", default: false
    t.boolean "can_use_service_register", default: false
    t.boolean "can_view_service_register_on_client", default: false
    t.boolean "can_manage_auto_client_de_duplication", default: false
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
    t.boolean "can_unsubmit_submitted_claims", default: false
    t.boolean "can_edit_health_emergency_contact_tracing", default: false
    t.boolean "health_role", default: false, null: false
    t.boolean "can_view_all_vprs", default: false
    t.boolean "can_view_my_vprs", default: false
    t.boolean "can_search_own_clients", default: false
    t.boolean "can_view_confidential_project_names", default: false
    t.boolean "can_report_on_confidential_projects", default: false
    t.boolean "can_edit_assigned_project_groups", default: false
    t.boolean "can_view_chronic_tab", default: false
    t.boolean "can_view_confidential_enrollment_details", default: false
    t.boolean "can_configure_cohorts", default: false
    t.boolean "can_add_cohort_clients", default: false
    t.boolean "can_manage_cohort_data", default: false
    t.boolean "can_view_cohorts", default: false
    t.boolean "can_participate_in_cohorts", default: false
    t.boolean "can_view_inactive_cohort_clients", default: false
    t.boolean "can_manage_inactive_cohort_clients", default: false
    t.boolean "can_view_deleted_cohort_clients", default: false
    t.boolean "can_view_cohort_client_changes_report", default: false
    t.boolean "system", default: false, null: false
    t.boolean "can_approve_careplan", default: false
    t.boolean "can_manage_inbound_api_configurations", default: false
    t.boolean "can_view_client_enrollments_with_roi", default: false
    t.boolean "can_edit_collections", default: false
    t.boolean "can_search_clients_with_roi", default: false
    t.boolean "can_see_confidential_files", default: false
    t.boolean "can_edit_own_client_notes", default: false
    t.boolean "can_publish_reports", default: false
    t.boolean "can_edit_theme", default: false
    t.boolean "can_view_client_name", default: false
    t.boolean "can_view_client_photo", default: false
    t.datetime "deleted_at", precision: nil
    t.boolean "can_view_project_locations", default: false
    t.boolean "can_view_supplemental_client_data", default: false
    t.boolean "can_edit_cohort_columns", default: false
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "similarity_metrics", id: :serial, force: :cascade do |t|
    t.string "type", null: false
    t.float "mean", default: 0.0, null: false
    t.float "standard_deviation", default: 0.0, null: false
    t.float "weight", default: 1.0, null: false
    t.integer "n", default: 0, null: false
    t.hstore "other_state", default: {}, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["type"], name: "index_similarity_metrics_on_type", unique: true
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id"
    t.string "taggable_type"
    t.integer "taggable_id"
    t.string "tagger_type"
    t.integer "tagger_id"
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

  create_table "task_queues", force: :cascade do |t|
    t.string "task_key"
    t.boolean "active", default: true, null: false
    t.datetime "queued_at", precision: nil
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tokens", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "token", null: false
    t.string "path", null: false
    t.datetime "expires_at", precision: nil
    t.index ["created_at"], name: "index_tokens_on_created_at"
    t.index ["expires_at"], name: "index_tokens_on_expires_at"
    t.index ["token"], name: "index_tokens_on_token"
    t.index ["updated_at"], name: "index_tokens_on_updated_at"
  end

  create_table "translations", force: :cascade do |t|
    t.string "key"
    t.string "text"
    t.boolean "common", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_translations_on_key"
  end

  create_table "two_factors_memorized_devices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "uuid", null: false
    t.string "name", null: false
    t.datetime "expires_at", precision: nil, null: false
    t.integer "session_id"
    t.string "log_in_ip"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["user_id"], name: "index_two_factors_memorized_devices_on_user_id"
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "started_at", precision: nil
    t.datetime "completed_at", precision: nil
    t.datetime "deleted_at", precision: nil
    t.integer "user_id"
    t.index ["deleted_at"], name: "index_uploads_on_deleted_at"
  end

  create_table "user_access_controls", force: :cascade do |t|
    t.bigint "access_control_id"
    t.bigint "user_id"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_control_id"], name: "index_user_access_controls_on_access_control_id"
    t.index ["user_id"], name: "index_user_access_controls_on_user_id"
  end

  create_table "user_group_members", force: :cascade do |t|
    t.bigint "user_group_id"
    t.bigint "user_id"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_group_id"], name: "index_user_group_members_on_user_group_id"
    t.index ["user_id"], name: "index_user_group_members_on_user_id"
  end

  create_table "user_groups", force: :cascade do |t|
    t.string "name"
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "system", default: false, null: false
    t.text "description"
  end

  create_table "user_roles", id: :serial, force: :cascade do |t|
    t.integer "role_id"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "last_name", null: false
    t.string "email", null: false
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
    t.string "invitation_token"
    t.datetime "invitation_created_at", precision: nil
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
    t.string "first_name"
    t.datetime "invitation_sent_at", precision: nil
    t.datetime "invitation_accepted_at", precision: nil
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.integer "invited_by_id"
    t.integer "invitations_count", default: 0
    t.boolean "receive_file_upload_notifications", default: false
    t.string "phone"
    t.string "deprecated_agency"
    t.boolean "notify_on_vispdat_completed", default: false
    t.boolean "notify_on_client_added", default: false
    t.boolean "notify_on_anomaly_identified", default: false, null: false
    t.string "email_schedule", default: "immediate", null: false
    t.boolean "active", default: true, null: false
    t.integer "agency_id"
    t.string "encrypted_otp_secret"
    t.string "encrypted_otp_secret_iv"
    t.string "encrypted_otp_secret_salt"
    t.integer "consumed_timestep"
    t.boolean "otp_required_for_login", default: false, null: false
    t.string "unique_session_id"
    t.datetime "last_activity_at", precision: nil
    t.datetime "expired_at", precision: nil
    t.integer "confirmed_2fa", default: 0, null: false
    t.string "otp_backup_codes", array: true
    t.datetime "password_changed_at", precision: nil
    t.boolean "training_completed", default: false
    t.date "last_training_completed"
    t.boolean "receive_account_request_notifications", default: false
    t.string "deprecated_provider"
    t.string "deprecated_uid"
    t.json "deprecated_provider_raw_info"
    t.datetime "deprecated_provider_set_at", precision: nil
    t.boolean "exclude_from_directory", default: false
    t.boolean "exclude_phone_from_directory", default: false
    t.boolean "notify_on_new_account", default: false, null: false
    t.string "credentials"
    t.string "hmis_unique_session_id"
    t.string "permission_context", default: "role_based"
    t.jsonb "superset_roles", default: []
    t.string "talent_lms_email"
    t.jsonb "training_courses"
    t.index "btrim(lower((email)::text))", name: "index_active_users_on_lower_email", unique: true, where: "(deleted_at IS NULL)"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_active_users_on_email", unique: true, where: "(deleted_at IS NULL)"
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
    t.datetime "created_at", precision: nil
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deleted_at", precision: nil
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "glacier_archives", "glacier_vaults"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_grants", "users", column: "resource_owner_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "users", column: "resource_owner_id"
  add_foreign_key "report_results", "users"
  add_foreign_key "reports", "report_results_summaries"
  add_foreign_key "two_factors_memorized_devices", "users"
  add_foreign_key "user_roles", "roles", on_delete: :cascade
  add_foreign_key "user_roles", "users", on_delete: :cascade

  create_view "hmis_user_client_activity_log_summaries", sql_definition: <<-SQL
      SELECT concat(hmis_activity_logs_clients.client_id, ':', hmis_activity_logs.user_id) AS id,
      max(hmis_activity_logs.created_at) AS last_accessed_at,
      hmis_activity_logs_clients.client_id,
      hmis_activity_logs.user_id
     FROM (hmis_activity_logs
       JOIN hmis_activity_logs_clients ON ((hmis_activity_logs_clients.activity_log_id = hmis_activity_logs.id)))
    GROUP BY hmis_activity_logs_clients.client_id, hmis_activity_logs.user_id;
  SQL
  create_view "hmis_user_enrollment_activity_log_summaries", sql_definition: <<-SQL
      SELECT concat(hmis_activity_logs_enrollments.enrollment_id, ':', hmis_activity_logs.user_id) AS id,
      max(hmis_activity_logs.created_at) AS last_accessed_at,
      hmis_activity_logs_enrollments.enrollment_id,
      hmis_activity_logs_enrollments.project_id,
      hmis_activity_logs.user_id
     FROM (hmis_activity_logs
       JOIN hmis_activity_logs_enrollments ON ((hmis_activity_logs_enrollments.activity_log_id = hmis_activity_logs.id)))
    GROUP BY hmis_activity_logs_enrollments.enrollment_id, hmis_activity_logs_enrollments.project_id, hmis_activity_logs.user_id;
  SQL

  create_trigger :no_modify_hmis_user_client_activity_log_summaries, sql_definition: <<-SQL
      CREATE TRIGGER no_modify_hmis_user_client_activity_log_summaries INSTEAD OF DELETE OR UPDATE ON public.hmis_user_client_activity_log_summaries FOR EACH ROW EXECUTE FUNCTION prevent_modification()
  SQL
  create_trigger :no_modify_hmis_user_enrollment_activity_log_summaries, sql_definition: <<-SQL
      CREATE TRIGGER no_modify_hmis_user_enrollment_activity_log_summaries INSTEAD OF DELETE OR UPDATE ON public.hmis_user_enrollment_activity_log_summaries FOR EACH ROW EXECUTE FUNCTION prevent_modification()
  SQL
end
