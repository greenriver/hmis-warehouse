module CohortColumns
  class ActiveCohorts < ReadOnly
    attribute :column, String, lazy: true, default: :active_cohorts
    attribute :title, String, lazy: true, default: 'Cohorts'

    def value(cohort_client)
      cohort_names.except(cohort.id).values.join('; ')
    end
  end
end
