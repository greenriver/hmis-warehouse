# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_ce_referral, class: 'Hmis::Ce::Referral' do
    transient do
      project { nil }
      workflow_template { nil }
    end
    association(:opportunity, factory: :hmis_ce_opportunity)
    association(:workflow_instance, factory: :hmis_workflow_execution_instance)
    association(:client, factory: :hmis_hud_client)
    association(:referred_by, factory: :hmis_user)
    after(:create) do |instance, evaluator|
      instance.opportunity.project = evaluator.project if evaluator.project.present?

      if evaluator.workflow_template.present?
        instance.opportunity.workflow_template = evaluator.workflow_template
        instance.workflow_instance.template = evaluator.workflow_template
      end

      instance.opportunity.save! if instance.opportunity.changed?
      instance.workflow_instance.save! if instance.workflow_instance.changed?
    end
  end
end
