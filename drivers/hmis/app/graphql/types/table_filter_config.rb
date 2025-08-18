# frozen_string_literal: true

module Types
  class TableFilterConfig < Types::BaseObject
    skip_activity_log
    description 'Represents a dynamic filter configuration.'

    field :key, String, 'The key or field name of the filter.', null: false
    field :label, String, 'The display label for the filter.', null: false
    # field :type, Types::TableFilterConfigType, 'The type of the filter.', null: false
    field :options, [Forms::PickListOption], 'The list of possible values for this filter.', null: false
  end
end
