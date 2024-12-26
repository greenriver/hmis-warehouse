# Represents decision points in the workflow where the process path splits or merges based on conditions or parallel execution rules.
#
# node.gateway_type determines flow behavior, it supports a subset of BPMN gate way behavior
# Join Gateway
#   always wait for all incoming flows before proceeding. Every incoming flow is mandatory for the process to proceed
# Inclusive Gateway
#   follow all outflows that match condition
# Exclusive Gateway
#   follow only the first outflow that matches condition

module Hmis::WorkflowDefinition
  class Gateway < Node
    validates :gateway_type, presence: true, inclusion: { in: ['exclusive', 'inclusive', 'join'] }

    def gateway? = true

    def join_inflows?
      gateway_type == 'join'
    end

    def exclusive_outflows?
      gateway_type == 'exclusive'
    end
  end
end
