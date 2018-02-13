module CohortColumns
  class EnrolledHomelessUnsheltered < Base
    attribute :column, String, lazy: true, default: :enrolled_homeless_unsheltered
    attribute :title, String, lazy: true, default: 'Enrolled in unsheltered homeless project (SO)'

    def default_input_type
      :read_only
    end

    def value(cohort_client)
      Rails.cache.fetch([cohort_client.client.id, :enrolled_homeless_unsheltered], expires_at: 8.hours) do
        cohort_client.client.service_history_enrollments.homeless_unsheltered.ongoing.exists?
      end
    end
  end
end
