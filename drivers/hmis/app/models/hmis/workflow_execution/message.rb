# Represents a message generated during workflow execution that may trigger actions or external state changes

# A message consists of:
# - type: The kind of action to perform (e.g., 'send_notification', 'create_ce_event')
# - params: Additional data needed to perform the action
# - step: (Optional) The workflow step that generated this message
#
# Example usage:
#   Message.new(
#     type: 'send_notification',
#     params: { recipient: 'case_manager', template: 'new_task' },
#     step: current_step
#   )
module Hmis::WorkflowExecution
  Message = Struct.new(:type, :params, :step, keyword_init: true)
end
