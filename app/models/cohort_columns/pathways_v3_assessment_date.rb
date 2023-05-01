###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class PathwaysV3AssessmentDate < ReadOnly
    attribute :column, String, lazy: true, default: :pathways_v3_assessment_date
    attribute :translation_key, String, lazy: true, default: 'Pathways V3 Assessment Date'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def date_format
      'll'
    end

    def renderer
      'date'
    end

    def value(cohort_client) # OK
      GrdaWarehouse::Config.get(:cas_calculator).constantize.new.most_recent_assessment_for_destination(cohort_client.client)
    end
  end
end
