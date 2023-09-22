###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class FirstDateHomeless < ReadOnly
    attribute :column, String, lazy: true, default: :first_date_homeless
    attribute :translation_key, String, lazy: true, default: 'First Date Homeless'
    attribute :title, String, lazy: true, default: ->(model, _attr) { Translation.translate(model.translation_key) }

    def cast_value(val)
      val.to_date
    end

    def arel_col
      wcp_t[:first_date_homeless]
    end

    def date_format
      'll'
    end

    def renderer
      'date'
    end

    def value(cohort_client) # OK
      cohort_client.client.first_homeless_date&.to_date&.to_s
    end
  end
end
