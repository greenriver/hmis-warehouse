###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Age < ReadOnly
    attribute :column, String, lazy: true, default: :age
    attribute :translation_key, String, lazy: true, default: 'Age*'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def value(cohort_client) # OK
      cohort_client.client.age_on(cohort_client.cohort.effective_date || Date.current)
    end
  end
end
