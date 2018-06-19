module CohortColumns
  class CalculatedDaysHomeless < ReadOnly
    attribute :column, String, lazy: true, default: :calculated_days_homeless
    attribute :title, String, lazy: true, default: 'Calculated Days Homeless*'

    def description
      'Days homeless on the effective date, or today'
    end

    def value(cohort_client) # OK
      cohort_client.calculated_days_homeless_on_effective_date
    end
  end
end
