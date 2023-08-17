###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BasePaginated < BaseObject
    def self.build(node_class)
      dynamic_name = "#{node_class.graphql_name.pluralize}Paginated"
      Object.const_set(dynamic_name, Class.new(self) do
        graphql_name(dynamic_name)
        field :nodes, [node_class], null: false
      end)
    end

    field :has_more_before, Boolean, null: false
    field :has_more_after, Boolean, null: false
    field :pages_count, Integer, null: false
    field :nodes_count, Integer, null: false
    field :limit, Integer, null: false
    field :offset, Integer, null: false
  end
end
