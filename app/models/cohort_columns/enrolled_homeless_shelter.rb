module CohortColumns
  class EnrolledHomelessShelter < ReadOnly
    attribute :column, String, lazy: true, default: :enrolled_homeless_shelter
    attribute :title, String, lazy: true, default: 'Enrolled in sheltered homeless project (ES, TH, SH)'

    def value(cohort_client)
      Rails.cache.fetch([cohort_client.client.id, :enrolled_homeless_shelter], expires_at: 8.hours) do
        cohort_client.client.service_history_enrollments.homeless_sheltered.ongoing.exists?
      end
    end
  end
end
