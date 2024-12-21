# Track the events that occur in a workflow execution
module Hmis::WorkflowExecution
  class AuditEvent < GrdaWarehouseBase
    belongs_to :instance, class_name: 'Hmis::WorkflowExecution::Instance'
    belongs_to :step, class_name: 'Hmis::WorkflowExecution::Step', optional: true
    belongs_to :user, class_name: 'Hmis::User', optional: true
  end
end
