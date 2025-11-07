###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Manages redirect URL storage and retrieval.
#
# Stores redirect URLs in Rails cache (backed by Redis) to survive OAuth2-proxy redirect flow.
# Redirect URLs are tied to session ID to prevent cross-session access.
class RedirectManager
  attr_reader :session_id

  # Initialize a new RedirectManager instance.
  #
  # @param session_id [String] Session ID to use for storage key
  def initialize(session_id)
    @session_id = session_id.to_s
  end

  # Store redirect URL.
  #
  # @param url [String] URL to redirect to after authentication
  # @return [String] Cache key used for storage
  def store(url)
    return nil unless session_id.present? && url.present?

    # Use a reasonable TTL as safety measure (redirects are cleared immediately after use)
    Rails.cache.write(cache_key, url, expires_in: 1.hour)
    cache_key
  end

  # Get stored redirect URL.
  #
  # @return [String, nil] Stored redirect URL or nil if not found/expired
  def get
    return nil unless session_id.present?

    Rails.cache.read(cache_key)
  end

  # Clear stored redirect URL.
  def clear
    return unless session_id.present?

    Rails.cache.delete(cache_key)
  end

  # Check if redirect URL exists.
  #
  # @return [Boolean] true if redirect URL exists, false otherwise
  def active?
    get.present?
  end

  private

  # Generate cache key for redirect storage.
  #
  # @return [String] Cache key
  def cache_key
    "redirect:#{session_id}"
  end
end
