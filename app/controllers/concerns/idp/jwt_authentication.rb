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

    @idp_token_holder = begin
      jwt_helper = idp_jwt_helper_for_request
      jwt_helper&.token? && jwt_helper.valid? ? User.find_or_create_from_jwt(jwt_helper) : nil
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

  def idp_validate_impersonation_permissions(true_user, impersonated_user)
    return false unless true_user&.can_impersonate_users?
    return false unless impersonated_user&.impersonateable_by?(true_user)

    true
  end

  # Memoized per request. The manager does not cache anything itself (it reads the session
  # again on every call to #get), so it is fine to reuse one instance for store/get/clear
  # within a single request.
  def impersonation_manager
    @impersonation_manager ||= Idp::ImpersonationManager.new(session)
  end

  def idp_authenticated_user_from_jwt(user_class: User)
    # find_or_create_from_jwt only creates a user if idp/auto_create_user is set, and it
    # updates the Authentication Source record on every request (via Idp::UserProvisioner).
    # idp_token_holder memoizes this so it only happens once per request.
    authenticated_user = idp_token_holder
    return nil unless authenticated_user

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
      # Only apply impersonation if the current token belongs to the user who started it.
      # If it doesn't match the stored true_user, this is a leftover session from an
      # earlier sign-in on this browser, so it is ignored.
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

  def idp_handle_unauthenticated
    original_url = Idp::PostAuthRedirect.new(
      request: request,
      cookies: cookies,
    ).capture
    # No current_user here (that's why we're unauthenticated), so the connector comes
    # from the cookie oauth2-proxy set on the last sign-in.
    redirect_to Idp::Oauth2ProxySignInPath.call(
      connector_id: cookies[:last_connector_id],
      redirect_to: original_url,
    )
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

  def user_session_expires_at
    idp_jwt_helper_for_request.expiration_time
  end
end
