class CreateThriveAssessments < ActiveRecord::Migration[6.1]
  def change
    create_table :thrive_assessments do |t|
      t.references :patient, null: false
      t.references :user, null: false

      t.boolean :decline_to_answer
      t.integer :housing_status
      t.integer :food_insecurity
      t.integer :food_worries
      t.boolean :trouble_drug_cost
      t.boolean :trouble_medical_transportation
      t.boolean :trouble_utility_cost
      t.boolean :trouble_caring_for_family
      t.boolean :unemployed
      t.boolean :interested_in_education

      t.boolean :help_with_housing
      t.boolean :help_with_food
      t.boolean :help_with_drug_cost
      t.boolean :help_with_medical_transportation
      t.boolean :help_with_utilities
      t.boolean :help_with_childcare
      t.boolean :help_with_eldercare
      t.boolean :help_with_job_search
      t.boolean :help_with_education

      t.date :completed_on

      t.timestamps
    end
  end
end
