module CohortColumns
  class LegalBarriers < Select
    attribute :column, String, lazy: true, default: :legal_barriers
    attribute :title, String, lazy: true, default: 'Legal Barriers'


    def available_options
      ['CORI', 'SORI', 'Wage Garnishments', 'State Only']
    end
  end
end
