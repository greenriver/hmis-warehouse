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
        if access_token.present?
          jwt_helper = Idp::JwtHelper.new(access_token: access_token)
          if jwt_helper.token? && jwt_helper.valid?
            # Read-only resolver — a WebSocket frame must not provision or write the connector link.
            user = User.find_from_jwt(jwt_helper)
            return user if user&.active?
          end
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
