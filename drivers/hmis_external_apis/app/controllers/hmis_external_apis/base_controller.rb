###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class BaseController < ApplicationController
    before_action :authorize_request
    # Not needed for API-key authenticated endpoints
    skip_before_action :verify_authenticity_token
    # Not needed for API-key authenticated endpoints
    skip_before_action :authenticate_user!

    prepend_before_action :skip_timeout

    private

    def internal_system
      raise 'Set in subclass'
    end

    def handle_unauthorized_error(error)
      json = {
        message: error.message,
      }
      render(status: :unauthorized, json: json)
    end

    def authorize_request
      not_authorized!('No API key provided') unless request.headers['Authorization']

      request.headers['Authorization'].match(/\A *bearer +(.+) *\z/i) do |match|
        api_key = match[1]

        not_authorized!('Authorization header not formatted correctly') unless api_key

        valid = InboundApiConfiguration.validate(api_key: api_key, internal_system: internal_system)

        not_authorized!('Invalid key or mismatched usage') unless valid
      end
    end

    def request_log
      @request_log ||= HmisExternalApis::ExternalRequestLog.create!(
        initiator: internal_system,
        url: request.original_url,
        http_method: request.method,
        request: request.raw_post,
        requested_at: Time.current,
        response: 'pending', # can't be null
      )
    end

    # render a 400 with error messages
    def respond_with_errors(errors)
      json = {
        message: 'error',
        errors: errors,
      }
      request_log.update!(response: json, http_status: 400)
      render(status: :bad_request, json: json)
    end
  end
end
