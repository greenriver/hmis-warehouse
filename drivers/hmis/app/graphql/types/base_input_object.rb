###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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

    # Infers type from warehouse configuration
    def self.hud_argument(name, type = nil, **kwargs)
      return field name, type, **kwargs unless source_type&.configuration.present?

      config = source_type.configuration.transform_keys { |k| k.to_s.underscore }[name.to_s]
      type ||= Types::BaseObject.hud_to_gql_type_map[config[:type]] if config.present?
      raise "No type for #{name}" unless type.present?

      required = kwargs[:required] || false
      args = kwargs.except(:required)
      argument name, type, required: required, **args
    end

    def to_params
      self.class.transformer.new(self).to_params
    end
  end
end
