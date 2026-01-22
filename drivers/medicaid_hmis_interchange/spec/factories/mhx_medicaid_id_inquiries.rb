###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :mhx_medicaid_id_inquiry, class: 'MedicaidHmisInterchange::Health::MedicaidIdInquiry' do
    service_date { Date.current }
    created_at { Time.current }
    sequence(:isa_control_number, 100)
    sequence(:group_control_number, 1100)
    sequence(:transaction_control_number, 1100)
  end
end
