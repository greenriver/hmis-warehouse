module CohortColumns
  class DaysLiterallyHomelessLastThreeYears < ReadOnly
    attribute :column, String, lazy: true, default: :days_literally_homeless_last_three_years
    attribute :title, String, lazy: true, default: 'Days Literally Homeless in the last 3 years*'


    def value(cohort_client) # OK
      cohort.time_dependant_client_data[cohort_client.client_id][:days_literally_homeless_last_three_years]
    end

  end
end
