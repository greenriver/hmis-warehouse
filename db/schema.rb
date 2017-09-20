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

ActiveRecord::Schema.define(version: 20170901153110) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"
  enable_extension "fuzzystrmatch"

  create_table "activity_logs", force: :cascade do |t|
    t.string   "item_model"
    t.integer  "item_id"
    t.string   "title"
    t.integer  "user_id",         :null=>false
    t.string   "controller_name", :null=>false
    t.string   "action_name",     :null=>false
    t.string   "method"
    t.string   "path"
    t.string   "ip_address",      :null=>false
    t.string   "session_hash"
    t.text     "referrer"
    t.text     "params"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "activity_logs", ["controller_name"], :name=>"index_activity_logs_on_controller_name", :using=>:btree
  add_index "activity_logs", ["item_model"], :name=>"index_activity_logs_on_item_model", :using=>:btree
  add_index "activity_logs", ["user_id"], :name=>"index_activity_logs_on_user_id", :using=>:btree

  create_table "client_service_history", id: false, force: :cascade do |t|
    t.integer "unduplicated_client_id"
    t.date    "date"
    t.date    "first_date_in_program"
    t.date    "last_date_in_program"
    t.string  "program_group_id"
    t.integer "program_type"
    t.integer "program_id"
    t.integer "age"
    t.decimal "income"
    t.integer "income_type"
    t.integer "income_source_code"
    t.integer "destination"
    t.string  "head_of_household_id"
    t.string  "household_id"
    t.string  "database_id"
    t.string  "program_name"
    t.integer "program_tracking_method"
    t.string  "record_type"
    t.integer "dc_id"
    t.integer "housing_status_at_entry"
    t.integer "housing_status_at_exit"
  end
  add_index "client_service_history", ["unduplicated_client_id"], :name=>"unduplicated_clients_unduplicated_client_id", :using=>:btree

  create_table "clients_unduplicated", force: :cascade do |t|
    t.string  "client_unique_id"
    t.integer "unduplicated_client_id"
    t.integer "dc_id"
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   :default=>0, :null=>false
    t.integer  "attempts",   :default=>0, :null=>false
    t.text     "handler",    :null=>false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "delayed_jobs", ["priority", "run_at"], :name=>"delayed_jobs_priority", :using=>:btree

  create_table "imports", force: :cascade do |t|
    t.string   "file"
    t.string   "source"
    t.float    "percent_complete"
    t.datetime "created_at",       :null=>false
    t.datetime "updated_at",       :null=>false
    t.datetime "completed_at"
    t.datetime "deleted_at"
    t.json     "unzipped_files"
    t.json     "import_errors"
  end
  add_index "imports", ["deleted_at"], :name=>"index_imports_on_deleted_at", :using=>:btree

  create_table "letsencrypt_plugin_challenges", force: :cascade do |t|
    t.text     "response"
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "letsencrypt_plugin_settings", force: :cascade do |t|
    t.text     "private_key"
    t.datetime "created_at",  :null=>false
    t.datetime "updated_at",  :null=>false
  end

  create_table "nicknames", force: :cascade do |t|
    t.string  "name"
    t.integer "nickname_id"
  end

  create_table "report_results", force: :cascade do |t|
    t.integer  "report_id"
    t.integer  "import_id"
    t.float    "percent_complete"
    t.json     "results"
    t.datetime "created_at",       :null=>false
    t.datetime "updated_at",       :null=>false
    t.datetime "deleted_at"
    t.datetime "completed_at"
    t.integer  "user_id"
    t.json     "original_results"
    t.json     "options"
    t.string   "job_status"
    t.json     "validations"
    t.json     "support"
  end
  add_index "report_results", ["deleted_at"], :name=>"index_report_results_on_deleted_at", :using=>:btree
  add_index "report_results", ["report_id"], :name=>"index_report_results_on_report_id", :using=>:btree

  create_table "report_results_summaries", force: :cascade do |t|
    t.string   "name",       :null=>false
    t.string   "type",       :null=>false
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
    t.integer  "weight",     :default=>0, :null=>false
  end

  create_table "reports", force: :cascade do |t|
    t.string   "name",                      :null=>false
    t.string   "type",                      :null=>false
    t.datetime "created_at",                :null=>false
    t.datetime "updated_at",                :null=>false
    t.integer  "weight",                    :default=>0, :null=>false
    t.integer  "report_results_summary_id"
  end
  add_index "reports", ["report_results_summary_id"], :name=>"index_reports_on_report_results_summary_id", :using=>:btree

  create_table "roles", force: :cascade do |t|
    t.string   "name",                             :null=>false
    t.string   "verb"
    t.datetime "created_at",                       :null=>false
    t.datetime "updated_at",                       :null=>false
    t.boolean  "can_view_clients",                 :default=>false
    t.boolean  "can_edit_clients",                 :default=>false
    t.boolean  "can_view_reports",                 :default=>false
    t.boolean  "can_edit_users",                   :default=>false
    t.boolean  "can_view_full_ssn",                :default=>false
    t.boolean  "can_view_full_dob",                :default=>false
    t.boolean  "can_view_imports",                 :default=>false
    t.boolean  "can_edit_roles",                   :default=>false
    t.boolean  "can_view_censuses",                :default=>false
    t.boolean  "can_view_census_details",          :default=>false
    t.boolean  "can_view_projects",                :default=>false
    t.boolean  "can_view_organizations",           :default=>false
    t.boolean  "can_view_client_window",           :default=>false
    t.boolean  "can_upload_hud_zips",              :default=>false
    t.boolean  "can_view_hiv_status",              :default=>false
    t.boolean  "can_view_dmh_status",              :default=>false
    t.boolean  "health_role",                      :default=>false, :null=>false
    t.boolean  "can_administer_health",            :default=>false
    t.boolean  "can_edit_client_health",           :default=>false
    t.boolean  "can_view_client_health",           :default=>false
    t.boolean  "can_edit_project_groups",          :default=>false
    t.boolean  "can_view_everything",              :default=>false
    t.boolean  "can_edit_anything_super_user",     :default=>false
    t.boolean  "can_edit_projects",                :default=>false
    t.boolean  "can_edit_organizations",           :default=>false
    t.boolean  "can_edit_data_sources",            :default=>false
    t.boolean  "can_manage_assessments",           :default=>false
    t.boolean  "can_edit_translations",            :default=>false
    t.boolean  "can_manage_config",                :default=>false
    t.boolean  "can_edit_dq_grades",               :default=>false
    t.boolean  "can_manage_client_files",          :default=>false
    t.boolean  "can_manage_window_client_files",   :default=>false
    t.boolean  "can_view_vspdat",                  :default=>false
    t.boolean  "can_edit_vspdat",                  :default=>false
    t.boolean  "can_create_clients",               :default=>false
    t.boolean  "can_view_client_history_calendar", :default=>false
    t.boolean  "can_view_aggregate_health",        :default=>false
  end
  add_index "roles", ["name"], :name=>"index_roles_on_name", :using=>:btree

  create_table "similarity_metrics", force: :cascade do |t|
    t.string   "type",               :null=>false
    t.float    "mean",               :default=>0.0, :null=>false
    t.float    "standard_deviation", :default=>0.0, :null=>false
    t.float    "weight",             :default=>1.0, :null=>false
    t.integer  "n",                  :default=>0, :null=>false
    t.hstore   "other_state",        :default=>{}, :null=>false
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "similarity_metrics", ["type"], :name=>"index_similarity_metrics_on_type", :unique=>true, :using=>:btree

  create_table "translation_keys", force: :cascade do |t|
    t.string   "key",        :default=>"", :null=>false
    t.datetime "created_at"
    t.datetime "updated_at"
  end
  add_index "translation_keys", ["key"], :name=>"index_translation_keys_on_key", :using=>:btree

  create_table "translation_texts", force: :cascade do |t|
    t.text     "text"
    t.string   "locale"
    t.integer  "translation_key_id", :null=>false
    t.datetime "created_at",         :null=>false
    t.datetime "updated_at",         :null=>false
  end
  add_index "translation_texts", ["translation_key_id"], :name=>"index_translation_texts_on_translation_key_id", :using=>:btree

  create_table "unique_names", force: :cascade do |t|
    t.string "name"
    t.string "double_metaphone"
  end

  create_table "uploads", force: :cascade do |t|
    t.integer  "data_source_id"
    t.string   "file",             :null=>false
    t.float    "percent_complete"
    t.string   "unzipped_path"
    t.json     "unzipped_files"
    t.json     "summary"
    t.json     "import_errors"
    t.datetime "created_at",       :null=>false
    t.datetime "updated_at",       :null=>false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "deleted_at"
    t.integer  "user_id"
  end
  add_index "uploads", ["deleted_at"], :name=>"index_uploads_on_deleted_at", :using=>:btree

  create_table "user_roles", force: :cascade do |t|
    t.integer  "role_id"
    t.integer  "user_id"
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end
  add_index "user_roles", ["role_id"], :name=>"index_user_roles_on_role_id", :using=>:btree
  add_index "user_roles", ["user_id"], :name=>"index_user_roles_on_user_id", :using=>:btree

  create_table "users", force: :cascade do |t|
    t.string   "last_name",              :null=>false
    t.string   "email",                  :null=>false
    t.string   "encrypted_password",     :default=>"", :null=>false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default=>0, :null=>false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.string   "invitation_token"
    t.datetime "invitation_created_at"
    t.integer  "failed_attempts",        :default=>0, :null=>false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at",             :null=>false
    t.datetime "updated_at",             :null=>false
    t.datetime "deleted_at"
    t.string   "first_name"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.integer  "invitations_count",      :default=>0
  end
  add_index "users", ["confirmation_token"], :name=>"index_users_on_confirmation_token", :unique=>true, :using=>:btree
  add_index "users", ["deleted_at"], :name=>"index_users_on_deleted_at", :using=>:btree
  add_index "users", ["email"], :name=>"index_users_on_email", :unique=>true, :using=>:btree
  add_index "users", ["invitation_token"], :name=>"index_users_on_invitation_token", :unique=>true, :using=>:btree
  add_index "users", ["invitations_count"], :name=>"index_users_on_invitations_count", :using=>:btree
  add_index "users", ["invited_by_id"], :name=>"index_users_on_invited_by_id", :using=>:btree
  add_index "users", ["reset_password_token"], :name=>"index_users_on_reset_password_token", :unique=>true, :using=>:btree
  add_index "users", ["unlock_token"], :name=>"index_users_on_unlock_token", :unique=>true, :using=>:btree

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

  add_foreign_key "report_results", "users"
  add_foreign_key "reports", "report_results_summaries"
  add_foreign_key "user_roles", "roles", on_delete: :cascade
  add_foreign_key "user_roles", "users", on_delete: :cascade
end
