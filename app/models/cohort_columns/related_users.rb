module CohortColumns
  class RelatedUsers < ReadOnly
    attribute :column, String, lazy: true, default: :related_users
    attribute :title, String, lazy: true, default: 'Related Users'


    def value(cohort_client) # TODO: N+1
      cohort.time_dependant_client_data[cohort_client.client_id][:related_users]
    end
  end
end
