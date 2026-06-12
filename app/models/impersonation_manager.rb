###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Manages impersonation state storage and retrieval.
#
# Stores impersonation state ({ true_user_id, impersonated_user_id, session_id }) in the
# Rails session, and in Rails.cache under RUN_SYSTEM_TESTS (cookie sessions don't persist
# reliably under Cuprite). Replaces pretender's session machinery.
class ImpersonationManager
  attr_reader :session

  def initialize(session)
    # Support both session object (preferred) and session_id (for backwards compatibility)
    @session = session.is_a?(String) ? nil : session
    @session_id = session.is_a?(String) ? session.to_s : session&.id&.to_s
  end

  def store(true_user_id, impersonated_user_id)
    return false unless @session_id.present?

    data = {
      true_user_id: true_user_id,
      impersonated_user_id: impersonated_user_id,
      session_id: @session_id,
    }

    # Use Rails.cache for system tests (backed by Redis), session otherwise
    if Rails.env.test? && ENV['RUN_SYSTEM_TESTS']
      cache_key = "impersonation:#{@session_id}"
      Rails.cache.write(cache_key, data, expires_in: 12.hours)
    else
      return false unless session.present?

      session[:impersonation] = data
    end

    true
  end

  def get
    data = if Rails.env.test? && ENV['RUN_SYSTEM_TESTS']
      cache_key = "impersonation:#{@session_id}"
      Rails.cache.read(cache_key)
    else
      return nil unless session.present?

      session[:impersonation]
    end
    return nil unless data

    # Ensure keys are symbols for consistency
    stored_data = {
      true_user_id: data[:true_user_id] || data['true_user_id'],
      impersonated_user_id: data[:impersonated_user_id] || data['impersonated_user_id'],
      session_id: data[:session_id] || data['session_id'],
    }

    # If the session has changed, impersonation is invalid
    return nil if stored_data[:session_id] != @session_id

    stored_data
  end

  def clear
    if Rails.env.test? && ENV['RUN_SYSTEM_TESTS']
      cache_key = "impersonation:#{@session_id}"
      Rails.cache.delete(cache_key)
    else
      return unless session.present?

      session.delete(:impersonation)
    end
  end

  def active?
    get.present?
  end
end
