module CohortColumns
  class FirstName < ReadOnly
    attribute :column, String, lazy: true, default: :first_name
    attribute :title, String, lazy: true, default: 'First Name'

    def column_editable?
      false
    end

    def renderer
      'html'
    end

    def value(cohort_client)
      cohort_client.client.FirstName
    end 

    def display_for(user)
      display_read_only(user)
    end

    def display_read_only(user)
      html = content_tag(:span, class: "hidden") do 
        value(cohort_client)
      end
      if user.can_view_clients?
        html += link_to value(cohort_client), client_path(cohort_client.client), target: '_blank'
      elsif user.can_view_client_window?
        html += link_to value(cohort_client), window_client_path(cohort_client.client), target: '_blank'
      else
        html += value(cohort_client)
      end
      html
    end
  end
end
