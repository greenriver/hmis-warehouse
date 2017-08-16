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

  around_filter :cache_grda_warehouse_base_queries
  before_action :compose_activity, only: [:show, :index, :merge, :unmerge, :edit, :update, :destroy, :create, :new]
  after_action :log_activity, only: [:show, :index, :merge, :unmerge, :edit, :destroy, :create, :new]

  helper_method :locale
  before_filter :set_gettext_locale

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

  def locale
    default_locale = 'en'
    params[:locale] || session[:locale] || default_locale
  end

  private

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
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :name) }
  end

  # Redirect to window page after signin if you have
  # no where else to go (and you can see it)
  def after_sign_in_path_for(resource)
    last_url = session["user_return_to"]
    if last_url.present?
      last_url
    elsif can_view_client_window?
      window_clients_path
    else
      root_path
    end
  end
end
