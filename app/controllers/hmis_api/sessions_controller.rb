###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisApi::SessionsController < Devise::SessionsController
  include AuthenticatesWithTwoFactor
  respond_to :json
  skip_before_action :verify_signed_out_user
  before_action :authenticate_with_2fa, only: [:create], if: -> { two_factor_enabled? }

  def create
    self.resource = warden.authenticate!(auth_options)
    sign_in(:hmis_api_user, resource)
    set_csrf_cookie
    render json: { success: true, name: resource.name, email: resource.email }
  end

  def destroy
    sign_out(:hmis_api_user) # Only sign out of the HMIS, not the warehouse

    render json: { success: true }, status: 200
  end

  private def authenticate_with_2fa
    set_csrf_cookie
    authenticate_with_two_factor
  end

  def find_user
    if session[:otp_user_id]
      HmisApiUser.find(session[:otp_user_id])
    elsif user_params[:email]
      HmisApiUser.find_by(email: user_params[:email])
    end
  end

  def prompt_for_two_factor(user, invalid_code: false)
    session[:otp_user_id] = user.id # Needed for AuthenticatesWithTwoFactor to work
    error_type = invalid_code ? :invalid_code : :mfa_required
    render_json_error(:forbidden, error_type)
  end

  def user_params
    params.require(:hmis_api_user).permit(:email, :password, :otp_attempt, :remember_device, :device_name)
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

  private def render_json_error(status, type, message: nil)
    status = Rack::Utils::SYMBOL_TO_STATUS_CODE[status] if status.is_a? Symbol
    error = { type: type }
    error[:message] = message if message.present?
    render status: status, json: { error: error }
  end

  private def two_factor_resource_name
    :hmis_api_user
  end
end
