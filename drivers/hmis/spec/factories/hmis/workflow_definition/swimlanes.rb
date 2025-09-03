# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_workflow_definition_swimlane, class: 'Hmis::WorkflowDefinition::Swimlane' do
    name { 'Default' }
    association :template, factory: :hmis_workflow_definition_template
  end
end
