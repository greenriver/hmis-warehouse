###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class DaysSinceCasMatch < ReadOnly
    attribute :column, String, lazy: true, default: :days_since_cas_match
    attribute :translation_key, String, lazy: true, default: 'Days Since CAS Match'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

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
