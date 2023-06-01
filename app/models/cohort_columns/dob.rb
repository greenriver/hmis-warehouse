###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Dob < ReadOnly
    attribute :column, String, lazy: true, default: :dob
    attribute :translation_key, String, lazy: true, default: 'DOB'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def cast_value(val)
      val.to_date
    end

    def arel_col
      c_t[:DOB]
    end

    def value(cohort_client) # OK
      cohort_client.client.DOB
    end
  end
end
