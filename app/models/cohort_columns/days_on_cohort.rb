###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DaysOnCohort < ReadOnly
    attribute :column, String, lazy: true, default: :days_on_cohort
    attribute :translation_key, String, lazy: true, default: 'Days on Cohort'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Days between the date the client was added to the cohort and today.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def value(cohort_client)
      (Date.current - (cohort_client.date_added_to_cohort&.to_date || cohort_client.created_at.to_date)).to_i
    end
  end
end
