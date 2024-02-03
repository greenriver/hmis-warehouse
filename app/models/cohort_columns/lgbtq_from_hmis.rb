###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class LgbtqFromHmis < ReadOnly
    attribute :column, String, lazy: true, default: :lgbtq_from_hmis
    attribute :translation_key, String, lazy: true, default: 'Sexual Orientation (from HMIS)'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Sexual Orientation as collected from the ETO API'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.lgbtq_from_hmis
    end
  end
end
