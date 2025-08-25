###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddCePoolToUnitGroups < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      add_reference :hmis_unit_groups, :candidate_pool, foreign_key: { to_table: :ce_match_candidate_pools }
    end
  end
end
