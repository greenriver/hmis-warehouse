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

        task_1 = create(
          :hmis_workflow_definition_user_task,
          template: template,
          name: 'Review Application',
        )

        task_2 = create(
          :hmis_workflow_definition_user_task,
          template: template,
          name: 'Provider Accepts',
        )

        end_event = create(
          :hmis_workflow_definition_end_event,
          template: template,
          name: 'Complete',
        )

        # Connect the nodes with flows
        start_event.connect_to!(task_1)
        task_1.connect_to!(task_2)
        task_2.connect_to!(end_event)
      end
    end
  end
end
