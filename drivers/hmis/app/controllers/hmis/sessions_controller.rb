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
  # Return IDP logout URL for frontend to redirect to
  def destroy
    attach_data_source_id

    # Generate logout URL for HMIS frontend
    # Flow: Frontend → Zitadel end_session → HMIS oauth2-proxy sign_out (with rd param) → HMIS root
    hmis_root_url = root_url(host: data_source.hmis)
    hmis_base_url = "#{request.scheme}://#{data_source.hmis}"

    # OAuth2-proxy sign_out URL with redirect back to HMIS root
    # The rd (redirect) parameter tells oauth2-proxy where to go after clearing the session
    oauth2_signout_url = "#{hmis_base_url}/oauth2/sign_out?rd=#{CGI.escape(hmis_root_url)}"

    # Get IDP logout URL (for Zitadel, this is the end_session endpoint)
    # Zitadel will log out the user and redirect to oauth2_signout_url
    # Pass the HMIS-specific client_id for Zitadel to validate the post_logout_redirect_uri
    idp_service = Idp::ServiceFactory.for_connector(
      current_hmis_user&.last_connector_id || cookies[:last_connector_id],
    )
    logout_url = idp_service.logout_url(
      post_logout_redirect_uri: oauth2_signout_url,
      client_id: ENV['ZITADEL_IDP_HMIS_CLIENT_ID'],
    )

    render json: { success: true, redirect_url: logout_url }, status: 200
  end
end
