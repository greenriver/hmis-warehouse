module CohortColumns
  class RelatedUsers < Base
    attribute :column, String, lazy: true, default: :related_users
    attribute :title, String, lazy: true, default: 'Related Users'

    def default_input_type
      :read_only
    end

    def value(cohort_client)
      Rails.cache.fetch([cohort_client.client.id, :related_users], expires_at: 8.hours) do
        user_ids = cohort_client.client.user_clients.pluck(:user_id)
        User.where(id: user_ids).map(&:name).join('; ')
      end
    end
  end
end
