require "application_responder"

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder
  respond_to :html, :js, :json, :csv

  include ControllerAuthorization
  include ActivityLogger
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :authenticate_user!
  auto_session_timeout User.timeout_in

  before_filter :set_paper_trail_whodunnit
  before_filter :set_notification
  before_filter :set_hostname

  around_filter :cache_grda_warehouse_base_queries
  before_action :compose_activity, except: [:poll, :active, :rollup, :image]#, only: [:show, :index, :merge, :unmerge, :edit, :update, :destroy, :create, :new]
  after_action :log_activity, except: [:poll, :active, :rollup, :image]#, only: [:show, :index, :merge, :unmerge, :edit, :destroy, :create, :new]

  helper_method :locale
  before_filter :set_gettext_locale

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
    request.env['exception_notifier.exception_data'] = {"server" => request.env['SERVER_NAME']}
  end

  if Rails.configuration.force_ssl
    force_ssl
  end

  protected

  def redirect_back(*args)
    argsdup = args.dup
    fallback = argsdup.delete(:fallback_location) || root_path

    if request.env['HTTP_REFERER'].present?
      redirect_to request.env['HTTP_REFERER'], *argsdup
    else
      redirect_to fallback, *argsdup
    end
  end

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
    payload[:request_start] = request.headers['HTTP_X_REQUEST_START'].try(:gsub, /\At=/,'')
  end

  def info_for_paper_trail
    {
      user_id: current_user&.id,
      session_id: request.env['rack.session.record']&.session_id,
      request_id: request.uuid
    }
  end

  def colorize(object)
    # make a hash of the object, truncate it to an appropriate size and then turn it into
    # a css friendly hash code
    "#%06x" % (Zlib::crc32(Marshal.dump(object)) & 0xffffff)
  end
  helper_method :colorize

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :email, :password, :password_confirmation, :name])
  end

  # Redirect to window page after signin if you have
  # no where else to go (and you can see it)
  def after_sign_in_path_for(resource)
    last_url = session["user_return_to"]
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

  def check_all_db_migrations
    return true unless Rails.env.development?
    query = 'select version from schema_migrations'
    # Warehouse
    all = ActiveRecord::Migrator.migrations(['db/warehouse/migrate']).collect(&:version)
    migrated = GrdaWarehouseBase.connection.select_rows(query).flatten(1).map(&:to_i)
    raise ActiveRecord::MigrationError.new "Warehouse Migrations pending. To resolve this issue, run:\n\n\t bin/rake warehouse:db:migrate RAILS_ENV=#{::Rails.env}" if (all - migrated).size > 0
    # Health
    all = ActiveRecord::Migrator.migrations(['db/health/migrate']).collect(&:version)
    migrated = HealthBase.connection.select_rows(query).flatten(1).map(&:to_i)
    raise ActiveRecord::MigrationError.new "Health Migrations pending. To resolve this issue, run:\n\n\t bin/rake health:db:migrate RAILS_ENV=#{::Rails.env}" if (all - migrated).size > 0

    # Reporting
    all = ActiveRecord::Migrator.migrations(['db/reporting/migrate']).collect(&:version)
    migrated = ReportingBase.connection.select_rows(query).flatten(1).map(&:to_i)
    raise ActiveRecord::MigrationError.new "Reporting Migrations pending. To resolve this issue, run:\n\n\t bin/rake reporting:db:migrate RAILS_ENV=#{::Rails.env}" if (all - migrated).size > 0
  end

  def pjax_request?
    false
  end
  helper_method :pjax_request?

  def set_hostname
    @op_hostname ||= `hostname` rescue 'test-server'
  end
end
