###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'uri'
require 'net/http'
module GrdaWarehouse
  class RemoteConfigs::Eccovia < GrdaWarehouse::RemoteConfig
    # Docs: https://apidoc.eccovia.com/
    alias_attribute :subscriptionkey, :username
    alias_attribute :apikey, :password

    # Note, CRQL queries are paginated at 25 by default, if more than 25 results are needed
    # and 25 results are returned, continue to fetch additional queries incrementing the page argument
    def get(query, page: nil)
      url = URI([endpoint, query].compact.join('/'))
      if page.present?
        params = Hash[URI.decode_www_form(url.query || '')].merge(pageNo: page)
        url.query = URI.encode_www_form(params)
      end
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Get.new(url)
      request['Ocp-Apim-Subscription-Key'] = subscriptionkey
      request['Authorization'] = "ApiKey #{apikey}"
      response = https.request(request)
      response.read_body
    end

    def post(query, body)
      url = URI([endpoint, query].compact.join('/'))
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Post.new(url)
      request['Content-Type'] = 'application/json'
      request['Ocp-Apim-Subscription-Key'] = subscriptionkey
      request['Authorization'] = "ApiKey #{apikey}"
      request.body = JSON.dump(body)
      response = https.request(request)
      response.read_body
    end
  end
end
