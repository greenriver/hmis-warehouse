# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_workflow_definition_template, class: 'Hmis::WorkflowDefinition::Template' do
    sequence(:name) { |n| "Workflow #{n}" }
    sequence(:identifier) { |n| "workflow_#{n}" }
    association(:data_source, factory: :hmis_data_source)
    template_type { 'ce_referral' }
    version { 0 }
    status { 'published' }

    trait :with_basic_tasks do
      after(:create) do |template|
        # Create a basic workflow: Start -> User Task -> End
        start_event = create(
          :hmis_workflow_definition_start_event,
          template: template,
          name: 'Start',
        )

        user_task = create(
          :hmis_workflow_definition_user_task,
          template: template,
          name: 'Review Application',
        )

        end_event = create(
          :hmis_workflow_definition_end_event,
          template: template,
          name: 'Complete',
        )

        # Connect the nodes with flows
        start_event.connect_to!(user_task)
        user_task.connect_to!(end_event)
      end
    end
  end
end
