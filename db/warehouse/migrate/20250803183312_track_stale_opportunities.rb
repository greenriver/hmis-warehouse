###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class TrackStaleOpportunities < ActiveRecord::Migration[7.1]
  def up
    safety_assured do
      add_column :ce_opportunities, :stale, :boolean, default: false, null: false
      add_column :ce_opportunities, :initial_rule_attrs, :json, null: false, default: []
    end
  end
end
