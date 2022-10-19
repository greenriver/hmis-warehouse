module Types::Concerns::HasFields
  extend ActiveSupport::Concern

  class_methods do
    def add_fields
      config = configuration.transform_keys { |k| k.to_s.underscore }
      puts config
      type_fields.map do |key, options|
        next if options[:field].nil?

        # HMIS overrides
        field_options = options[:field]
        # Warehouse field configuration
        config_options = config.dig(key.to_s)

        type = field_options[:type] || hud_to_gql_type_map[config_options&.dig(:type)]
        nullable = field_options[:null].nil? ? config_options&.dig(:null) : field_options[:null]

        raise "No type for #{key}" unless type.present?

        args = field_options.except(:type, :null)
        field key, type: type, null: nullable, **args
      end
    end
  end
end
