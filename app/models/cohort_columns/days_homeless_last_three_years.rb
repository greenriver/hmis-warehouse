###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DaysHomelessLastThreeYears < ReadOnly
    attribute :column, String, lazy: true, default: :days_homeless_last_three_years
    attribute :translation_key, String, lazy: true, default: 'Days Homeless in the last 3 years*'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Days spent in homeless projects that are not overlapping housed dates. Calculated from HMIS data.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def cast_value(val)
      val.to_i
    end

    def arel_col
      c_client_t[:days_homeless_last_three_years_on_effective_date]
    end

    def value(cohort_client) # OK
      cohort_client.days_homeless_last_three_years_on_effective_date
    end
  end
end
