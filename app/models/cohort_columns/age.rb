module CohortColumns
  class Age < Base
    attribute :column, String, lazy: true, default: :age
    attribute :title, String, lazy: true, default: 'Age*'

    def default_input_type
      :read_only
    end

    def value(cohort_client)
      cohort_client.client.age_on(cohort_client.cohort.effective_date || Date.today)
    end
  end
end
