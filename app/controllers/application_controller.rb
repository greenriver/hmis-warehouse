###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'application_responder'
require_relative '../../lib/util/git'

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder
  respond_to :html, :js, :json, :csv

  include CurrentUser
  include ActivityLogger
  include LogRagePayloadBehavior
  include Pagy::Backend

  # conditional includes support the migration away from deprecated authorization methods.
  # New controllers should inherit from ApplicationControllerV2 which replaces older auth
  # methods with authorize_with()
  def self.inherited(subclass)
    super
    subclass.include(LegacyControllerAuthorization) unless ApplicationControllerV2.in?(subclass.ancestors)
  end

  protect_from_forgery with: :exception

  before_action :authenticate_user!

  before_action :set_sentry_user

  before_action :set_paper_trail_whodunnit
  before_action :set_notification
  before_action :set_hostname

  before_action :compose_activity, except: [:poll, :active, :rollup, :image] # , only: [:show, :index, :merge, :unmerge, :edit, :update, :destroy, :create, :new]
  after_action :log_activity, except: [:poll, :active, :rollup, :image] # , only: [:show, :index, :merge, :unmerge, :edit, :destroy, :create, :new]

  helper_method :locale
  before_action :require_compliance_agreement!
  before_action :require_training!
  before_action :health_emergency?

  before_action :prepare_exception_notifier

  prepend_before_action :skip_timeout

  # raise NotAuthorizedError which we can rescue from. This stops flow on a failed authorization check
  protected def not_authorized!(message = nil)
    raise NotAuthorizedError, message
  end

  # override the handler in the subclass, such as to return JSON in API requests
  rescue_from 'NotAuthorizedError', with: :handle_unauthorized_error
  protected def handle_unauthorized_error(error)
    location = current_user&.my_root_path || root_path
    redirect_to(location, alert: error.message)
  end

  # Send any exceptions on production to slack
  def set_notification
    request.env['exception_notifier.exception_data'] = { 'server' => request.env['SERVER_NAME'] }
  end

  # To permit merge(link_params) when creating a new link from existing parameters
  def link_params
    params.permit!.merge(only_path: true, script_name: nil)
  end
  helper_method :link_params

  protected

  # Removed 7/30/2019 -- no longer in use, brakeman identified as Possible unprotected redirect
  # def redirect_back(*args)
  #   argsdup = args.dup
  #   fallback = argsdup.delete(:fallback_location) || root_path

  #   if request.env['HTTP_REFERER'].present?
  #     redirect_to request.env['HTTP_REFERER'], *argsdup
  #   else
  #     redirect_to fallback, *argsdup
  #   end
  # end

  def locale
    default_locale = 'en'
    params[:locale] || session[:locale] || default_locale
  end

  private

  # Skip tracking timeout for AJAX requests (no-op for JWT auth).
  def skip_timeout
    # Session timeout is handled by JWT expiration, not trackable
  end

  def _basic_auth
    authenticate_or_request_with_http_basic do |user, password|
      user == Rails.application.secrets.basic_auth_user && \
      password == Rails.application.secrets.basic_auth_password
    end
  end

  def append_info_to_payload(payload)
    super
    payload[:user_id] = current_user&.id
  end

  def info_for_paper_trail
    {
      user_id: current_user&.id,
      true_user_id: true_user&.id,
      session_id: session&.id&.to_s,
      request_id: request.uuid,
    }
  end

  # Sets whodunnit for PaperTrail
  #
  # Returns the true user ID when impersonating, otherwise the current user ID.
  # Format when impersonating: "#{true_user.id} as #{current_user.id}"
  def user_for_paper_trail
    return 'unauthenticated' unless current_user.present?
    return current_user.id unless impersonating?

    "#{true_user.id} as #{current_user.id}"
  end

  def colorize(object)
    # make a hash of the object, truncate it to an appropriate size and then turn it into
    # a css friendly hash code
    format('#%06x', (Zlib.crc32(Marshal.dump(object)) & 0xffffff))
  end
  helper_method :colorize

  def sentry_frontend_config
    {
      dsn: ENV['WAREHOUSE_SENTRY_DSN'],
      environment: Rails.env,
      release: Git.revision,
      user: current_user&.id,
      true_user_id: true_user&.id,
    }.compact
  end
  helper_method :sentry_frontend_config

  protected

  # Redirect after signin
  # no where else to go (and you can see it)
  #
  # Priority order:
  # 1. Stored redirect URL from OAuth2-proxy flow (via redirect_url_after_auth)
  # 2. Application root path
  #
  # @param user [User, nil] User instance (defaults to current_user)
  # @return [String] Path to redirect to
  def after_sign_in_path_for(user = current_user)
    # Check for stored redirect URL from OAuth2-proxy flow (includes user.my_root_path)
    redirect_url = RedirectUrlHelper.redirect_url_after_auth(
      params: params,
      request: request,
      session_id: session&.id&.to_s,
      user: user,
    )
    if redirect_url.present?
      # Clear the stored redirect after use
      RedirectManager.new(session&.id&.to_s).clear
      return redirect_url
    end
    # Final fallback to application root
    root_path
  end

  def after_sign_out_path_for(_scope)
    root_url
  end

  # Store a location in session for redirect after authentication.
  #
  # Compatible with Devise's store_location_for helper.
  #
  # @param scope [Symbol] Scope name (e.g., :user)
  # @param location [String] URL to store
  def store_location_for(scope, location)
    session["#{scope}_return_to"] = location
  end

  # Retrieve stored location from session.
  #
  # Compatible with Devise's stored_location_for helper.
  #
  # @param scope [Symbol] Scope name (e.g., :user)
  # @return [String, nil] Stored location or nil if not present
  def stored_location_for(scope)
    session["#{scope}_return_to"]
  end

  # Clear stored location from session.
  #
  # @param scope [Symbol] Scope name (e.g., :user)
  def clear_stored_location_for(scope)
    session.delete("#{scope}_return_to")
  end

  def allowed_setup_controllers
    controller_path.in?(
      [
        'users/sessions',
        'accounts',
        'account_emails',
        'user_training',
        'compliance_agreements',
        'content_pages',
      ],
    ) || controller_path == 'admin/users' && action_name == 'stop_impersonating'
  end

  def require_training!
    return unless current_user
    return unless current_user.training_required?
    return if allowed_setup_controllers

    # Verifying with local data before hitting the API. This prevents unneeded API calls
    # and ensures local data is updated when new trainings have been completed.
    lms = Talentlms::Facade.new(current_user)
    return unless lms.any_training_required?

    redirect_to user_training_path
  end

  def require_compliance_agreement!
    return unless current_user
    return if current_user.pending_compliance_requirements.empty?
    return if allowed_setup_controllers

    redirect_to compliance_agreement_path
  end

  # is the user in a portal (tos agreement)
  helper_method def access_captured_for_setup? = false

  def health_emergency?
    health_emergency.present? && current_user&.can_see_health_emergency?
  end
  helper_method :health_emergency?

  def health_emergency
    @health_emergency ||= GrdaWarehouse::Config.get(:health_emergency)
  end
  helper_method :health_emergency

  def health_emergency_test_status
    @health_emergency_test_status ||= GrdaWarehouse::HealthEmergency::TestBatch.completed.maximum(:completed_at) if health_emergency? && current_user.can_see_health_emergency_clinical?
  end
  helper_method :health_emergency_test_status

  def healthcare_available?
    GrdaWarehouse::Config.get(:healthcare_available)
  end
  helper_method :healthcare_available?

  def ajax_modal_request?
    false
  end
  helper_method :ajax_modal_request?

  def bypass_2fa_enabled?
    GrdaWarehouse::Config.get(:bypass_2fa_duration)&.positive?
  end
  helper_method :bypass_2fa_enabled?

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
      current_user: current_user&.email || 'none',
      current_user_browser: browser.to_s,
    }
  end

  def set_sentry_user
    return unless ENV['WAREHOUSE_SENTRY_DSN'].present?

    Sentry.configure_scope { |scope| scope.set_user(id: current_user.id, email: current_user.email) } if Sentry.initialized? && defined?(current_user) && current_user.is_a?(User)
  end

  before_action :set_app_user_header
  def set_app_user_header
    response.headers['X-app-user-id'] = current_user&.id
  end
end
