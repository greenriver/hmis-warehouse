# frozen_string_literal: true

# Represents the assignment of a user to a step/task in a workflow
module Hmis::WorkflowExecution
  class StepAssignment < GrdaWarehouseBase
    belongs_to :step, class_name: 'Hmis::WorkflowExecution::Step'
    belongs_to :user, class_name: 'Hmis::User'
  end
end
