module CohortColumns
  class LegalBarriers < Select
    attribute :column, String, lazy: true, default: :legal_barriers
    attribute :translation_key, String, lazy: true, default: 'Legal Barriers'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
