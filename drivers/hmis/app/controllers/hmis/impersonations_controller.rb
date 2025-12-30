###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::ImpersonationsController < Hmis::BaseController
  before_action :attach_data_source_id
  before_action :authorize_action

  def create
    # Force session to be created by writing to it (needed for tests where sessions are lazy-loaded)
    session[:_session_initialized] = true if Rails.env.test?

    return render_error("Already impersonating #{true_hmis_user.id} => #{current_hmis_user.id}") if impersonating?

    user = Hmis::User.with_hmis_access.find(params[:user_id])

    return render_error('Cannot impersonate current user') if user.id == current_hmis_user.id

    # Validate permissions before storing
    return render_error('You do not have permission to impersonate users') unless true_hmis_user.can_impersonate_users?

    return render_error('This user cannot be impersonated') unless user.impersonateable_by?(true_hmis_user)

    # Store impersonation state in session
    manager = ImpersonationManager.new(session)
    manager.store(true_hmis_user.id, user.id)

    # Clear memoized current_hmis_user so it re-checks impersonation
    @current_hmis_user = nil

    render_success
  end

  def destroy
    return render_error('Not impersonating') unless impersonating?

    manager = ImpersonationManager.new(session)
    manager.clear

    # Clear memoized current_hmis_user so it re-checks impersonation
    @current_hmis_user = nil

    render_success
  end

  protected

  def authorize_action
    return not_authorized! unless true_hmis_user.can_impersonate_users?
  end

  def render_success
    payload = current_hmis_user&.current_user_api_values || {}
    payload[:impersonating] = impersonating?

    # Add true user info when impersonating
    if impersonating? && true_hmis_user
      payload[:trueUser] = {
        id: true_hmis_user.id.to_s,
        name: true_hmis_user.name,
      }
    end

    # Calculate session duration from JWT token expiration
    # The JWT token represents the true user's session (even when impersonating)
    access_token = request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN']
    if access_token.present?
      jwt_helper = JwtHelper.new(access_token: access_token)
      if jwt_helper.token? && jwt_helper.validate!
        expiration_time = jwt_helper.expiration_time
        if expiration_time
          # Return remaining seconds until expiration
          payload[:sessionDuration] = [(expiration_time - Time.current).to_i, 0].max
        end
      end
    end

    render json: payload
  end

  def render_error(message)
    render status: :bad_request, json: { error: message }
  end
end
