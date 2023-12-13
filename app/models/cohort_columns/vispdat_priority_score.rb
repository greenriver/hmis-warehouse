###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class VispdatPriorityScore < ReadOnly
    attribute :column, String, lazy: true, default: :vispdat_priority_score
    attribute :translation_key, String, lazy: true, default: 'VI-SPDAT Priority Score'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'VI-SPDAT score plus additonal prioritization logic.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.vispdat_priority_score
    end
  end
end
