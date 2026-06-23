###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class EnhanceImporterLog < ActiveRecord::Migration[7.0]
  def change
    add_column :hmis_csv_importer_logs, :phase_metrics, :jsonb
  end
end
