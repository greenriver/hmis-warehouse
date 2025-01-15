###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
    validates :config_id, presence: true
    validates :name, presence: true
    validate :check_course_dates
    validate :check_configuration_is_valid

    attr_encrypted :api_key, key: ENV['ENCRYPTION_KEY'][0..31]

    delegate :get, to: :config
    delegate :post, to: :config

    scope :default, -> do
      where(default: true)
    end

    scope :active_on_date, ->(date) do
      a_t = Talentlms::Course.arel_table
      where(a_t[:start_date].eq(nil).or(a_t[:start_date].lteq(date)).and(a_t[:end_date].eq(nil).or(a_t[:end_date].gteq(date))))
    end

    # Validator to make sure course dates are valid
    def check_course_dates
      return unless start_date.present? && end_date.present?
      return unless start_date > end_date

      errors.add(:start_date, 'Start date must be before the end date.')
      errors.add(:end_date, 'End date must be after start date.')
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
      "Cannot contact server #{config.subdomain}.talentlms.com"
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

    # Check local data for course completion by user
    def completed_by?(user)
      login = Talentlms::Login.find_by(config: config, user: user)
      return unless login # Login does not exist, user has not completed training

      Talentlms::CompletedTraining.where(login_id: login.id, course_id: id).exists?
    end

    def active_date_order_value
      [
        active? ? 0 : 1,
        start_date ? 0 : 1,
        start_date,
        end_date ? 0 : 1,
        end_date,
      ]
    end

    def active?(date = Date.today)
      return false if start_date.present? && start_date > date
      return false if end_date.present? && end_date < date

      true
    end

    def active_date_range_for_display
      return start_date if start_date.present? && end_date.present? && start_date == end_date
      return "#{start_date} through #{end_date}" if start_date.present? && end_date.present?
      return "After #{start_date}" if start_date.present?
      return "Before #{end_date}" if end_date.present?

      'Always'
    end
  end
end
