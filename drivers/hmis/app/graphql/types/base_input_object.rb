###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseInputObject < GraphQL::Schema::InputObject
    argument_class Types::BaseArgument

    def self.transformer
      @transformer ||= Types::HmisSchema::Transformers::BaseTransformer
    end

    def self.transform_with(transformer_class)
      @transformer = transformer_class
    end

    def self.date_string_argument(name, description, **kwargs)
      argument name, String, description, validates: { format: { with: /\d{4}-\d{2}-\d{2}/ } }, **kwargs
    end

    def to_params
      self.class.transformer.new(self).to_params
    end
  end
end
