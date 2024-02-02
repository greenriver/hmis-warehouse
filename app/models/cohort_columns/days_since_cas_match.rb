###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DaysSinceCasMatch < ReadOnly
    attribute :column, String, lazy: true, default: :days_since_cas_match
    attribute :translation_key, String, lazy: true, default: 'Days Since CAS Match'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Days elapsed since the most-recent CAS match was started.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def value(cohort_client)
      match_started_time = cohort_client.client.processed_service_history&.last_cas_match_date
      override_date = cohort_client.client.cas_match_override

      if override_date.present?
        (Date.current - override_date).to_i
      elsif match_started_time.present?
        (Date.current - match_started_time.to_date).to_i
      end
    end
  end
end
