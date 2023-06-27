###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_external_api_ac_hmis_referral_posting, class: 'HmisExternalApis::AcHmis::ReferralPosting' do
    sequence :identifier, Zlib.crc32('HmisExternalApis::AcHmis::ReferralPosting')
    association :project, factory: :hmis_hud_project
    association :referral, factory: :hmis_external_api_ac_hmis_referral
    association :unit_type, factory: :hmis_unit_type
    status { 'assigned_status' }
  end
end
