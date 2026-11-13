###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hud_chronic_report, class: 'GrdaWarehouse::WarehouseReports::HudChronicReport' do
    parameters { { 'filter' => { 'on' => Date.current.to_s } } }
    data { [] }
  end
end
