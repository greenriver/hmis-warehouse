###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class OngoingSh < ReadOnly
    attribute :column, String, lazy: true, default: :ongoing_sh
    attribute :translation_key, String, lazy: true, default: 'Ongoing SH Enrollments'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def description
      'Date of last service in ongoing SH enrollments'
    end

    def value(cohort_client) # OK
      return nil unless cohort_client.client.processed_service_history&.cohorts_ongoing_enrollments_sh

      # in the form [['Project Name', 'last date']]
      cohort_client.client.processed_service_history.cohorts_ongoing_enrollments_sh.
        sort do |a, b|
          b.last.to_date <=> a.last.to_date
        end.
        map do |row|
          row.join(': ')
        end.join('; ')
    end
  end
end
