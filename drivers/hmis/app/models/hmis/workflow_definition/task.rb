# frozen_string_literal: true

# Represents a task that needs to be performed by a user in an execution step
# Tasks require form completion to proceed which is tracked corresponding execution steps
# Tasks may include a swimline which can be used to determine which user is assigned to the corresponding step
module Hmis::WorkflowDefinition
  class Task < Node
    belongs_to :form_definition, class_name: 'Hmis::Form::Definition'
    # swimlane assoc is defined on Node, even though it is only relevant on Task, so that Step can join through
    # belongs_to :swimlane, class_name: 'Hmis::WorkflowDefinition::Swimlane', optional: true

    validates :name, presence: true

    def task? = true
  end
end
