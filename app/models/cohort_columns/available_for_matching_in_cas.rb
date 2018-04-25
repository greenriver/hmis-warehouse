module CohortColumns
  class AvailableForMatchingInCas < ReadOnly
    attribute :column, String, lazy: true, default: :available_for_matching_in_cas
    attribute :title, String, lazy: true, default: 'Available in CAS'
    
    def renderer
      'html'
    end

    def value(cohort_client)
      checkmark_or_x text_value(cohort_client)
    end

    def text_value cohort_client
      cohort_client.client.active_in_cas?
    end
  end
end
