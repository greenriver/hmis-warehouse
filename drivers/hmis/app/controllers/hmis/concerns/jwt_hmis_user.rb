###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The JWT arm for HMIS controllers — the :hmis_user-named contract that the Devise/Pretender
# macros generate today (current_hmis_user / true_hmis_user / authenticate_hmis_user! /
# hmis_user_signed_in? and the impersonation write methods), re-implemented on top of a validated
# forwarded JWT. Included into Hmis::BaseController only when AuthMethod.jwt? (the Devise arm keeps
# the pretender macro). The generic resolution machinery is shared with the warehouse arm via
# Idp::JwtAuthentication, here driven with user_class: Hmis::User (the same users row, re-fetched as
# its Hmis::User facet). Failure responses are JSON (the HMIS SPA contract), not HTML redirects.
module Hmis::Concerns::JwtHmisUser
  extend ActiveSupport::Concern
  include Idp::JwtAuthentication

  included do
    def current_hmis_user
      @current_hmis_user ||= idp_authenticated_user_from_jwt(user_class: Hmis::User)
    end
    helper_method :current_hmis_user

    def authenticate_hmis_user!
      return if current_hmis_user

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
        impersonation_manager = Idp::ImpersonationManager.new(session)
        impersonation_data = impersonation_manager.get
        if impersonation_data && impersonation_data[:true_user_id].present?
          Hmis::User.find_by(id: impersonation_data[:true_user_id]) || current_hmis_user
        else
          current_hmis_user
        end
      end
    end
    helper_method :true_hmis_user

    # Impersonation write-side under JWT (replaces pretender's impersonate_hmis_user). This is the
    # first JWT impersonation writer in the codebase — phase 08 built only the read side. Backs the
    # session via Idp::ImpersonationManager and updates the memoized current user so the remainder of
    # *this* request reflects the impersonation (mirroring pretender's in-request behavior). The
    # authoritative authorization check is the controller's HMIS policy; subsequent requests
    # re-resolve from the session via idp_authenticated_user_from_jwt, which re-validates permissions.
    def impersonate_hmis_user(user)
      Idp::ImpersonationManager.new(session).store(true_hmis_user.id, user.id)
      @current_hmis_user = user
    end

    def stop_impersonating_hmis_user
      real_user = true_hmis_user
      Idp::ImpersonationManager.new(session).clear
      @current_hmis_user = real_user
    end

    private

    # no-op under JWT: session lifetime is governed by the IdP token, not a warehouse-side
    # inactivity timer. Some HMIS controllers prepend this as a before_action
    # (e.g. Hmis::UsersController#show), so the JWT arm must respond to it as the Devise arm does.
    def skip_timeout
      nil
    end

    # HMIS is a JSON SPA API: every auth-failure path returns JSON, overriding the HTML
    # redirect/render defaults in Idp::JwtAuthentication. render_json_error comes from
    # Hmis::Concerns::JsonErrors (already included in Hmis::BaseController).
    def idp_handle_unauthenticated
      render_json_error(401, :unauthenticated)
    end

    def idp_handle_deactivated
      render_json_error(403, :account_deactivated)
    end
  end
end
