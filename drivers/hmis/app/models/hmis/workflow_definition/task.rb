# Represents a task that needs to be performed by a user.
# Tasks are assignable and require form completion to proceed which is tracked corresponding execution steps
module Hmis::WorkflowDefinition
  class Task < Node
    belongs_to :form_definition, class_name: 'Hmis::Form::Definition'
    belongs_to :swimlane, class_name: 'Hmis::WorkflowDefinition::Swimlane', optional: true

    validates :name, presence: true

    def task? = true
  end
end
