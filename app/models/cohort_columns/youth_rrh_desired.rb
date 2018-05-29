module CohortColumns
  class YouthRrhDesired < ReadOnly
    attribute :column, String, lazy: true, default: :youth_rrh_desired
    attribute :title, String, lazy: true, default: 'Interested in Youth RRH'
    
    def renderer
      'html'
    end

    def value(cohort_client)
      checkmark_or_x text_value(cohort_client)
    end

    def text_value cohort_client
      cohort_client.client.youth_rrh_desired
    end
  end
end
