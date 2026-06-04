###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Model for managing JWT token denylists.
#
# This model uses Rails.cache to maintain a blacklist of invalidated JWT tokens.
# When a token is added to the denylist via its at_hash claim, it cannot be used for authentication
# until it naturally expires at the IDP level.
#
# The denylist is used to force logout users without requiring IDP interaction.
# When a denylisted token is used, the user is redirected to a captive portal
# to sign out and re-authenticate.
#
# @example Add a token's at_hash to the denylist
#   TokenDenylist.add('token_at_hash_value', expires_at: Time.current + 12.hours)
#
# @example Check if a token's at_hash is denylisted
#   TokenDenylist.denied?('token_at_hash_value')
class TokenDenylist
  DENYLIST_PREFIX = 'token_denylist'

  # Add a token's subject to the denylist.
  #
  # @param subject [String] The token subject (sub claim) to denylist
  # @param expires_at [Time, nil] When the token expires. If provided, cache will auto-expire the key.
  def self.add(subject, expires_at: nil)
    return if subject.blank?

    key = denylist_key(subject)
    expires_in = if expires_at.present?
      ttl = (expires_at - Time.current).to_i
      ttl.positive? ? ttl : nil
    end

    Rails.cache.write(key, true, expires_in: expires_in)
  end

  # Check if a token's subject is denylisted.
  #
  # @param subject [String] The token subject (sub claim) to check
  # @return [Boolean] true if the token is denylisted, false otherwise
  def self.denied?(subject)
    return false if subject.blank?

    Rails.cache.exist?(denylist_key(subject))
  end

  # Remove a token from the denylist (mainly for testing or admin override).
  #
  # @param subject [String] The token subject (sub claim) to remove
  def self.remove(subject)
    return if subject.blank?

    Rails.cache.delete(denylist_key(subject))
  end

  private

  # Get the cache key for a denylisted token's subject.
  #
  # @param subject [String] The token subject (sub claim)
  # @return [String] The cache key
  private_class_method def self.denylist_key(subject)
    "#{DENYLIST_PREFIX}:#{subject}"
  end
end
