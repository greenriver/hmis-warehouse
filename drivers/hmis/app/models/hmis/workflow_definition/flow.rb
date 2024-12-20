module Hmis::WorkflowDefinition
  class Flow < GrdaWarehouseBase
    belongs_to :template, class_name: 'Hmis::WorkflowDefinition::Template'
    belongs_to :source_node, class_name: 'Hmis::WorkflowDefinition::Node'
    belongs_to :target_node, class_name: 'Hmis::WorkflowDefinition::Node'

    # "client_accepts = 1"
    # def condition; end
  end
end
