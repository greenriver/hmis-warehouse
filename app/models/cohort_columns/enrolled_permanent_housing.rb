###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class EnrolledPermanentHousing < ReadOnly
    attribute :column, String, lazy: true, default: :enrolled_permanent_housing
    attribute :translation_key, String, lazy: true, default: 'Enrolled in PH'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'True if the client has an ongoing enrollment in a Permanent Housing project regardless of move-in-date.'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def available_for_rules?
      false
    end

    def renderer
      'html'
    end

    def value(cohort_client) # OK
      checkmark_or_x text_value(cohort_client)
    end

    def text_value(cohort_client)
      cohort_client.client.processed_service_history&.enrolled_permanent_housing
    end
  end
end
