module Hmis::WorkflowDefinition
  class Gateway < Node
    validates :gateway_type, presence: true
  end
end
