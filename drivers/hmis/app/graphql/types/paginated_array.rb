###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# See: docs/domain-pack/hmis/graphql-layer.md
module Types
  class PaginatedArray < Types::PaginatedScope
    def nodes
      @all_nodes.drop(@offset).first(@limit)
    end
  end
end
