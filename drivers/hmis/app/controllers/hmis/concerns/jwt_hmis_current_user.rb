###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# JWT for HMIS controllers. Provides devise-compatible methods
module Hmis::Concerns::JwtHmisCurrentUser
  extend ActiveSupport::Concern
  include Idp::JwtAuthentication

  included do
    def current_hmis_user
      @current_hmis_user ||= idp_authenticated_user_from_jwt(user_class: Hmis::User)
    end
    helper_method :current_hmis_user

    def authenticate_hmis_user!
      if current_hmis_user
        idp_schedule_user_sync
        return
      end

      # A deactivated user holds a valid IdP token
      return idp_handle_deactivated if idp_token_holder && !idp_token_holder.active?

      idp_handle_unauthenticated
    end

    def hmis_user_signed_in?
      current_hmis_user.present?
    end
    helper_method :hmis_user_signed_in?

    # The actual authenticated user from the JWT, not the impersonated user. Memoized to match the
    # Devise/pretender arm: before_actions mutate this object in place (e.g. attach_data_source_id
    # sets hmis_data_source_id), so every call within a request must return the SAME instance or the
    # mutation is lost on the throwaway find_by result and downstream policy_for raises.
    def true_hmis_user
      return nil unless current_hmis_user

      @true_hmis_user ||= begin
        impersonation_data = impersonation_manager.get
        if impersonation_data && impersonation_data[:true_user_id].present?
          Hmis::User.find_by(id: impersonation_data[:true_user_id]) || current_hmis_user
        else
          current_hmis_user
        end
      end
    end
    helper_method :true_hmis_user

    # Impersonation write-side under JWT (replaces pretender's impersonate_hmis_user). Backs the
    # session via Idp::ImpersonationManager and updates the memoized current user so the remainder of
    # *this* request reflects the impersonation (mirroring pretender's in-request behavior). The
    # authoritative authorization check is the controller's HMIS policy; subsequent requests
    # re-resolve from the session via idp_authenticated_user_from_jwt, which re-validates permissions.
    def impersonate_hmis_user(user)
      impersonation_manager.store(true_hmis_user.id, user.id)
      @current_hmis_user = user
    end

    def stop_impersonating_hmis_user
      real_user = true_hmis_user
      impersonation_manager.clear
      @current_hmis_user = real_user
    end

    private

    def session_duration_seconds
      (user_session_expires_at - Time.current).to_i
    end

    # no-op under JWT: session lifetime is governed by the IdP token, not a warehouse-side
    # inactivity timer. Some HMIS controllers prepend this as a before_action
    # (e.g. Hmis::UsersController#show), so the JWT arm must respond to it as the Devise arm does.
    def skip_timeout
      nil
    end

    # HMIS is a JSON SPA API, so the terminal pages in Idp::JwtAuthentication become JSON here.
    # render_json_error comes from Hmis::Concerns::JsonErrors (already included in
    # Hmis::BaseController).
    def idp_handle_unauthenticated
      # No 401 for a tokenless request, deliberately. This endpoint doesn't authenticate its own
      # callers, it trusts the proxy — so there is no legitimate client that arrives without a token,
      # and api_routes=["^/hmis/"] already 401s the one race the proxy knows about (a request
      # overlapping a logout) before Rails sees it. One getting through means the proxy was bypassed or
      # misconfigured, which a 401 would disguise as an ordinary signed-out client.
      raise Idp::UnauthenticatedRequestError, request.path unless idp_jwt_helper_for_request.token?

      # 403, not 401: signing in again can't produce an account, and a 401 would send the SPA to a
      # sign-in screen it would come straight back from. The SPA keys off error.type on the 403 to
      # render a terminal page (hmis-frontend apolloErrorLink.tsx -> AccountTerminalErrorDialog,
      # contract in src/modules/auth/hooks/README.md).
      render_json_error(403, :no_warehouse_account)
    end

    def idp_handle_deactivated
      render_json_error(403, :account_deactivated)
    end

    # 500, not a 4xx: the request was fine, we couldn't reach the IdP. No message — the SPA's
    # LogoutFailedDialog writes its own copy and never reads the body.
    def idp_handle_session_logout_failure
      render_json_error(500, :sign_out_failed)
    end
  end
end
