# Represents decision points in the workflow where the process path splits or merges based on conditions or parallel execution rules.
module Hmis::WorkflowDefinition
  class Gateway < Node
    validates :gateway_type, presence: true
  end
end
