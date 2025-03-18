# frozen_string_literal: true

# Represents connections between nodes in a workflow.
# Flows define the possible paths through the workflow and may include conditions that determine which path is taken.
module Hmis::WorkflowDefinition
  class Flow < GrdaWarehouseBase
    belongs_to :template, class_name: 'Hmis::WorkflowDefinition::Template'
    belongs_to :source_node, class_name: 'Hmis::WorkflowDefinition::Node'
    belongs_to :target_node, class_name: 'Hmis::WorkflowDefinition::Node'
  end
end
