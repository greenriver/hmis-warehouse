###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class UnshelteredDaysHomelessLastThreeYears < ReadOnly
    attribute :column, String, lazy: true, default: :unsheltered_days_homeless
    attribute :translation_key, String, lazy: true, default: 'Unsheltered Days Homeless in the last 3 years'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Days in SO in the last 3 years with no overlapping sheltered dates ES, SH, TH, or PH after move-in date'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def cast_value(val)
      val.to_i
    end

    def arel_col
      c_client_t[:unsheltered_days_homeless_last_three_years]
    end

    def value(cohort_client)
      cohort_client.unsheltered_days_homeless_last_three_years
    end
  end
end
