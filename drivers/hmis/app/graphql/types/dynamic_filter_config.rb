# frozen_string_literal: true

module Types
  class DynamicFilterConfig < Types::BaseObject
    skip_activity_log
    description 'Represents an available dynamic filter configuration.'

    field :key, String, 'The key or field name of the filter.', null: false
    field :label, String, 'The display label for the filter.', null: false
    field :values, [String], 'The list of possible values for this filter.', null: false
  end
end
