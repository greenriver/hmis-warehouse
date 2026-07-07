###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class AddRecentItem < BaseMutation
    argument :item_id, ID, required: true
    argument :item_type, Types::HmisSchema::Enums::RecentItemType, required: true
    type Types::Application::User

    def resolve(item_id:, item_type:)
      # item_type is an enum where the value is an AR class that corresponds to that type
      item = item_type.viewable_by(current_user).find_by(id: item_id)
      access_denied! unless item

      current_user.add_recent_item(item)
      current_user
    end
  end
end
