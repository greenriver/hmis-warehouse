# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_workflow_definition_template, class: 'Hmis::WorkflowDefinition::Template' do
    sequence(:name) { |n| "Workflow #{n}" }
    sequence(:identifier) { |n| "workflow_#{n}" }
    association(:data_source, factory: :hmis_data_source)
    template_type { 'ce_referral' }
    version { 0 }
    status { 'published' }
  end
end
