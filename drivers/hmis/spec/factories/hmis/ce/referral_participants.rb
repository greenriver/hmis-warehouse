# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_referral_participant, class: 'Hmis::Ce::ReferralParticipant' do
    referral { association :hmis_ce_referral }
    user { association :hmis_user, data_source: referral.data_source }
    swimlane { association :hmis_workflow_definition_swimlane, template: referral.workflow_template }
  end
end
