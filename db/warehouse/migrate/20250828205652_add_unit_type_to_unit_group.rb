###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddUnitTypeToUnitGroup < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      add_reference :hmis_unit_groups, :unit_type, null: true, foreign_key: { to_table: :hmis_unit_types }
    end
  end
end
