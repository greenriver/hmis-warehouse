###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class OngoingTh < ReadOnly
    include CohortOngoingEnrollments
    attribute :column, String, lazy: true, default: :ongoing_th
    attribute :translation_key, String, lazy: true, default: 'Ongoing TH Enrollments'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Date of last service in ongoing TH enrollments'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def value(cohort_client, user) # rubocop:disable Lint/UnusedMethodArgument
      for_display(:cohorts_ongoing_enrollments_th, user)
    end
  end
end
