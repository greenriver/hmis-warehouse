# Represents a reusable workflow template that defines the structure and rules
# of a workflow process. Templates contain nodes (tasks, events, gateways) connected
# by flows that determine the sequence of execution.
module Hmis::WorkflowDefinition
  class Template < GrdaWarehouseBase
    has_many :nodes, class_name: 'Hmis::WorkflowDefinition::Node', dependent: :destroy
    has_many :flows, class_name: 'Hmis::WorkflowDefinition::Flow', dependent: :destroy
    has_many :instances, class_name: 'Hmis::WorkflowExecution::Instance', dependent: :restrict_with_exception, foreign_key: 'template_id'
    has_many :swimlanes, class_name: 'Hmis::WorkflowDefinition::Swimlane', dependent: :restrict_with_exception, foreign_key: 'template_id'
    has_many :ce_opportunities, class_name: 'Hmis::Ce::Opportunity', dependent: :restrict_with_exception

    validates :name, presence: true

    def graph
      Hmis::WorkflowDefinition::Graph.new(nodes.preload(:outflows))
    end
  end
end
