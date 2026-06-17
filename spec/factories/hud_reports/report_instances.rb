###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hud_reports_report_instance, class: 'HudReports::ReportInstance' do
    sequence(:question_names) { [] }
  end
end
