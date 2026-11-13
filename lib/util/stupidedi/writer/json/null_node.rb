###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
