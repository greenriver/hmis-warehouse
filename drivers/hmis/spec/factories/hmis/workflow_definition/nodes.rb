# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_workflow_definition_task, class: 'Hmis::WorkflowDefinition::Task' do
    sequence(:name) { |n| "Step #{n}" }
    trigger_config { [] }
    association(:template, factory: :hmis_workflow_definition_template)
    transient do
      form_definition { association(:hmis_form_definition) }
    end
    after(:build) do |task, evaluator|
      task.form_definition_identifier = evaluator.form_definition.identifier
    end
  end

  factory :hmis_workflow_definition_start_event, class: 'Hmis::WorkflowDefinition::StartEvent' do
    sequence(:name) { |n| "Start Event #{n}" }
    trigger_config { [] }
    association(:template, factory: :hmis_workflow_definition_template)
  end

  factory :hmis_workflow_definition_end_event, class: 'Hmis::WorkflowDefinition::EndEvent' do
    sequence(:name) { |n| "End Event #{n}" }
    trigger_config do
      [
        {
          event: 'end_workflow',
          message: Hmis::WorkflowExecution::Engine::ACCEPT_REFERRAL,
        },
      ]
    end
    association(:template, factory: :hmis_workflow_definition_template)
  end

  factory :hmis_workflow_definition_gateway, class: 'Hmis::WorkflowDefinition::Gateway' do
    sequence(:name) { |n| "Gateway #{n}" }
    gateway_type { 'exclusive' }
    trigger_config { [] }
    association(:template, factory: :hmis_workflow_definition_template)
  end
end
