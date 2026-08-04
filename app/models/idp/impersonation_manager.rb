###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Manages impersonation state storage and retrieval.
#
# Stores impersonation state ({ true_user_id, impersonated_user_id }) in the Rails session,
# replacing pretender's session machinery.
#
# Whose impersonation this is gets policed upstream in Idp::JwtAuthentication, not here.
class Idp::ImpersonationManager
  attr_reader :session

  def initialize(session)
    @session = session
  end

  def store(true_user_id, impersonated_user_id)
    # Gate on nil, NOT present?: an empty ActionDispatch session responds to empty?, so a
    # fresh (unwritten) session is blank? → present? == false. The impersonation write is
    # frequently the FIRST write to the session, so present? would wrongly refuse it. A non-nil
    # session is writable regardless of whether it currently holds anything.
    return false if session.nil?

    session[:impersonation] = {
      true_user_id: true_user_id,
      impersonated_user_id: impersonated_user_id,
    }
    true
  end

  def get
    return nil if session.nil?

    data = session[:impersonation]
    return nil unless data

    # The session store may come back with string keys; normalize to symbols.
    data.symbolize_keys
  end

  def clear
    return if session.nil?

    session.delete(:impersonation)
  end
end
