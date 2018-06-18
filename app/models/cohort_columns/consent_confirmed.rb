module CohortColumns
  class ConsentConfirmed < ReadOnly
    attribute :column, String, lazy: true, default: :consent_confirmed
    attribute :title, String, lazy: true, default: 'Consent Confirmed'

    def renderer
      'html'
    end

    def value cohort_client
      checkmark_or_x text_value(cohort_client)
    end

    def text_value cohort_client
      cohort_client.client.consent_form_id.present? && cohort_client.client.consent_form_signed_on.present?
    end
  end
end
