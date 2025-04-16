# frozen_string_literal: true

# Provides graph traversal and analysis capabilities for workflow templates.
# - Used for validating workflow structure and determining execution paths.
# - Does not consider conditions or other conditions on flows.
module Hmis::WorkflowDefinition
  class Graph
    attr_reader :nodes

    def initialize(nodes)
      @nodes = nodes
    end

    # entrypoints allows starting with the descendants of specific node. Defaults to graph entrypoints
    # stop_when allows us to perform a bounded depth-first search:
    # matches = graph.walk(entrypoint_ids: ids, stop_when: ->(node) { node.type == 'task' })
    def walk(entrypoint_ids: nil, stop_when: nil)
      nodes_by_id = nodes.index_by(&:id) # map nodes by ID so we can get them without re-querying the database

      Enumerator.new do |yielder|
        visited = Set.new
        stack = nodes.filter(&:entrypoint?) if entrypoint_ids.nil?
        stack = nodes.filter { |n| n.id.in?(entrypoint_ids) } if entrypoint_ids
        skip_ids = entrypoint_ids&.to_set || []

        while stack.any?
          node = stack.pop
          next if visited.include?(node)

          yielder << node unless node.id.in?(skip_ids)
          visited.add(node) unless node.id.in?(skip_ids) # if entrypoints were passed as arguments, don't return them

          # If this node was passed as an entrypoint, don't check the stop_when condition. (Otherwise we wouldn't traverse any nodes)
          unless node.id.in?(skip_ids)
            # Check the stop_when condition and if it's true, exit early without traversing the children.
            next if stop_when&.call(node)
          end

          # Traverse this node's children:
          child_ids = node.outflows.sort_by(&:position).map(&:target_node_id) # get all outflows from this node
          children = child_ids.map { |id| nodes_by_id[id] } # get the nodes they point to -- from in-memory `nodes_by_id`, so we don't hit the database again
          stack.concat(children.reverse) # preserve order of children in stack
        end
      end
    end

    # could add helpers for validation such as graph.acyclic?
  end
end
