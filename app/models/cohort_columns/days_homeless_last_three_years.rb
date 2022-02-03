###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DaysHomelessLastThreeYears < ReadOnly
    attribute :column, String, lazy: true, default: :days_homeless_last_three_years
    attribute :translation_key, String, lazy: true, default: 'Days Homeless in the last 3 years*'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def value(cohort_client) # OK
      cohort_client.days_homeless_last_three_years_on_effective_date
    end
  end
end
