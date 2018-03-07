module CohortColumns
  class LocationType < Select
    attribute :column, String, lazy: true, default: :location_type
    attribute :title, String, lazy: true, default: 'Location Type'

    def available_options
      [
        'Sheltered',
        'Unsheltered',
        'Institution less than 90 days',
        'Unknown/Missing',
      ]
    end


  end
end
