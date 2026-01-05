###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::BaseController < ActionController::Base
  include BaseApplicationControllerBehavior
  include LogRagePayloadBehavior
  include CurrentUser

  before_action :authenticate_hmis_user!
  before_action :initialize_session_for_tests, if: -> { Rails.env.test? }

  include Hmis::Concerns::JsonErrors
  respond_to :json
  before_action :set_csrf_cookie
  before_action :set_app_user_header
  before_action :set_git_revision_header

  private def set_csrf_cookie
    cookies['CSRF-Token'] = form_authenticity_token
  end

  # Reset the session and return 401, instead of raising InvalidAuthenticityToken
  def handle_unverified_request
    reset_session
    render_json_error(401, :unverified_request)
  end

  def current_hmis_host
    # Trust Rack/Rails host resolution (respects trusted proxies and allowed hosts)
    return request.host if request.host.present?

    raise 'cannot determine HMIS host'
  end

  def attach_data_source_id
    domain = current_hmis_host

    # In development: treat requests from GraphiQL as if they are coming from the local frontend
    if Rails.env.development?
      use_hmis_hostname = domain == ENV['HOSTNAME'] && ENV['HMIS_HOSTNAME'].present?
      use_hmis_hostname ||= domain == ENV['HMIS_BACKEND_FQDN'] && ENV['HMIS_HOSTNAME'].present?
      domain = ENV['HMIS_HOSTNAME'] if use_hmis_hostname
    end

    data_source_id = GrdaWarehouse::DataSource.hmis.find_by(hmis: domain)&.id
    raise "HMIS data source not configured: #{domain}" unless data_source_id.present?

    current_hmis_user.hmis_data_source_id = data_source_id
  end

  def data_source
    @data_source ||= GrdaWarehouse::DataSource.find(current_hmis_user.hmis_data_source_id) if current_hmis_user&.hmis_data_source_id.present?
  end
  helper_method :data_source

  # PaperTrail whodunnit (set in ApplicationController) uses this method to determine the label to be stored
  #
  # Returns the true user ID when impersonating, otherwise the current user ID.
  # Format when impersonating: "#{true_hmis_user.id} as #{current_hmis_user.id}"
  def user_for_paper_trail
    return 'unauthenticated' unless current_hmis_user.present?
    return current_hmis_user.id unless impersonating?

    "#{true_hmis_user.id} as #{current_hmis_user.id}"
  end

  def info_for_paper_trail
    {
      user_id: current_hmis_user&.id,
      true_user_id: true_hmis_user&.id,
      session_id: session&.id&.to_s, # maps to session_hash in Hmis::ActivityLog
      request_id: request.uuid, # maps to request_id on ActivityLog, and X-Request-Id header in Sentry
    }
  end

  def set_app_user_header
    # Always use the true user's ID for session tracking, even when impersonating
    # The impersonation state is communicated through the API response fields
    response.headers['X-app-user-id'] = true_hmis_user&.id
  end

  def set_git_revision_header
    response.headers['X-git-revision'] = Git.revision
  end

  # Get the current authenticated HMIS user from JWT token.
  #
  # Also ensures authentication source exists for the user (only once per request).
  # If impersonation is active, returns the impersonated user instead of the true user.
  #
  # @return [Hmis::User, nil] Current user (or impersonated user) or nil if not authenticated
  def current_hmis_user
    @current_hmis_user ||= authenticated_user_from_jwt(user_class: Hmis::User)
  end
  helper_method :current_hmis_user

  # Authenticate HMIS user via JWT token.
  #
  # Returns 401 JSON response if authentication fails.
  #
  # @raise [NotAuthorizedError] if user is not authenticated
  def authenticate_hmis_user!
    user = authenticated_user_from_jwt(user_class: Hmis::User)
    unless user
      not_authorized!
      return
    end

    # Ensure user is active and eligible for authentication
    unless user.active_for_authentication?
      not_authorized!
      return
    end

    @current_hmis_user = user
  end

  # Get the true user (when impersonating).
  #
  # Returns the actual authenticated user from JWT, not the impersonated user.
  # If not impersonating, returns the current_hmis_user.
  #
  # @return [Hmis::User, nil] True user or nil if not authenticated
  def true_hmis_user
    return nil unless current_hmis_user

    impersonation_manager = ImpersonationManager.new(session)
    impersonation_data = impersonation_manager.get
    return current_hmis_user unless impersonation_data && impersonation_data[:true_user_id].present?

    # Load directly as Hmis::User to ensure HMIS permissions are loaded
    Hmis::User.find_by(id: impersonation_data[:true_user_id]) || current_hmis_user
  end
  helper_method :true_hmis_user

  # Check if currently impersonating another user.
  #
  # @return [Boolean] true if impersonating, false otherwise
  def impersonating?
    return false unless current_hmis_user

    impersonation_manager = ImpersonationManager.new(session)
    impersonation_data = impersonation_manager.get
    return false unless impersonation_data && impersonation_data[:impersonated_user_id].present?

    # Verify the impersonated user matches current_hmis_user
    impersonation_data[:impersonated_user_id] == current_hmis_user.id
  end
  helper_method :impersonating?

  # for mixins
  def current_app_user
    current_hmis_user
  end

  def authenticate_user!
    raise 'authenticate_user called in HMIS controller. Did you mean authenticate_user?'
  end

  def current_user
    raise 'current_user called in HMIS controller. Did you mean current_hmis_user?'
  end

  def append_info_to_payload(payload)
    super
    payload[:user_id] = current_app_user&.id
  end

  # Initialize session in test environment to ensure session.id is available for activity logging
  def initialize_session_for_tests
    session[:_session_initialized] = true
  end

  def not_authorized!
    raise NotAuthorizedError
  end

  rescue_from 'NotAuthorizedError' do |_exception|
    render_json_error(401, :unauthenticated)
  end
end
