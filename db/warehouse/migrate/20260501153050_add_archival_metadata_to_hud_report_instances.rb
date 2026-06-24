###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddArchivalMetadataToHudReportInstances < ActiveRecord::Migration[7.2]
  def change
    add_column :hud_report_instances, :archival_metadata, :jsonb
  end
end
