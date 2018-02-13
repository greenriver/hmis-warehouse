module CohortColumns
  class Status < Base
    attribute :column, String, lazy: true, default: :status
    attribute :title, String, lazy: true, default: 'Status'

    def available_options
      [
        'Chronic',
        'Probable Chronic',
        'At risk 180+ days',
        'At risk 90-179 days',
      ]
    end

    def default_input_type
      :select2
    end
  end
end
