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
      t.string :form_definition_identifier, null: false
      t.string :algorithm, null: false
      # The type of scoring criteria - determines how to evaluate the response value
      t.string :criteria_type, null: false # 'range', 'exact_match', 'value', 'include'

      # JSON field containing the criteria configuration
      # Examples:
      # Range: {"gte": 1000, "lt": 2000}. Multiply weight by 1 when response is in range
      #        {"gt": 0} for "greater than 0"
      #        {"lte": 100} for "less than or equal to 100"
      # Exact match: {"match_value": "Yes"}. Multiply weight by 1 when response is exact match
      # Include: {"include": "option_3"}. Multiply weight by 1 when response array includes this value
      # Value: {}. Multiply weight by the response value
      t.json :criteria_config, null: false, default: {}

      # The weight to multiply by when criteria are met
      t.decimal :weight, null: false, precision: 14, scale: 12

      t.timestamps null: false
    end

    create_table :hmis_scoring_calculation_logs do |t|
      t.string :namespace, null: false
      t.decimal :final_score, null: false, precision: 14, scale: 12
      # calculation values stores a json blob of intermediate values in the calculation: for example raw scores and weighted scores.
      # Don't store input values since they are sensitive. They are stored as CDEs when assessment is submitted
      t.json :calculation_details, null: false

      # Owner can be a custom assessment (if the assessment is already saved) or enrollment (if this is a calculation happening on a new assessment)
      t.references :owner, null: false, polymorphic: true

      # This refers to the users table in the app db (not warehouse), so fk relationship is not made explicitly here
      t.references :user, null: false, index: false
      t.timestamps null: false
    end
  end
end
