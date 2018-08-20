module CohortColumns
  class HousingOpportunity < Select
    attribute :column, String, lazy: true, default: :housing_opportunity
    attribute :title, String, lazy: true, default: 'Housing Opportunity'

  end
end
