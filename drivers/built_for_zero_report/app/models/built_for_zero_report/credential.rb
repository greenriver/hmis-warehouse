###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'uri'
require 'net/http'
module BuiltForZeroReport
  class Credential < GrdaWarehouse::RemoteCredential
    alias_attribute :apikey, :path
    attr_accessor :bearer_token
    attr_accessor :bearer_token_expires_at
    acts_as_paranoid

    private def login
      query = 'auth/v1/token?grant_type=password'
      url = URI([endpoint, query].compact.join('/'))

      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      body = { email: username, password: password }
      headers = {
        'Content-Type' => 'application/json',
        'apikey' => apikey,
      }
      request = Net::HTTP::Post.new(url, headers)
      request.body = body.to_json
      response = https.request(request)
      parsed_response = Oj.load(response.body)
      self.bearer_token = parsed_response['access_token']
      self.bearer_token_expires_at = Time.current + parsed_response['expires_in']
    end

    def get_json(query)
      login if bearer_token.blank? || Time.current > bearer_token_expires_at
      url = URI([endpoint, query].compact.join('/'))
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Get.new(url)
      request['apikey'] = apikey
      request['Authorization: Bearer'] = bearer_token
      response = https.request(request)
      response.read_body
    end

    def get(query)
      Oj.load(get_json(query))
    end

    def post(query, body)
      login if bearer_token.blank? || Time.current > bearer_token_expires_at
      url = URI([endpoint, query].compact.join('/'))
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request['Content-Type'] = 'application/json'
      request['Ocp-Apim-Subscription-Key'] = subscriptionkey
      request['Authorization'] = "ApiKey #{apikey}"
      request.body = Oj.dump(body)
      response = https.request(request)
      response.read_body
    end
  end
end
