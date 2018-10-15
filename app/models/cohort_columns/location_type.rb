module CohortColumns
  class LocationType < Select
    attribute :column, String, lazy: true, default: :location_type
    attribute :title, String, lazy: true, default: _('Location Type')

  end
end
