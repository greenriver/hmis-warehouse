module CohortColumns
  class HousingTrackEnrolled < Select
    attribute :column, String, lazy: true, default: :housing_track_enrolled
    attribute :title, String, lazy: true, default: _('Housing Track Enrolled')

  end
end
