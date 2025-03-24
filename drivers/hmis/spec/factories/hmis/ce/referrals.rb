# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_referral, class: 'Hmis::Ce::Referral' do
    transient do
      project { nil }
    end
    opportunity { build(:hmis_ce_opportunity, project: project) }
    association(:workflow_instance, factory: :hmis_workflow_execution_instance)
    association(:client, factory: :hmis_hud_client)
    association(:referred_by, factory: :hmis_user)
  end
end
