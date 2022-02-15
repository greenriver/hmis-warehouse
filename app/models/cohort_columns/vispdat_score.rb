###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class VispdatScore < ReadOnly
    attribute :column, String, lazy: true, default: :vispdat_score
    attribute :translation_key, String, lazy: true, default: 'VI-SPDAT Score'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.vispdat_score
    end
  end
end
