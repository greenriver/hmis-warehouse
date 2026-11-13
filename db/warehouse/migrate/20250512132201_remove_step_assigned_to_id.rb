###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RemoveStepAssignedToId < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      # This column was added during the spike, but ended up not being used, in favor of the separate step_assignment table
      # Safety assured because the column was never used in production
      remove_reference :wfe_steps, :assigned_to
    end
  end
end
