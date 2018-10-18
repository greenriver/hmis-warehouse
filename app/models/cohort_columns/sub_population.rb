module CohortColumns
  class SubPopulation < Select
    attribute :column, String, lazy: true, default: :sub_population
    attribute :title, String, lazy: true, default: _('Subpopulation')

  end
end
