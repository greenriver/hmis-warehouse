###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class AvailableForMatchingInCas < ReadOnly
    attribute :column, String, lazy: true, default: :available_for_matching_in_cas
    attribute :translation_key, String, lazy: true, default: 'Available in CAS'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'True if the client is available to match in CAS because they meet the criteria used for sending clients to CAS'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def renderer
      'html'
    end

    def value(cohort_client)
      checkmark_or_x text_value(cohort_client)
    end

    # NOTE: depending on how availability is calculated, calling
    # active_in_cas? may cause N+1 queries
    def text_value(cohort_client)
      cohort_client.client.active_in_cas?
    end
  end
end
