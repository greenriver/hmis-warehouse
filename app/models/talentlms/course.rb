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

    delegate :get, to: :config
    delegate :post, to: :config

    scope :default, -> do
      where(default: true)
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

    def name_with_subdomain
      @name_with_subdomain ||= "#{name} - #{config.unique_name}"
    end

    def self.remove_course(course_id)
      course = Talentlms::Course.find(course_id)
      course.completed_trainings.delete_all
      course.delete
    end

    def self.collection_for_form
      Talentlms::Course.all.map { |c| [c.name_with_subdomain, c.id] }
    end
  end
end
