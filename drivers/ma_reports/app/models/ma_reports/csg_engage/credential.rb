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

    def post(body)
      url = URI("#{endpoint}/Import")
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      file = Multipart::Post::UploadIO.new(StringIO.new(body.to_json), 'application/json', 'test.json')

      request = Net::HTTP::Post::Multipart.new(url, file: file)
      request['import_api_key'] = import_api_key
      response = https.request(request)
      response.read_body
    end

    def delete(agency_id:, program_name:, import_keyword:)
      params = {
        'agencyId' => agency_id,
        'programName' => program_name,
        'importKeyword' => import_keyword,
      }

      url = URI("#{endpoint}/Delete")
      url.query = params.map { |key, val| [key, val].join('=') }.join('&')
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request['import_api_key'] = import_api_key
      request['delete_api_key'] = delete_api_key
      request['Content-Length'] = '0'
      response = https.request(request)
      response.read_body
    end

    def set_api_keys(import_api_key:, delete_api_key:)
      update!(apikey: [import_api_key, delete_api_key].join('|'))
    end

    protected

    def import_api_key
      apikey.split('|').first
    end

    def delete_api_key
      apikey.split('|').second
    end
  end
end
