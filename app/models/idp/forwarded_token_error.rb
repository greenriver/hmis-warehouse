###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # oauth2-proxy only forwards tokens it has vouched for, so a token we refused is our stack
  # disagreeing with itself (wrong OIDC client, an opaque token where we want a JWT, a token that
  # isn't ours) rather than a signed-out user. Uncaught on purpose: the 500 is the point, and
  # sentry-rails attaches the request context. See Idp::JwtAuthentication for who raises it.
  class ForwardedTokenError < StandardError
    def initialize(details)
      super("oauth2-proxy forwarded a token we refused (#{details.map { |key, value| "#{key}: #{value.inspect}" }.join(', ')})")
    end
  end
end
