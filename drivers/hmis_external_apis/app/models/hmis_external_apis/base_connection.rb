# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class BaseConnection
    attr_accessor :creds, :additional_headers, :base_url, :connection_timeout, :logger

    def initialize(creds, connection_timeout: 5, logger: BaseLogger.new)
      self.creds = creds
      self.base_url = creds.base_url.strip.gsub(/\/*\z/, '') # normalize base_url
      self.additional_headers = creds.additional_headers
      self.connection_timeout = connection_timeout
      self.logger = logger
    end

    def get(path)
      request(:get, url_for(path))
    end

    def post(path, payload)
      request(:post, url_for(path), payload)
    end

    def patch(path, payload)
      request(:patch, url_for(path), payload)
    end

    protected

    def request(verb, url, payload = nil)
      raise NotImplementedError, 'implement in subclass'
    end

    # normalize leading/trailing slashes
    def url_for(path)
      return base_url if path.blank?

      base_url + '/' + path.strip.gsub(/\A\/*/, '')
    end

    def try_parse_json(str)
      return nil unless str.present?

      JSON.parse(str)
    rescue JSON::ParserError
      nil
    end

    def base_headers
      { 'Content-Type' => 'application/json' }
    end

    def create_result(result, verb, url, merged_headers, request_log)
      # result is either a Faraday::Response or OAuth2::Response
      BaseResult.new(
        body: result.body,
        content_type: result.respond_to?(:content_type) ? result.content_type : result.headers['content-type'],
        error: nil,
        error_type: nil,
        http_method: verb,
        http_status: result.status,
        ip: nil,
        parsed_body: try_parse_json(result.body),
        request_headers: merged_headers,
        url: url,
        request_log: request_log,
      )
    end

    def create_connection_error_result(exception, request_log)
      BaseResult.new(
        body: exception.message.presence || 'Unknown Error',
        error: try_parse_json(exception.message) || exception.message.presence || 'Unknown Error',
        error_type: exception.class.name,
        request_log: request_log,
      )
    end

    def create_http_error_result(exception, result, request_log)
      BaseResult.new(
        body: result&.body || exception.message,
        content_type: result&.content_type || exception.response&.headers&.dig('content-type'),
        error: try_parse_json(exception.message) || exception.message.presence || 'Unknown Error',
        error_type: exception.class.name,
        http_method: exception.response&.env&.method,
        http_status: result&.status || exception.response&.status,
        ip: nil,
        parsed_body: try_parse_json(result&.body),
        request_headers: exception.response&.env&.request_headers,
        request_body: exception.response&.env&.request_body,
        url: exception.response&.env&.url&.to_s,
        request_log: request_log,
      )
    end

    def create_oauth_error_result(exception, result, request_log)
      BaseResult.new(
        body: result&.body || exception.message,
        content_type: result&.content_type || exception.response&.headers&.dig('content-type'),
        error: try_parse_json(exception.message) || exception.message.presence || 'Unknown Error',
        error_type: exception.class.name,
        http_method: exception.response.response.env.method,
        http_status: result&.status || exception.response&.status,
        ip: nil,
        parsed_body: try_parse_json(result&.body),
        request_headers: exception.response.response.env.request_headers,
        request_body: exception.response.response.env.request_body,
        url: exception.response.response.env.url.to_s,
        request_log: request_log,
      )
    end
  end
end
