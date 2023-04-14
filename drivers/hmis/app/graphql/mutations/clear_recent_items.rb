###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class ClearRecentItems < BaseMutation
    type Types::Application::User

    def resolve
      current_user.clear_recent_items
      current_user
    end
  end
end
