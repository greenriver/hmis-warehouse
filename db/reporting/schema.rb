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

ActiveRecord::Schema.define(version: 20180925175825) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "warehouse_houseds", force: :cascade do |t|
    t.date    "search_start"
    t.date    "search_end"
    t.date    "housed_date"
    t.date    "housing_exit"
    t.integer "project_type"
    t.integer "destination"
    t.string  "service_project"
    t.string  "residential_project"
    t.integer "client_id",           null: false
    t.string  "source"
    t.date    "dob"
    t.string  "race"
    t.integer "ethnicity"
    t.integer "gender"
    t.integer "veteran_status"
    t.date    "month_year"
    t.string  "ph_destination"
    t.integer "project_id"
  end

  add_index "warehouse_houseds", ["client_id"], name: "index_warehouse_houseds_on_client_id", using: :btree
  add_index "warehouse_houseds", ["housed_date"], name: "index_warehouse_houseds_on_housed_date", using: :btree
  add_index "warehouse_houseds", ["housing_exit"], name: "index_warehouse_houseds_on_housing_exit", using: :btree
  add_index "warehouse_houseds", ["search_end"], name: "index_warehouse_houseds_on_search_end", using: :btree
  add_index "warehouse_houseds", ["search_start"], name: "index_warehouse_houseds_on_search_start", using: :btree

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
  end

  add_index "warehouse_returns", ["client_id"], name: "index_warehouse_returns_on_client_id", using: :btree
  add_index "warehouse_returns", ["first_date_in_program"], name: "index_warehouse_returns_on_first_date_in_program", using: :btree
  add_index "warehouse_returns", ["project_type"], name: "index_warehouse_returns_on_project_type", using: :btree
  add_index "warehouse_returns", ["record_type"], name: "index_warehouse_returns_on_record_type", using: :btree
  add_index "warehouse_returns", ["service_history_enrollment_id"], name: "index_warehouse_returns_on_service_history_enrollment_id", using: :btree
  add_index "warehouse_returns", ["service_type"], name: "index_warehouse_returns_on_service_type", using: :btree

end
