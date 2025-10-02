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
  before_action :authenticate_with_2fa, only: [:create], if: -> { two_factor_enabled? }

  # GET /hmis/login
  def new
    raise ActionController::RoutingError, 'Not Found'
  end

  # POST /hmis/login
  def create
    return failure_response(:locked) if locked_account?

    self.resource = warden.authenticate(auth_options)
    return handle_failed_authentication unless resource

    sign_in(:hmis_user, resource)
    record_login_activity_for(resource, success: true)
    set_csrf_cookie
    response.headers['X-app-user-id'] = resource&.id
    render json: resource.current_user_api_values
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

  private def authenticate_with_2fa
    set_csrf_cookie
    authenticate_with_two_factor
  end

  private def record_login_activity_for(user, success: false)
    return unless user

    LoginActivity.create!(
      user: user,
      scope: :hmis_user,
      success: success,
      ip: request.remote_ip,
      user_agent: request.user_agent,
      strategy: authentication_strategy,
    )
  end

  def find_user
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

  def user_params
    params.require(:hmis_user).permit(:email, :password, :otp_attempt, :remember_device, :device_name)
  end

  def two_factor_enabled?
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

  private def authentication_strategy
    return :otp if user_params[:otp_attempt].present?

    :password
  end

  private def handle_failed_authentication
    record_login_activity_for(find_user, success: false)
    render status: 401, json: { error: { type: :invalid, message: I18n.t('devise.failure.invalid') } }
  end

  # If the account has been locked, show an appropriate message. We choose to show this message even if the password was
  # not a match because otherwise an attacker would be able to infer the correct password even after the account locks
  private def locked_account?
    return false unless sign_in_params['email'] && sign_in_params['password']

    user = resource_class.find_for_authentication(email: sign_in_params['email'])
    user&.access_locked?
  end
end
