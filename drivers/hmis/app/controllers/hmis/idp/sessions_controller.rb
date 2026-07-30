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
      # Skipped defensively: every side effect here is a sign-out, so a forged request only ever logs
      # someone out. Wider than it used to be, though — the IdP call below ends their Keycloak
      # sessions realm-wide. Only reachable from the SPA's origin, per config/initializers/cors.rb.
      skip_before_action :verify_authenticity_token, only: :destroy

      def destroy
        # First: the Keycloak session, which /oauth2/sign_out never reaches — the proxy ends its own
        # cookie and Dex's, but Dex doesn't propagate logout upstream. Ahead of reset_session because
        # it reads the forwarded token, and because it fails closed. Don't make it best-effort.
        # ::Idp::SessionsController#destroy is the same sequence with an HTML response.
        idp_end_token_holder_sessions

        # Second: the Rails session, so it doesn't outlive this login.
        reset_session

        # Third, once the SPA navigates to this. Relative on purpose — an absolute URL built from
        # request.base_url could be spoofed via the Host header.
        render json: { redirect_url: "/oauth2/sign_out?rd=#{CGI.escape(root_path)}" }
      rescue ::Idp::SessionLogoutRefused
        idp_handle_session_logout_failure
      end
    end
  end
end
