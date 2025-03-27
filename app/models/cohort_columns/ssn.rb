###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CohortColumns
  class Ssn < ReadOnly
    attribute :column, String, lazy: true, default: :ssnumber
    attribute :translation_key, String, lazy: true, default: 'SSN'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Client Social Security Number'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def value(cohort_client)
      ssn(cohort_client.client.SSN)
    end

    # Don't report PII in Cohort Data, this can be obtained from the PII store
    def analytics_value
      nil
    end
  end
end
