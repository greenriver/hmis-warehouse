module CohortColumns
  class HousingTrack < Base
    attribute :column, String, lazy: true, default: :housing_track
    attribute :title, String, lazy: true, default: 'Housing Track'

  end
end