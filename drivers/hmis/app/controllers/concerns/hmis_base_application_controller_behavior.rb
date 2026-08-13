###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'application_responder'

# Shared setup for Hmis::BaseController, common to both the Devise and JWT auth arms.
module HmisBaseApplicationControllerBehavior
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

    protected

    # Send any exceptions on production to slack
    def set_notification
      request.env['exception_notifier.exception_data'] = { 'server' => request.env['SERVER_NAME'] }
    end

    def locale
      default_locale = 'en'
      params[:locale] || session[:locale] || default_locale
    end

    # Devise::Timeoutable-only (don't extend the user's session if it's an ajax request); a no-op
    # under JWT (session lifetime is governed by the IdP token), overridden in
    # Hmis::Concerns::JwtHmisCurrentUser.
    def skip_timeout
      request.env['devise.skip_trackable'] = true if request.xhr?
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
  end
end
