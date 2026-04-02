# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_workflow_definition_user_task, class: 'Hmis::WorkflowDefinition::UserTask' do
    sequence(:name) { |n| "Step #{n}" }
    trigger_config { [] }
    association(:template, factory: :hmis_workflow_definition_template)
    transient do
      data_source { association(:hmis_data_source) }
      form_definition { association(:hmis_form_definition, data_source: data_source) }
    end
    after(:build) do |task, evaluator|
      # If form_definition was passed in to the factory, use that to set the task's form_definition_identifier.
      # But if form_definition_identifier was explicitly passed in to the factory, don't overwrite it
      task.form_definition_identifier = evaluator.form_definition.identifier unless evaluator.form_definition_identifier.present?
    end
  end

  factory :hmis_workflow_definition_script_task, class: 'Hmis::WorkflowDefinition::ScriptTask' do
    sequence(:name) { |n| "Script Task #{n}" }
    trigger_config { [] }
    association(:template, factory: :hmis_workflow_definition_template)
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
          message: Hmis::Ce::ReferralMessageHandler::ACCEPT_REFERRAL_MESSAGE,
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
