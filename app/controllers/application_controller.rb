###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'application_responder'

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder
  respond_to :html, :js, :json, :csv
  impersonates :user

  # Don't start in development if you have pending migrations
  # moved to top for dockerization
  prepend_before_action :check_all_db_migrations

  include ControllerAuthorization
  include ActivityLogger
  include Pagy::Backend
  protect_from_forgery with: :exception

  before_action :authenticate_user!
  auto_session_timeout User.timeout_in

  before_action :set_paper_trail_whodunnit
  before_action :set_notification
  before_action :set_hostname

  around_action :cache_grda_warehouse_base_queries
  before_action :compose_activity, except: [:poll, :active, :rollup, :image] # , only: [:show, :index, :merge, :unmerge, :edit, :update, :destroy, :create, :new]
  after_action :log_activity, except: [:poll, :active, :rollup, :image] # , only: [:show, :index, :merge, :unmerge, :edit, :destroy, :create, :new]

  helper_method :locale
  before_action :set_gettext_locale
  before_action :possibly_reset_fast_gettext_cache
  before_action :enforce_2fa!
  before_action :require_training!
  before_action :health_emergency?

  before_action :prepare_exception_notifier

  prepend_before_action :skip_timeout

  def cache_grda_warehouse_base_queries
    GrdaWarehouseBase.cache do
      yield
    end
  end

  private def resource_name
    :user
  end
  helper_method :resource_name

  private def resource_class
    User
  end
  helper_method :resource_class

  def resource
    @user = User.new
  end
  helper_method :resource

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
  helper_method :devise_mapping

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

  # don't extend the user's session if its an ajax request.
  def skip_timeout
    request.env['devise.skip_trackable'] = true if request.xhr?
  end

  def set_gettext_locale
    session[:locale] = I18n.locale = FastGettext.set_locale(locale)
    super
  end

  def possibly_reset_fast_gettext_cache
    key_for_host = "translation-fresh-at-for-#{set_hostname}"
    last_change = Rails.cache.read('translation-fresh-at') || Time.current
    last_loaded_for_host = Rails.cache.read(key_for_host)
    if last_loaded_for_host.blank? || last_change > last_loaded_for_host # rubocop:disable Style/GuardClause
      FastGettext.cache.reload!
      Rails.cache.write(key_for_host, Time.current)
    end
  end

  def _basic_auth
    authenticate_or_request_with_http_basic do |user, password|
      user == Rails.application.secrets.basic_auth_user && \
      password == Rails.application.secrets.basic_auth_password
    end
  end

  before_action :configure_permitted_parameters, if: :devise_controller?

  def append_info_to_payload(payload)
    super
    payload[:server_protocol] = request.env['SERVER_PROTOCOL']
    payload[:remote_ip] = request.remote_ip
    payload[:ip] = request.ip
    payload[:session_id] = request.env['rack.session.record'].try(:session_id)
    payload[:user_id] = current_user&.id
    payload[:pid] = Process.pid
    payload[:request_id] = request.uuid
    payload[:request_start] = request.headers['HTTP_X_REQUEST_START'].try(:gsub, /\At=/, '')
  end

  def info_for_paper_trail
    {
      user_id: warden&.user&.id,
      session_id: request.env['rack.session.record']&.session_id,
      request_id: request.uuid,
    }
  end

  # Sets whodunnit
  def user_for_paper_trail
    return 'unauthenticated' unless current_user.present?
    return current_user.id unless true_user.present?
    return current_user.id if true_user == current_user

    "#{true_user.id} as #{current_user.id}"
  end

  def colorize(object)
    # make a hash of the object, truncate it to an appropriate size and then turn it into
    # a css friendly hash code
    format('#%06x', (Zlib.crc32(Marshal.dump(object)) & 0xffffff))
  end
  helper_method :colorize

  protected

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
      current_user.my_root_path
    end
  end

  def after_sign_out_path_for(_scope)
    if (user = request.env['last_user'])
      url = user.idp_signout_url(post_logout_redirect_uri: root_url)
      return url if url.present?
    else
      root_url
    end
  end

  def allowed_setup_controllers
    controller_path.in?(
      [
        'users/sessions',
        'accounts',
        'account_two_factors',
        'account_emails',
        'account_passwords',
        'user_training',
      ],
    ) || controller_path == 'admin/users' && action_name == 'stop_impersonating'
  end

  # If a user must have Two-factor authentication turned on, only let them go
  # to their 2FA page and their account page
  def enforce_2fa!
    return unless current_user
    return unless current_user.enforced_2fa?
    return if current_user.two_factor_enabled?
    return if allowed_setup_controllers

    flash[:alert] = 'Two factor authentication must be enabled for this account.'
    redirect_to edit_account_two_factor_path
  end

  def require_training!
    return unless current_user
    return unless current_user.training_required?
    return if current_user.training_completed?
    return if allowed_setup_controllers

    redirect_to user_training_path
  end

  # NOTE: if this gets merged, this may not be necessary
  # https://github.com/rails/rails/pull/39750/files
  def check_all_db_migrations
    return true unless Rails.env.development?
    raise ActiveRecord::MigrationError, "App Migrations pending. To resolve this issue, run:\n\n\t bin/rails db:migrate:primary RAILS_ENV=#{::Rails.env}" if ApplicationRecord.needs_migration?
    raise ActiveRecord::MigrationError, "Warehouse Migrations pending. To resolve this issue, run:\n\n\t bin/rails db:migrate:warehouse RAILS_ENV=#{::Rails.env}" if GrdaWarehouseBase.needs_migration?
    raise ActiveRecord::MigrationError, "Health Migrations pending. To resolve this issue, run:\n\n\t bin/rails db:migrate:health RAILS_ENV=#{::Rails.env}" if HealthBase.needs_migration?
    raise ActiveRecord::MigrationError, "Reporting Migrations pending. To resolve this issue, run:\n\n\t bin/rails db:migrate:reporting RAILS_ENV=#{::Rails.env}" if ReportingBase.needs_migration?
  end

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
end
