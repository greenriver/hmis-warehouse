###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseInputObject < GraphQL::Schema::InputObject
    argument_class Types::BaseArgument

    def current_user
      context[:current_user]
    end

    def self.transformer
      @transformer ||= Types::HmisSchema::Transformers::BaseTransformer
    end

    def self.transform_with(transformer_class)
      @transformer = transformer_class
    end

    def self.date_string_argument(name, description, **kwargs)
      argument name, String, description, validates: { format: { with: /\d{4}-\d{2}-\d{2}/ } }, **kwargs
    end

    def self.yes_no_missing_argument(name, description = nil, yes_value: 1, no_value: 0, null_value: 99, **kwargs)
      argument(
        name,
        Boolean,
        description,
        **kwargs,
        prepare: ->(value, _ctx) do
          case value
          when true
            yes_value
          when false
            no_value
          when nil
            null_value
          end
        end,
      )
    end

    def to_params
      self.class.transformer.new(self).to_params
    end

    def trim_keys(hash)
      hash.transform_keys { |k| k.to_s.gsub(/^_+/, '').to_sym }
    end
  end
end
