module CohortColumns
  class AdjustedDaysHomeless < Base
    attribute :column, String, lazy: true, default: :adjusted_days_homeless
    attribute :title, String, lazy: true, default: 'Adjusted Days Homeless'

    def default_input_type
      :integer
    end

  end
end
