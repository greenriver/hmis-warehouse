###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class HouseholdMembers < ReadOnly
    attribute :column, String, lazy: true, default: :household_members
    attribute :translation_key, String, lazy: true, default: 'Household Members'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Names and ages of household members for any enrollments in the past 3 years.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.household_members
    end
  end
end
