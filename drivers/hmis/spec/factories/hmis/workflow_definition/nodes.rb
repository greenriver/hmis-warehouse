# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_workflow_definition_task, class: 'Hmis::WorkflowDefinition::Task' do
    sequence(:name) { |n| "Step #{n}" }
    form_definition { association :hmis_form_definition }
    trigger_config { [] }
  end

  factory :hmis_workflow_definition_start_event, class: 'Hmis::WorkflowDefinition::StartEvent' do
    sequence(:name) { |n| "Start Event #{n}" }
    trigger_config { [] }
  end

  factory :hmis_workflow_definition_end_event, class: 'Hmis::WorkflowDefinition::EndEvent' do
    sequence(:name) { |n| "End Event #{n}" }
    trigger_config do
      [
        {
          event: 'end_workflow',
          message: 'accept_referral',
        },
      ]
    end
  end

  factory :hmis_workflow_definition_gateway, class: 'Hmis::WorkflowDefinition::Gateway' do
    sequence(:name) { |n| "Gateway #{n}" }
    gateway_type { 'exclusive' }
    trigger_config { [] }
  end
end
