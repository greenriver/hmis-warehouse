###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CurrentUser
  extend ActiveSupport::Concern

  included do
    include Memery
    memoize def current_user
      current_user_from(request: request)
    end

    memoize def current_user_from(request:)
      return unless jwt_helper.validate!

      email = jwt_helper.email(fetch_from_headers_or_cookies(request, 'HTTP_X_FORWARDED_USER'))
      return unless email

      User.from_jwt!(jwt_helper, request)
    end

    # Helper to parse and expose token details.
    # - NOTE: jwt_helper.validate! should always be called first
    # @return [JwtHelper]
    memoize def jwt_helper
      JwtHelper.new(access_token: fetch_from_headers_or_cookies(request, 'HTTP_X_FORWARDED_ACCESS_TOKEN'))
    end

    memoize def fetch_from_headers_or_cookies(request, name)
      request.headers[name].presence || request.cookies[name]
    end
  end
end
