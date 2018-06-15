module CohortColumns
  class EnrolledHomelessUnsheltered < ReadOnly
    attribute :column, String, lazy: true, default: :enrolled_homeless_unsheltered
    attribute :title, String, lazy: true, default: 'Enrolled in unsheltered homeless project (SO)'

    def renderer
      'html'
    end

    def value(cohort_client)
      checkmark_or_x text_value(cohort_client)
    end

    def text_value cohort_client
      Rails.cache.fetch([cohort_client.client.id, :enrolled_homeless_unsheltered], expires_in: 8.hours) do
        cohort_client.client.service_history_enrollments.homeless_unsheltered.ongoing.exists?
      end
    end
  end
end
