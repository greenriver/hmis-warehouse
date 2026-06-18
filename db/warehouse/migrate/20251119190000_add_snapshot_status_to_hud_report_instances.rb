###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddSnapshotStatusToHudReportInstances < ActiveRecord::Migration[7.1]
  def change
    add_column :hud_report_instances, :snapshot_status, :string
  end
end
