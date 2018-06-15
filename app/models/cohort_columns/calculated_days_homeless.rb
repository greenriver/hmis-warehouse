module CohortColumns
  class CalculatedDaysHomeless < ReadOnly
    attribute :column, String, lazy: true, default: :calculated_days_homeless
    attribute :title, String, lazy: true, default: 'Calculated Days Homeless*'

    def description
      'Days homeless on the effective date, or today'
    end

    def value(cohort_client) # OK
      cohort.time_dependant_client_data[cohort_client.client_id][:calculated_days_homeless]
    end
  end
end
