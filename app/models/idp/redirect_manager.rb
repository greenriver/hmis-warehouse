###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Manages redirect URL storage and retrieval.
#
# Stores redirect URLs in Rails cache (backed by Redis) to survive the OAuth2-proxy
# redirect flow. URLs are tied to session ID to prevent cross-session access.
class Idp::RedirectManager
  attr_reader :session_id

  def initialize(session_id)
    @session_id = session_id.to_s
  end

  def store(url)
    return nil unless session_id.present? && url.present?

    # Reasonable TTL as a safety measure (redirects are cleared immediately after use)
    Rails.cache.write(cache_key, url, expires_in: 1.hour)
    cache_key
  end

  def get
    return nil unless session_id.present?

    Rails.cache.read(cache_key)
  end

  def clear
    return unless session_id.present?

    Rails.cache.delete(cache_key)
  end

  def active?
    get.present?
  end

  private

  def cache_key
    "redirect:#{session_id}"
  end
end
