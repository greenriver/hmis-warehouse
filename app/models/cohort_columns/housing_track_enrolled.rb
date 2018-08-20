module CohortColumns
  class HousingTrackEnrolled < Select
    attribute :column, String, lazy: true, default: :housing_track_enrolled
    attribute :title, String, lazy: true, default: 'Housing Track Enrolled'


    def available_options
      GrdaWarehouse::CohortColumnOption.where(cohort_column: "Housing Track Enrolled").map {|x| x.value}
    end
  end
end
