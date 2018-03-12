module CohortColumns
  class CalculatedDaysHomeless < ReadOnly
    attribute :column, String, lazy: true, default: :calculated_days_homeless
    attribute :title, String, lazy: true, default: 'Calculated Days Homeless*'
    
    def value(cohort_client)
      Rails.cache.fetch([cohort_client.client.id, 'calculated_days_homeless'], expires_at: 8.hours) do
        cohort_client.client.days_homeless(on_date: (cohort_client.cohort.effective_date || Date.today))
      end
    end
  end
end
