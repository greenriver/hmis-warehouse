class CreateCePerformanceTables < ActiveRecord::Migration[6.1]
  def change
    create_table :ce_performance_clients do |t|
      t.belongs_to :client
      t.belongs_to :report
      t.string :first_name
      t.string :last_name
      t.integer :reporting_age
      t.boolean :head_of_household
      t.integer :prior_living_situation
      t.integer :los_under_threshold
      t.integer :previous_street_essh
      t.integer :prevention_tool_score
      t.integer :assessment_score
      t.jsonb :events
      t.jsonb :assessments
      t.boolean :diversion_event
      t.boolean :diversion_successful
      t.boolean :veteran
      t.integer :household_size
      t.jsonb :household_ages
      t.boolean :chronically_homeless_at_entry
      t.date :entry_date
      t.date :exit_date
      t.date :initial_assessment_date
      t.date :latest_assessment_date
      t.date :initial_housing_referral_date
      t.date :housing_enrollment_entry_date
      t.date :housing_enrollment_move_in_date

      t.timestamps
    end
    create_table :ce_performance_results do |t|
      t.belongs_to :report
      t.string :field
      t.float :value
      t.string :format

      t.timestamps
    end
  end
end
