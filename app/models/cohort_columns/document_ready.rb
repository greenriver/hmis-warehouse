module CohortColumns
  class DocumentReady < Select
    attribute :column, String, lazy: true, default: :document_ready
    attribute :title, String, lazy: true, default: 'Document Ready'
    
  end
end
