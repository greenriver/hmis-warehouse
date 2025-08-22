# frozen_string_literal: true

module Types
  class TableFilterConfig < Types::BaseObject
    skip_activity_log
    description 'Represents a dynamic filter configuration.'
    # backed by Hmis::TableConfiguration#filters object

    field :key, String, 'The key or field name of the filter.', null: false
    field :label, String, 'The display label for the filter.', null: false
    field :options, [Forms::PickListOption], 'The list of possible values for this filter.', null: false
    # Note: may want to add a filter "type" later to support different filter types, for example Dates.
    # field :type, Types::TableFilterConfigType, 'The type of the filter.', null: false
  end
end
