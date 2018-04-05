module CohortColumns
  class VispdatPriorityScore < ReadOnly
    attribute :column, String, lazy: true, default: :vispdat_priority_score
    attribute :title, String, lazy: true, default: 'VI-SPDAT Priority Score'

    def value(cohort_client)
      Rails.cache.fetch([cohort_client.client, 'vispdat_priority_score'], expires_at: 8.hours) do
        cohort_client.client.calculate_vispdat_priority_score
      end
    end
  end
end
