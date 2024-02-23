###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_external_api_ac_hmis_referral_household_member, class: 'HmisExternalApis::AcHmis::ReferralHouseholdMember' do
    client { association :hmis_hud_client }
    relationship_to_hoh { 1 }
    mci_id { Faker::IDNumber.valid }
    created_at { Time.current }
    updated_at { Time.current }
  end

  factory :hmis_external_api_ac_hmis_referral, class: 'HmisExternalApis::AcHmis::Referral' do
    sequence :identifier, Zlib.crc32('HmisExternalApis::AcHmis::Referral')
    service_coordinator { Faker::Name.name }
    referral_date { Date.current }
  end
end
