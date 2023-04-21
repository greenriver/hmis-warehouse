###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_external_api_referral, class: 'HmisExternalApis::Referral' do
    service_coordinator { Faker::Name.name }
    identifier { SecureRandom.uuid }
    referral_date { Date.today }
  end
end
