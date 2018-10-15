module CohortColumns
  class DateDocumentReady < CohortDate
    attribute :column, String, lazy: true, default: :document_ready_on
    attribute :title, String, lazy: true, default: _('Date Document Ready')

    def description
      _('Manually entered date at which the client became document ready')
    end
  end
end
