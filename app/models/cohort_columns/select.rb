module CohortColumns
  class Select < Base


    def default_input_type
      :select2
    end
    
    def display_for user
      if display_as_editable?(user, cohort_client)
        select(form_group, column, available_options, {include_blank: true, selected: value(cohort_client)}, {class: ['select2', input_class]})
      else
        display_read_only
      end
    end

    def display_read_only
      value(cohort_client)
    end
  end
end
