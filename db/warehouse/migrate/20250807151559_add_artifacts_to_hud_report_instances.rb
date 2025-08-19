# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AddArtifactsToHudReportInstances < ActiveRecord::Migration[7.0]
  def change
    # Note: ActiveStorage handles the actual attachment storage
    # This migration is for documentation and any additional columns if needed

    # Add a flag to track if artifacts have been stored
    add_column :hud_report_instances, :artifacts_stored_at, :datetime

    # Add an index for efficient querying of reports with stored artifacts
    safety_assured do
      add_index :hud_report_instances, :artifacts_stored_at
    end
  end
end
