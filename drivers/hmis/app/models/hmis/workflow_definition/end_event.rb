module Hmis::WorkflowDefinition
  class EndEvent < Node
    # events must have at least one trigger
    validates :trigger_config, presence: true
  end
end
