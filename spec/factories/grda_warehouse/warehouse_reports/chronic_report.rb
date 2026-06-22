###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :chronic_report, class: 'GrdaWarehouse::WarehouseReports::ChronicReport' do
    parameters { {} }
    data { [] }
  end
end
