module CohortColumns
  class Status < Select
    attribute :column, String, lazy: true, default: :status
    attribute :title, String, lazy: true, default: 'Risk'

    def description
      'Risk of becoming chronic'
    end

  end
end
