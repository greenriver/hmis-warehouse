###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class BasePaginated < BaseObject
    skip_activity_log
    # @param include_search_query_id [Boolean] When true, exposes `searchQueryId` on the paginated type (e.g. for client search).
    #   Opt in per node type by overriding `BaseObject.page_type` and passing `include_search_query_id: true`.
    def self.build(node_class, include_search_query_id: false)
      dynamic_name = "#{node_class.graphql_name.pluralize}Paginated"

      klass = Class.new(self) do
        graphql_name(dynamic_name)
        field :nodes, [node_class], null: false
        field :search_query_id, String, null: true if include_search_query_id
      end
      Object.const_set(dynamic_name, klass) unless Object.const_defined?(dynamic_name)
      klass
    end

    field :has_more_before, Boolean, null: false
    field :has_more_after, Boolean, null: false
    field :pages_count, Integer, null: false
    field :nodes_count, Integer, null: false
    field :limit, Integer, null: false
    field :offset, Integer, null: false
  end

  # Empty class that enables us to explicitly state that a return type should use Array pagination rather than Scope
  class ArrayPaginated < BasePaginated
  end
end
