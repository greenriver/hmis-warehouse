module CohortColumns
  class HousingTrackEnrolled < Select
    attribute :column, String, lazy: true, default: :housing_track_enrolled
    attribute :translation_key, String, lazy: true, default: 'Housing Track Enrolled'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
