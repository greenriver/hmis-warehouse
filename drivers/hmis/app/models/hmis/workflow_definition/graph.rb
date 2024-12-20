# graph helpers
module Hmis::WorkflowDefinition
  class Graph
    attr_reader :nodes

    def initialize(nodes)
      @nodes = nodes
    end

    def walk(&block)
      return enum_for(:walk) unless block_given?

      visited = Set.new
      nodes.filter(&:entrypoint?).each do |node|
        walk_from_node(node, visited, &block) unless visited.include?(node.id)
      end
    end

    # could add helpers for validation such as graph.acyclic?

    protected

    def walk_from_node(node, visited, &block)
      return if visited.include?(node.id)

      visited.add(node.id)
      yield node

      node.outflows.each do |child|
        walk_from_node(child.target_node, visited, &block)
      end
    end
  end
end
