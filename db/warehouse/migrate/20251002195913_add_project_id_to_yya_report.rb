###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddProjectIdToYyaReport < ActiveRecord::Migration[7.1]
  def change
    add_reference :ma_yya_report_clients, :report, null: true, index: false
    add_reference :ma_yya_report_clients, :project, null: true, index: false
    add_reference :ma_yya_report_clients, :enrollment, null: true, index: false
  end
end
