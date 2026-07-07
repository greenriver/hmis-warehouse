###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddAutomationUpdatedAtToCohorts < ActiveRecord::Migration[7.1]
  def change
    add_column :cohorts, :automation_updated_at, :datetime
  end
end
