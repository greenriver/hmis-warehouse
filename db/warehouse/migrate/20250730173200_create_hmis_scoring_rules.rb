###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateHmisScoringRules < ActiveRecord::Migration[7.0]
  def change
    create_table :hmis_scoring_rules do |t|
      t.string :link_id, null: false
      t.string :min_value, null: true
      t.string :max_value, null: true
      t.string :exact_value, null: true
      # precision 14, scale 12 = 14 total digits with 12 after decimal point (e.g., 99.123456789012)
      t.decimal :weight, null: false, precision: 14, scale: 12
      t.string :algorithm, null: false

      t.timestamps null: false
    end

    # Prevent duplicate rules for the same conditions
    add_index :hmis_scoring_rules, [:algorithm, :link_id, :min_value, :max_value, :exact_value], name: 'index_hmis_scoring_rules_unique', unique: true

    create_table :hmis_scoring_calculation_logs do |t|
      t.string :namespace, null: false
      t.decimal :final_score, null: false, precision: 14, scale: 12
      t.json :calculation_details, null: false
      # Don't store input values since they are sensitive. They are stored as CDEs when assessment is submitted
      t.references :custom_assessment

      # This refers to the users table in the app db (not warehouse), so fk relationship is not made explicitly here
      t.references :user, null: false, index: false
      t.timestamps null: false
    end
  end
end
