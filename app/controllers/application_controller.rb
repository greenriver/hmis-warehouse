###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

require 'application_responder'

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder
  respond_to :html, :js, :json, :csv
  impersonates :user

  include ControllerAuthorization
  include ActivityLogger
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
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

  # Don't start in development if you have pending migrations
  prepend_before_action :check_all_db_migrations
  prepend_before_action :skip_timeout

  def cache_grda_warehouse_base_queries
    GrdaWarehouseBase.cache do
      yield
    end
  end

  # Send any exceptions on production to slack
  def set_notification
    request.env['exception_notifier.exception_data'] = { 'server' => request.env['SERVER_NAME'] }
  end

  force_ssl if Rails.configuration.force_ssl

  # To permit merge(link_params) when creating a new link from existing parameters
  def link_params
    params.permit!
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
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end

  # Redirect to window page after signin if you have
  # no where else to go (and you can see it)
  def after_sign_in_path_for(resource)
    # alert users if their password has been compromised
    set_flash_message! :alert, :warn_pwned if resource.respond_to?(:pwned?) && resource.pwned?

    last_url = session['user_return_to']
    if last_url.present?
      last_url
    elsif can_view_clients?
      clients_path
    elsif can_search_window?
      window_clients_path
    else
      root_path
    end
  end

  # If a user must have Two-factor authentication turned on, only let them go
  # to their 2FA page and their account page
  def enforce_2fa!
    return unless current_user
    return unless current_user.enforced_2fa?
    return if current_user.two_factor_enabled?
    return if controller_path.in?(
      [
        'users/sessions',
        'accounts',
        'account_two_factors',
        'account_emails',
        'account_passwords',
      ],
    )
    return if controller_path == 'admin/users' && action_name == 'stop_impersonating'

    flash[:alert] = 'Two factor authentication must be enabled for this account.'
    redirect_to edit_account_two_factor_path
  end

  def check_all_db_migrations
    return true unless Rails.env.development?

    raise ActiveRecord::MigrationError, "Warehouse Migrations pending. To resolve this issue, run:\n\n\t bin/rake warehouse:db:migrate RAILS_ENV=#{::Rails.env}" if ActiveRecord::Migration.check_pending!(GrdaWarehouseBase.connection)
    raise ActiveRecord::MigrationError, "Health Migrations pending. To resolve this issue, run:\n\n\t bin/rake health:db:migrate RAILS_ENV=#{::Rails.env}" if ActiveRecord::Migration.check_pending!(HealthBase.connection)
    raise ActiveRecord::MigrationError, "Reporting Migrations pending. To resolve this issue, run:\n\n\t bin/rake reporting:db:migrate RAILS_ENV=#{::Rails.env}" if ActiveRecord::Migration.check_pending!(ReportingBase.connection)
  end

  def pjax_request?
    false
  end
  helper_method :pjax_request?

  def set_hostname
    @op_hostname ||= begin # rubocop:disable Naming/MemoizedInstanceVariableName
      `hostname`
    rescue StandardError
      'test-server'
    end
  end
end
