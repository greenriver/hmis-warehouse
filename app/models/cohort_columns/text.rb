###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Text < Base
    def default_input_type
      :text
    end

    def display_for(user)
      value = cohort_client.public_send(column)
      if display_as_editable?(user, cohort_client)
        text_area(form_group, column, size: '20x3', value: value, class: input_class)
      else
        display_read_only(user)
      end
    end

    def display_read_only(_user)
      value(cohort_client)
    end
  end
end
