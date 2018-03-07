module CohortColumns
  class LastName < ReadOnly
    attribute :column, String, lazy: true, default: :last_name
    attribute :title, String, lazy: true, default: 'Last Name'


    def value(cohort_client)
      cohort_client.client.LastName
    end 

    def display_for(current_user)
      link_to_if(current_user.can_view_clients?, value(cohort_client), client_path(cohort_client.client))
    end
  end
end
