# frozen_string_literal: true

# Represents a running instance of a workflow template.
# Tracks the current state of the process and maintains the context data for the workflow execution.
module Hmis::WorkflowExecution
  class Instance < GrdaWarehouseBase
    belongs_to :template, class_name: 'Hmis::WorkflowDefinition::Template'
    has_many :steps, class_name: 'Hmis::WorkflowExecution::Step', dependent: :destroy

    # TODO(#7647) rename the scope.
    # Steps that have been available longest are ordered first, so the frontend can most easily display the stalest tasks
    has_many :open_steps, -> { open.order_by_updated_at }, class_name: 'Hmis::WorkflowExecution::Step'
    has_many :audit_events, class_name: 'Hmis::WorkflowExecution::AuditEvent', dependent: :destroy
    has_many :swimlanes, through: :template, class_name: 'Hmis::WorkflowDefinition::Swimlane'
  end
end
