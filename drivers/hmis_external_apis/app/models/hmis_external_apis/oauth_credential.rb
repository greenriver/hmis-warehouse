###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis
  # https://gitlab.com/oauth-xx/oauth2/
  OauthCredential = Struct.new(:client_id, :client_secret, :token_url, :headers, :scope, keyword_init: true) do
    def get(url)
      request(:get, url)
    end

    def post(url, payload)
      request(:post, url, payload)
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

      OpenStruct.new(
        status: result.status,
        body: result.body,
        parsed_body: JSON.parse(result.body),
        error: nil,
        error_type: nil,
      )
    rescue StandardError => e
      OpenStruct.new(
        status: result&.status,
        body: result&.body,
        parsed_body: nil,
        error: e.message,
        error_type: e.class.name,
      )
    end

    # We can't cache this in redis, but we want to retain access tokens between
    # web requests.
    def access
      a = OauthCredential.access(client_id)

      needs_a_new_one = a.blank? || (a.present? && (a.expires_at - Time.now.to_i) < 30)

      OauthCredential.access = client.client_credentials.get_token(scope: scope) if needs_a_new_one

      OauthCredential.access(client_id)
    end

    def client
      OAuth2::Client.new(client_id, client_secret, token_url: token_url)
    end
  end
end
