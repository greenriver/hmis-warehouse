class CreateDataQualityReports < ActiveRecord::Migration
  def change
    create_table :warehouse_data_quality_report_enrollments do |t|
      t.integer :report_id
      t.integer :client_id
      t.integer :project_id
      t.integer :project_type
      t.integer :enrollment_id
      t.boolean :enrolled
      t.boolean :active
      t.boolean :entered
      t.boolean :exited
      t.boolean :adult
      t.boolean :head_of_household
      t.string :household_id
      t.string :household_type

      t.integer :age
      t.date :dob
      t.date :entry_date
      t.date :exit_date

      t.integer :days_to_add_entry_date
      t.integer :days_to_add_exit_date

      t.boolean :dob_after_entry_date

      t.date :most_recent_service_within_range
      t.boolean :service_within_last_30_days
      t.boolean :service_after_exit
      t.integer :days_of_service

      t.integer :destination_id

      t.boolean :name_complete, default: false
      t.boolean :name_missing, default: false
      t.boolean :name_refused, default: false
      t.boolean :name_not_collected, default: false
      t.boolean :name_partial, default: false

      t.boolean :ssn_complete, default: false
      t.boolean :ssn_missing, default: false
      t.boolean :ssn_refused, default: false
      t.boolean :ssn_not_collected, default: false
      t.boolean :ssn_partial, default: false

      t.boolean :gender_complete, default: false
      t.boolean :gender_missing, default: false
      t.boolean :gender_refused, default: false
      t.boolean :gender_not_collected, default: false
      t.boolean :gender_partial, default: false

      t.boolean :dob_complete, default: false
      t.boolean :dob_missing, default: false
      t.boolean :dob_refused, default: false
      t.boolean :dob_not_collected, default: false
      t.boolean :dob_partial, default: false

      t.boolean :veteran_complete, default: false
      t.boolean :veteran_missing, default: false
      t.boolean :veteran_refused, default: false
      t.boolean :veteran_not_collected, default: false
      t.boolean :veteran_partial, default: false

      t.boolean :ethnicity_complete, default: false
      t.boolean :ethnicity_missing, default: false
      t.boolean :ethnicity_refused, default: false
      t.boolean :ethnicity_not_collected, default: false
      t.boolean :ethnicity_partial, default: false

      t.boolean :race_complete, default: false
      t.boolean :race_missing, default: false
      t.boolean :race_refused, default: false
      t.boolean :race_not_collected, default: false
      t.boolean :race_partial, default: false

      t.boolean :disabling_condition_complete, default: false
      t.boolean :disabling_condition_missing, default: false
      t.boolean :disabling_condition_refused, default: false
      t.boolean :disabling_condition_not_collected, default: false
      t.boolean :disabling_condition_partial, default: false

      t.boolean :destination_complete, default: false
      t.boolean :destination_missing, default: false
      t.boolean :destination_refused, default: false
      t.boolean :destination_not_collected, default: false
      t.boolean :destination_partial, default: false

      t.boolean :prior_living_situation_complete, default: false
      t.boolean :prior_living_situation_missing, default: false
      t.boolean :prior_living_situation_refused, default: false
      t.boolean :prior_living_situation_not_collected, default: false
      t.boolean :prior_living_situation_partial, default: false

      t.boolean :income_at_entry_complete, default: false
      t.boolean :income_at_entry_missing, default: false
      t.boolean :income_at_entry_refused, default: false
      t.boolean :income_at_entry_not_collected, default: false
      t.boolean :income_at_entry_partial, default: false

      t.boolean :income_at_exit_complete, default: false
      t.boolean :income_at_exit_missing, default: false
      t.boolean :income_at_exit_refused, default: false
      t.boolean :income_at_exit_not_collected, default: false
      t.boolean :income_at_exit_partial, default: false

      t.boolean :include_in_income_change_calculation
      t.integer :income_at_entry_earned
      t.integer :income_at_entry_non_cash
      t.integer :income_at_entry_overall
      t.integer :income_at_later_date_earned
      t.integer :income_at_later_date_non_cash
      t.integer :income_at_later_date_overall

      t.integer :name_data_quality
      t.integer :ssn_data_quality
      t.integer :dob_data_quality

      t.integer :days_to_move_in_date

      t.datetime :calculated_at, null: false

    end

    create_table :warehouse_data_quality_report_projects do |t|
      t.integer :report_id
      t.integer :project_id
      t.integer :project_type
      t.date :operating_start_date
      t.string :coc_code
      t.string :funder
      t.string :inventory_information_dates
      t.string :geocode
      t.string :geography_type
      t.integer :unit_inventory
      t.integer :bed_inventory
      t.integer :housing_type

      t.integer :average_nightly_clients
      t.integer :average_nightly_households

      t.integer :average_bed_utilization
      t.integer :average_unit_utilization

      t.jsonb :nightly_client_census
      t.jsonb :nightly_household_census

      t.datetime :calculated_at, null: false
    end

    create_table :warehouse_data_quality_report_project_groups do |t|
      t.integer :report_id

      t.integer :unit_inventory
      t.integer :bed_inventory

      t.integer :average_nightly_clients
      t.integer :average_nightly_households

      t.integer :average_bed_utilization
      t.integer :average_unit_utilization

      t.jsonb :nightly_client_census
      t.jsonb :nightly_household_census

      t.datetime :calculated_at, null: false
    end
  end
end
