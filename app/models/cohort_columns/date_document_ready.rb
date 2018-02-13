module CohortColumns
  class DateDocumentReady < Base
    attribute :column, String, lazy: true, default: :document_ready_on
    attribute :title, String, lazy: true, default: 'Date Document Ready'

    def default_input_type
      :date_picker
    end

  end
end
