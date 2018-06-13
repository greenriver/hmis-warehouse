module CohortColumns
  class EtoCoordinatedEntryAssessmentScore < ReadOnly
    attribute :column, String, lazy: true, default: :eto_coordinated_entry_assessment_score
    attribute :title, String, lazy: true, default: 'Coordinated Entry Assessment Score'

    def description
      'Most recent score from ETO'
    end

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.eto_coordinated_entry_assessment_score
    end
  end
end
