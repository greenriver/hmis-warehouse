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

    after(:create) do |referral, evaluator|
      if evaluator.project.present?
        referral.opportunity.project = evaluator.project
        # Update the workflow template data source to match, unless a workflow template has also been explicitly passed
        referral.opportunity.workflow_template.data_source = evaluator.project.data_source unless evaluator.workflow_template.present?
      end

      if evaluator.workflow_template.present?
        referral.opportunity.workflow_template = evaluator.workflow_template
        referral.workflow_instance.template = evaluator.workflow_template
        # Update the project data source to match, unless a project has also been explicitly passed
        referral.opportunity.project.data_source = evaluator.workflow_template.data_source unless evaluator.project.present?
      end

      referral.opportunity.save! if referral.opportunity.changed?
      referral.workflow_instance.save! if referral.workflow_instance.changed?
    end
  end
end
