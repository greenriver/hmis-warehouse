###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class PrimaryHousingTrackSuggested < Select
    attribute :column, String, lazy: true, default: :primary_housing_track_suggested
    attribute :translation_key, String, lazy: true, default: 'Primary Housing Track Suggested'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }
  end
end
