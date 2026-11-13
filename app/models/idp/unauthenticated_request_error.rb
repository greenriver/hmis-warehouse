###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # authenticate_user! ran on a request that carried no forwarded token at all. oauth2-proxy performs
  # the sign-in redirect itself, and the routes it does pass through unauthenticated (skip_auth_routes)
  # all declare skip_before_action :authenticate_user!, so this combination shouldn't exist. Either a
  # route was added to skip_auth_routes without the matching skip_before_action, or something reached
  # Rails without traversing the proxy.
  #
  # Uncaught on purpose: the 500 is the point, and sentry-rails attaches the request context. See
  # Idp::JwtAuthentication for who raises it.
  class UnauthenticatedRequestError < StandardError
    def initialize(path)
      super("An authenticated route was reached with no forwarded token (#{path})")
    end
  end
end
