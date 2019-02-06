module CohortColumns
  class EtoCoordinatedEntryAssessmentScore < ReadOnly
    attribute :column, String, lazy: true, default: :eto_coordinated_entry_assessment_score
    attribute :translation_key, String, lazy: true, default: 'Coordinated Entry Assessment Score'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def description
      'Most recent score from ETO'
    end

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.eto_coordinated_entry_assessment_score
    end
  end
end
