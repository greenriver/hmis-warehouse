module CohortColumns
  class RelatedUsers < ReadOnly
    attribute :column, String, lazy: true, default: :related_users
    attribute :translation_key, String, lazy: true, default: 'Related Users'
    attribute :title, String, lazy: true, default: -> (model, attr) { _(model.translation_key)}

    def value(cohort_client) # OK
      cohort_client.related_users
    end
  end
end
