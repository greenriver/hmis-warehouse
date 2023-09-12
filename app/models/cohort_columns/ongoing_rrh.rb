###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class OngoingRrh < ReadOnly
    include CohortOngoingEnrollments
    attribute :column, String, lazy: true, default: :ongoing_rrh
    attribute :translation_key, String, lazy: true, default: 'Ongoing RRH Enrollments'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }

    def description
      'Date of last service in ongoing RRH enrollments'
    end

    def value(cohort_client, user) # rubocop:disable Lint/UnusedMethodArgument
      for_display(:cohorts_ongoing_enrollments_rrh, user)
    end
  end
end
