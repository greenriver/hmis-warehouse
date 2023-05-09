###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    include OmniauthCallbackBehavior

    protected

    def handle_success(user)
      sign_in(:user, user, event: :authentication)
      log('sign-in success')
      set_flash_message(:notice, :success, kind: 'OKTA') if is_navigational_format?
      redirect_to after_sign_in_path_for(user)
    end

    def user_scope
      User
    end
  end
end
