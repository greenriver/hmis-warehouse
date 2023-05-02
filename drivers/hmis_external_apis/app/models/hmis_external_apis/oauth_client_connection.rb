###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'addressable/uri'

module HmisExternalApis
  # https://gitlab.com/oauth-xx/oauth2/
  OauthClientConnection = Struct.new(:client_id, :client_secret, :token_url, :headers, :scope, :base_url, keyword_init: true) do
    def get(path)
      request(:get, url_for(path))
    end

    def post(path, payload)
      request(:post, url_for(path), payload)
    end

    def patch(path, payload)
      request(:patch, url_for(path), payload)
    end

    def self.access(client_id)
      @access ||= {}
      @access[client_id]
    end

    def self.access=(payload)
      @access ||= {}
      @access[payload.client.id] = payload
    end

    private

    # normalize leading/trailing slashes
    def url_for(path)
      uri = Addressable::URI.parse(base_url)
      uri + path.strip.gsub(/\A\//, '')
    end

    def request(verb, url, payload = nil)
      result =
        case verb
        when :get
          access.get(url, headers: headers)
        when :post
          access.post(url, headers: merged_headers, body: payload.to_json)
        when :patch
          access.patch(url, headers: merged_headers, body: payload.to_json)
        else
          raise "invalid verb #{verb}"
        end

      OauthClientResult.new(
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
      )
    rescue OAuth2::Error => e
      OauthClientResult.new(
        body: result&.body || e.message,
        content_type: result&.content_type || e.response&.headers&.dig('content-type'),
        error: try_parse_json(e.message) || e.message,
        error_type: e.class.name,
        http_method: e.response.response.env.method,
        http_status: result&.status || e.response&.status,
        ip: nil,
        parsed_body: try_parse_json(result&.body),
        request_headers: e.response.response.env.request_headers,
        request_body: e.response.response.env.request_body,
        url: e.response.response.env.url.to_s,
      )
    end

    def merged_headers
      { 'Content-Type' => 'application/json' }.merge(headers || {})
    end

    def try_parse_json(str)
      return nil unless str.present?

      JSON.parse(str)
    rescue JSON::ParserError
      nil
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
      OAuth2::Client.new(client_id, client_secret, token_url: token_url)
    end
  end
end
