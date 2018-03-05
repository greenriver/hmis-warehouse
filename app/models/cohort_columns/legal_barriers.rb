module CohortColumns
  class LegalBarriers < Base
    attribute :column, String, lazy: true, default: :legal_barriers
    attribute :title, String, lazy: true, default: 'Legal Barriers'

    def default_input_type
      :select2
    end

    def available_options
      ['CORI', 'SORI', 'Wage Garnishments', 'State Only']
    end
  end
end
