###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class LastHomelessVisit < ReadOnly
    attribute :column, String, lazy: true, default: :last_seen
    attribute :translation_key, String, lazy: true, default: 'Last Seen'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def description
      'Date of last homeless service in ongoing enrollments'
    end

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.last_homeless_visit
    end
  end
end
