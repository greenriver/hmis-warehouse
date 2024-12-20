# graph helpers
module Hmis::WorkflowDefinition
  class Graph
    attr_reader :nodes

    def initialize(nodes)
      @nodes = nodes
    end

    # stop_when allows us to perform a bounded depth-first search:
    # matches = graph.walk(start_node, stop_when: ->(node) { node.type == 'task' })
    #
    def walk(entrypoints: nil, stop_when: nil, &block)
      return enum_for(:walk) unless block_given?

      visited = Set.new
      entrypoints ||= nodes.filter(&:entrypoint?)
      entrypoints.each do |node|
        walk_from_node(node, visited, stop_when, &block) unless visited.include?(node.id)
      end
    end

    # could add helpers for validation such as graph.acyclic?

    protected

    def walk_from_node(node, visited, stop_when, &block)
      return if visited.include?(node.id)

      visited.add(node.id)
      yield node

      # Don't traverse further if stop condition is met
      return if stop_when&.call(node)

      node.outflows.each do |child|
        walk_from_node(child.target_node, visited, stop_when, &block)
      end
    end
  end
end
