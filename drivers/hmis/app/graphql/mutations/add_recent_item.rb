###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class AddRecentItem < BaseMutation
    argument :item_id, ID, required: true
    argument :item_type, Types::HmisSchema::Enums::RecentItemType, required: true
    type Types::Application::User

    def resolve(item_id:, item_type:)
      # item_type is an enum where the value is an AR class that corresponds to that type
      item = item_type&.find(item_id)
      current_user.add_recent_item(item)
      current_user
    end
  end
end
