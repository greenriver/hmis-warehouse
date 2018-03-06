module CohortColumns
  class FirstName < ReadOnly
    attribute :column, String, lazy: true, default: :first_name
    attribute :title, String, lazy: true, default: 'First Name'

    def value(cohort_client)
      cohort_client.client.FirstName
    end

    def display_for(current_user)
      link_to_if(current_user.can_view_clients?, value(cohort_client), client_path(cohort_client.client))
    end
  end
end
