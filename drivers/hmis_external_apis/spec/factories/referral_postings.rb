###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_external_api_referral_posting, class: 'HmisExternalApis::ReferralPosting' do
    sequence :identifier, Zlib.crc32('HmisExternalApis::ReferralPosting')
    association :project, factory: :hmis_hud_project
    association :referral, factory: :hmis_external_api_referral
    status { 'assigned_status' }
  end
end
