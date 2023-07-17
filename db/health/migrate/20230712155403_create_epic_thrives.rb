class CreateEpicThrives < ActiveRecord::Migration[6.1]
  def change
    create_table :epic_thrives do |t|
      t.string :patient_id
      t.string :id_in_source
      t.datetime :thrive_updated_at
      t.string :housing_status
      t.string :food_insecurity
      t.string :food_worries
      t.string :trouble_drug_cost
      t.string :trouble_medical_transportation
      t.string :trouble_utility_cost
      t.string :trouble_caring_for_family
      t.string :trouble_with_adl
      t.string :unemployed
      t.string :interested_in_education
      t.string :assistance
      t.bigint :data_source_id

      t.timestamps
    end

    safety_assured do
      change_table :thrive_assessments do |t|
        t.string :epic_source_id
        t.integer :reporter
        t.boolean :trouble_with_adl
        t.boolean :help_with_adl
      end
    end
  end
end
