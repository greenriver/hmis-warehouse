###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'faker'
FactoryBot.define do
  factory :hmis_external_api_referral_request, class: 'HmisExternalApis::ReferralRequest' do
    identifier { SecureRandom.uuid }
    association :project, factory: :hmis_hud_project
    association :unit_type, factory: :hmis_unit_type
    requested_on { Date.today }
    needed_by { Date.today + 1.week }
    # FIXME - this doesn't work due to data source issue
    # association :requested_by, factory: :hmis_user
    requestor_name { Faker::Name.name }
    requestor_phone { Faker::PhoneNumber.phone_number }
    requestor_email { Faker::Internet.email }
  end
end
