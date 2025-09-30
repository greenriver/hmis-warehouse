###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DaysToReturnOnYouthClient < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      remove_column :ma_yya_report_clients, :returned_within_2_years, :boolean, default: false
    end
    add_column :ma_yya_report_clients, :permanent_exit_date, :date
    add_column :ma_yya_report_clients, :days_to_return, :integer
  end
end
