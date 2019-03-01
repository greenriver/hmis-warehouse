module CohortColumns
  class ConsentConfirmed < ReadOnly
    attribute :column, String, lazy: true, default: :consent_confirmed
    attribute :translation_key, String, lazy: true, default: 'Consent Confirmed'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def renderer
      'html'
    end

    def value cohort_client
      checkmark_or_x text_value(cohort_client)
    end

    def text_value cohort_client
      cohort_client.client.consent_confirmed?
    end
  end
end
