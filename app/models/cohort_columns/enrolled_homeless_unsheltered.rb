module CohortColumns
  class EnrolledHomelessUnsheltered < ReadOnly
    attribute :column, String, lazy: true, default: :enrolled_homeless_unsheltered
    attribute :title, String, lazy: true, default: 'Enrolled in unsheltered homeless project (SO)'

    def renderer
      'html'
    end

    def value(cohort_client)
      Rails.cache.fetch([cohort_client.client.id, :enrolled_homeless_unsheltered], expires_at: 8.hours) do
        checkmark_or_x cohort_client.client.service_history_enrollments.homeless_unsheltered.ongoing.exists?
      end
    end
  end
end
