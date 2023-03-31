###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis
  module Users
    class OmniauthCallbacksController < Devise::OmniauthCallbacksController
      include OmniauthCallbackBehavior

      protected

      def handle_success(user)
        sign_in(:hmis_user, user, event: :authentication)
        log('sign-in success')
        set_csrf_cookie
        redirect_to hmis_host_url
      end

      def set_csrf_cookie
        cookies['CSRF-Token'] = form_authenticity_token
      end

      def user_scope
        Hmis::User
      end

      def hmis_host_url
        host = ENV.fetch('HMIS_HOSTNAME')
        "https://#{host}"
      end

      def handle_2fa(user)
        log '2fa'
        raise "2fa not supported for Hmis::User##{user.id}"
      end
    end
  end
end
