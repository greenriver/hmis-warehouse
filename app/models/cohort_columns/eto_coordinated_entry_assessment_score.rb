module CohortColumns
  class EtoCoordinatedEntryAssessmentScore < ReadOnly
    attribute :column, String, lazy: true, default: :eto_coordinated_entry_assessment_score
    attribute :title, String, lazy: true, default: 'Coordinated Entry Assessment Score'

    def description
      'Most recent score from ETO'
    end

    def value(cohort_client) # TODO: N+1 move_to_processed
      Rails.cache.fetch([cohort_client.client.id, 'eto_coordinated_entry_assessment_score'], expires_at: 8.hours) do
        cohort_client.client.most_recent_coc_assessment_score
      end
    end
  end
end
