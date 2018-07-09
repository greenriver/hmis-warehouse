module CohortColumns
  class Veteran < CohortBoolean
    attribute :column, String, lazy: true, default: :veteran
    attribute :title, String, lazy: true, default: 'Veteran'

    def value(cohort_client) # OK
      cohort_client.client.veteran?
    end
  end
end
