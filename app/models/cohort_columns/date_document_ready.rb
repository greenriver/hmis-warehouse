module CohortColumns
  class DateDocumentReady < CohortDate
    attribute :column, String, lazy: true, default: :document_ready_on
    attribute :title, String, lazy: true, default: 'Date Document Ready'

    def description
      'Manually entered date at which the client became document ready'
    end
  end
end
