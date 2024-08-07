###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'application_responder'

# ApplicationController that could be shared between WH and HMIS, but is currently only used by HMIS
module BaseApplicationControllerBehavior
  extend ActiveSupport::Concern

  included do
    self.responder = ApplicationResponder

    protect_from_forgery with: :exception

    before_action :set_sentry_user

    before_action :set_paper_trail_whodunnit
    before_action :set_notification
    before_action :set_hostname

    helper_method :locale

    before_action :prepare_exception_notifier

    before_action :configure_permitted_parameters, if: :devise_controller?

    protected

    # Send any exceptions on production to slack
    def set_notification
      request.env['exception_notifier.exception_data'] = { 'server' => request.env['SERVER_NAME'] }
    end

    def locale
      default_locale = 'en'
      params[:locale] || session[:locale] || default_locale
    end

    # don't extend the user's session if its an ajax request.
    def skip_timeout
      request.env['devise.skip_trackable'] = true if request.xhr?
    end

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt, :remember_device, :device_name])
    end

    # Redirect to window page after signin if you have
    # no where else to go (and you can see it)
    def after_sign_in_path_for(resource)
      # alert users if their password has been compromised
      set_flash_message! :alert, :warn_pwned if resource.respond_to?(:pwned?) && resource.pwned?

      last_url = session['user_return_to']
      if last_url.present?
        last_url
      else
        current_app_user&.my_root_path || root_path
      end
    end

    def after_sign_out_path_for(_scope)
      user = request.env['last_user']
      if user
        provider = cookies.signed[:active_provider]
        identity = OauthIdentity.for_user(user).where(provider: provider).first if provider
        identity&.idp_signout_url(post_logout_redirect_uri: root_url) || root_url
      else
        root_url
      end
    end

    def set_hostname
      @op_hostname ||= begin # rubocop:disable Naming/MemoizedInstanceVariableName
        `hostname`
      rescue StandardError
        'test-server'
      end
    end

    def prepare_exception_notifier
      browser = Browser.new(request.user_agent)
      request.env['exception_notifier.exception_data'] = {
        current_app_user: current_app_user&.email || 'none',
        current_app_user_browser: browser.to_s,
      }
    end

    def set_sentry_user
      return unless ENV['WAREHOUSE_SENTRY_DSN'].present? && Sentry.initialized?
      return unless defined?(current_app_user)
      return unless current_app_user.is_a?(User) || current_app_user.is_a?(Hmis::User)

      Sentry.configure_scope do |scope|
        scope.set_user(id: current_app_user.id, email: current_app_user.email)
      end
    end

    def bypass_2fa_enabled?
      GrdaWarehouse::Config.get(:bypass_2fa_duration)&.positive?
    end
    helper_method :bypass_2fa_enabled?
  end
end
