module CohortColumns
  class Integer < Base

    def default_input_type
      :integer
    end

    def display_for user
      if display_as_editable?(user, cohort_client)
        text_field(form_group, column, value: display_read_only, size: 4, type: :number, style: 'max-width: 6em;', class: 'form-control')
      else
        display_read_only
      end
    end

    def display_read_only
      value(cohort_client)
    end
    
  end
end
