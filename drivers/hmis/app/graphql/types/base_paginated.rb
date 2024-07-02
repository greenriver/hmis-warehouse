###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BasePaginated < BaseObject
    skip_activity_log
    def self.build(node_class)
      dynamic_name = "#{node_class.graphql_name.pluralize}Paginated"

      klass = Class.new(self) do
        graphql_name(dynamic_name)
        field :nodes, [node_class], null: false
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
