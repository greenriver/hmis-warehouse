###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'curb'

module Talentlms
  class Course < GrdaWarehouseBase
    self.table_name = :talentlms_courses

    has_many :completed_trainings, class_name: 'Talentlms::CompletedTraining'
    belongs_to :config, class_name: 'Talentlms::Config'

    validates :courseid, presence: true
    validate :check_configuration_is_valid

    attr_encrypted :api_key, key: ENV['ENCRYPTION_KEY'][0..31]

    # Submit a 'get' request to TalentLMS
    #
    # @param action [String] the REST endpoint name
    # @param args [Hash<String, String>] arguments to be added to the end of the URL
    # @return [JSON] results
    def get(action, args = nil)
      config.get(action, args)
    end

    # Submit a 'post' request to TalentLMS
    #
    # @param action [String] the REST endpoint name
    # @param data [Hash] the post data
    # @param args [Hash<String, String>] arguments to be added to the end of the URL
    # @return [JSON] results
    def post(action, data, args = nil)
      config.post(action, data, args)
    end

    # Validator to check this configuration is valid.
    def check_configuration_is_valid
      error = configuration_error_message
      return unless error.present?

      error = ": #{error}"
      errors.add(:courseid, error) if error.include?('course')
    end

    # Get configuration error messages from TalentLMS
    #
    # @param course_id [Integer] the id of the course
    # @return [String] validation error if the configuration is invalid
    private def configuration_error_message
      get('courses', { id: courseid })
      nil
    rescue JSON::ParserError
      "Cannot contact server #{course.subdomain}.talentlms.com"
    rescue RuntimeError => e
      e.message
    end
  end
end
