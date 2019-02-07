module CohortColumns
  class HouseholdMembers < ReadOnly
    attribute :column, String, lazy: true, default: :household_members
    attribute :translation_key, String, lazy: true, default: 'Household Members'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.household_members
    end

  end
end
