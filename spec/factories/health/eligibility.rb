###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :eligibility_inquiry, class: 'Health::EligibilityInquiry' do
    service_date { Date.current }
  end

  factory :eligibility_response, class: 'Health::EligibilityResponse'
end
