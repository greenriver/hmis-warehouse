module CohortColumns
  class DaysHomelessLastThreeYears < ReadOnly
    attribute :column, String, lazy: true, default: :days_homeless_last_three_years
    attribute :title, String, lazy: true, default: 'Days Homeless in the last 3 years*'

    def value(cohort_client) # OK
      cohort.time_dependant_client_data[cohort_client.client_id][:days_homeless_last_three_years]
    end
  end
end
