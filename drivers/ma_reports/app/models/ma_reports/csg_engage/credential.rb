###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'uri'
require 'net/http'
require 'net/http/post/multipart'
module MaReports::CsgEngage
  class Credential < ::GrdaWarehouse::RemoteCredential
    # Docs: TODO
    alias_attribute :apikey, :password
    acts_as_paranoid

    def post(body)
      url = URI(endpoint)
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      file = Multipart::Post::UploadIO.new(StringIO.new(body.to_json), 'application/json', 'test.json')

      request = Net::HTTP::Post::Multipart.new(url, file: file)
      request['import_api_key'] = apikey
      response = https.request(request)
      response.read_body
    end
  end
end
