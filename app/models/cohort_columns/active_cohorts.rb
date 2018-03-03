module CohortColumns
  class ActiveCohorts < Base
    attribute :column, String, lazy: true, default: :active_cohorts
    attribute :title, String, lazy: true, default: 'Cohorts'

    def default_input_type
      :read_only
    end

    def value(cohort_client)
      cohort_names.except(cohort.id).values.join('; ')
    end
  end
end
