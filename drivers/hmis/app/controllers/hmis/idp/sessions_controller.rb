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
    #
    # Unlike ::Idp::SessionsController, #destroy keeps authenticate_hmis_user! (Hmis::BaseController
    # applies it, and this class does not skip it): the SPA recovers from a JSON 403 by hitting
    # /oauth2/sign_out itself, so there is no server-rendered dead-end page needing sign-out to work
    # without a resolvable current_user (the reason the warehouse skips the filter).
    #
    class SessionsController < Hmis::BaseController
      # The CSRF token is what guards #destroy
      def destroy
        # First: the Keycloak session, which /oauth2/sign_out never reaches. Ahead of reset_session
        # because it reads the forwarded token, and because it fails closed. Don't make it
        # best-effort. ::Idp::SessionsController#destroy is the same sequence with an HTML response.
        idp_end_token_holder_sessions

        # Second: the Rails session, so it doesn't outlive this login.
        reset_session

        # Third, once the SPA navigates to this. Relative on purpose — an absolute URL built from
        # request.base_url could be spoofed via the Host header.
        render json: { redirect_url: "/oauth2/sign_out?rd=#{CGI.escape(root_path)}" }
      rescue ::Idp::SessionLogoutRefused
        idp_handle_session_logout_failure
      end

      private

      # Deliberately doesn't call up to Hmis::BaseController's version, which resets the session
      # first. Under JWT that reset signs nobody out — the credential is the forwarded token — but it
      # drops any impersonation and strands the CSRF-Token cookie the browser holds, since
      # set_csrf_cookie is a later before_action and never runs once this one halts the chain. The
      # user's own retry of the sign-out would then fail the same way. 401 and no side effect.
      def handle_unverified_request
        render_json_error(401, :unverified_request)
      end
    end
  end
end
