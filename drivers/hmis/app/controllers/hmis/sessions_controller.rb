###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::SessionsController < Devise::SessionsController
  include Hmis::Concerns::JsonErrors
  include AuthenticatesWithTwoFactor
  respond_to :json
  skip_before_action :verify_signed_out_user
  before_action :authenticate_with_2fa, only: [:create], if: -> { two_factor_enabled? }

  def create
    self.resource = warden.authenticate!(auth_options)
    sign_in(:hmis_user, resource)
    set_csrf_cookie
    render json: { name: resource.name, email: resource.email }
  end

  def destroy
    sign_out(:hmis_user) # Only sign out of the HMIS, not the warehouse
    render json: { success: true }, status: 204
  end

  # We require a valid CSRF token on login form submission.
  # Override the devise implementation to return 401 instead of raising InvalidAuthenticityToken.
  def handle_unverified_request
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
end
