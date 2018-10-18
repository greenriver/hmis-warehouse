module CohortColumns
  class HousingTrackSuggested < Select
    attribute :column, String, lazy: true, default: :housing_track_suggested
    attribute :title, String, lazy: true, default: _('Housing Track Suggested')

  end
end
