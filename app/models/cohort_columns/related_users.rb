module CohortColumns
  class RelatedUsers < ReadOnly
    attribute :column, String, lazy: true, default: :related_users
    attribute :title, String, lazy: true, default: 'Related Users'


    def value(cohort_client) # OK
      cohort_client.related_users
    end
  end
end
