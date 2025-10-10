###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::SessionsController < Devise::SessionsController
  include Hmis::Concerns::JsonErrors
  include AuthenticatesWithTwoFactor

  # Only respond to JSON requests
  clear_respond_to
  respond_to :json

  skip_before_action :verify_signed_out_user
  prepend_before_action :begin_time_log, only: [:create]
  before_action :authenticate_with_2fa, only: [:create], if: -> { two_factor_enabled? }

  # Minimum required login processing time for ALL login attempts (seconds)
  MIN_REQ_LOGIN_TIME = 1

  # GET /hmis/login
  def new
    raise ActionController::RoutingError, 'Not Found'
  end

  # POST /hmis/login
  def create
    return failure_response(:locked) if locked_account?

    self.resource = warden.authenticate(auth_options)
    if resource
      sign_in(:hmis_user, resource)
      # Successful login activity is automatically recorded by authtrail gem via devise hooks
      clear_reset_password_state(resource)
      set_csrf_cookie
      response.headers['X-app-user-id'] = resource.id
      render json: resource.current_user_api_values
    else
      handle_failed_authentication
    end
  ensure
    # Ensure consistent response time for all login attempts to prevent timing attacks
    # that could be used to enumerate valid usernames
    end_time_log
  end

  # DELETE /hmis/logout
  def destroy
    sign_out(:hmis_user) # Only sign out of the HMIS, not the warehouse
    render json: { success: true }, status: 204
  end

  # We require a valid CSRF token on login form submission.
  # Override the devise implementation to reset the session
  # and return 401, instead of raising InvalidAuthenticityToken
  def handle_unverified_request
    reset_session
    render_json_error(401, :unverified_request)
  end

  def begin_time_log
    # Timestamp for tracking login time to help ensure that the application response time is consistent for valid/invalid usernames.
    # This helps prevent using login method time to enumerate valid vs invalid usernames
    @session_create_timestamp = Time.current
  end

  def end_time_log
    # Wait a semi-random length of time to return after a login attempt to prevent using login time analysis to enumerate valid usernames.
    # We want to make sure valid and invalid username attempts all take the same minimum amount of time to process and then add a random salt.
    return unless @session_create_timestamp

    elapsed = Time.current - @session_create_timestamp
    wait_time = MIN_REQ_LOGIN_TIME - elapsed + rand(0.5..1)
    sleep(wait_time) if wait_time.positive? && elapsed < MIN_REQ_LOGIN_TIME
  end

  private def authenticate_with_2fa
    # Set CSRF cookie for 2FA prompt response
    set_csrf_cookie
    authenticate_with_two_factor
  end

  private def find_user
    if session[:otp_user_id]
      Hmis::User.find(session[:otp_user_id])
    elsif user_params[:email]
      Hmis::User.find_by(email: user_params[:email])
    end
  end

  def prompt_for_two_factor(user, invalid_code: false)
    session[:otp_user_id] = user.id
    error_type = invalid_code ? :invalid_code : :mfa_required
    render_json_error(:forbidden, error_type)
  end

  private def user_params
    params.require(:hmis_user).permit(:email, :password, :otp_attempt, :remember_device, :device_name)
  end

  private def two_factor_enabled?
    find_user&.two_factor_enabled?
  end

  def locked_user_redirect(*)
    render_json_error(:forbidden, :account_locked)
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

  private def set_csrf_cookie
    cookies['CSRF-Token'] = form_authenticity_token
  end

  private def two_factor_resource_name
    :hmis_user
  end

  private def failure_response(type)
    render status: 401, json: { error: { type: type, message: I18n.t("devise.failure.#{type}") } }
  end

  private def handle_failed_authentication
    # This will be caught by the warden middleware and handled by the CustomAuthFailure failure app, which will render a
    # JSON response for API requests.
    # The authtrail gem will automatically record the failed login activity
    throw(:warden, scope: :hmis_user, message: :invalid)
  end

  private def clear_reset_password_state(user)
    return unless user&.reset_password_token.present?

    user.update(reset_password_token: nil, reset_password_sent_at: nil)
  end

  # If the account has been locked, show an appropriate message. We choose to show this message even if the password was
  # not a match because otherwise an attacker would be able to infer the correct password even after the account locks
  # sign_in_params is provided by devise
  private def locked_account?
    return false unless sign_in_params['email'] && sign_in_params['password']

    user = resource_class.find_for_authentication(email: sign_in_params['email'])
    user&.access_locked?
  end
end
