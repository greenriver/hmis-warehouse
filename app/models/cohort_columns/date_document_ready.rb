###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DateDocumentReady < CohortDate
    attribute :column, String, lazy: true, default: :document_ready_on
    attribute :translation_key, String, lazy: true, default: 'Date Document Ready'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def description
      _('Manually entered date at which the client became document ready')
    end
  end
end
