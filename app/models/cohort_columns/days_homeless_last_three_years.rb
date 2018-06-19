module CohortColumns
  class DaysHomelessLastThreeYears < ReadOnly
    attribute :column, String, lazy: true, default: :days_homeless_last_three_years
    attribute :title, String, lazy: true, default: 'Days Homeless in the last 3 years*'

    def value(cohort_client) # OK
      cohort_client.days_homeless_last_three_years_on_effective_date
    end
  end
end
