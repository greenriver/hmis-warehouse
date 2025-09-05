###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddRawIncomeToAprClients < ActiveRecord::Migration[7.1]
  def change
    add_column :hud_report_apr_clients, :income_from_any_source_at_annual_assessment_raw, :integer
    add_column :hud_report_apr_clients, :income_from_any_source_at_exit_raw, :integer
    add_column :hud_report_apr_clients, :income_from_any_source_at_start_raw, :integer
  end
end
