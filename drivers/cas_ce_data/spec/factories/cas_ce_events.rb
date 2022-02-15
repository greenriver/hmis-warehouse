###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :program_to_project, class: 'CasCeData::GrdaWarehouse::ProgramToProject' do
    program_id { 100 }
  end

  factory :cas_referral_event, class: 'CasCeData::GrdaWarehouse::CasReferralEvent' do
  end
end
