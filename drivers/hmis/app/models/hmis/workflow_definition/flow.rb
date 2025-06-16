# frozen_string_literal: true

# Represents connections between nodes in a workflow.
# Flows define the possible paths through the workflow and may include conditions that determine which path is taken.
module Hmis::WorkflowDefinition
  class Flow < GrdaWarehouseBase
    belongs_to :template, class_name: 'Hmis::WorkflowDefinition::Template'
    belongs_to :source_node, class_name: 'Hmis::WorkflowDefinition::Node'
    belongs_to :target_node, class_name: 'Hmis::WorkflowDefinition::Node'

    def describe_as_string(source_only: false, target_only: false)
      str = if source_only
        source_node.name
      elsif target_only
        target_node.name
      else
        "#{source_node.name} -> #{target_node.name}"
      end
      str += " (IF #{condition})" if condition.present?
      str += " (#{id})"
      str
    end
  end
end
