module CohortColumns
  class SensoryImpaired < Select
    attribute :column, String, lazy: true, default: :sensory_impaired
    attribute :translation_key, String, lazy: true, default: 'Sensory Impaired'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
