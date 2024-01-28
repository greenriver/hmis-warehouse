###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ImpersonationsController < Hmis::BaseController
  before_action :attach_data_source_id
  before_action :authorize_action

  def create
    return render_error("Already impersonating #{true_hmis_user.id} => #{current_hmis_user.id}") if impersonating?

    user = Hmis::User.with_hmis_access.find(params[:user_id])

    return render_error('Cannot impersonate current user') if user.id == current_hmis_user.id

    impersonate_hmis_user(user)
    render_success
  end

  def destroy
    return render_error('Not impersonating') unless impersonating?

    stop_impersonating_hmis_user
    render_success
  end

  protected

  def authorize_action
    return not_authorized! unless true_hmis_user.can_impersonate_users?
  end

  def render_success
    payload = current_hmis_user&.current_user_api_values || {}
    payload[:impersonating] = impersonating?
    render json: payload
  end

  def render_error(message)
    render status: :bad_request, json: { error: message }
  end
end
