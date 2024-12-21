# Provides graph traversal and analysis capabilities for workflow templates.
# Used for validating workflow structure and determining execution paths.
# Does not consider conditions or other conditions on flows.
module Hmis::WorkflowDefinition
  class Graph
    attr_reader :nodes

    def initialize(nodes)
      @nodes = nodes
    end

    # entrypoints allows starting with the descendants of specific node. Defaults to graph entrypoints
    # stop_when allows us to perform a bounded depth-first search:
    # matches = graph.walk(start_node, stop_when: ->(node) { node.type == 'task' })
    #
    def walk(entrypoint_ids: nil, stop_when: nil)
      Enumerator.new do |yielder|
        visited = Set.new
        stack = nodes.filter(&:entrypoint?) if entrypoint_ids.nil?
        stack = nodes.filter { |n| n.id.in?(entrypoint_ids) } if entrypoint_ids
        skip_ids = entrypoint_ids&.to_set || []

        while stack.any?
          node = stack.pop
          next if visited.include?(node)

          yielder << node unless node.id.in?(skip_ids)
          visited.add(node) unless node.id.in?(skip_ids) # don't return entrypoints if from args

          # careful, this logic is a bit ugly/fragile
          if node.id.in?(skip_ids) || (stop_when.nil? || !stop_when.call(node))
            children = node.outflows.sort_by(&:position).map(&:target_node)
            stack.concat(children.reverse) # preserve order of children in stack)
          end
        end
      end.lazy
    end

    # could add helpers for validation such as graph.acyclic?
  end
end
