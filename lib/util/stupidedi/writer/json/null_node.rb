# frozen_string_literal: true

module Stupidedi
  using Refinements

  module Writer
    class Json
      class NullNode
        def initialize(*)
        end

        def reduce(memo, *)
          # do nothing
          memo
        end
      end
    end
  end
end
