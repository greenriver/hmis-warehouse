module CohortColumns
  class LastHomelessVisit < ReadOnly
    attribute :column, String, lazy: true, default: :last_seen
    attribute :title, String, lazy: true, default: 'Last Seen'


    def value(cohort_client)
      Rails.cache.fetch([cohort_client.client.id, 'last_seen'], expires_at: 8.hours) do
        cohort_client.client.last_homeless_visits.map do |row|
          row.join(': ')
        end.join('; ')
      end
    end
  end
end
