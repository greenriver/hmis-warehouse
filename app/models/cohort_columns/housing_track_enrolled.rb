###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class HousingTrackEnrolled < Select
    attribute :column, String, lazy: true, default: :housing_track_enrolled
    attribute :translation_key, String, lazy: true, default: 'Housing Track Enrolled'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def available_for_rules?
      false
    end
  end
end
