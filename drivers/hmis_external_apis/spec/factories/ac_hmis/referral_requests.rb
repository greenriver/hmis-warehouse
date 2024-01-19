###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'
FactoryBot.define do
  factory :hmis_external_api_ac_hmis_referral_request, class: 'HmisExternalApis::AcHmis::ReferralRequest' do
    sequence :identifier, Zlib.crc32('HmisExternalApis::AcHmis::ReferralRequest')
    association :project, factory: :hmis_hud_project
    association :unit_type, factory: :hmis_unit_type
    requested_on { Date.current }
    needed_by { Date.current + 1.week }
    association :requested_by, factory: :hmis_user
    requestor_name { Faker::Name.name }
    requestor_phone { Faker::PhoneNumber.phone_number }
    requestor_email { Faker::Internet.email }
  end
end
