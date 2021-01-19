module Stupidedi
  using Refinements

  module Writer
    class Json
      class TransactionSet
        attr_reader :node

        def_delegators :node, :children

        def initialize(node)
          @node = node
        end

        def reduce(memo, &block)
          memo[key] = children.map(&block)
        end

        def key
          :transactions
        end
      end
    end
  end
end
