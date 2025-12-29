###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Test middleware for system tests only.
# Promotes test_jwt_token cookie to HTTP_X_FORWARDED_ACCESS_TOKEN header,
# allowing system tests to inject JWT tokens via cookies that are read by
# CurrentUser as if they came from oauth2-proxy.
if Rails.env.test? && (ENV['RUN_SYSTEM_TESTS'] == 'true' || ENV['RUN_RAILS_SYSTEM_TESTS'] == 'true')
  # Define middleware class
  class TestJwtMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      # Read test JWT from cookie
      cookie_header = env['HTTP_COOKIE']
      if cookie_header&.include?('test_jwt_token=')
        # Extract token from cookie string
        cookie_match = cookie_header.match(/test_jwt_token=([^;]+)/)
        if cookie_match
          token = cookie_match[1]
          # Promote to HTTP_X_FORWARDED_ACCESS_TOKEN header so CurrentUser can read it
          env['HTTP_X_FORWARDED_ACCESS_TOKEN'] = token
        end
      end

      @app.call(env)
    end
  end

  # Insert middleware into the stack
  Rails.application.config.middleware.insert_before(
    ActionDispatch::Cookies,
    TestJwtMiddleware,
  )
end
