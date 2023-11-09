###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DateDocumentReady < CohortDate
    attribute :column, String, lazy: true, default: :document_ready_on
    attribute :translation_key, String, lazy: true, default: 'Date Document Ready'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: Translation.translate('Manually entered date at which the client became document ready')
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end
  end
end
