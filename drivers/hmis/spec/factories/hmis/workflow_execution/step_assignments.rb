# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_wfe_step_assignment, class: 'Hmis::WorkflowExecution::StepAssignment' do
    step { association :hmis_wfe_step }
    user { association :hmis_user }
  end
end
