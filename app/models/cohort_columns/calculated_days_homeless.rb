###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class CalculatedDaysHomeless < ReadOnly
    attribute :column, String, lazy: true, default: :calculated_days_homeless
    attribute :translation_key, String, lazy: true, default: 'Calculated Days Homeless*'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def cast_value(val)
      val.to_i
    end

    def arel_col
      c_client_t[:calculated_days_homeless_on_effective_date]
    end

    def description
      'Days homeless on the effective date, or today'
    end

    def value(cohort_client) # OK
      cohort_client.calculated_days_homeless_on_effective_date
    end
  end
end
