###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Manages impersonation state storage and retrieval.
#
# Stores impersonation state in Rails cache (backed by Redis) to prevent cookie manipulation.
# Impersonation state includes the true user ID and impersonated user ID, allowing the
# application to track who is actually authenticated versus who is being impersonated.
# Impersonation is automatically invalidated if the session changes.
class ImpersonationManager
  attr_reader :session_id

  # Initialize a new ImpersonationManager instance.
  #
  # @param session_id [String] Session ID to use for storage key
  def initialize(session_id)
    @session_id = session_id.to_s
  end

  # Store impersonation state.
  #
  # @param true_user_id [Integer] ID of the user who is impersonating
  # @param impersonated_user_id [Integer] ID of the user being impersonated
  # @return [String] Cache key used for storage
  def store(true_user_id, impersonated_user_id)
    return nil unless session_id.present?

    impersonation_data = {
      true_user_id: true_user_id,
      impersonated_user_id: impersonated_user_id,
      session_id: session_id,
    }

    Rails.cache.write(cache_key, impersonation_data, expires_in: 24.hours)
    cache_key
  end

  # Get stored impersonation state.
  #
  # @return [Hash, nil] Impersonation data hash or nil if not found or session changed
  # @return [Hash] Hash with keys: :true_user_id, :impersonated_user_id, :session_id
  def get
    return nil unless session_id.present?

    data = Rails.cache.read(cache_key)
    return nil unless data

    # Ensure keys are symbols for consistency
    stored_data = {
      true_user_id: data[:true_user_id] || data['true_user_id'],
      impersonated_user_id: data[:impersonated_user_id] || data['impersonated_user_id'],
      session_id: data[:session_id] || data['session_id'],
    }

    # If session has changed, impersonation is invalid
    return nil unless stored_data[:session_id] == session_id

    stored_data
  end

  # Clear stored impersonation state.
  def clear
    return unless session_id.present?

    Rails.cache.delete(cache_key)
  end

  # Check if impersonation is active (exists and session matches).
  #
  # @return [Boolean] true if impersonation exists and session matches
  def active?
    get.present?
  end

  private

  # Generate cache key for impersonation storage.
  #
  # @return [String] Cache key
  def cache_key
    "impersonation:#{session_id}"
  end
end
