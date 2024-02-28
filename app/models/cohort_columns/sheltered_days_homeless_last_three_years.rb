###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class ShelteredDaysHomelessLastThreeYears < ReadOnly
    attribute :column, String, lazy: true, default: :sheltered_days_homeless
    attribute :translation_key, String, lazy: true, default: 'Sheltered Days Homeless in the last 3 years'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Days in ES, SH, or TH in the last 3 years with no overlapping PH after move-in date'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def cast_value(val)
      val.to_i
    end

    def value(cohort_client)
      GrdaWarehouse::Hud::Client.find_by(id: cohort_client.client_id).sheltered_days_homeless_last_three_years
    end
  end
end
