module CohortColumns
  class HousingOpportunity < Select
    attribute :column, String, lazy: true, default: :housing_opportunity
    attribute :title, String, lazy: true, default: 'Housing Opportunity'


    def available_options
      [
        '', 
        'CAS', 
        'Non-CAS',
      ]
    end

  end
end
