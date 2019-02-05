module CohortColumns
  class HousingOpportunity < Select
    attribute :column, String, lazy: true, default: :housing_opportunity
    attribute :translation_key, String, lazy: true, default: 'Housing Opportunity'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}
  end
end
