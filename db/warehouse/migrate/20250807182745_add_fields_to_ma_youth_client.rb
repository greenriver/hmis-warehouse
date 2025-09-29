###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddFieldsToMaYouthClient < ActiveRecord::Migration[7.1]
  def change
    [
      :employed,
      :former_foster_ward,
      :former_juvenile_justice_ward,
      :voluntary_dcf_service,
      :voluntary_dys_yes_service,
      :exchange_for_sex,
      :returned_within_2_years,
    ].each do |column|
      add_column :ma_yya_report_clients, column, :boolean, default: false
    end
  end
end
