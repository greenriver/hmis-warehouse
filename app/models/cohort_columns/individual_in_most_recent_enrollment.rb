###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class IndividualInMostRecentEnrollment < ReadOnly
    attribute :column, String, lazy: true, default: :individual_in_most_recent_homeless_enrollment
    attribute :translation_key, String, lazy: true, default: 'Presented as Individual'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }
    attribute :description_translation_key, String, lazy: true, default: 'Client presented as an individual (with no other household members) in the most recent homeless enrollment'
    attribute :description, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.description_translation_key) }

    def cast_value(val)
      val.to_s == 'true'
    end

    def renderer
      'html'
    end

    def value(cohort_client) # OK
      checkmark_or_x(cohort_client.individual_in_most_recent_homeless_enrollment)
    end
  end
end
