# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_workflow_definition_template, class: 'Hmis::WorkflowDefinition::Template' do
    sequence(:name) { |n| "Workflow #{n}" }
    sequence(:identifier) { |n| "workflow_#{n}" }
    template_type { 'ce_referral' }
    version { 0 }
    status { 'published' }
  end
end
