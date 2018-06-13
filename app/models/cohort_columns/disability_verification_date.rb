module CohortColumns
  class DisabilityVerificationDate < ReadOnly
    attribute :column, String, lazy: true, default: :disability_verification_date
    attribute :title, String, lazy: true, default: 'Disability Verification Upload Date'

    def date_format
      'll'
    end

    def value(cohort_client) # TODO: N+1 move_to_processed
      cohort_client.client.most_recent_verification_of_disability&.created_at&.to_date&.to_s
    end
  end
end
