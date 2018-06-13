module CohortColumns
  class HouseholdMembers < ReadOnly
    attribute :column, String, lazy: true, default: :household_members
    attribute :title, String, lazy: true, default: 'Household Members'

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.household_members
    end

  end
end
