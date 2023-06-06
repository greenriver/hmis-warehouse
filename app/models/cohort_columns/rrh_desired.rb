###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class RrhDesired < ReadOnly
    attribute :column, String, lazy: true, default: :rrh_desired
    attribute :title, String, lazy: true, default: 'Interested in RRH'

    def cast_value(val)
      val.to_s == 'true'
    end

    def arel_col
      c_t[:rrh_desired]
    end

    def renderer
      'html'
    end

    def value(cohort_client) # OK
      checkmark_or_x text_value(cohort_client)
    end

    def text_value(cohort_client)
      cohort_client.client.rrh_desired
    end
  end
end
