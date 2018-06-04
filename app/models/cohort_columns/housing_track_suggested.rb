module CohortColumns
  class HousingTrackSuggested < Select
    attribute :column, String, lazy: true, default: :housing_track_suggested
    attribute :title, String, lazy: true, default: 'Housing Track Suggested'


    def available_options
      [
        '', 
        'CoC', 
        'ESG RRH',
        'Other - in notes', 
        'RRHHI', 
        'SSVF - NECHV', 
        'SSVF - VOA', 
        'VASH', 
        'VWH'
      ]
    end
  end
end
