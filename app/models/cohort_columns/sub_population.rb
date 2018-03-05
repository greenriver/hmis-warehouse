module CohortColumns
  class SubPopulation < Base
    attribute :column, String, lazy: true, default: :sub_population
    attribute :title, String, lazy: true, default: 'Subpopulation'

    def default_input_type
      :select2
    end

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
