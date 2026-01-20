###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddArchivalMetadataToSimpleReportInstances < ActiveRecord::Migration[7.1]
  def change
    add_column :simple_report_instances, :archival_metadata, :jsonb
  end
end
