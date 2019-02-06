module CohortColumns
  class LocationType < Select
    attribute :column, String, lazy: true, default: :location_type
    attribute :translation_key, String, lazy: true, default: 'Location Type'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
