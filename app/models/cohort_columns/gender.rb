module CohortColumns
  class Gender < ReadOnly
    attribute :column, String, lazy: true, default: :gender
    attribute :title, String, lazy: true, default: 'Gender'

    def value(cohort_client) # OK
      cohort_client.client.gender
    end
  end
end
