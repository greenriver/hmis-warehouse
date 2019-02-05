module CohortColumns
  class ActiveCohorts < ReadOnly
    attribute :column, String, lazy: true, default: :active_cohorts
    attribute :translation_key, String, lazy: true, default: 'Cohorts'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def value(cohort_client) # OK
      cohort_ids = cohort_client.client.active_cohort_ids - [cohort.id]
      cohort_names.values_at(*cohort_ids).join('; ')
    end
  end
end
