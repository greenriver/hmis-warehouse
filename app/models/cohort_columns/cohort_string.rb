module CohortColumns
  class CohortString < Base


    def default_input_type
      :string
    end

    def display_for user
      if display_as_editable?(user, cohort_client)
        text_field(form_group, column, value: value(cohort_client), class: ['form-control', input_class])
      else
        display_read_only
      end
    end

    def display_read_only
      value(cohort_client)
    end
    
  end
end
