module CohortColumns
  class ActiveCohorts < ReadOnly
    attribute :column, String, lazy: true, default: :active_cohorts
    attribute :title, String, lazy: true, default: 'Cohorts'


    def value(cohort_client) # OK
      cohort_ids = cohort_client.client.active_cohort_ids - [cohort.id]
      cohort_names.select{|k,_| cohort_ids.include?(k)}.values.join('; ')
    end
  end
end
