###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class ClearRecentItems < BaseMutation
    type Types::Application::User

    def resolve
      current_user.clear_recent_items
      current_user
    end
  end
end
