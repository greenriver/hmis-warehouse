module CohortColumns
  class DaysHomelessLastThreeYears < ReadOnly
    attribute :column, String, lazy: true, default: :days_homeless_last_three_years
    attribute :title, String, lazy: true, default: 'Days Homeless in the last 3 years*'


    def value(cohort_client) # TODO: N+1 & and time dependant
      #return "FIXME"
      Rails.cache.fetch([cohort_client.client, effective_date, 'days_homeless_last_three_years'], expires_in: 8.hours) do
        cohort_client.client.days_homeless_in_last_three_years(on_date: effective_date)
      end
    end

  end
end
