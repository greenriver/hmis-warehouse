###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class ReadOnly < Base
    def column_editable?
      false
    end

    def default_input_type
      :read_only
    end

    def display_for(user)
      display_read_only(user)
    end

    def display_read_only(_user)
      value(cohort_client)
    end

    def text_value(cohort_client)
      value(cohort_client)
    end
  end
end
