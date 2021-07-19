###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class OngoingSo < ReadOnly
    include CohortOngoingEnrollments
    attribute :column, String, lazy: true, default: :ongoing_so
    attribute :translation_key, String, lazy: true, default: 'Ongoing SO Enrollments'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def description
      'Date of last service in ongoing So enrollments'
    end

    def value(cohort_client, user) # rubocop:disable Lint/UnusedMethodArgument
      for_display(:cohorts_ongoing_enrollments_so, user)
    end
  end
end
