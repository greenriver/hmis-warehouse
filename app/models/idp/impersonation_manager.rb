###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Manages impersonation state storage and retrieval.
#
# Stores impersonation state ({ true_user_id, impersonated_user_id, session_id }) in the
# Rails session, replacing pretender's session machinery.
#
# The `session_id` stamp is a self-managed token (session[:impersonation_session_token]),
# NOT Rails' session.id. Under JWT the cookie-store session.id is nil during the very request
# that first writes the session — and the impersonation write IS that first write — so gating on
# session.id silently dropped the write. The self-managed token rides in the same cookie as the
# payload, so the stamp is always consistent within a session and is wiped together with the
# payload by reset_session (preserving "session changed ⇒ impersonation invalid"). The real
# cross-user guard lives upstream in Idp::JwtAuthentication#idp_authenticated_user_from_jwt.
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
      session_id: session_token,
    }
    true
  end

  def get
    return nil if session.nil?

    data = session[:impersonation]
    return nil unless data

    # The session store may come back with string keys; normalize to symbols.
    stored_data = data.symbolize_keys

    # If the session has changed, impersonation is invalid
    return nil if stored_data[:session_id] != session_token

    stored_data
  end

  def clear
    return if session.nil?

    session.delete(:impersonation)
  end

  private

  # Self-managed stamp identifying this session for impersonation. Generated on first write and
  # carried in the session cookie alongside the payload; read-only here once it exists.
  def session_token
    session[:impersonation_session_token] ||= SecureRandom.uuid
  end
end
