###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Concern providing JWT-based current_user functionality for controllers.
#
# Re-implements Devise's current_user / authenticate_user! / user_signed_in? / true_user /
# impersonating? / warden on top of a validated JWT instead of a Devise/Warden session, so
# existing call sites keep working unchanged once a Deployment flips to JWT. The token is read
# from X-Forwarded-Access-Token, validated via Idp::JwtHelper, and resolved via User.find_or_create_from_jwt.
module Idp::CurrentUser
  extend ActiveSupport::Concern

  included do
    def current_user
      @current_user ||= idp_authenticated_user_from_jwt(user_class: User)
    end
    helper_method :current_user

    def warden
      @warden ||= Idp::WardenProxy.new(current_user, session: session)
    end

    def authenticate_user!
      # use current_user for memoized resolution to avoid a multiple calls to find_or_create_from_jwt
      idp_handle_unauthenticated unless current_user
    end

    def user_signed_in?
      current_user.present?
    end
    helper_method :user_signed_in?

    # The actual authenticated user from the JWT, not the impersonated user.
    def true_user
      return nil unless current_user

      impersonation_manager = Idp::ImpersonationManager.new(session)
      impersonation_data = impersonation_manager.get
      return current_user unless impersonation_data && impersonation_data[:true_user_id].present?

      # Use same class as current_user to ensure permissions load correctly
      true_user_record = current_user.class.find_by(id: impersonation_data[:true_user_id])
      true_user_record || current_user
    end
    helper_method :true_user

    def impersonating?
      return false unless current_user

      impersonation_manager = Idp::ImpersonationManager.new(session)
      impersonation_data = impersonation_manager.get
      return false unless impersonation_data && impersonation_data[:impersonated_user_id].present?

      impersonation_data[:impersonated_user_id] == current_user.id
    end
    helper_method :impersonating?

    # Absolute expiration timestamp of the current token, for the session-expiry modal.
    def jwt_expires_at
      jwt_helper = idp_jwt_helper_for_request
      return nil unless jwt_helper&.token? && jwt_helper.valid?

      jwt_helper.expiration_time
    end
    helper_method :jwt_expires_at

    private

    # In production/development, reads the JWT from the X-Forwarded-Access-Token header
    # (set by oauth2-proxy). In system tests, TestJwtMiddleware promotes a cookie to this header.
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

    # Resolve the authenticated user from the JWT, applying impersonation. Generic over
    # user_class so both warehouse (User) and HMIS (Hmis::User) controllers can use it.
    def idp_authenticated_user_from_jwt(user_class: User)
      jwt_helper = idp_jwt_helper_for_request
      return nil unless jwt_helper&.token? && jwt_helper.valid?

      # learn: true path — self-gates JIT creation on idp/auto_create_user and learns the
      # Authentication Source link on every request (via Idp::UserProvisioner).
      authenticated_user = User.find_or_create_from_jwt(jwt_helper)
      return nil unless authenticated_user

      # Set the cookie so the sign-in page can route a logged-out user back to the right
      # Connector (the DB last_connector_id is unreadable when there's no current_user).
      cookies.permanent[:last_connector_id] = jwt_helper.connector_id if jwt_helper.connector_id.present?

      # find_or_create_from_jwt can hand back a plain User even when the caller wants an
      # Hmis::User, so re-fetch by id as the requested class. Both use the users table — same row.
      user = user_class == User ? authenticated_user : user_class.find_by(id: authenticated_user.id)
      return nil unless user

      impersonation_manager = Idp::ImpersonationManager.new(session)
      impersonation_data = impersonation_manager.get
      if impersonation_data && impersonation_data[:impersonated_user_id].present?
        # Only honor impersonation for the person who started it. If the logged-in user
        # (from the token) isn't the stored true_user, this is a leftover session from an
        # earlier sign-in on this browser — ignore it.
        if impersonation_data[:true_user_id] != authenticated_user.id
          impersonation_manager.clear
          return user
        end

        # Validate permissions on every request, using user_class for both users so
        # permissions load correctly (both User in warehouse, both Hmis::User in HMIS).
        true_user = user_class.find_by(id: impersonation_data[:true_user_id])
        impersonated_user = user_class.find_by(id: impersonation_data[:impersonated_user_id])

        return impersonated_user if true_user && impersonated_user && idp_validate_impersonation_permissions(true_user, impersonated_user)

        # Clear invalid impersonation
        impersonation_manager.clear
        return user
      end

      user
    end

    # Capture the original request URL and redirect to OAuth2-proxy sign-in, preserving the
    # URL via the `rd` query parameter. Override in subclasses for custom behavior (e.g. JSON).
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

    def info_for_paper_trail
      {
        user_id: current_user&.id,
        true_user_id: true_user&.id,
        session_id: session&.id&.to_s,
        request_id: request.uuid,
      }
    end

    def skip_timeout
      nil # no-op for jwt
    end

    def user_session_expires_at
      idp_jwt_helper_for_request.expiration_time
    end
    helper_method :user_session_expires_at
  end
end
