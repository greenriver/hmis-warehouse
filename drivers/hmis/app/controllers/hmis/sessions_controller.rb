###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Sessions controller for HMIS API.
#
# With JWT authentication, login is handled by OAuth2-proxy.
# This controller provides endpoints for the frontend to interact with authentication.
class Hmis::SessionsController < Hmis::BaseController
  include Hmis::Concerns::JsonErrors
  helper ApplicationHelper
  include CurrentUser

  skip_before_action :authenticate_hmis_user!, only: [:create]

  # Only respond to JSON requests
  respond_to :json

  # We require a valid CSRF token on login form submission.
  # Reset the session and return 401, instead of raising InvalidAuthenticityToken
  def handle_unverified_request
    reset_session
    render_json_error(401, :unverified_request)
  end

  # GET /hmis/login
  # With JWT auth, login is handled by OAuth2-proxy
  def new
    raise ActionController::RoutingError, 'Not Found'
  end

  # POST /hmis/login
  # With JWT auth, login is handled by OAuth2-proxy.
  # This endpoint returns an error indicating authentication must be done via OAuth2-proxy.
  def create
    render_json_error(401, :unauthenticated, message: 'Authentication is handled by OAuth2-proxy. Please sign in via the OAuth2-proxy endpoint.')
  end

  # DELETE /hmis/logout
  # Return oauth2-proxy logout URL for frontend to redirect to
  def destroy
    attach_data_source_id

    # Generate logout URL for HMIS frontend
    # Flow: Frontend → oauth2-proxy sign_out (with rd param) → HMIS root
    # oauth2-proxy will clear the session cookie and the user will be redirected to the homepage
    hmis_root_url = root_url(host: data_source.hmis)
    hmis_base_url = "#{request.scheme}://#{data_source.hmis}"

    # OAuth2-proxy sign_out URL with redirect back to HMIS root
    # The rd (redirect) parameter tells oauth2-proxy where to go after clearing the session
    logout_url = "#{hmis_base_url}/oauth2/sign_out?rd=#{CGI.escape(hmis_root_url)}"

    Rails.logger.info("HMIS logout: logout_url=#{logout_url}")

    render json: { success: true, redirect_url: logout_url }, status: 200
  end
end
