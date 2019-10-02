# frozen_string_literal: true

module Stupidedi
  using Refinements

  module Writer
    class Json
      def initialize(node)
        @node = node
      end

      # @return [Hash]
      def write(out = Hash.new { |k, v| self[k] = v })
        build(@node, out)
        out
      end

      private

      def resolve_traverser(node)
        if node.transmission?
          Transmission
        elsif node.interchange?
          Interchange
        elsif node.segment?
          Segment
        elsif node.loop?
          Loop
        elsif node.element?
          Element
        elsif node.functional_group?
          FunctionalGroup
        elsif node.transaction_set?
          TransactionSet
        elsif node.table?
          Table
        else
          NullNode
        end.new(node)
      end

      def build(node, out)
        traverser = resolve_traverser(node)

        traverser.reduce(out) do |children, memo = {}|
          build(children, memo)
        end

        out
      end
    end
  end
end
