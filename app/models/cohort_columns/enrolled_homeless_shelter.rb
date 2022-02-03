###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class EnrolledHomelessShelter < ReadOnly
    attribute :column, String, lazy: true, default: :enrolled_homeless_shelter
    attribute :translation_key, String, lazy: true, default: 'Enrolled in sheltered homeless project (ES, TH, SH)'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def renderer
      'html'
    end

    def value(cohort_client) # OK
      checkmark_or_x text_value(cohort_client)
    end

    def text_value(cohort_client)
      cohort_client.client.processed_service_history&.enrolled_homeless_shelter
    end
  end
end
