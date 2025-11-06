###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Concern for storing and retrieving redirect URLs for post-authentication redirects.
#
# Stores redirect URLs in Rails cache to survive OAuth2-proxy redirect flow.
# Also supports OAuth2-proxy's built-in `rd` query parameter mechanism.
module RedirectStorage
  extend ActiveSupport::Concern

  # Store redirect URL for the current session.
  #
  # @param url [String] URL to redirect to after authentication
  # @param session_id [String, nil] Session ID (defaults to current session ID)
  # @return [String] Cache key used for storage
  def store_redirect_url(url, session_id: nil)
    session_id ||= session&.id&.to_s
    return nil unless session_id.present?

    cache_key = redirect_cache_key(session_id)
    Rails.cache.write(cache_key, url, expires_in: redirect_ttl)
    cache_key
  rescue StandardError => e
    Rails.logger.warn("Failed to store redirect URL in cache: #{e.message}")
    nil
  end

  # Get stored redirect URL for the current session.
  #
  # @param session_id [String, nil] Session ID (defaults to current session ID)
  # @return [String, nil] Stored redirect URL or nil if not found/expired
  def get_redirect_url(session_id: nil)
    session_id ||= session&.id&.to_s
    return nil unless session_id.present?

    cache_key = redirect_cache_key(session_id)
    Rails.cache.read(cache_key)
  rescue StandardError => e
    Rails.logger.warn("Failed to get redirect URL from cache: #{e.message}")
    nil
  end

  # Clear stored redirect URL for the current session.
  #
  # @param session_id [String, nil] Session ID (defaults to current session ID)
  def clear_redirect_url(session_id: nil)
    session_id ||= session&.id&.to_s
    return unless session_id.present?

    cache_key = redirect_cache_key(session_id)
    Rails.cache.delete(cache_key)
  rescue StandardError => e
    Rails.logger.warn("Failed to clear redirect URL from cache: #{e.message}")
    nil
  end

  # Capture the original request URL for post-authentication redirect.
  #
  # Captures the full path including query parameters, but excludes:
  # - OAuth2-proxy endpoints (/oauth2/*)
  # - Sign-in/sign-out endpoints
  # - AJAX requests (returns nil)
  #
  # @return [String, nil] Original request URL or nil if should not be captured
  def capture_original_request_url
    return nil if request.xhr? # Don't capture AJAX requests
    return nil if request.path.start_with?('/oauth2/')
    return nil if request.path.in?(['/users/sign_in', '/users/sign_out', '/hmis/login', '/hmis/logout'])

    # Use full path with query string if present
    url = request.fullpath
    return nil if url.blank?

    # Store in cache as backup (in case OAuth2-proxy doesn't preserve rd parameter)
    store_redirect_url(url) if session&.id.present?

    url
  end

  private

  # Generate cache key for redirect storage.
  #
  # @param session_id [String] Session ID
  # @return [String] Cache key
  def redirect_cache_key(session_id)
    "redirect:#{session_id}"
  end

  # TTL for redirect URLs in cache (30 minutes).
  #
  # @return [ActiveSupport::Duration] TTL duration
  def redirect_ttl
    Idp::ServiceFactory.default_session_timeout
  end
end
