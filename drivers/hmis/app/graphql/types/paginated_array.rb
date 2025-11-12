###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class PaginatedArray < Types::PaginatedScope
    def nodes
      @all_nodes.drop(@offset).first(@limit)
    end
  end
end
