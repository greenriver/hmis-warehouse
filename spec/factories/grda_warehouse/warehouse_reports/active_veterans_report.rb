###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :active_veterans_report, class: 'GrdaWarehouse::WarehouseReports::ActiveVeteransReport' do
    parameters { {} }
    data { [] }
  end
end
