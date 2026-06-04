###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::SessionKeepalivesController < Hmis::BaseController
  # GET /hmis/session_keepalive
  # Extends the session by triggering OAuth2-proxy to refresh the JWT token.
  # oauth2-proxy intercepts GET requests and automatically refreshes the token if it's
  # within the cookie_refresh window (10m) and a refresh token is available.
  # Returns the new expiration time so the frontend can update its countdown.
  def show
    access_token = request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN']
    return head :unauthorized unless access_token.present?

    jwt_helper = JwtHelper.new(access_token: access_token)
    return head :unauthorized unless jwt_helper.token? && jwt_helper.validate!

    expiration_time = jwt_helper.expiration_time
    return head :ok unless expiration_time

    # Calculate remaining seconds until expiration
    remaining_seconds = [(expiration_time - Time.current).to_i, 0].max

    render json: {
      success: true,
      expiration_time: expiration_time.to_i,
      remaining_seconds: remaining_seconds,
    }
  end
end
