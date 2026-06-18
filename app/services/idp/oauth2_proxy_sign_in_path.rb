###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Builds oauth2-proxy's sign-in path, e.g. '/oauth2/sign_in?connector_id=keycloak&rd=/path'.
  #
  # Targets the oauth2-proxy sidecar that fronts the app under JWT auth — NOT the legacy
  # direct-to-Okta OmniAuth flow. connector_id directs the user to the correct upstream IdP;
  # callers resolve it from the user's record (logged-in) or the last_connector_id cookie
  # (logged-out). oauth2-proxy uses the `rd` query parameter to preserve the original URL
  # through the authentication flow.
  class Oauth2ProxySignInPath
    PATH = '/oauth2/sign_in'

    def self.call(connector_id: nil, redirect_to: nil)
      params = {}
      params[:connector_id] = connector_id if connector_id.present?
      params[:rd] = redirect_to if redirect_to.present?

      return PATH if params.empty?

      "#{PATH}?#{URI.encode_www_form(params)}"
    end
  end
end
