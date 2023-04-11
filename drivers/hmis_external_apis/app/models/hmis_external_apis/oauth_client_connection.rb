###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  # https://gitlab.com/oauth-xx/oauth2/
  OauthClientConnection = Struct.new(:client_id, :client_secret, :token_url, :headers, :scope, :base_url, keyword_init: true) do
    def get(path)
      request(:get, base_url + path)
    end

    def post(path, payload)
      request(:post, base_url + path, payload)
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

    def request(verb, url, payload = nil)
      result =
        case verb
        when :get
          access.get(url, headers: headers)
        when :post
          merged_headers = {
            'Content-Type' => 'application/json',
          }.merge(headers || {})

          access.post(url, headers: merged_headers, body: payload.to_json)
        else
          raise "invalid verb #{verb}"
        end

      OauthClientResult.new(
        http_status: result.status,
        body: result.body,
        content_type: result.content_type,
        http_method: verb,
        ip: nil,
        parsed_body: JSON.parse(result.body),
        url: url,
        request_headers: merged_headers,
        error: nil,
        error_type: nil,
      )
    rescue StandardError => e
      OauthClientResult.new(
        http_status: result&.status,
        body: result&.body,
        content_type: result&.content_type,
        http_method: verb,
        ip: nil,
        parsed_body: nil,
        error: begin
                 JSON.parse(e.message)
               rescue StandardError
                 e.message
               end,
        error_type: e.class.name,
      )
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
