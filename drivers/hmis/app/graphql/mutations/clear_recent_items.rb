module Mutations
  class ClearRecentItems < BaseMutation
    type [Types::HmisSchema::OmnisearchResult]

    def resolve
      current_user.clear_recent_items
      current_user.recent_items
    end
  end
end
