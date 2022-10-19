module Types::Concerns::HasInputArguments
  extend ActiveSupport::Concern

  class_methods do
    def add_input_arguments
      source_type.type_fields.map do |key, options|
        next unless options[:argument].present?

        name = options[:argument][:name] || key
        type = options[:argument][:type] || options[:field][:type]
        args = options[:argument].except(:name, :type)
        argument(name.to_sym, type, **args)
      end
    end
  end
end
