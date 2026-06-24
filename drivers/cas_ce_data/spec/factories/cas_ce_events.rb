###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :program_to_project, class: 'CasCeData::GrdaWarehouse::ProgramToProject' do
    program_id { 100 }
  end

  factory :cas_referral_event, class: 'CasCeData::GrdaWarehouse::CasReferralEvent' do
  end
end
