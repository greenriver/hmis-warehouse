module CohortColumns
  class HousingTrackSuggested < Select
    attribute :column, String, lazy: true, default: :housing_track_suggested
    attribute :translation_key, String, lazy: true, default: 'Housing Track Suggested'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
