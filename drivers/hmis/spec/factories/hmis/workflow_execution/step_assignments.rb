###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_wfe_step_assignment, class: 'Hmis::WorkflowExecution::StepAssignment' do
    step { association :hmis_wfe_step }
    user { association :hmis_user }
  end
end
