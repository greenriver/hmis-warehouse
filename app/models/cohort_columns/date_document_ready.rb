module CohortColumns
  class DateDocumentReady < CohortDate
    attribute :column, String, lazy: true, default: :document_ready_on
    attribute :title, String, lazy: true, default: 'Date Document Ready'


  end
end
