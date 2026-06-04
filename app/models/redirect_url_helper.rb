###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Helper methods for redirect URL logic that requires controller context.
#
# These methods need access to `request`, `params`, and `session` objects
# from the controller, so they accept them as parameters.
module RedirectUrlHelper
  module_function

  # Get the redirect URL to use after authentication.
  #
  # Checks multiple sources in priority order:
  # 1. Query parameter from OAuth2-proxy (`rd` parameter)
  # 2. Rails cache key (`redirect:{session_id}`)
  # 3. OAuth2-proxy header (`X-Auth-Request-Redirect`) - if available
  # 4. User's root path (`user.my_root_path`) - if user provided
  #
  # @param params [ActionController::Parameters] Request parameters
  # @param request [ActionDispatch::Request] Request object
  # @param session_id [String, nil] Session ID
  # @param user [User, nil] User instance to get root path from (optional)
  # @return [String, nil] Redirect URL or nil if not found
  def redirect_url_after_auth(params:, request:, session_id:, user: nil)
    redirect_manager = RedirectManager.new(session_id)
    redirect_url = params[:rd].presence || redirect_manager.get || request.headers['X-Auth-Request-Redirect'].presence || user&.my_root_path

    redirect_url if redirect_url.present? && safe_redirect_url?(redirect_url, request)
  end

  # Validate that a redirect URL is safe to use.
  #
  # Ensures the URL:
  # - Is not external (same host)
  # - Is a relative path or same-origin URL
  # - Doesn't contain dangerous protocols (javascript:, data:, etc.)
  #
  # @param url [String] URL to validate
  # @param request [ActionDispatch::Request] Request object for host comparison
  # @return [Boolean] true if URL is safe, false otherwise
  def safe_redirect_url?(url, request)
    return false if url.blank?

    # Allow relative paths (starting with /)
    return true if url.start_with?('/')

    # Parse absolute URLs
    begin
      uri = URI.parse(url)
    rescue URI::InvalidURIError
      return false
    end

    # Reject dangerous protocols
    return false if ['javascript', 'data', 'vbscript'].include?(uri.scheme&.downcase)

    # Allow same-origin URLs (same host as current request)
    # Also allow URLs without a host (nil or empty string)
    return true if uri.host == request.host || uri.host.blank?

    # Reject external URLs
    false
  end

  # Capture the original request URL for post-authentication redirect.
  #
  # Captures the full path including query parameters, but excludes:
  # - OAuth2-proxy endpoints (/oauth2/*)
  # - Sign-in/sign-out endpoints
  # - AJAX requests (returns nil)
  #
  # @param request [ActionDispatch::Request] Request object
  # @param session_id [String, nil] Session ID
  # @return [String, nil] Original request URL or nil if should not be captured
  def capture_original_request_url(request:, session_id:)
    return nil if request.xhr? # Don't capture AJAX requests
    return nil if request.path.start_with?('/oauth2/')
    return nil if request.path.in?(['/users/sign_in', '/users/sign_out', '/hmis/login', '/hmis/logout'])

    # Use full path with query string if present
    url = request.fullpath
    return nil if url.blank?

    # Store in cache as backup (in case OAuth2-proxy doesn't preserve rd parameter)
    redirect_manager = RedirectManager.new(session_id)
    redirect_manager.store(url) if session_id.present?

    url
  end
end
