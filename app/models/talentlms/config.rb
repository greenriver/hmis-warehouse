###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

require 'curb'

module Talentlms
  class Config < GrdaWarehouseBase
    self.table_name = :talentlms_configs

    attr_encrypted :api_key, key: ENV['ENCRYPTION_KEY']

    # Submit a 'get' request to TalentLMS
    #
    # @param action [String] the REST endpoint name
    # @param args [Hash<String, String>] arguments to be added to the end of the URL
    # @return [JSON] results
    def get(action, args = nil)
      key = Base64.strict_encode64("#{api_key}:")
      url = generate_url(action, args)

      result = Curl.get(url) do |curl|
        curl.headers['Authorization'] = "Basic #{key}"
      end

      json = JSON.parse(result.body_str)
      error = json['error'] if json.is_a?(Hash)

      if error.present?
        raise error['message']
      else
        json
      end
    end

    # Submit a 'post' request to TalentLMS
    #
    # @param action [String] the REST endpoint name
    # @param data [Hash] the post data
    # @param args [Hash<String, String>] arguments to be added to the end of the URL
    # @return [JSON] results
    def post(action, data, args = nil)
      key = Base64.strict_encode64("#{api_key}:")
      url = generate_url(action, args)
      result = Curl.post(url, data) do |curl|
        curl.headers['Authorization'] = "Basic #{key}"
      end

      json = JSON.parse(result.body_str)
      error = json['error'] if json.is_a?(Hash)

      if error.present?
        raise error['message']
      else
        json
      end
    end

    # Generate a TalentLMS URL for this configuration.
    #
    # For example, '.../users/username:example' is returned from 'generate_url('users', {email: 'example'})'
    #
    # @param action [String] the REST endpoint name
    # @param args [Hash<String, String>] arguments to be added to the end of the URL
    # @return [String] the URL
    private def generate_url(action, args)
      url = "https://#{subdomain}.talentlms.com/api/v1/#{action}"
      if args.present?
        arguments = args.map {|k,v| "#{k}:#{v}"}.join(',')
        url = "#{url}/#{arguments}"
      end
      url
    end
  end
end