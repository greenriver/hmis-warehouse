###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include AuthenticatesWithTwoFactor

  def okta
    logger.debug "OmniauthCallbacksController#okta #{request.env['omniauth.auth'].inspect}"

    user = User.from_omniauth request.env['omniauth.auth']

    if user.two_factor_enabled?
      return locked_user_redirect(user) unless user.active?

      # bypass 2fa if user has device
      if using_memorized_device?(user) && bypass_2fa_enabled?
        two_factor_successful(user)

        redirect_to after_sign_in_path_for(user)
      else
        prompt_for_two_factor(user)
      end
    else
      sign_in user, event: :authentication
      set_flash_message(:notice, :success, kind: 'OKTA') if is_navigational_format?
      redirect_to after_sign_in_path_for(user)
    end
  end

  def passthru
    # Just send them to the home page for now instead
    # of showing the ugly text messsage

    redirect_to root_path
  end

  def failure
    logger.error "OmniauthCallbacksController#failure #{request.env['omniauth.auth']}"
    super
  end
end
