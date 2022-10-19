module Types::Concerns::HasInputArguments
  extend ActiveSupport::Concern

  TYPE_MAP = {
    string: String,
    integer: Integer,
    datetime: GraphQL::Types::ISO8601DateTime,
    date: GraphQL::Types::ISO8601Date,
  }.freeze

  class_methods do
    def add_input_arguments
      config = source_type.configuration.transform_keys { |k| k.to_s.gsub('ID', '').underscore }

      source_type.type_fields.map do |key, options|
        next if options[:argument].nil?

        # HMIS overrides
        field_options = options[:field]
        argument_options = options[:argument]
        # Warehouse field configuration
        config_options = config.dig(key.to_s)

        name = argument_options[:name] || key
        type = argument_options[:type] || field_options[:type] || TYPE_MAP[config_options[:type]]
        required = options[:argument][:required] || false

        raise "No type for #{key}" unless type.present?

        args = options[:argument].except(:name, :type, :required)
        argument(name.to_sym, type, required: required, **args)
      end
    end
  end
end
