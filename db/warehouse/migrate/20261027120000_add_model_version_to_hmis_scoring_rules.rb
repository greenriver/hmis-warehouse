###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddModelVersionToHmisScoringRules < ActiveRecord::Migration[7.2]
  def up
    # No default: every writer must say which model version it is loading.
    add_column :hmis_scoring_rules, :model_version, :integer
    safety_assured do
      execute 'UPDATE hmis_scoring_rules SET model_version = 1'
      change_column_null :hmis_scoring_rules, :model_version, false
    end

    # Optional second criterion; when present, the rule contributes only when both criteria match.
    add_column :hmis_scoring_rules, :secondary_link_id, :string
    add_column :hmis_scoring_rules, :secondary_criteria_type, :string
    add_column :hmis_scoring_rules, :secondary_criteria_config, :jsonb

    # Allow more decimal places. Some weights in the new scoring model are so small that the old
    # column rounded them to zero, which changes the score even though the weights look negligible.
    safety_assured { change_column :hmis_scoring_rules, :weight, :decimal, precision: 30, scale: 24, null: false }
  end

  def down
    # Without model_version, the v1 calculator would load newer-version rules as its own.
    if select_value('SELECT 1 FROM hmis_scoring_rules WHERE model_version <> 1 LIMIT 1')
      raise ActiveRecord::IrreversibleMigration, 'hmis_scoring_rules has rows for model versions other than 1. Delete them before rolling back.'
    end

    safety_assured { change_column :hmis_scoring_rules, :weight, :decimal, precision: 14, scale: 12, null: false }
    remove_column :hmis_scoring_rules, :secondary_criteria_config
    remove_column :hmis_scoring_rules, :secondary_criteria_type
    remove_column :hmis_scoring_rules, :secondary_link_id
    remove_column :hmis_scoring_rules, :model_version
  end
end

# rails db:migrate:up:warehouse VERSION=20261027120000
# rails db:migrate:down:warehouse VERSION=20261027120000
