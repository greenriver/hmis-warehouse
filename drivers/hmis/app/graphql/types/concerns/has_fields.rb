module Types::Concerns::HasFields
  extend ActiveSupport::Concern

  TYPE_MAP = {
    string: String,
    integer: Integer,
    datetime: GraphQL::Types::ISO8601DateTime,
    date: GraphQL::Types::ISO8601Date,
  }.freeze

  class_methods do
    def add_fields
      config = configuration.transform_keys { |k| k.to_s.gsub('ID', '').underscore }

      type_fields.map do |key, options|
        next if options[:field].nil?

        # HMIS overrides
        field_options = options[:field]
        # Warehouse field configuration
        config_options = config.dig(key.to_s)

        type = field_options[:type] || TYPE_MAP[config_options[:type]]
        raise "No type for #{key}" unless type.present?

        nullable = field_options[:null].nil? ? config_options&.dig(:null) : field_options[:null]
        args = field_options.except(:type, :null)

        field key, type: type, null: nullable, **args
      end
    end
  end
end
