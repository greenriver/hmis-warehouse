# frozen_string_literal: true

# Represents a task that needs to be performed by a user in an execution step
# Tasks require form completion to proceed which is tracked corresponding execution steps
# Tasks may include a swimline which can be used to determine which user is assigned to the corresponding step
module Hmis::WorkflowDefinition
  class Task < Node
    # Similar to Hmis::Form::Instance, Task has a form _identifier_, not a specific form, so that referral workflow steps can use newly published form versions
    has_many :form_definitions, primary_key: :form_definition_identifier, foreign_key: :identifier, class_name: 'Hmis::Form::Definition'

    belongs_to :swimlane, class_name: 'Hmis::WorkflowDefinition::Swimlane', optional: true

    validates :name, presence: true

    def task? = true

    # If the task has no form definition, it is a BPMN Script Task.
    # The engine will process it, and any side effects (trigger_config), without requiring user input.
    def script_task?
      form_definition_identifier.blank?
    end

    # If the task has a form definition, it is a BPMN User Task.
    def user_task?
      form_definition_identifier.present?
    end
  end
end
