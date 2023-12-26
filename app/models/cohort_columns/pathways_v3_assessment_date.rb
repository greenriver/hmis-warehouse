###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class PathwaysV3AssessmentDate < ReadOnly
    attribute :column, String, lazy: true, default: :pathways_v3_assessment_date
    attribute :translation_key, String, lazy: true, default: 'Pathways V3 Assessment Date'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Date of the most-recent Pathways assessment for the client.'
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
      return unless GrdaWarehouse::Config.get(:cas_calculator) == 'GrdaWarehouse::CasProjectClientCalculator::Boston'

      GrdaWarehouse::Config.get(:cas_calculator).constantize.new.most_recent_pathways_assessment_for_destination(cohort_client.client)
    end
  end
end
