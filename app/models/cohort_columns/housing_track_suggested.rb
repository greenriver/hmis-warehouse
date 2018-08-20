module CohortColumns
  class HousingTrackSuggested < Select
    attribute :column, String, lazy: true, default: :housing_track_suggested
    attribute :title, String, lazy: true, default: 'Housing Track Suggested'


    def available_options
      GrdaWarehouse::CohortColumnOption.where(cohort_column: "Housing Track Suggested").map {|x| x.value}
    end
  end
end
