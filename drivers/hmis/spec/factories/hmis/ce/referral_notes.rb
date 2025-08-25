# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_referral_note, class: 'Hmis::Ce::ReferralNote' do
    referral { association :hmis_ce_referral }
    user { association :hmis_user, data_source: referral.data_source }
    note { 'Test note' }
  end
end
