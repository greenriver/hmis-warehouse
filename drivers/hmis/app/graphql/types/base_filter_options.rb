###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseFilterOptions < BaseInputObject
    @omit = []
    def self.build(node_class, name: nil, omit: [], &block)
      Class.new(self) do
        @omit = omit
        graphql_name("#{name || node_class.graphql_name}FilterOptions")

        instance_eval(&block) if block
      end
    end

    def self.arg(name, *args, **kwargs)
      return if @omit&.include?(name)

      argument(name, *args, required: false, **kwargs)
    end
  end
end
