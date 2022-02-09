###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Gender < ReadOnly
    attribute :column, String, lazy: true, default: :gender
    attribute :translation_key, String, lazy: true, default: 'Gender'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def value(cohort_client) # OK
      cohort_client.client.gender
    end
  end
end
