###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class IndividualInMostRecentEnrollment < ReadOnly
    attribute :column, String, lazy: true, default: :individual_in_most_recent_homeless_enrollment
    attribute :translation_key, String, lazy: true, default: 'Presented as Individual'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def description
      'Client presented as an individual in the most recent homeless enrollment'
    end

    def renderer
      'html'
    end

    def value(cohort_client) # OK
      checkmark_or_x(cohort_client.individual_in_most_recent_homeless_enrollment)
    end
  end
end
