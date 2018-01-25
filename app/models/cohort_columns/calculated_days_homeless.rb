module CohortColumns
  class CalculatedDaysHomeless < Base
    attribute :column, String, lazy: true, default: :calculated_days_homeless
    attribute :title, String, lazy: true, default: 'Calculated Days Homeless*'

    def default_input_type
      :read_only
    end

    def value(cohort_client)
      cohort_client.client.days_homeless(on_date: (cohort_client.cohort.effective_date || Date.today))
    end
  end
end
