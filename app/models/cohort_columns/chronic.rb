###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Chronic < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :chronic
    attribute :translation_key, String, lazy: true, default: 'On Previous Chronic List'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Manually entered record of previous chronic membership'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }
  end
end
