###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class OngoingRrh < ReadOnly
    attribute :column, String, lazy: true, default: :ongoing_rrh
    attribute :translation_key, String, lazy: true, default: 'Ongoing RRH Enrollments'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def description
      'Date of last service in ongoing RRH enrollments'
    end

    def value(cohort_client) # OK
      return nil unless cohort_client.client.processed_service_history&.cohorts_ongoing_enrollments_rrh

      # in the form [['Project Name', 'last date']]
      cohort_client.client.processed_service_history.cohorts_ongoing_enrollments_rrh.
        sort do |a, b|
          b.last.to_date <=> a.last.to_date
        end.
        map do |row|
          row.join(': ')
        end.join('; ')
    end
  end
end
