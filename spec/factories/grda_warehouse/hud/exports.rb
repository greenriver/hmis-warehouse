###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https: //github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hud_export, class: 'GrdaWarehouse::Hud::Export' do
    ExportID { 'TEST' }
    SourceType { 'Test Export' }
    ExportDate { Date.new(2021, 6, 1).to_time }
    ExportStartDate { Date.new(2020, 6, 1) }
    ExportEndDate { Date.new(2021, 6, 1) }
    CSVVersion { '2022' }
    ExportPeriodType { 3 }
    ExportDirective { 3 }
    HashStatus { 1 }
  end
end
