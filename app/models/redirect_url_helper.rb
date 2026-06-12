###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Helper methods for redirect URL logic that requires controller context.
#
# These methods need access to `request`, `params`, and `session`, so they accept
# them as parameters.
module RedirectUrlHelper
  module_function

  # Resolve the post-auth redirect URL, checking sources in priority order:
  # 1. `rd` query parameter (from OAuth2-proxy), 2. Rails cache (redirect:{session_id}),
  # 3. X-Auth-Request-Redirect header, 4. user.my_root_path. Only returns safe URLs.
  def redirect_url_after_auth(params:, request:, session_id:, user: nil)
    redirect_manager = RedirectManager.new(session_id)
    redirect_url = params[:rd].presence || redirect_manager.get || request.headers['X-Auth-Request-Redirect'].presence || user&.my_root_path

    redirect_url if redirect_url.present? && safe_redirect_url?(redirect_url, request)
  end

  # Open-redirect guard: allow relative paths and same-origin URLs only; reject
  # external hosts and dangerous protocols (javascript:, data:, vbscript:).
  def safe_redirect_url?(url, request)
    return false if url.blank?

    # Reject protocol-relative ("//host") and backslash-obfuscated ("/\host", "\host")
    # URLs first — they start with a slash but browsers treat them as absolute
    # navigations to an external host, slipping past the relative-path allow below.
    return false if url.start_with?('//', '/\\', '\\')

    # Allow relative paths (starting with /)
    return true if url.start_with?('/')

    begin
      uri = URI.parse(url)
    rescue URI::InvalidURIError
      return false
    end

    return false if ['javascript', 'data', 'vbscript'].include?(uri.scheme&.downcase)

    # Allow same-origin URLs (or URLs without a host)
    return true if uri.host == request.host || uri.host.blank?

    false
  end

  # Capture the full request path for post-auth redirect, excluding OAuth2-proxy /
  # sign-in/sign-out endpoints and AJAX requests. Stores a cache backup keyed by session.
  def capture_original_request_url(request:, session_id:)
    return nil if request.xhr? # Don't capture AJAX requests
    return nil if request.path.start_with?('/oauth2/')
    return nil if request.path.in?(['/users/sign_in', '/users/sign_out', '/hmis/login', '/hmis/logout'])

    url = request.fullpath
    return nil if url.blank?

    # Store in cache as backup (in case OAuth2-proxy doesn't preserve the rd parameter)
    redirect_manager = RedirectManager.new(session_id)
    redirect_manager.store(url) if session_id.present?

    url
  end
end
