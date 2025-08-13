# frozen_string_literal: true

module Types
  class DynamicFilter < Types::BaseInputObject
    description 'Represents a dynamic filter that can be applied to queries.'

    argument :key, String, 'The key or field name to filter on. Must match key on DynamicFilterConfig.', required: true
    argument :values, [String], 'The value to filter by. Must match one of the values on DynamicFilterConfig.', required: false
  end
end
