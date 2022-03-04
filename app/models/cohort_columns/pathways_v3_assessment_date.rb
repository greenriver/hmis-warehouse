###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
      cohort_client.client&.most_recent_pathways_or_rrh_assessment_for_destination&.AssessmentDate&.to_date&.to_s
    end
  end
end
