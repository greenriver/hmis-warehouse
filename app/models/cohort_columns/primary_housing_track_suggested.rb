###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class PrimaryHousingTrackSuggested < Select
    attribute :column, String, lazy: true, default: :primary_housing_track_suggested
    attribute :translation_key, String, lazy: true, default: 'Primary Housing Track Suggested'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: ->(model, _attr) { "#{model.translation_key} Description" }
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }
  end
end
