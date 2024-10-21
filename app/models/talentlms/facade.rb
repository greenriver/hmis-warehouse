###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Talentlms
  class Facade
    def initialize(user)
      @user = user
      @courses = Talentlms::Course.where(default: true)
    end

    private def lms_find_user_by_id(api, id)
      result = api.post('users', { id: id })
      result
    rescue RuntimeError => e
      raise e unless e.message.include?('The requested user does not exist')
    end

    private def lms_find_user_by_email(api, email)
      result = api.post('users', { email: email })
      result
    rescue RuntimeError => e
      raise e unless e.message.include?('The requested user does not exist')
    end

    private def lms_find_user_by_username(api, username)
      result = api.post('users', { username: username })
      result
    rescue RuntimeError => e
      raise e unless e.message.include?('The requested user does not exist')
    end

    # Login username to TalentLMS
    #
    # ENV['DEV_OFFSET'] can be set to an integer to prevent username collisions between development environments
    #
    # @@param user [User] the user
    # @return [String] username to be used for generated users in TalentLMS
    def lms_username
      username = "#{ENV['RAILS_ENV']}_#{@user.id}"
      return username unless Rails.env.development?

      "#{username}_#{ENV.fetch('DEV_OFFSET', 0)}"
    end

    # email address user in TalentLMS
    #
    # @@param user [User] the user
    # @return [String] email address to be used for generated users in TalentLMS
    def lms_email
      return @user.talent_lms_email if @user.talent_lms_email.present?

      "#{lms_username}@#{ENV['FQDN']}"
    end

    # Login user to TalentLMS
    #
    # @@param user [User] the user
    # @return [String] URL to redirect user to
    def login(api)
      login = Login.find_by(config: api, user: @user)

      # We may have a local talent record for this user, but we need to run it
      # through the sync process to ensure that the email address that we have
      # on record matches the email address that TalentLMS has for this user.
      result = sync_lms_account(api, login)
      result['login_key']
    end

    def sync_lms_account(api, login)
      username = lms_username
      email_address = lms_email

      # If we have a local login record, we have a talent account id. Check here first for the talent record
      result = lms_find_user_by_id(api, login.lms_user_id) if login.present?
      # The local login record does not exist OR Talent does not have an account for this id.
      # Check for a Talent account with the assocaited email address
      result ||= lms_find_user_by_email(api, email_address)
      # Talent does not have a record associated with this email address, check the default username. If we generated an
      # account for this user prior to allowing emails to be set, we should be able to find it this way.
      result ||= lms_find_user_by_username(api, username)
      # Talent does not have a record associated with this user, create an account for them.
      result ||= create_account(api)

      # Update the talent_lms_email on the local user if it differs from the email address in TalentLMS
      @user.update!(talent_lms_email: result['email']) if result.try(:[], 'email') != @user.talent_lms_email

      # If we want to update the email in Talent to match the local account instead of updating the local email
      # address to match what we are seeing in Talent. The line below will update the account in TalentLMS.
      # Leaving this here in case we want to use this behavior.
      ## result = @api.post('edituser', { user_id: result['id'], email: email_address }) if result.present? && result['email'] != email_address

      # Make sure the local login record matches what we have identified in the Talent account.
      # With this saved, out local data will be synced with that in Talent for this user.
      create_or_update_local_login(api, result) if result.present?

      result
    end

    def create_or_update_local_login(api, lms_account_data)
      login = Login.where(config: api, user: @user).first_or_initialize
      login.login = lms_account_data['login']
      login.lms_user_id = lms_account_data['id']
      login.save! if login.changed?
    end

    # Create an account in TalentLMS for a user
    #
    # @param user [User] the user
    # @return [String] URL to redirect the user to to login
    def create_account(api)
      username = lms_username
      email_address = lms_email

      account = {
        first_name: @user.first_name,
        last_name: @user.last_name,
        email: email_address,
        login: username,
        password: random_password,
        restrict_email: 'on',
      }
      result = api.post('usersignup', account)
      result
    end

    # Enroll a user in a course in TalentLMS
    #
    # @param user [User] the user
    # @param course_id [Integer] the id of the course
    def enroll(api, course_id)
      login = Login.find_by(config: api, user: @user)
      return false if login.nil?

      course = Course.find_by(config: api, courseid: course_id)
      return false if course.nil?

      api.post('addusertocourse', { course_id: course.courseid, user_id: login.lms_user_id })
    rescue RuntimeError => e
      raise e unless e.message.include?('already enrolled')
    end

    # Reset progress for a user in a course in TalentLMS
    #
    # @param user [User] the user
    # @param course_id [Integer] the id of the course
    def reset_user_progress(api, course_id)
      login = Login.find_by(config: api, user: @user)
      return false if login.nil?

      course = Course.find_by(config: api, courseid: course_id)
      return false if course.nil?

      @api.post('resetuserprogress', { course_id: course.courseid, user_id: login.lms_user_id })
    end

    # Log a completed training with the current TalentLMS course
    #
    # @param user [User] the user
    # @param completion_date [Date] the date which the training was completed
    # @param course_id [Integer] the id of the course
    # @return [CompletedTraining] the completed training data
    def log_course_completion(api, course_id, completion_date)
      login = Login.find_by(config: api, user: @user)
      return nil if login.nil?

      course = Course.find_by(config: api, courseid: course_id)
      return false if course.nil?

      CompletedTraining.where(login: login, config: api, course_id: course, completion_date: completion_date).first_or_create
    end

    # Get course completion status in TalentLMS
    #
    # @param user [User] the user
    # @param course_id [Integer] the id of the course
    # @return [Boolean] complete if the user has completed the course
    def complete?(api, course_id)
      login = Login.find_by(config: api, user: @user)
      return nil if login.nil?

      course = Course.find_by(config: api, courseid: course_id)
      return false if course.nil?

      result = api.get('getuserstatusincourse', { course_id: course.courseid, user_id: login.lms_user_id })
      return result['completed_on'] if result['completion_status'] == 'Completed'

      false
    end

    # Checks if the user's training has expired
    #
    # @param user [User] the user
    # @param verify_with_api [Boolean] call the API for the last completed date or use local data
    # @return [Boolean] true if the user's training has expired
    def training_expired?(api, course_id, verify_with_api = true)
      login = Login.find_by(config: api, user: @user)
      return false if login.nil?

      course = Course.find_by(config: api, courseid: course_id)
      return false if course.nil?

      completed_training = CompletedTraining.find_by(course: course, login: login)

      # Recertification is only required when a value has been set for months_to_expiration
      return false unless course.months_to_expiration.present?

      completed_on = verify_with_api ? complete?(api, course.courseid) : completed_training&.completion_date
      return false if completed_on.blank?

      time_distance = if Rails.env.production? then :months else :days end
      (completed_on.to_date + course.months_to_expiration.send(time_distance)).past?
    end

    # Checks if the user requires training
    #
    # @param user [User] the user
    # @return true if the user requires training
    def training_required?(api, course_id)
      login = Login.find_by(config: api, user: @user)
      return false if login.nil?

      course = Course.find_by(config: api, courseid: course_id)
      return false if course.nil?

      completed_training = CompletedTraining.find_by(course: course, login: login)

      return unless @user.training_required?
      return true unless completed_training&.completion_date

      training_expired?(api, course_id, false)
    end

    # Get the URL to send the user to for a course
    #
    # @param user [User] the user
    # @param course_id [Integer] the id of the course
    # @param redirect_url [String] where to send the user after course completion
    # @param logout_url [String] where to send the user after logout
    # @return [String] URL to redirect user to
    def course_url(api, course_id, redirect_url, logout_url)
      login = Login.find_by(config: api, user: @user)
      return nil if login.nil?

      course = Course.find_by(config: api, courseid: course_id)
      return false if course.nil?

      encoded_redirect_url = Base64.strict_encode64(redirect_url)
      encoded_logout_url = Base64.strict_encode64(logout_url)
      result = api.get('gotocourse',
                       {
                         course_id: course.courseid,
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

    def any_training_required?
      training_required = []
      @courses.each do |course|
        training_required << training_required?(course.config, course.courseid)
      end
      training_required.any?(true)
    end
  end
end
