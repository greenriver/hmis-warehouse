###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDetailColumnsToMaYyaReportClients < ActiveRecord::Migration[7.1]
  def change
    add_column :ma_yya_report_clients, :entry_current_living_situation_code, :integer
    add_column :ma_yya_report_clients, :previous_universe_entry_date, :date
    add_column :ma_yya_report_clients, :project_type_at_entry, :integer
    add_column :ma_yya_report_clients, :homelessness_basis, :string
    add_column :ma_yya_report_clients, :homeless_enrollment_project_type, :integer
    add_column :ma_yya_report_clients, :latest_homeless_cls_in_range_code, :integer
    add_column :ma_yya_report_clients, :latest_homeless_cls_code, :integer
    add_column :ma_yya_report_clients, :previous_universe_project_type, :integer
    add_column :ma_yya_report_clients, :homeless_enrollment_project_type_during_range, :integer
  end
end
