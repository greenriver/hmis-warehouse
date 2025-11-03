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
class Hmis::SessionsController < ActionController::Base
  include Hmis::Concerns::JsonErrors

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
  # Redirect to OAuth2-proxy sign out
  def destroy
    # Redirect to OAuth2-proxy sign out
    # For JSON API, return success and let the frontend handle redirect
    render json: { success: true, redirect_url: '/oauth2/sign_out' }, status: 200
  end
end
