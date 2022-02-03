###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class LocationType < Select
    attribute :column, String, lazy: true, default: :location_type
    attribute :translation_key, String, lazy: true, default: 'Location Type'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
