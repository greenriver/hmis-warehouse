# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_custom_referral_status, class: 'Hmis::Ce::CustomReferralStatus' do
    name { 'Approved Pending' }
    key { 'approved_pending' }
    association(:data_source, factory: :hmis_data_source)
  end
end
