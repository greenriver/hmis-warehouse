###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AddVariableNameToScoringRules < ActiveRecord::Migration[7.1]
  def change
    add_column :hmis_scoring_rules, :variable_name, :string, null: true
  end
end
