###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class TrackStaleOpportunities < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      add_column :ce_opportunities, :stale, :boolean, default: false, null: false
      add_column :ce_opportunities, :assignment_rules, :json, null: false, default: []
    end
  end
end
