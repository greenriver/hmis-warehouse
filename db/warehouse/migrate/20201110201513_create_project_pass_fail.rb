class CreateProjectPassFail < ActiveRecord::Migration[5.2]
  def change
    create_table :project_pass_fails do |t|
      t.references :user, index: true
      t.jsonb :options, default: {}
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.text :processing_errors
      t.float :utilization_rate
      t.integer :projects_failing_universal_data_elements
      t.float :average_days_to_enter_entry_date
      t.timestamps index: true, null: false
      t.datetime :deleted_at, index: true
    end

    create_table :project_pass_fails_projects do |t|
      t.references :project_pass_fail, index: true, foreign_key: { on_delete: :cascade }
      t.references :project, index: true
      t.references :apr
      t.float :available_beds
      t.float :utilization_rate
      t.float :name_error_rate
      t.float :ssn_error_rate
      t.float :race_error_rate
      t.float :ethnicity_error_rate
      t.float :gender_error_rate
      t.float :dob_error_rate
      t.float :veteran_status_error_rate
      t.float :start_date_error_rate
      t.float :relationship_to_hoh_error_rate
      t.float :location_error_rate
      t.float :disabling_condition_error_rate
      t.float :utilization_count
      t.float :name_error_count
      t.float :ssn_error_count
      t.float :race_error_count
      t.float :ethnicity_error_count
      t.float :gender_error_count
      t.float :dob_error_count
      t.float :veteran_status_error_count
      t.float :start_date_error_count
      t.float :relationship_to_hoh_error_count
      t.float :location_error_count
      t.float :disabling_condition_error_count
      t.float :average_days_to_enter_entry_date
      t.timestamps index: true, null: false
      t.datetime :deleted_at, index: true
    end

    create_table :project_pass_fails_clients do |t|
      t.references :project_pass_fail, index: true, foreign_key: { on_delete: :cascade }
      t.references :project, index: { name: :ppfc_ppfp_idx }
      t.references :client
      t.string :first_name
      t.string :last_name
      t.date :first_date_in_program
      t.date :last_date_in_program
      t.integer :disabling_condition
      t.integer :dob_quality
      t.date :dob
      t.integer :ethnicity
      t.integer :gender
      t.integer :name_quality
      t.integer :race
      t.integer :ssn_quality
      t.string :ssn
      t.integer :veteran_status
      t.integer :relationship_to_hoh
      t.date :enrollment_created
      t.string :enrollment_coc
      t.integer :days_to_enter_entry_date
      t.integer :days_served
      t.timestamps index: true, null: false
      t.datetime :deleted_at, index: true
    end
  end
end
