###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class PaginatedScope
    attr_reader :offset, :limit

    def initialize(all_nodes, offset: 0, limit: 50)
      @all_nodes = all_nodes
      @offset = offset
      @limit = limit
    end

    def nodes
      @all_nodes.offset(@offset).limit(@limit)
    end

    def nodes_count
      @all_nodes.count
    end

    def pages_count
      (nodes_count / @limit.to_f).ceil
    end

    # Ignoring rubocop because the method names need to match the API field names, which use "has_*"
    # rubocop:disable Naming/PredicateName
    def has_more_after
      @offset + @limit < nodes_count
    end

    def has_more_before
      @offset.positive?
    end
    # rubocop:enable Naming/PredicateName
  end
end
