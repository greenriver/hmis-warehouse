module CohortColumns
  class Chapter115 < Select
    attribute :column, String, lazy: true, default: :chapter_115
    attribute :title, String, lazy: true, default: 'Chapter 115'

    def available_options
      ['Receiving', 'Eligible', 'Ineligible']
    end
  end
end
