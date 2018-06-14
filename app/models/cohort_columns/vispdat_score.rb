module CohortColumns
  class VispdatScore < ReadOnly
    attribute :column, String, lazy: true, default: :vispdat_score
    attribute :title, String, lazy: true, default: 'VI-SPDAT Score'

    def value(cohort_client)
      Rails.cache.fetch([cohort_client.client.id, 'vispdat_score'], expires_in: 8.hours) do
        cohort_client.client.most_recent_vispdat_score
      end
    end
  end
end
