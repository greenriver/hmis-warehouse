###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def okta
    logger.debug "OmniauthCallbacksController#okta #{request.env['omniauth.auth'].inspect}"

    user = User.from_omniauth request.env['omniauth.auth']
    sign_in_and_redirect user, event: :authentication # this will throw if @user is not activated
    set_flash_message(:notice, :success, kind: 'OKTA') if is_navigational_format?
  end

  def failure
    logger.error "OmniauthCallbacksController#failure #{request.env['omniauth.auth']}"
    super
  end
end
