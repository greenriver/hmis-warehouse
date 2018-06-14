module CohortColumns
  class CalculatedDaysHomeless < ReadOnly
    attribute :column, String, lazy: true, default: :calculated_days_homeless
    attribute :title, String, lazy: true, default: 'Calculated Days Homeless*'

    def description
      'Days homeless on the effective date, or today'
    end


    def value(cohort_client) # TODO: N+1 & and time dependant
      #return "FIXME"
      Rails.cache.fetch([cohort_client.client, effective_date, 'calculated_days_homeless'], expires_in: 8.hours) do
        cohort_client.client.days_homeless(on_date: effective_date)
      end
    end
  end
end
