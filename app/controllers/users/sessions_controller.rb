###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Users::SessionsController < ApplicationController
  # Skip authentication for these actions since they're handled by OAuth2-proxy
  skip_before_action :authenticate_user!, only: [:new, :create]

  # GET /users/sign_in
  # With JWT auth, login is handled by OAuth2-proxy
  def new
    redirect_to helpers.oauth2_sign_in_path
  end

  # POST /users/sign_in
  # With JWT auth, login is handled by OAuth2-proxy
  def create
    redirect_to helpers.oauth2_sign_in_path
  end

  # DELETE /users/sign_out
  def destroy
    request.env['last_user'] = current_user

    # Redirect to IDP-specific logout URL
    # For Zitadel: Logs out of Zitadel → clears oauth2-proxy session → redirects to root
    # For others: Clears oauth2-proxy session → redirects to root
    redirect_to helpers.idp_logout_url(user: current_user, final_redirect_uri: root_url), allow_other_host: true
  end

  # POST /session_keepalive
  # Extends the session by triggering OAuth2-proxy to refresh the JWT token.
  # OAuth2-proxy will automatically refresh the token if a refresh token is available.
  # Returns the new expiration time so the frontend can update its countdown.
  def keepalive
    access_token = request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN']
    return head :unauthorized unless access_token.present?

    jwt_helper = JwtHelper.new(access_token: access_token)
    return head :unauthorized unless jwt_helper.token? && jwt_helper.validate!

    expiration_time = jwt_helper.expiration_time
    return head :ok unless expiration_time

    # Calculate remaining seconds until expiration
    remaining_seconds = [(expiration_time - Time.current).to_i, 0].max

    respond_to do |format|
      format.json do
        render json: {
          success: true,
          expiration_time: expiration_time.to_i,
          remaining_seconds: remaining_seconds,
        }
      end
      format.all { head :ok }
    end
  end
end
