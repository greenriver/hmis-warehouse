###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Api::SessionsController < Devise::SessionsController
  include AuthenticatesWithTwoFactor
  skip_before_action :verify_signed_out_user
  before_action :check_request_format, only: [:create]
  respond_to :json

  prepend_before_action do
    authenticate_with_two_factor(perform_authentication: false) if action_name == 'create' && two_factor_enabled?
  end

  def create
    self.resource = warden.authenticate!(auth_options)
    # FIXME should call record_failure_and_lock_access_if_exceeded if otp strategy failed,
    # but we never get here if it does. and no exception is thrown (???)
    sign_in(:api_user, resource)
    render json: { success: true, jwt: current_token }
  end

  def check_request_format
    return if request.format == :json

    sign_out
    render status: 406, json: { success: 'false', message: 'JSON requests only.' }
  end

  private def current_token
    request.env['warden-jwt_auth.token']
  end

  def find_user
    if session[:otp_user_id]
      ApiUser.find(session[:otp_user_id])
    elsif user_params[:email]
      ApiUser.find_by(email: user_params[:email])
    end
  end

  def prompt_for_two_factor(user, invalid_code: false)
    session[:otp_user_id] = user.id
    render status: 403, json: { error: invalid_code ? 'invalid_code' : 'mfa_required' }
  end

  def user_params
    params.require(:api_user).permit(:email, :password, :otp_attempt, :remember_device, :device_name)
  end

  def two_factor_enabled?
    find_user&.two_factor_enabled?
  end

  def locked_user_redirect(*)
    render status: 403, json: { error: 'account locked' }
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
end
