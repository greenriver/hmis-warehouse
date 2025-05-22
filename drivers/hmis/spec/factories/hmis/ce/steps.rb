# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_wfe_step, class: 'Hmis::WorkflowExecution::Step' do
    transient do
      assignees { nil }
    end

    association(:instance, factory: :hmis_workflow_execution_instance)
    association(:node, factory: :hmis_workflow_definition_task)

    status { 'available' }
    available_at { Time.current }

    after(:create) do |step, evaluator|
      if step.node.template != step.instance.template
        step.node.template = step.instance.template
        step.node.save!
      end

      if evaluator.assignees.present?
        evaluator.assignees.each do |assignee|
          step.assignments.create(user: assignee)
        end
      end
    end
  end
end
