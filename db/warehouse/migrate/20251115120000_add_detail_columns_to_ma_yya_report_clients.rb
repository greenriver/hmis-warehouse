###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDetailColumnsToMaYyaReportClients < ActiveRecord::Migration[7.1]
  def change
    change_table :ma_yya_report_clients, bulk: true do |t|
      t.integer :entry_current_living_situation_code
      t.date :previous_universe_entry_date
      t.integer :project_type_at_entry
      t.string :homelessness_basis
      t.integer :homeless_enrollment_project_type
      t.integer :latest_homeless_cls_in_range_code
      t.integer :latest_homeless_cls_code
      t.integer :previous_universe_project_type
      t.integer :homeless_enrollment_project_type_during_range
    end
  end
end
