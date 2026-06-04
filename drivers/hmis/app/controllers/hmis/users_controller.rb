###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::UsersController < Hmis::BaseController
  skip_before_action :authenticate_hmis_user!, only: [:show]
  prepend_before_action :skip_timeout, only: [:show]
  before_action :clear_etag, only: [:index]

  # Endpoint to retrieve the currently logged-in user.
  #
  # This is called by the frontend on initial page load, to determine whether
  # there is a currently active session.
  #
  # Returns 401 if not authenticated, user data if authenticated.
  def show
    return render_json_error(401, :unauthenticated) unless current_hmis_user

    payload = current_hmis_user.current_user_api_values || {}
    payload[:impersonating] = impersonating?

    # Add true user info when impersonating
    if impersonating? && true_hmis_user
      payload[:trueUser] = {
        id: true_hmis_user.id.to_s,
        name: true_hmis_user.name,
      }
    end

    # Calculate session duration from JWT token expiration
    # In system tests, TestJwtMiddleware promotes test_jwt_token cookie to the header
    access_token = request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN']
    if access_token.present?
      jwt_helper = JwtHelper.new(access_token: access_token)
      if jwt_helper.token?
        validation_result = jwt_helper.validate!
        if validation_result
          expiration_time = jwt_helper.expiration_time
          if expiration_time
            # Return remaining seconds until expiration
            duration = [(expiration_time - Time.current).to_i, 0].max
            payload[:sessionDuration] = duration
          end
        end
      end
    end

    render json: payload
  end

  # clear etag to prevent caching
  def clear_etag
    response.headers['Etag'] = nil
  end
end
