###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisApi::SessionsController < Devise::SessionsController
  include AuthenticatesWithTwoFactor
  skip_before_action :verify_signed_out_user
  respond_to :json

  prepend_before_action do
    authenticate_with_two_factor(perform_authentication: false) if action_name == 'create' && two_factor_enabled?
  end

  def create
    self.resource = warden.authenticate!(auth_options)
    # FIXME should call record_failure_and_lock_access_if_exceeded if otp strategy failed (or save device if it succeeded?),
    # but we never get here if it does. and no exception is thrown (???)
    sign_in(:hmis_api_user, resource)
    cookies['CSRF-Token'] = form_authenticity_token
    render json: { success: true, name: resource.name, email: resource.email }
  end

  def destroy
    sign_out(resource_name) # Only sign out of the HMIS, not the warehouse

    render json: { success: true }, status: 200
  end

  def find_user
    HmisApiUser.find_by(email: user_params[:email])
  end

  def prompt_for_two_factor(user, invalid_code: false)
    session[:otp_user_id] = user.id # we don't use this, just need it for AuthenticatesWithTwoFactor to work
    render status: 403, json: { error: invalid_code ? 'invalid_code' : 'mfa_required' }
  end

  def user_params
    params.require(:hmis_api_user).permit(:email, :password, :otp_attempt, :remember_device, :device_name)
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
