module Mutations
  class ClearRecentItems < BaseMutation
    type Types::HmisSchema::User

    def resolve
      current_user.clear_recent_items
      current_user
    end
  end
end
