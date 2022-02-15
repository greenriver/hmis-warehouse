###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Ssn < ReadOnly
    attribute :column, String, lazy: true, default: :ssnumber
    attribute :translation_key, String, lazy: true, default: 'SSN'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def value(cohort_client)
      ssn(cohort_client.client.SSN)
    end
  end
end
