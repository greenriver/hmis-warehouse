module Types::Concerns::HasFields
  extend ActiveSupport::Concern

  class_methods do
    def add_fields
      type_fields.map do |key, options|
        next unless options[:field].present?

        field key, **options[:field]
      end
    end
  end
end
