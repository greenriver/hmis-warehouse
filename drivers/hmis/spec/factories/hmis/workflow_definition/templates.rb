FactoryBot.define do
  factory :hmis_workflow_definition_template, class: 'Hmis::WorkflowDefinition::Template' do
    sequence(:name) { |n| "Workflow #{n}" }
    sequence(:identifier) { |n| "workflow_#{n}" }
    version { 0 }
  end
end
