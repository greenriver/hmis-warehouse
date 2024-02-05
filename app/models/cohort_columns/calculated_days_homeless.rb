###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class CalculatedDaysHomeless < ReadOnly
    attribute :column, String, lazy: true, default: :calculated_days_homeless
    attribute :translation_key, String, lazy: true, default: 'Calculated Days Homeless*'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Days homeless on the effective date, or today as calculated from HMIS data'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def cast_value(val)
      val.to_i
    end

    def arel_col
      c_client_t[:calculated_days_homeless_on_effective_date]
    end

    def value(cohort_client) # OK
      cohort_client.calculated_days_homeless_on_effective_date
    end
  end
end
