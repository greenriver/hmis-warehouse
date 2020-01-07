###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module CohortColumns
  class CohortBoolean < Base
    def default_input_type
      :boolean
    end

    def display_for(user)
      if display_as_editable?(user, cohort_client)
        selected = !!value(cohort_client)
        check_box(form_group, column, checked: selected, class: input_class)
      else
        display_read_only(user)
      end
    end

    def renderer
      'checkbox'
    end

    def display_read_only(_user)
      # ApplicationController.helpers.checkmark value(cohort_client)
      value(cohort_client) || false
    end
  end
end
