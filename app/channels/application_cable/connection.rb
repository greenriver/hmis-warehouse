###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user
    def connect
      self.current_user = find_verified_user
      logger.add_tags 'ActionCable', current_user.id
    end

    protected def find_verified_user
      # Try JWT authentication first
      access_token = request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN']
      if access_token.present?
        jwt_helper = JwtHelper.new(access_token: access_token)
        if jwt_helper.token? && jwt_helper.validate!
          user = User.find_from_jwt(jwt_helper)
          return user if user&.active?
        end
      end

      # Fallback to warden for backward compatibility during transition
      if env['warden']
        verified_user = env['warden'].user
        return verified_user if verified_user&.active?
      end

      reject_unauthorized_connection
    end
  end
end
