###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CohortColumns
  class Dob < ReadOnlyDate
    attribute :column, String, lazy: true, default: :dob
    attribute :translation_key, String, lazy: true, default: 'DOB'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Date of Birth of the client.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def cast_value(val)
      val.to_date
    end

    def arel_col
      c_t[:DOB]
    end

    def value(cohort_client) # OK
      cohort_client.client.DOB
    end

    # Don't report PII in Cohort Data, this can be obtained from the PII store
    def analytics_value
      nil
    end
  end
end
