###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::BaseController < ActionController::Base
  include BaseApplicationControllerBehavior
  include LogRagePayloadBehavior

  before_action :authenticate_hmis_user!
  impersonates :hmis_user, with: ->(id) { Hmis::User.find_by(id: id) }

  include Hmis::Concerns::JsonErrors
  respond_to :json
  before_action :set_csrf_cookie
  before_action :set_app_user_header
  before_action :set_git_revision_header

  private def set_csrf_cookie
    cookies['CSRF-Token'] = form_authenticity_token
  end

  # Override the devise implementation to reset the session
  # and return 401, instead of raising InvalidAuthenticityToken
  def handle_unverified_request
    reset_session
    render_json_error(401, :unverified_request)
  end

  # HMIS domain for this request; used to resolve the data source (DataSource.hmis).
  # @see docs/architecture/multi-hmis-support.md
  def current_hmis_host
    # In development, use untrusted header X-Hmis-Dev-Host.
    # Trusted header 'request.host' cannot be used because the dev server setup makes it appear to come from the backend host.
    return request.headers['X-Hmis-Dev-Host'].presence || raise('X-Hmis-Dev-Host header required in development') if Rails.env.development?

    # Trust Rack/Rails host resolution (respects trusted proxies and allowed hosts)
    return request.host if request.host.present?

    raise 'cannot determine HMIS host'
  end

  def current_data_source
    data_source = GrdaWarehouse::DataSource.hmis.find_by(hmis: current_hmis_host)
    raise "HMIS data source not configured: #{current_hmis_host}" unless data_source.present?

    data_source
  end

  # Binds the current request to an HMIS data source using the request host
  # @see docs/architecture/multi-hmis-support.md
  def attach_data_source_id
    current_hmis_user.hmis_data_source_id = current_data_source.id
  end

  # PaperTrail whodunnit (set in ApplicationController) uses this method to determine the label to be stored
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
    response.headers['X-app-user-id'] = current_hmis_user&.id
  end

  def set_git_revision_header
    response.headers['X-git-revision'] = Git.revision
  end

  def impersonating?
    true_hmis_user != current_hmis_user
  end

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

  def not_authorized!
    raise NotAuthorizedError
  end

  rescue_from 'NotAuthorizedError' do |_exception|
    head :unauthorized
  end
end
