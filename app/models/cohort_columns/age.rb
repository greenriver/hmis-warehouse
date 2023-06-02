###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Age < ReadOnly
    attribute :column, String, lazy: true, default: :age
    attribute :translation_key, String, lazy: true, default: 'Age*'
    attribute :title, String, lazy: true, default: ->(model, _attr) { _(model.translation_key) }

    def cast_value(val)
      val.to_i
    end

    def arel_col
      cast(
        datepart(
          GrdaWarehouse::CohortClient,
          'YEAR',
          nf('AGE', [effective_date, c_t[:DOB]]),
        ),
        'integer',
      )
    end

    def value(cohort_client) # OK
      cohort_client.client.age_on(effective_date)
    end
  end
end
