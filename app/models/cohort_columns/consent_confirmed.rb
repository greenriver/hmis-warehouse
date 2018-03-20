module CohortColumns
  class ConsentConfirmed < ReadOnly
    attribute :column, String, lazy: true, default: :consent_confirmed
    attribute :title, String, lazy: true, default: 'Consent Confirmed'
    
    def renderer
      'html'
    end

    def value(cohort_client)
      checkmark_or_x cohort_client.client.consent_confirmed?
    end
  end
end
