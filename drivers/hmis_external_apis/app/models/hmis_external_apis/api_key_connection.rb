# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  class ApiKeyConnection < BaseConnection
    # @param creds [::GrdaWarehouse::RemoteCredentials::ApiKey]
    def initialize(creds, connection_timeout: 5, logger: BaseLogger.new)
      super(creds, connection_timeout: connection_timeout, logger: logger)
    end

    protected

    def request(verb, url, payload = nil)
      result, request_log = logger.capture(creds: creds, url: url, method: verb, payload: payload, headers: masked_headers) do
        case verb
        when :get
          client.get(url, headers: merged_headers)
        when :post
          client.post(url, headers: merged_headers, body: payload.to_json)
        when :patch
          client.patch(url, headers: merged_headers, body: payload.to_json)
        else
          raise "invalid verb #{verb}"
        end
      end

      create_result(result, verb, url, merged_headers, request_log)
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      create_connection_error_result(e, request_log)
    rescue Faraday::Error => e
      create_http_error_result(e, result, request_log)
    end

    private

    def merged_headers
      base_headers.merge(additional_headers || {}).merge('Authorization' => creds.authorization_header)
    end

    def masked_headers
      base_headers.merge(additional_headers || {}).merge('Authorization' => '[FILTERED]')
    end

    def client
      @client ||= Faraday.new do |builder|
        builder.options.timeout = connection_timeout
        builder.request :url_encoded
        builder.adapter Faraday.default_adapter
      end
    end
  end
end
