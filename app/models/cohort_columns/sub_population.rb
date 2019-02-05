module CohortColumns
  class SubPopulation < Select
    attribute :column, String, lazy: true, default: :sub_population
    attribute :translation_key, String, lazy: true, default: 'Subpopulation'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
