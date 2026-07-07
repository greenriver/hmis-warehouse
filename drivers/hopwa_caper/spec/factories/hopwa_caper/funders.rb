###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hopwa_caper_funder, class: 'HopwaCaper::Funder' do
    association :report, factory: :hud_reports_report_instance
    association :project, factory: :hud_project
    sequence(:code) { |n| n }
    sequence(:funder_id) { |n| n }
  end
end
