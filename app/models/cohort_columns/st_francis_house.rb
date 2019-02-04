module CohortColumns
  class StFrancisHouse < Select
    attribute :column, String, lazy: true, default: :st_francis_house
    attribute :translation_key, String, lazy: true, default: 'St. Francis House'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
