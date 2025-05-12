###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CohortColumns
  class FirstDateHomeless < ReadOnlyDate
    attribute :column, String, lazy: true, default: :first_date_homeless
    attribute :translation_key, String, lazy: true, default: 'First Date Homeless'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Date the client first appeared in a homeless enrollment in HMIS.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def cast_value(val)
      val.to_date
    end

    def arel_col
      wcp_t[:first_date_homeless]
    end

    def value(cohort_client) # OK
      cohort_client.client.first_homeless_date&.to_date&.to_s
    end
  end
end
