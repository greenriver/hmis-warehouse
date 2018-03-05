module CohortColumns
  class FirstDateHomeless < ReadOnly
    attribute :column, String, lazy: true, default: :first_date_homeless
    attribute :title, String, lazy: true, default: 'First Date Homeless'

    def value(cohort_client)
      cohort_client.client.first_homeless_date
    end

  end
end
