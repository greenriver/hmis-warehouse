# Represents a running instance of a workflow template.
# Tracks the current state of the process and maintains the context data for the workflow execution.
module Hmis::WorkflowExecution
  class Instance < GrdaWarehouseBase
    belongs_to :template, class_name: 'Hmis::WorkflowDefinition::Template'
    has_many :steps, class_name: 'Hmis::WorkflowExecution::Step', dependent: :destroy
    has_many :audit_events, class_name: 'Hmis::WorkflowExecution::AuditEvent', dependent: :destroy
  end
end
