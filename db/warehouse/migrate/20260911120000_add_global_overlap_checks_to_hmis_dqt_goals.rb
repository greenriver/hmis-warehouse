###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddGlobalOverlapChecksToHmisDqtGoals < ActiveRecord::Migration[7.2]
  def change
    add_column :hmis_dqt_goals, :global_overlap_checks, :boolean, default: false, null: false
  end
end
