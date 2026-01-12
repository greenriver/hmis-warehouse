###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :ce_referral_decline_reason, class: 'Hmis::Ce::ReferralDeclineReason' do
    association :data_source, factory: :data_source
    sequence(:key) { |n| "decline_reason_#{n}" }
    sequence(:name) { |n| "Decline Reason #{n}" }
  end
end
