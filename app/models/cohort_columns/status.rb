module CohortColumns
  class Status < Select
    attribute :column, String, lazy: true, default: :status
    attribute :title, String, lazy: true, default: 'Risk'

    def description
      'Risk of becoming chronic'
    end

    def available_options
      [
        '', 
        'Chronic',
        'Probable Chronic',
        'At risk 180+ days',
        'At risk 90-179 days',
      ]
    end

  end
end
