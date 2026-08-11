###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  module Idp
    # Logout for AUTH_METHOD=jwt only; only mounted by the AuthMethod.jwt? arm of
    # drivers/hmis/config/routes.rb (the Devise arm keeps using Hmis::SessionsController, untouched).
    #
    # Mirrors ::Idp::SessionsController#destroy (the warehouse's JWT logout), but the SPA calls this
    # via fetch + response.json() rather than following a browser redirect, so the oauth2-proxy
    # sign-out URL comes back as a JSON field instead of an HTTP redirect.
    class SessionsController < Hmis::BaseController
      # account_deactivated / no_warehouse_account users hold a valid token but no
      # current_hmis_user; without this skip, #destroy would 403 their sign-out request.
      skip_before_action :authenticate_hmis_user!, only: [:destroy]

      def destroy
        # authenticate_hmis_user! (skipped above) would raise on a tokenless request; reproduce
        # that so idp_handle_unauthenticated (JwtHmisCurrentUser) runs rather than a login redirect.
        raise ::Idp::UnauthenticatedRequestError, request.path unless idp_jwt_helper_for_request.token?

        # Ends the Keycloak session that /oauth2/sign_out never reaches. reset_session would clear
        # the forwarded token this reads, so it runs first. Let ::Idp::SessionLogoutRefused reach
        # the rescue below — swallowing it here silently skips teardown and leaves the session live.
        idp_end_token_holder_sessions

        reset_session

        # Relative, not absolute: an absolute URL built from request.base_url could be spoofed via
        # the Host header.
        render json: { redirect_url: "/oauth2/sign_out?rd=#{CGI.escape(root_path)}" }
      rescue ::Idp::SessionLogoutRefused
        idp_handle_session_logout_failure
      end

      private

      # Overrides Hmis::BaseController's handler and skips super, which calls reset_session. Under
      # JWT, reset_session signs nobody out (the credential is the forwarded token, not the session)
      # and has two costs. It drops any active impersonation. And it strands the CSRF-Token cookie:
      # set_csrf_cookie, the before_action that refreshes that cookie, runs later in the chain, so it
      # is skipped once this handler halts the request — and the user's next sign-out attempt then
      # fails the same way. Respond 401 and leave the session untouched.
      def handle_unverified_request
        render_json_error(401, :unverified_request)
      end
    end
  end
end
