###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddStaffToEpicThrives < ActiveRecord::Migration[6.1]
  def change
    add_column :epic_thrives, :staff, :string
  end
end
