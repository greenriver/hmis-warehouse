###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user
    def connect
      self.current_user = find_verified_user
      logger.add_tags "ActionCable", current_user.id
    end

    protected def find_verified_user
      if (verified_user = env["warden"].user)
        verified_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
