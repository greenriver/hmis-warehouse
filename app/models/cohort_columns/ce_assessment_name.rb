###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class CeAssessmentName < ReadOnly
    attribute :column, String, lazy: true, default: :ce_assessment_name
    attribute :translation_key, String, lazy: true, default: 'Most-Recent CE Assessment Name'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Name of the most-recent Coordinated Entry assessment for the client.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def value(cohort_client) # OK
      cohort_client.client.source_clients.map(&:most_recent_ce_assessment).
        compact.max_by(&:assessment_date)&.name
    end
  end
end
