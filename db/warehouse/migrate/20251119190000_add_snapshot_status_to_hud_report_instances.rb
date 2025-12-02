###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddSnapshotStatusToHudReportInstances < ActiveRecord::Migration[7.1]
  def change
    add_column :hud_report_instances, :snapshot_status, :string
  end
end
