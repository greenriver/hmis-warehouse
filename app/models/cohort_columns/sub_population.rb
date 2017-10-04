module CohortColumns
  class SubPopulation < Base
    attribute :column, String, lazy: true, default: :sub_population
    attribute :title, String, lazy: true, default: 'Subpopulation'

  end
end