###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateHmisScoringRules < ActiveRecord::Migration[7.0]
  def change
    create_table :hmis_scoring_algorithms do |t|
      t.string :name, null: false
      t.string :namespace, null: false

      t.timestamps null: false
    end

    add_index :hmis_scoring_algorithms, :name, unique: true

    create_table :hmis_scoring_rules do |t|
      t.string :link_id, null: false
      t.decimal :min_value, null: true, precision: 10, scale: 2
      t.decimal :max_value, null: true, precision: 10, scale: 2
      t.string :exact_value, null: true
      t.decimal :weight, null: false, precision: 14, scale: 12
      t.references :hmis_scoring_algorithm, null: false, foreign_key: true, index: { name: 'idx_scoring_rules_on_algo' }

      t.timestamps null: false
    end

    # Composite unique index to prevent duplicate rules for the same conditions
    add_index :hmis_scoring_rules, [:hmis_scoring_algorithm_id, :link_id, :min_value, :max_value, :exact_value], name: 'index_hmis_scoring_rules_unique', unique: true

    create_table :hmis_scoring_algorithm_thresholds do |t|
      t.references :hmis_scoring_algorithm, null: false, foreign_key: true, index: { name: 'idx_algo_thresholds_on_algo' }
      t.decimal :threshold, null: false, precision: 14, scale: 12
      t.integer :points, null: false

      t.timestamps null: false
    end

    add_index :hmis_scoring_algorithm_thresholds, [:hmis_scoring_algorithm_id, :points], name: 'index_hmis_scoring_algorithm_thresholds_unique', unique: true

    create_table :hmis_scoring_calculation_logs do |t|
      t.string :namespace, null: false
      t.string :client_identifier, null: true
      t.decimal :final_score, null: false, precision: 14, scale: 12
      t.json :calculation_details, null: false
      t.json :input_values, null: true

      t.timestamps null: false
    end
  end
end
