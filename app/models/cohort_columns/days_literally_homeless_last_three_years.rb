module CohortColumns
  class DaysLiterallyHomelessLastThreeYears < ReadOnly
    attribute :column, String, lazy: true, default: :days_literally_homeless_last_three_years
    attribute :title, String, lazy: true, default: 'Days Literally Homeless in the last 3 years*'


    def value(cohort_client) # TODO: N+1 & and time dependant
      #return "FIXME"
      Rails.cache.fetch([cohort_client.client, effective_date, 'days_literally_homeless_last_three_years'], expires_in: 8.hours) do
        cohort_client.client.literally_homeless_last_three_years(on_date: effective_date)
      end
    end

  end
end
