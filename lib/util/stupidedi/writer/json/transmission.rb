module Stupidedi
  using Refinements

  module Writer
    class Json
      class Transmission
        attr_reader :node

        def_delegators :node, :children

        def initialize(node)
          @node = node
        end

        def reduce(memo)
          if single_child?
            yield(child, memo)
          else
            children.map { |c| yield(c, memo) }
          end
        end

        def single_child?
          children.size == 1
        end

        def child
          @child ||= children.first
        end
      end
    end
  end
end
