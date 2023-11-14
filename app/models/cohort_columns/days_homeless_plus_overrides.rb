###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DaysHomelessPlusOverrides < ReadOnly
    attribute :column, String, lazy: true, default: :days_homeless_plus_overrides
    attribute :translation_key, String, lazy: true, default: 'Days Homeless Plus Overrides*'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Days homeless + verified additional days'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def cast_value(val)
      val.to_i
    end

    def value(cohort_client) # OK
      cohort_client.days_homeless_plus_overrides
    end
  end
end
