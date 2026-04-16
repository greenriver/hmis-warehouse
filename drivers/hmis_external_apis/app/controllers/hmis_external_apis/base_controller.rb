###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

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

    # Authorizes API requests by validating the Bearer token in the Authorization header.
    # Ensures the request includes a valid API key from a properly formatted header.
    def authorize_request
      not_authorized!('No API key provided') unless request.headers['Authorization']

      # String#match with a block only runs the block when the regex matches; non-Bearer schemes
      # (e.g. Basic) must be rejected explicitly.
      match_data = request.headers['Authorization'].match(/\A *bearer +([a-z0-9\-_\.]+) *\z/i)
      not_authorized!('Authorization header not formatted correctly') unless match_data

      api_key = match_data[1]
      valid = InboundApiConfiguration.validate(api_key: api_key, internal_system: internal_system)
      not_authorized!('Invalid key or mismatched usage') unless valid
    end

    def request_log
      @request_log ||= HmisExternalApis::ExternalRequestLog.create!(
        initiator: internal_system,
        url: request.original_url,
        http_method: request.method,
        request: request.raw_post.presence || request.query_parameters&.to_json,
        requested_at: Time.current,
        response: 'pending', # can't be null
        ip: request.remote_ip,
        request_headers: inbound_request_headers_for_log,
      )
    end

    # Small allowlist of inbound headers for support tracing
    def inbound_request_headers_for_log
      {
        'Content-Type' => truncate_header_for_log(request.get_header('CONTENT_TYPE')),
        'Accept' => truncate_header_for_log(request.get_header('HTTP_ACCEPT')),
        'User-Agent' => truncate_header_for_log(request.user_agent, 512),
        'Host' => truncate_header_for_log(request.host),
        'Referer' => truncate_header_for_log(request.referer),
        'X-Forwarded-For' => truncate_header_for_log(request.get_header('HTTP_X_FORWARDED_FOR')),
        'X-Forwarded-Host' => truncate_header_for_log(request.get_header('HTTP_X_FORWARDED_HOST')),
        'X-Forwarded-Proto' => truncate_header_for_log(request.get_header('HTTP_X_FORWARDED_PROTO')),
        'X-Real-Ip' => truncate_header_for_log(request.get_header('HTTP_X_REAL_IP')),
      }.compact_blank
    end

    def truncate_header_for_log(value, max = 200)
      return if value.blank?

      value.to_s.truncate(max)
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
