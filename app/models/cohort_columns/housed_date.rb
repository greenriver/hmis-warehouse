module CohortColumns
  class HousedDate < Base
    attribute :column, String, lazy: true, default: :housed_date
    attribute :title, String, lazy: true, default: 'Housed Date'

    def default_input_type
      :date
    end

  end
end
