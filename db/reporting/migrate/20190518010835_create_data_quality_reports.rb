class CreateDataQualityReports < ActiveRecord::Migration
  def change
    create_table :warehouse_data_quality_report_enrollments do |t|
      t.integer :report_id
      t.integer :client_id
      t.integer :project_id
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
      t.boolean :service_witin_last_30_days
      t.boolean :service_after_exit
      t.integer :days_of_service

      t.integer :destination_id

      t.boolean :name_present
      t.boolean :name_missing
      t.boolean :name_refused

      t.boolean :ssn_present
      t.boolean :ssn_missing
      t.boolean :ssn_refused

      t.boolean :dob_present
      t.boolean :dob_missing
      t.boolean :dob_refused

      t.boolean :veteran_present
      t.boolean :veteran_missing
      t.boolean :veteran_refused

      t.boolean :ethnicity_present
      t.boolean :ethnicity_missing
      t.boolean :ethnicity_refused

      t.boolean :race_present
      t.boolean :race_missing
      t.boolean :race_refused

      t.boolean :disabling_condition_present
      t.boolean :disabling_condition_missing
      t.boolean :disabling_condition_refused

      t.boolean :prior_living_situation_present
      t.boolean :prior_living_situation_missing
      t.boolean :prior_living_situation_refused

      t.boolean :income_at_entry_present
      t.boolean :income_at_entry_missing
      t.boolean :income_at_entry_refused

      t.boolean :income_at_exit_present
      t.boolean :income_at_exit_missing
      t.boolean :income_at_exit_refused

      t.boolean :exit_interview_completed

      t.boolean :include_in_income_change_calculation
      t.integer :income_at_entry
      t.integer :income_at_later_date

      t.integer :name_data_quality
      t.integer :ssn_data_quality
      t.integer :dob_data_quality
      t.integer :disability_type
      t.integer :disability_response

    end
  end
end
