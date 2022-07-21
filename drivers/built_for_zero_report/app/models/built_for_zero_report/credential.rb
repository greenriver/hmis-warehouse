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
    alias_attribute :community_id, :bucket
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

      headers = {
        'apikey' => apikey,
        'Authorization: Bearer' => bearer_token,
      }
      request = Net::HTTP::Get.new(url, headers)
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
      headers = {
        'Content-Type' => 'application/json',
        'apikey' => apikey,
      }
      request = Net::HTTP::Post.new(url, headers)

      request.body = Oj.dump(body)
      response = https.request(request)
      response.read_body
    end

    # Use this to determine the community_id, then save that to the credential
    def communities
      get('rest/v1/communities?select=*')
    end

    def section_ids
      @section_ids ||= get("rest/v1/subpopulations?accountid=eq.#{community_id}&select=*")
    end
  end
end
