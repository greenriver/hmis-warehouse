###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Plumbing for future JWT system/request test support.
# Not yet wired up — will be used when spec/support/jwt_authentication_helper.rb is implemented.
#
# Promotes test_jwt_token cookie to HTTP_X_FORWARDED_ACCESS_TOKEN header,
# allowing tests to inject JWT tokens via cookies that are read by
# Idp::JwtCurrentUser as if they came from oauth2-proxy.
# See also: spec/support/jwt_helper_test_extensions.rb (validation bypass for mock tokens)
if Rails.env.test?
  class TestJwtMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      cookie_header = env['HTTP_COOKIE']
      if cookie_header&.include?('test_jwt_token=')
        cookie_match = cookie_header.match(/test_jwt_token=([^;]+)/)
        if cookie_match
          token = cookie_match[1]
          env['HTTP_X_FORWARDED_ACCESS_TOKEN'] = token
        end
      end

      @app.call(env)
    end
  end

  Rails.application.config.middleware.insert_before(
    ActionDispatch::Cookies,
    TestJwtMiddleware,
  )
end
