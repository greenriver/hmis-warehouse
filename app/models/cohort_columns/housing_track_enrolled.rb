###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class HousingTrackEnrolled < Select
    attribute :column, String, lazy: true, default: :housing_track_enrolled
    attribute :translation_key, String, lazy: true, default: 'Housing Track Enrolled'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
