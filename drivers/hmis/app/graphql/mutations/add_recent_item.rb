module Mutations
  class AddRecentItem < BaseMutation
    argument :item_id, ID, required: true
    argument :item_type, Types::HmisSchema::Enums::RecentItemType, required: true
    type Types::HmisSchema::User

    def resolve(item_id:, item_type:)
      # item_type is an enum where the value is an AR class that corresponds to that type
      item = item_type&.find(item_id)
      current_user.add_recent_item(item)
      current_user
    end
  end
end
