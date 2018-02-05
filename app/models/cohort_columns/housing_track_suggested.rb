module CohortColumns
  class HousingTrackSuggested < Base
    attribute :column, String, lazy: true, default: :housing_track_suggested
    attribute :title, String, lazy: true, default: 'Housing Track Suggested'

    def default_input_type
      :select
    end

    def available_options
      ['CoC', 'ESG RRH', 'Inactive', 'Other - in notes', 'RRHHI', 'SSVF - NECHV', 'SSVF - VOA', 'VASH', 'VWH']
    end
  end
end
