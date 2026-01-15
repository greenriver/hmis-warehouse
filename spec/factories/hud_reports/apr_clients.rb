###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hud_report_apr_client, class: 'HudApr::Fy2020::AprClient' do
    association :report_instance, factory: :hud_reports_report_instance
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    personal_id { SecureRandom.hex(8) }
    client_id { rand(1..100000) }
    destination_client_id { rand(1..100000) }
  end
end
