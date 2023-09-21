###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class EtoCoordinatedEntryAssessmentScore < ReadOnly
    attribute :column, String, lazy: true, default: :eto_coordinated_entry_assessment_score
    attribute :translation_key, String, lazy: true, default: 'Coordinated Entry Assessment Score'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }

    def available_for_rules?
      false
    end

    def description
      'Most recent score from ETO'
    end

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.eto_coordinated_entry_assessment_score
    end
  end
end
