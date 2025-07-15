# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  # https://gitlab.com/oauth-xx/oauth2/
  class OauthClientConnection < ExternalApiConnection
    attr_accessor :client_id, :scope

    # @param creds [::GrdaWarehouse::RemoteCredential]
    def initialize(creds, connection_timeout: 5, logger: ExternalApiLogger.new)
      super(creds, connection_timeout: connection_timeout, logger: logger)
      self.client_id = creds.client_id
      self.scope = creds.oauth_scope
    end

    def self.access(client_id)
      @access ||= {}
      @access[client_id]
    end

    def self.access=(payload)
      @access ||= {}
      @access[payload.client.id] = payload
    end

    protected

    def request(verb, url, payload = nil)
      result, request_log = logger.capture(creds: creds, url: url, method: verb, payload: payload, headers: merged_headers) do
        case verb
        when :get
          access.get(url, headers: merged_headers)
        when :post
          access.post(url, headers: merged_headers, body: payload.to_json)
        when :patch
          access.patch(url, headers: merged_headers, body: payload.to_json)
        else
          raise "invalid verb #{verb}"
        end
      end

      create_result(result, verb, url, merged_headers, request_log)
    rescue OAuth2::TimeoutError, OAuth2::ConnectionError => e
      create_connection_error_result(e, request_log)
    rescue OAuth2::Error => e
      create_error_result(e, result, request_log)
    end

    private

    def merged_headers
      base_headers.merge(additional_headers || {})
    end

    # We can't cache this in redis, but we want to retain access tokens between
    # web requests.
    def access
      a = OauthClientConnection.access(client_id)

      needs_a_new_one = a.blank? || (a.present? && (a.expires_at - Time.now.to_i) < 30)

      OauthClientConnection.access = client.client_credentials.get_token(scope: scope) if needs_a_new_one

      OauthClientConnection.access(client_id)
    end

    def client
      connection_build = ->(builder) {
        # https://gitlab.com/oauth-xx/oauth2/-/blob/main/lib/oauth2/client.rb#L81
        builder.options.timeout = connection_timeout
        builder.request :url_encoded
        builder.adapter Faraday.default_adapter
      }
      OAuth2::Client.new(
        client_id,
        creds.client_secret,
        token_url: creds.token_url,
        connection_build: connection_build,
      )
    end

    def create_result(result, verb, url, merged_headers, request_log)
      # result is an OAuth2::Response
      ExternalApiResult.new(
        body: result.body,
        content_type: result.content_type,
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

    def create_error_result(exception, result, request_log)
      # exception is an OAuth2::Error, result is an OAuth2::Response or nil
      ExternalApiResult.new(
        body: result&.body || exception.message,
        content_type: result&.headers&.dig('content-type') || exception.response&.headers&.dig('content-type'),
        error: try_parse_json(exception.message) || exception.message.presence || 'Unknown Error',
        error_type: exception.class.name,
        http_method: exception.response&.response&.env&.method,
        http_status: result&.status || exception.response&.status,
        ip: nil,
        parsed_body: try_parse_json(result&.body),
        request_headers: exception.response&.response&.env&.request_headers,
        request_body: exception.response&.response&.env&.request_body,
        url: exception.response&.response&.env&.url&.to_s,
        request_log: request_log,
      )
    end
  end
end
