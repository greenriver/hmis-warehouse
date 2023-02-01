class CreateMaMonthlyPerformanceClients < ActiveRecord::Migration[6.1]
  def change
    create_table :ma_monthly_performance_enrollments do |t|
      t.references :report
      t.references :client
      t.references :enrollment
      t.references :project
      t.references :project_coc
      t.string :personal_id
      t.string :city
      t.string :coc_code
      t.date :entry_date, null: false
      t.date :exit_date
      t.boolean :latest_for_client
      t.boolean :chronically_homeless_at_entry
      t.integer :stay_length_in_days
      t.boolean :am_ind_ak_native
      t.boolean :asian
      t.boolean :black_af_american
      t.boolean :native_hi_pacific
      t.boolean :ethnicity # nil is unknown
      t.boolean :white
      t.boolean :male
      t.boolean :female
      t.boolean :gender_other
      t.boolean :transgender
      t.boolean :questioning
      t.boolean :no_single_gender
      t.boolean :disabling_condition
      t.integer :reporting_age
      t.integer :relationship_to_hoh
      t.string :household_id
      t.string :household_type
      t.jsonb :household_members
      t.integer :prior_living_situation
      t.integer :months_homeless_past_three_years
      t.integer :times_homeless_past_three_years
      t.timestamps
      t.datetime :deleted_at
    end
    create_table :ma_monthly_performance_projects do |t|
      t.references :report
      t.references :project
      t.references :project_coc
      t.string :project_name
      t.string :organization_name
      t.string :coc_code
      t.date :month_start
      t.integer :available_beds
      t.integer :average_length_of_stay_in_days
      t.integer :number_chronically_homeless_at_entry
      t.string :city
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
