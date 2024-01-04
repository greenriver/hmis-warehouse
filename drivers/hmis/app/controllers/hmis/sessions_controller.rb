###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
    # If the account has been locked, show an appropriate message. Ideally this would happen after the password is
    # validated however at that point there doesn't seem to be a way to differentiate failures for bad credentials vs
    # those due to locked accounts without performing a second validation (which could trigger unintended lockouts)
    #
    # There is a potential security issue in that this allows account emails to be enumerated
    if sign_in_params['email'] && sign_in_params['password']
      user = resource_class.find_for_authentication(email: sign_in_params['email'])
      return failure_response(:locked) if user&.access_locked?
    end

    self.resource = warden.authenticate!(auth_options)
    sign_in(:hmis_user, resource)
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
end
