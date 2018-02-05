module CohortColumns
  class Chapter115 < Base
    attribute :column, String, lazy: true, default: :chapter_115
    attribute :title, String, lazy: true, default: 'Chapter 115'

    def default_input_type
      :select
    end

    def available_options
      ['Receiving', 'Eligible', 'Ineligible']
    end
  end
end
