###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddCeEventTypeToUnitGroup < ActiveRecord::Migration[7.1]
  def change
    add_column :hmis_unit_groups, :ce_event_type, :integer, null: true
  end
end
