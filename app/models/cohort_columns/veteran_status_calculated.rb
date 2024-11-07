###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class VeteranStatusCalculated < ReadOnly
    attribute :column, String, lazy: true, default: :veteran_status_calculated
    attribute :translation_key, String, lazy: true, default: 'Veteran Status (from HMIS)'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Veteran Status as reported on the client dashboard.  This is calculated using all available client records.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def value(cohort_client) # OK
      HudUtility2024.veteran_status(cohort_client.client.veteran_status)
    end
  end
end
