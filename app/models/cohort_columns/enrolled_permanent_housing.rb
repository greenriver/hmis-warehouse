module CohortColumns
  class EnrolledPermanentHousing < ReadOnly
    attribute :column, String, lazy: true, default: :enrolled_permanent_housing
    attribute :title, String, lazy: true, default: 'Enrolled in PH'


    def value(cohort_client)
      Rails.cache.fetch([cohort_client.client.id, :enrolled_permanent_housing], expires_at: 8.hours) do
        cohort_client.client.service_history_enrollments.permanent_housing.ongoing.exists?
      end
    end
  end
end
