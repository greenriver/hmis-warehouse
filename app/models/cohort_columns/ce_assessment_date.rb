###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class CeAssessmentDate < ReadOnly
    attribute :column, String, lazy: true, default: :ce_assessment_date
    attribute :translation_key, String, lazy: true, default: 'Most-Recent CE Assessment Date'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Date of the most-recent Coordinated Entry assessment for the client.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def date_format
      'll'
    end

    def renderer
      'date'
    end

    def value(cohort_client) # OK
      cohort_client.client.source_clients.map { |sc| sc.most_recent_ce_assessment&.assessment_date }.compact.max
    end
  end
end
