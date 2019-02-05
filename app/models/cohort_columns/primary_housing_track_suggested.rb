module CohortColumns
  class PrimaryHousingTrackSuggested < Select
    attribute :column, String, lazy: true, default: :primary_housing_track_suggested
    attribute :translation_key, String, lazy: true, default: 'Primary Housing Track Suggested'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
