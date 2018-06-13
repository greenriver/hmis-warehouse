module CohortColumns
  class VispdatScore < ReadOnly
    attribute :column, String, lazy: true, default: :vispdat_score
    attribute :title, String, lazy: true, default: 'VI-SPDAT Score'

    def value(cohort_client) # TODO: N=1 move_to_processed
      Rails.cache.fetch([cohort_client.client.id, 'vispdat_score'], expires_at: 8.hours) do
        cohort_client.client.most_recent_vispdat_score
      end
    end
  end
end
