module CohortColumns
  class PrimaryHousingTrackSuggested < Select
    attribute :column, String, lazy: true, default: :primary_housing_track_suggested
    attribute :title, String, lazy: true, default: _('Primary Housing Track Suggested')

  end
end
