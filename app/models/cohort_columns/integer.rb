###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Integer < Base
    def default_input_type
      :integer
    end

    def display_for(user)
      if display_as_editable?(user, cohort_client)
        text_field(form_group, column, value: display_read_only(user), size: 4, type: :number, style: 'max-width: 6em;', class: "form-control #{input_class}")
      else
        display_read_only(user)
      end
    end

    def renderer
      'numeric'
    end

    def display_read_only(_user)
      value(cohort_client)
    end
  end
end
