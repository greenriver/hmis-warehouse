###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Individual < ReadOnly
    attribute :column, String, lazy: true, default: :individual
    attribute :translation_key, String, lazy: true, default: 'Presented as Individual'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def description
      'Client presented as an individual in the most recent enrollment'
    end

    def renderer
      'html'
    end

    def value(cohort_client) # OK
      checkmark_or_x(cohort_client.individual)
    end
  end
end
