###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

  def current_hmis_host
    raise 'cannot determine HMIS host because origin is missing' unless request.origin.present?

    URI.parse(request.origin).host
  end

  def attach_data_source_id
    domain = current_hmis_host

    # In development: treat requests from GraphiQL as if they are coming from the local frontend
    domain = ENV['HMIS_HOSTNAME'] if Rails.env.development? && domain == ENV['HOSTNAME'] && ENV['HMIS_HOSTNAME'].present?

    data_source_id = GrdaWarehouse::DataSource.hmis.find_by(hmis: domain)&.id
    raise "HMIS data source not configured: #{domain}" unless data_source_id.present?

    current_hmis_user.hmis_data_source_id = data_source_id
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
      session_id: request.env['rack.session.record']&.session_id,
      request_id: request.uuid,
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
