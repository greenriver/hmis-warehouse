###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::BaseController < ActionController::Base
  include HmisBaseApplicationControllerBehavior
  include LogRagePayloadBehavior
  include ControllerCacheBehavior

  before_action :authenticate_hmis_user!

  # AUTH_METHOD seam: under JWT, current_hmis_user / authenticate_hmis_user! / true_hmis_user / the
  # impersonation write-side / session_duration_seconds are provided by
  # Hmis::Concerns::JwtHmisCurrentUser (off a validated forwarded JWT); under Devise they come from
  # the pretender macro + the devise :hmis_user scope + Hmis::Concerns::DeviseHmisCurrentUser.
  # The before_action :authenticate_hmis_user! (above) and the set_anti_caching_headers
  # hmis_user_signed_in? guard (below) are satisfied either way.
  if AuthMethod.jwt?
    include Hmis::Concerns::JwtHmisCurrentUser
  else
    impersonates :hmis_user, with: ->(id) { Hmis::User.find_by(id: id) }
    include Hmis::Concerns::DeviseHmisCurrentUser
  end

  include Hmis::Concerns::JsonErrors
  include Hmis::Concerns::RequestDataSource
  respond_to :json
  before_action :set_csrf_cookie
  before_action :set_app_user_header
  before_action :set_git_revision_header
  before_action :set_anti_caching_headers, if: :hmis_user_signed_in?

  private def set_csrf_cookie
    cookies['CSRF-Token'] = form_authenticity_token
  end

  # Override the devise implementation to reset the session
  # and return 401, instead of raising InvalidAuthenticityToken
  def handle_unverified_request
    reset_session
    render_json_error(401, :unverified_request)
  end

  # Binds the current request to an HMIS data source using the request host, then refuses the
  # request if the signed-in person may not use that HMIS.
  # @see docs/features/hmis/multi-hmis-support.md
  def attach_data_source_id
    data_source = current_data_source
    current_hmis_user.hmis_data_source_id = data_source.id
    true_hmis_user.hmis_data_source_id = data_source.id if true_hmis_user.present?

    error = hmis_access_error
    # 403, not 401: signing in again cannot grant access, and a 401 sends the SPA to a sign-in screen.
    render_json_error(403, error) if error
  end

  # Checks the real person (true_hmis_user), so an admin impersonating a blocked user is not
  # locked out of the impersonation they are using to test.
  def hmis_access_error
    (true_hmis_user || current_hmis_user)&.hmis_access_error_for(current_data_source)
  end

  # Terminal state for the SPA bootstrap:
  # Checks the auth arm's account-level state first,
  # then the per-data-source check for a signed-in user.
  def bootstrap_account_error
    terminal_account_error || (current_hmis_user && hmis_access_error)
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

  # Shared shape for any endpoint that reports the signed-in HMIS user (user.json, impersonations).
  def current_user_payload
    payload = current_hmis_user&.current_user_api_values(session_duration: session_duration_seconds) || {}
    payload[:impersonating] = impersonating?
    payload
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
