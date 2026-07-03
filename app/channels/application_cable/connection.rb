###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user
    def connect
      self.current_user = find_verified_user
      logger.add_tags "ActionCable", current_user.id
    end

    protected def find_verified_user
      if AuthMethod.jwt?
        access_token = request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN']
        jwt_helper = Idp::JwtHelper.new(access_token: access_token)
        if jwt_helper.valid?
          # Do not provision a new user (find_from_jwt). A WebSocket frame must not cause side effects.
          user = User.find_from_jwt(jwt_helper)
          return user if user&.active?
        end
        reject_unauthorized_connection
      elsif (verified_user = env["warden"].user)
        verified_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
