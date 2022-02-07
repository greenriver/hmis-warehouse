###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'curb'

module Talentlms
  class Config < GrdaWarehouseBase
    self.table_name = :talentlms_configs

    validates :subdomain, presence: true
    validates :api_key, presence: true
    validates :courseid, presence: true
    validate :check_configuration_is_valid

    attr_encrypted :api_key, key: ENV['ENCRYPTION_KEY'][0..31]

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
      raise error['message'] if error.present?

      json
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
      raise error['message'] if error.present?

      json
    end

    # Validator to check this configuration is valid.
    def check_configuration_is_valid
      error = configuration_error_message
      if error
        error = ": #{error}"
        errors.add(:subdomain, error) if error.include?('server')
        errors.add(:api_key, error) if error.include?('API Key')
        errors.add(:courseid, error) if error.include?('course')
      end
    end


    # Get configuration error messages from TalentLMS
    #
    # @param course_id [Integer] the id of the course
    # @return [String] validation error if the configuration is invalid
    private def configuration_error_message
      get('courses', {id: courseid})
      nil
    rescue JSON::ParserError => e
      "Cannot contact server #{subdomain}.talentlms.com"
    rescue RuntimeError => e
      e.message
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
