module CohortColumns
  class HousingTrackEnrolled < Select
    attribute :column, String, lazy: true, default: :housing_track_enrolled
    attribute :title, String, lazy: true, default: 'Housing Track Enrolled'


    def available_options
      ['CoC', 'ESG RRH', 'Inactive', 'Other - in notes', 'RRHHI', 'SSVF - NECHV', 'SSVF - VOA', 'VASH', 'VWH']
    end
  end
end
