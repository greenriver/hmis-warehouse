###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_external_api_ac_hmis_referral_posting, class: 'HmisExternalApis::AcHmis::ReferralPosting' do
    sequence :identifier, Zlib.crc32('HmisExternalApis::AcHmis::ReferralPosting')
    data_source { association :hmis_data_source }
    project { association :hmis_hud_project, data_source: data_source }
    association :referral, factory: :hmis_external_api_ac_hmis_referral
    association :unit_type, factory: :hmis_unit_type
    status { 'assigned_status' }
  end
end
