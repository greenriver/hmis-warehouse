module CohortColumns
  class DisabilityVerificationDate < ReadOnly
    attribute :column, String, lazy: true, default: :disability_verification_date
    attribute :title, String, lazy: true, default: 'Disability Verification Upload Date'

    def date_format
      'll'
    end

    def value(cohort_client) # OK
      cohort_client.disability_verification_date&.to_s
    end
  end
end
