module CohortColumns
  class DocumentReady < Select
    attribute :column, String, lazy: true, default: :document_ready
    attribute :translation_key, String, lazy: true, default: 'Document Ready'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
