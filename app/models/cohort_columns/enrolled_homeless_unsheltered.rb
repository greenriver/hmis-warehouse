module CohortColumns
  class EnrolledHomelessUnsheltered < ReadOnly
    attribute :column, String, lazy: true, default: :enrolled_homeless_unsheltered
    attribute :title, String, lazy: true, default: 'Enrolled in unsheltered homeless project (SO)'

    def renderer
      'html'
    end

    def value(cohort_client) # OK
      checkmark_or_x text_value(cohort_client)
    end

    def text_value cohort_client
      cohort_client.client.processed_service_history&.enrolled_homeless_unsheltered
    end
  end
end
