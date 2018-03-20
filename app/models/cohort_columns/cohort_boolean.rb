module CohortColumns
  class CohortBoolean < Base


    def default_input_type
      :boolean
    end

    def display_for user
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

    def display_read_only user
      # ApplicationController.helpers.checkmark value(cohort_client)
      value(cohort_client) || false
    end
    
  end
end
