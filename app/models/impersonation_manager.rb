###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Manages impersonation state storage and retrieval.
#
# Stores impersonation state in the Rails session to ensure persistence across requests.
# Impersonation state includes the true user ID and impersonated user ID, allowing the
# application to track who is actually authenticated versus who is being impersonated.
# Session-based storage works reliably in all environments (development, test, production)
# without requiring a shared cache backend like Redis.
class ImpersonationManager
  attr_reader :session

  # Initialize a new ImpersonationManager instance.
  #
  # @param session [ActionDispatch::Request::Session] Rails session object or session ID (deprecated)
  def initialize(session)
    # Support both session object (preferred) and session_id (for backwards compatibility)
    @session = session.is_a?(String) ? nil : session
    @session_id = session.is_a?(String) ? session.to_s : session&.id&.to_s
  end

  # Store impersonation state.
  #
  # @param true_user_id [Integer] ID of the user who is impersonating
  # @param impersonated_user_id [Integer] ID of the user being impersonated
  # @return [Boolean] true if stored successfully
  def store(true_user_id, impersonated_user_id)
    return false unless @session_id.present?

    data = {
      true_user_id: true_user_id,
      impersonated_user_id: impersonated_user_id,
      session_id: @session_id,
    }

    # Use Rails.cache for system tests (backed by Redis), session for production
    # Cookie sessions don't persist reliably in Cuprite/system tests
    if Rails.env.test? && ENV['RUN_SYSTEM_TESTS']
      cache_key = "impersonation:#{@session_id}"
      Rails.cache.write(cache_key, data, expires_in: 12.hours)
    else
      return false unless session.present?

      session[:impersonation] = data
    end

    true
  end

  # Get stored impersonation state.
  #
  # @return [Hash, nil] Impersonation data hash or nil if not found or session changed
  # @return [Hash] Hash with keys: :true_user_id, :impersonated_user_id, :session_id
  def get
    # Use Rails.cache for system tests (backed by Redis), session for production
    if Rails.env.test? && ENV['RUN_SYSTEM_TESTS']
      cache_key = "impersonation:#{@session_id}"
      data = Rails.cache.read(cache_key)
    else
      return nil unless session.present?

      data = session[:impersonation]
    end

    return nil unless data

    # Ensure keys are symbols for consistency
    stored_data = {
      true_user_id: data[:true_user_id] || data['true_user_id'],
      impersonated_user_id: data[:impersonated_user_id] || data['impersonated_user_id'],
      session_id: data[:session_id] || data['session_id'],
    }

    # If session has changed, impersonation is invalid
    if stored_data[:session_id] != @session_id
      return nil
    end

    stored_data
  end

  # Clear stored impersonation state.
  def clear
    # Use Rails.cache for system tests, session for production
    if Rails.env.test? && ENV['RUN_SYSTEM_TESTS']
      cache_key = "impersonation:#{@session_id}"
      Rails.cache.delete(cache_key)
    else
      return unless session.present?

      session.delete(:impersonation)
    end
  end

  # Check if impersonation is active (exists and session matches).
  #
  # @return [Boolean] true if impersonation exists and session matches
  def active?
    get.present?
  end
end
