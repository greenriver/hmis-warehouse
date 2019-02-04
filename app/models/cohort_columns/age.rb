module CohortColumns
  class Age < ReadOnly
    attribute :column, String, lazy: true, default: :age
    attribute :translation_key, String, lazy: true, default: 'Age*'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}


    def value(cohort_client) # OK
      cohort_client.client.age_on(cohort_client.cohort.effective_date || Date.today)
    end
  end
end
