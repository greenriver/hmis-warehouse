###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Users::SessionsController < Devise::SessionsController
  include AuthenticatesWithTwoFactor
  # Start the time log before other methods are called in the authentication stack so we can get the server begin time for the login attempt
  prepend_before_action :begin_time_log, only: :create
  prepend_before_action(
    :authenticate_with_two_factor,
    if: -> { action_name == 'create' && two_factor_enabled? },
  )

  # Minimum required login processing time for ALL login attempts (seconds)
  MIN_REQ_LOGIN_TIME = 2

  def begin_time_log
    # Timestamp for tracking login time to help ensure that the application response time is consistent for valid/invalid usernames.
    # This helps prevent using login method time to enumerate valid vs invalid usernames
    @session_create_timestamp = Time.current
  end

  def end_time_log
    # Wait a semi-random length of time to return after a login attempt to prevent using login time analysis to enumerate valid usernames.
    # We want to make sure valid and invalid username attempts all take the same minimum amount of time to process and then add a random salt.
    elapsed = Time.now - @session_create_timestamp
    wait_time = MIN_REQ_LOGIN_TIME - elapsed + rand(0.5..1)
    sleep(wait_time) if wait_time.positive? && elapsed < MIN_REQ_LOGIN_TIME
  end

  def create
    super do |resource|
      # User has successfully signed in, so clear any unused reset token
      resource.update(reset_password_token: nil, reset_password_sent_at: nil) if resource.reset_password_token.present?
      # Note access for external reporting
      resource.delay(queue: ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)).populate_external_reporting_permissions!
    end
  ensure
    # `super` includes a redirect on failed authentication. We want to make sure this check is captured and processed
    # from a location with access to the server's initial login timestamp.
    end_time_log
  end

  def destroy
    request.env['last_user'] = current_user

    super
  end

  def keepalive
    head :ok
  end

  def find_user
    if session[:otp_user_id]
      User.find(session[:otp_user_id])
    elsif user_params[:email]
      User.find_by(email: user_params[:email])
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :otp_attempt, :remember_device, :device_name)
  end

  def two_factor_enabled?
    find_user&.two_factor_enabled?
  end

  def training_complete?
    find_user&.training_complete?
  end

  def valid_otp_attempt?(user)
    user.validate_and_consume_otp!(clean_code)
  end

  def valid_backup_code_attempt?(user)
    user.invalidate_otp_backup_code!(clean_code)
  end

  private def clean_code
    user_params[:otp_attempt].gsub(/[^0-9a-z]/, '')
  end

  # override devise to add 'allow_other_host: true' so we can redirect to okta
  if ENV['OKTA_DOMAIN']
    def respond_to_on_destroy
      respond_to do |format|
        format.all { head :no_content }
        format.any(*navigational_formats) { redirect_to after_sign_out_path_for(resource_name), status: Devise.responder.redirect_status, allow_other_host: true }
      end
    end
  end
end
