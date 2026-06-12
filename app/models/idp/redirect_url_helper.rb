###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Helper methods for redirect URL logic that requires controller context.
#
# These methods need access to `request`, `params`, and `session`, so they accept
# them as parameters. The session-keyed cache (backed by Redis) holds a backup of the
# original URL so it survives the OAuth2-proxy redirect flow even if the `rd` parameter
# is dropped; tying it to the session id keeps one session from reading another's.
module Idp::RedirectUrlHelper
  module_function

  # Resolve the post-auth redirect URL, checking sources in priority order:
  # 1. `rd` query parameter (from OAuth2-proxy), 2. Rails cache (redirect:{session_id}),
  # 3. X-Auth-Request-Redirect header, 4. user.my_root_path. Only returns safe URLs.
  def redirect_url_after_auth(params:, request:, session_id:, user: nil)
    redirect_url = params[:rd].presence || read_redirect(session_id: session_id) || request.headers['X-Auth-Request-Redirect'].presence || user&.my_root_path

    # The cached backup is single-use: once we've resolved a post-auth redirect it's
    # spent, so clear it regardless of which source won (the `rd` param short-circuits
    # the cache read above, so this also drops a stale backup in that case).
    clear_redirect(session_id: session_id)

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
    # Only capture a normal page navigation we can send the user back to after sign-in:
    # a GET (you can't redirect someone back to a POST — that also covers GraphQL), not a
    # background/AJAX request, and an HTML page (don't bounce a browser to a JSON/API URL).
    return nil unless request.get?
    return nil if request.xhr?
    return nil unless request.format.html?
    return nil if request.path.start_with?('/oauth2/')
    return nil if request.path.in?(['/users/sign_in', '/users/sign_out', '/hmis/login', '/hmis/logout'])

    url = request.fullpath
    return nil if url.blank?

    # Store in cache as backup (in case OAuth2-proxy doesn't preserve the rd parameter)
    store_redirect(session_id: session_id, url: url)

    url
  end

  def store_redirect(session_id:, url:)
    return unless session_id.present? && url.present?

    # Short TTL as a safety net; the redirect is consumed right after sign-in.
    Rails.cache.write(redirect_cache_key(session_id), url, expires_in: 10.minutes)
  end

  def read_redirect(session_id:)
    return unless session_id.present?

    Rails.cache.read(redirect_cache_key(session_id))
  end

  def clear_redirect(session_id:)
    return unless session_id.present?

    Rails.cache.delete(redirect_cache_key(session_id))
  end

  def redirect_cache_key(session_id)
    "redirect:#{session_id}"
  end
end
