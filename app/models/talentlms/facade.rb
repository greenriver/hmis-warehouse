###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Talentlms
  class Facade
    def initialize
      @api = Config.first
    end

    # Login user to TalentLMS
    #
    # @@param user [User] the user
    # @return [String] URL to redirect user to
    def login(user)
      login = Login.find_by(user: user)
      if login.nil?
        result = create_account(user)
      else
        result = @api.post('userlogin', { login: login.login, password: login.password })
      end
      result['login_key']
    end

    # Create an account in TalentLMS for a user
    #
    # ENV['DEV_OFFSET'] can be set to an integer to prevent username collisions between development environments
    #
    # @param user [User] the user
    # @return [String] URL to redirect the user to to login
    def create_account(user)
      login = "#{ENV['RAILS_ENV']}_#{user.id + Integer(ENV.fetch('DEV_OFFSET', 0))}"
      password = random_password
      server_domain = ENV['FQDN']
      account = {
        first_name: user.first_name,
        last_name: user.last_name,
        email: "#{login}@#{server_domain}",
        login: login,
        password: password,
        restrict_email: 'on',
      }
      result = @api.post('usersignup', account)
      Login.create(user: user, login: login, password: password, lms_user_id: result['id'])

      result['login_key']
    end

    # Enroll a user in a course in TalentLMS
    #
    # @param user [User] the user
    # @param course_id [Integer] the id of the course
    def enroll(user, course_id)
      login = Login.find_by(user: user)
      return false if login.nil?

      @api.post('addusertocourse', { course_id: course_id, user_id: login.lms_user_id })
    rescue RuntimeError => e
      raise e unless e.message.include?('already enrolled')
    end

    # Reset progress for a user in a course in TalentLMS
    #
    # @param user [User] the user
    # @param course_id [Integer] the id of the course
    def reset_user_progress(user, course_id = @api.courseid)
      login = Login.find_by(user: user)
      return false if login.nil?

      @api.post('resetuserprogress', { course_id: course_id, user_id: login.lms_user_id })
    end

    # Log a completed training with the current TalentLMS course
    #
    # @param user [User] the user
    # @param completion_date [Date] the date which the training was completed
    # @param course_id [Integer] the id of the course
    # @return [CompletedTraining] the completed training data
    def log_course_completion(user, completion_date, course_id = @api.courseid)
      login = Login.find_by(user: user)
      return nil if login.nil?

      return CompletedTraining.where(login: login, config: @api, course_id: course_id, completion_date: completion_date).first_or_create
    end

    # Get course completion status in TalentLMS
    #
    # @param user [User] the user
    # @param course_id [Integer] the id of the course
    # @return [Boolean] complete if the user has completed the course
    def complete?(user, course_id = @api.courseid)
      login = Login.find_by(user: user)
      return false if login.nil?

      result = @api.get('getuserstatusincourse', { course_id: course_id, user_id: login.lms_user_id })
      result['completed_on'] if result['completion_status'] == 'Completed'
    end

    # Checks if the user's training has expired
    #
    # @param user [User] the user
    # @param verify_with_api [Boolean] call the API for the last completed date or use local data
    # @return [Boolean] true if the user's training has expired
    def training_expired?(user, verify_with_api = true)
      # Recertification is only required when a value has been set for months_to_expiration
      return false unless @api.months_to_expiration.present?

      completed_on = verify_with_api ? complete?(user, @api.courseid) : user.last_training_completed
      return false if completed_on.nil?

      return (completed_on.to_date + @api.months_to_expiration.months).past?
    end

    # Get the URL to send the user to for a course
    #
    # @param user [User] the user
    # @param course_id [Integer] the id of the course
    # @param redirect_url [String] where to send the user after course completion
    # @param logout_url [String] where to send the user after logout
    # @return [String] URL to redirect user to
    def course_url(user, course_id, redirect_url, logout_url)
      login = Login.find_by(user: user)
      return false if login.nil?

      encoded_redirect_url = Base64.strict_encode64(redirect_url)
      encoded_logout_url = Base64.strict_encode64(logout_url)
      result = @api.get('gotocourse',
                        {
                          course_id: course_id,
                          user_id: login.lms_user_id,
                          course_completed_redirect: encoded_redirect_url,
                          logout_redirect: encoded_logout_url,
                        })
      result['goto_url']
    end

    # Generate random password for talentlms user creation
    #
    # An ArgumentError is raised if the length is less than 8
    #
    # @param length [Integer] number of characters to generate
    # @return [String] randomly generated string of the requested length with at least on upper, lower, numeric, and symbol character
    def random_password(length = 16)
      raise ArgumentError 'Length must be at least 8' if length < 8

      p = SecureRandom.urlsafe_base64(length - 4)
      lower_letter = ('a'..'z').to_a.sample
      upper_letter = ('A'..'Z').to_a.sample
      number = ('0'..'9').to_a.sample
      special = (('#'..'&').to_a + (':'..'?').to_a).sample

      "#{p}#{lower_letter}#{upper_letter}#{number}#{special}".chars.shuffle.join
    end
  end
end
