###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :ce_referral_decline_reason, class: 'Hmis::Ce::ReferralDeclineReason' do
    association :data_source, factory: :hmis_data_source
    sequence(:key) { |n| "decline_reason_#{n}" }
    sequence(:name) { |n| "Decline Reason #{n}" }
  end
end
