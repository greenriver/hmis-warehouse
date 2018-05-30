module CohortColumns
  class RrhSsvfEligible < ReadOnly
    attribute :column, String, lazy: true, default: :rrh_ssvf_eligible
    attribute :title, String, lazy: true, default: 'SSVF Eligible (from RRH Assessment)'
    
    def renderer
      'html'
    end

    def value(cohort_client)
      checkmark_or_x text_value(cohort_client)
    end

    def text_value cohort_client
      cohort_client.client.ssvf_eligible
    end
  end
end
