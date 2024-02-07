###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Ineligible < CohortBoolean
    attribute :column, Boolean, lazy: true, default: :ineligible
    attribute :translation_key, String, lazy: true, default: 'Ineligible'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: ->(model, _attr) { "#{model.translation_key} Description" }
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def default_value?
      true
    end

    def default_value(_client_id)
      false
    end
  end
end
