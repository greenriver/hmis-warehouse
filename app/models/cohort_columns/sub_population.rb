module CohortColumns
  class SubPopulation < Select
    attribute :column, String, lazy: true, default: :sub_population
    attribute :title, String, lazy: true, default: 'Subpopulation'


    def available_options
      [
        'Veteran',
        'HUES',
        'Street sleeper',
        'HUES + Street sleeper',
        'Veteran + Street sleeper',
        'Veteran + HUES',
        'Veteran + HUES + Street sleeper'
      ]
    end
  end
end
