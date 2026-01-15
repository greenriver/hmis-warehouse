# frozen_string_literal: true

# Represents a message generated during workflow execution that may trigger actions or external state changes

# A message consists of:
# - type: The kind of action to perform (e.g., 'send_notification', 'create_ce_event')
# - params: Additional data needed to perform the action
# - step: (Optional) The workflow step that generated this message
# - user: The user whose action initiated the message. (E.g. user who completed a step)
#
# Example usage:
#   Message.new(
#     type: 'send_notification',
#     params: { recipient: 'case_manager', template: 'new_task' },
#     step: current_step,
#     user: current_user,
#   )
module Hmis::WorkflowExecution
  Message = Struct.new(:type, :params, :step, :user, keyword_init: true)
end
