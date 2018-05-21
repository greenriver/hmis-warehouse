module CohortColumns
  class HouseholdMembers < ReadOnly
    attribute :column, String, lazy: true, default: :household_members
    attribute :title, String, lazy: true, default: 'Household Members'

    def value(cohort_client)
      Rails.cache.fetch([cohort_client.client.id, 'household_members'], expires_at: 8.hours) do
        households = cohort_client.client.households
        if households.present?
          households.households.values.flatten.
            map do |_, member| 
              "#{member['FirstName']} #{member['LastName']} (#{member['age']} in #{member['date'].year})"
            end.uniq.join('; ')
        end
      end
    end

  end
end
