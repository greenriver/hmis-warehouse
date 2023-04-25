###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_external_api_referral, class: 'HmisExternalApis::Referral' do
    sequence :identifier, Zlib.crc32('HmisExternalApis::Referral')
    service_coordinator { Faker::Name.name }
    referral_date { Date.today }
  end
end
