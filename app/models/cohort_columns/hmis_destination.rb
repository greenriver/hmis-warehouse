###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class HmisDestination < ReadOnly
    attribute :column, String, lazy: true, default: :hmis_destination
    attribute :translation_key, String, lazy: true, default: 'Exit Destination (HMIS)'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Projects, destinations, and dates for any exits within the last 3 months.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def value(cohort_client)
      cohort_client.client.processed_service_history&.last_exit_destination
    end
  end
end
