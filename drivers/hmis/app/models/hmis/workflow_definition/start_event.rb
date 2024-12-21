# Represents the starting point of a workflow.
# Each workflow must have at least one start event that triggers the beginning of the process.
module Hmis::WorkflowDefinition
  class StartEvent < Node
    def entrypoint? = true
  end
end
