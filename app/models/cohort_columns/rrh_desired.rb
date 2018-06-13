module CohortColumns
  class RrhDesired < ReadOnly
    attribute :column, String, lazy: true, default: :rrh_desired
    attribute :title, String, lazy: true, default: 'Interested in RRH'

    def renderer
      'html'
    end

    def value(cohort_client) # TODO: N+1 move_to_processed
      checkmark_or_x text_value(cohort_client)
    end

    def text_value cohort_client
      cohort_client.client.rrh_desired # < N+1 here
    end
  end
end
