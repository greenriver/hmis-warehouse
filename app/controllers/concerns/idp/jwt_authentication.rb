###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# This module contains JWT authentication code used by both the warehouse request layer
# (Idp::JwtCurrentUser, user_class: User) and the HMIS request layer
# (Hmis::Concerns::JwtHmisCurrentUser, user_class: Hmis::User). It reads the token from
# X-Forwarded-Access-Token, validates it using Idp::JwtHelper, resolves the user with
# User.find_or_create_from_jwt, checks the local `active` flag, and handles
# session-stored impersonation, if present.
#
# Each of the two callers uses its own method names (current_user vs current_hmis_user) and its
# own failure response format. The warehouse side uses the HTML redirect/render defaults defined
# below. The HMIS side overrides idp_handle_unauthenticated and idp_handle_deactivated to return
# JSON instead.
module Idp::JwtAuthentication
  extend ActiveSupport::Concern

  SESSION_PRINCIPAL_KEY = :idp_token_holder_id
  SESSION_SYNC_KEY = :idp_user_synced

  included do
    helper_method :user_session_expires_at
  end

  private

  # Returns the user who holds the JWT. This is resolved once per request and does not depend
  # on active state or impersonation. current_user is nil for a deactivated account, so
  # authenticate_user! uses this method to find out why. active? is defined on the base User,
  # and the row is shared with Hmis::User, so a plain User record is enough to check it.
  def idp_token_holder
    return @idp_token_holder if defined?(@idp_token_holder)

    # Set before the raise below: lograge's append_info_to_payload asks for current_user again on
    # the way out, and a second raise there escapes lograge.
    @idp_token_holder = nil

    jwt_helper = idp_jwt_helper_for_request
    case jwt_helper.invalid_reason
    when nil
      @idp_token_holder = User.find_or_create_from_jwt(jwt_helper)
    when :missing
      # The normal signed-out case: skip_auth_routes reach Rails with no header at all. Those
      # actions skip authenticate_user! and render based on current_user, so nil is the answer they
      # want.
      nil
    else
      # oauth2-proxy had already vouched for this token and we refused it, so our own stack is
      # misconfigured (wrong OIDC client, an opaque token where we want a JWT, a token that isn't
      # ours). Redirecting to a proxy that still holds a session would hand back the same token, so
      # fail loudly instead.
      raise Idp::ForwardedTokenError, jwt_helper.invalid_reason_details
    end
  end

  # In production and development, the JWT is read from the X-Forwarded-Access-Token header,
  # which is set by oauth2-proxy. In system tests, TestJwtMiddleware copies a cookie value into
  # this header instead.
  def idp_jwt_helper_for_request
    @idp_jwt_helper_for_request ||= begin
      token = request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN']

      Idp::JwtHelper.new(access_token: token)
    end
  end

  # Ends the token holder's sessions at the IDP, the one session /oauth2/sign_out doesn't reach: the
  # proxy ends Dex, but Dex doesn't propagate logout upstream.
  #
  # Uses the admin API rather than an RP-initiated logout redirect because the token is Dex's, so we
  # have no id_token_hint for Keycloak and no client of our own to name.
  #
  # This is not single logout: other apps' proxy cookies carry Dex refresh tokens that Dex renews
  # without re-checking Keycloak, so their sessions outlive this call.
  #
  # The id comes off the token rather than current_user because under impersonation current_user is
  # the impersonated user, and the impersonation-aware accessors are session-backed, so they would
  # be order-dependent against reset_session. Reading the token is also what lets this run before
  # reset_session.
  #
  # @raise [Idp::SessionLogoutRefused] the call failed, or we couldn't tell whether to make one.
  #   Either way a session may still be live, so callers fail closed. Returning means nothing to end.
  def idp_end_token_holder_sessions
    jwt_helper = idp_jwt_helper_for_request
    reason = jwt_helper.invalid_reason
    # No token means nothing to end.
    return if reason == :missing
    # Unreachable through the request layer: idp_token_holder already raised for any reason but
    # :missing. Kept as the fail-closed answer — the proxy vouched for the token, so assume a session
    # is live and that we can't tell whose.
    raise Idp::SessionLogoutRefused, "Sign-out refused: oauth2-proxy forwarded a token we refused (#{reason})" if reason

    connector_id = jwt_helper.connector_id
    connector_user_id = jwt_helper.connector_user_id
    # ::Idp::SessionsController#destroy and Hmis::Idp::SessionsController#destroy both skip their
    # authentication filter, so a token with no connector_user_id claim reaches this guard — the only
    # thing between it and logout_user_sessions(user_id: nil).
    return if connector_id.blank? || connector_user_id.blank?

    service = idp_session_logout_service(connector_id)
    # nil means resolution failed and was already reported. A service without session logout has no
    # admin API to call, so there is nothing to end.
    raise Idp::SessionLogoutRefused, "Sign-out refused: no IDP service for connector #{connector_id}" if service.nil?
    return unless service.supports_session_logout?

    begin
      # No deadline here: the service's own socket timeouts bound this, and Timeout.timeout would
      # raise at an arbitrary point in the thread, including after Keycloak ended the sessions.
      service.logout_user_sessions(user_id: connector_user_id)
    rescue StandardError => e
      Sentry.capture_exception_with_info(
        e,
        "Couldn't end IDP sessions for #{connector_id} user #{connector_user_id}; sign-out was refused",
      )
      raise Idp::SessionLogoutRefused, "Sign-out refused: #{e.class} ending IDP sessions for #{connector_id} user #{connector_user_id}"
    end

    nil
  end

  # Split out so a failure to resolve the service is reported on its own terms: the fix is ours
  # (connector config, credentials) rather than the IDP's. Callers still fail closed, since an
  # unresolvable connector tells us nothing about whether a session is live.
  #
  # @return [Idp::Service, nil] nil when resolution raised.
  def idp_session_logout_service(connector_id)
    Idp::ServiceFactory.for_connector(connector_id)
  rescue StandardError => e
    Sentry.capture_exception_with_info(
      e,
      "Couldn't resolve the IDP service for connector #{connector_id}; sign-out was refused",
    )
    nil
  end

  def idp_validate_impersonation_permissions(true_user, impersonated_user)
    return false unless true_user&.can_impersonate_users?
    return false unless impersonated_user&.impersonateable_by?(true_user)

    true
  end

  def impersonation_manager
    Idp::ImpersonationManager.new(session)
  end

  # Nothing rotates the Rails session under JWT: there is no sign-in event, and oauth2-proxy can
  # idle out without the app ever seeing a request. Left alone, the next person to sign in on this
  # browser inherits the previous one's session, including the session.id that PaperTrail,
  # Hmis::ActivityLog, lograge and Rack::Attack log against.
  #
  # Stamped with the user id rather than a token claim because oauth2-proxy refreshes the token
  # mid-session, which would otherwise reset the session on every refresh.
  def idp_sync_session_principal!(user_id)
    stamped = session[SESSION_PRINCIPAL_KEY]
    # Compared as strings so a session store that stringifies the id can't mismatch on every request
    # and reset the session continuously.
    return if stamped.to_s == user_id.to_s

    # No stamp means an anonymous visitor on a page that skips authenticate_user!, so there is no
    # previous session to clear.
    reset_session if stamped.present?

    session[SESSION_PRINCIPAL_KEY] = user_id
  end

  def idp_authenticated_user_from_jwt(user_class: User)
    # find_or_create_from_jwt provisions a user on first sign-in, and updates the Authentication
    # Source record on every request (via Idp::UserProvisioner). idp_token_holder memoizes this
    # so it only happens once per request.
    authenticated_user = idp_token_holder
    return nil unless authenticated_user

    # Ahead of the active? check on purpose: the principal is known either way, and the deactivated
    # 403 must not render on the previous user's session.
    idp_sync_session_principal!(authenticated_user.id)

    # A warehouse User that has been deactivated locally (active = false) is not allowed
    # to authenticate, even with a valid IdP token. This matches the check already done in
    # the ActionCable resolver (ApplicationCable::Connection) and the previous Devise
    # active_for_authentication? check, so deactivating an account still works under JWT.
    # authenticate_user! gets the deactivated reason from idp_token_holder.active?.
    return nil unless authenticated_user.active?

    # Set the cookie so the sign-in page can send a logged-out user back to the right
    # Connector. The last_connector_id column can't be read without a current_user.
    connector_id = idp_jwt_helper_for_request.connector_id
    cookies.permanent[:last_connector_id] = connector_id if connector_id.present?

    # find_or_create_from_jwt returns a plain User even if the caller asked for an
    # Hmis::User, so look it up again by id as the requested class. Both classes read
    # from the same users table.
    user = user_class == User ? authenticated_user : user_class.find_by(id: authenticated_user.id)
    return nil unless user

    impersonation_data = impersonation_manager.get
    if impersonation_data && impersonation_data[:impersonated_user_id].present?
      # idp_sync_session_principal! above already resets the session on a principal change. Checked
      # again here because honoring another user's impersonation escalates privileges.
      if impersonation_data[:true_user_id] != authenticated_user.id
        impersonation_manager.clear
        return user
      end

      true_user = user_class.find_by(id: impersonation_data[:true_user_id])
      impersonated_user = user_class.find_by(id: impersonation_data[:impersonated_user_id])

      # The active? check above applies to true_user (the person holding the token). It
      # is not applied to impersonated_user, since an admin may need to impersonate a
      # deactivated account to look into it.
      return impersonated_user if true_user && impersonated_user && idp_validate_impersonation_permissions(true_user, impersonated_user)

      impersonation_manager.clear
      return user
    end

    user
  end

  def idp_schedule_user_sync
    return if session[SESSION_SYNC_KEY]

    user = idp_token_holder
    return unless user

    connector_id = user.last_connector_id
    return if connector_id.blank?

    # Set before the checks below, not after: otherwise a paused or non-self-service connector
    # re-runs them on every request instead of spending its one per-session attempt.
    session[SESSION_SYNC_KEY] = true

    case user.idp_profile_source
    when :admin_api
      return unless user.email_change_enabled?
      return if Idp::SyncUserFromIdpJob.connector_paused?(connector_id)

      Idp::SyncUserFromIdpJob.perform_later(user_id: user.id)
    when :token_claims
      Idp::SyncUserFromClaimsJob.perform_later(user_id: user.id, claims: idp_profile_claims)
    end
  end

  def idp_profile_claims
    jwt_helper = idp_jwt_helper_for_request
    {
      email: jwt_helper.payload_email,
      email_verified: jwt_helper.email_verified,
      first_name: jwt_helper.first_name,
      last_name: jwt_helper.last_name,
    }
  end

  # Never redirects to sign-in. oauth2-proxy owns that, and both cases below arrive with the proxy
  # holding a live session, so bouncing them to /oauth2/sign_in would return the same request.
  def idp_handle_unauthenticated
    # No token at all — shouldn't be reachable, and ours to fix if it is, so fail loudly. See
    # Idp::UnauthenticatedRequestError for how the proxy config and route surface let it happen.
    raise Idp::UnauthenticatedRequestError, request.path unless idp_jwt_helper_for_request.token?

    # A valid token we could neither resolve nor provision an account from.
    render(template: 'errors/no_warehouse_account', status: :forbidden)
  end

  # Shown to a user whose warehouse account has been deactivated (active = false) while
  # still holding a valid IdP token. This does not redirect to sign-in, since that would just
  # loop back through the IdP. Instead it renders a 403 telling the user to contact an
  # administrator, using the default application layout (there is no layout override, and no
  # current_user to base one on). Subclasses can override this for a non-HTML response, such
  # as a JSON 403 for API/HMIS controllers, the same way as idp_handle_unauthenticated.
  def idp_handle_deactivated
    render(template: 'errors/account_deactivated', status: :forbidden)
  end

  # Shown when idp_end_token_holder_sessions raises Idp::SessionLogoutRefused. A template rather
  # than render(plain:) because sign-out is a link_to with method: :delete, so the user lands here on
  # a full page load and needs the layout and a retry link. HMIS overrides this to return JSON.
  def idp_handle_session_logout_failure
    render(template: 'errors/sign_out_failed', status: :internal_server_error)
  end

  def user_session_expires_at
    idp_jwt_helper_for_request.expiration_time
  end
end
