###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseFilterInput < BaseInputObject
    def self.build(node_class, name: nil, &block)
      Class.new(self) do
        graphql_name("#{name || node_class.graphql_name}FilterInput")
        instance_eval(&block) if block
      end
    end
  end
end
