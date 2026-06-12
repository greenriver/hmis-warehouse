###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Manages impersonation state storage and retrieval.
#
# Stores impersonation state ({ true_user_id, impersonated_user_id, session_id }) in the
# Rails session, replacing pretender's session machinery.
class Idp::ImpersonationManager
  attr_reader :session

  def initialize(session)
    @session = session
    @session_id = session&.id&.to_s
  end

  def store(true_user_id, impersonated_user_id)
    return false unless @session_id.present?

    session[:impersonation] = {
      true_user_id: true_user_id,
      impersonated_user_id: impersonated_user_id,
      session_id: @session_id,
    }
    true
  end

  def get
    return nil unless session.present?

    data = session[:impersonation]
    return nil unless data

    # Ensure keys are symbols for consistency (the session store may stringify them).
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
    return unless session.present?

    session.delete(:impersonation)
  end
end
