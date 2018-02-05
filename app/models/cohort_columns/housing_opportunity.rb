module CohortColumns
  class HousingOpportunity < Base
    attribute :column, String, lazy: true, default: :housing_opportunity
    attribute :title, String, lazy: true, default: 'Housing Opportunity'

    def default_input_type
      :select
    end

    def available_options
      ['Cas', 'Non-CAS']
    end

  end
end
