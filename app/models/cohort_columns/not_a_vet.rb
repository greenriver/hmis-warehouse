module CohortColumns
  class NotAVet < Select
    attribute :column, String, lazy: true, default: :not_a_vet
    attribute :translation_key, String, lazy: true, default: 'Not a Vet'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
