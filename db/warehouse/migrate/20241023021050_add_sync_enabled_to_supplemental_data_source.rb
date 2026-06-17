###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddSyncEnabledToSupplementalDataSource < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_column :hmis_supplemental_data_sets, :sync_enabled, :boolean, default: false
    end
  end
end
