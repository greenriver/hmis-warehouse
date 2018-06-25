module CohortColumns
  class Age < ReadOnly
    attribute :column, String, lazy: true, default: :age
    attribute :title, String, lazy: true, default: 'Age*'


    def value(cohort_client) # OK
      cohort_client.client.age_on(cohort_client.cohort.effective_date || Date.today)
    end
  end
end
