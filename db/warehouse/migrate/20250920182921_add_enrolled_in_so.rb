###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddEnrolledInSo < ActiveRecord::Migration[7.1]
  def change
    add_column :ma_yya_report_clients, :enrolled_in_street_outreach, :boolean, null: false, default: false
    add_column :ma_yya_report_clients, :earliest_homeless_cls_in_range, :date
    add_column :ma_yya_report_clients, :latest_homeless_cls_in_range, :date
    add_column :ma_yya_report_clients, :earliest_non_homeless_cls_in_range, :date
    add_column :ma_yya_report_clients, :latest_non_homeless_cls_in_range, :date
    add_column :ma_yya_report_clients, :homeless_enrollment_started_during_range, :boolean, null: false, default: false
    add_column :ma_yya_report_clients, :homeless_enrollment_started_prior_to_range, :boolean, null: false, default: false
    add_column :ma_yya_report_clients, :new_intake_in_range, :boolean, null: false, default: false
    add_column :ma_yya_report_clients, :continuing_in_case_management, :boolean, null: false, default: false
    add_column :ma_yya_report_clients, :first_prevention_date, :date
    add_column :ma_yya_report_clients, :latest_homeless_entry_date, :date
  end
end
