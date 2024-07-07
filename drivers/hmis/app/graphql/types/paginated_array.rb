###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
#
module Types
  class PaginatedArray < Types::PaginatedScope
    def nodes
      @all_nodes.drop(@offset).first(@limit)
    end
  end
end
