###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::ImpersonationsController < Hmis::BaseController
  before_action :attach_data_source_id
  before_action :authorize_action

  def create
    return render_error("Already impersonating #{true_hmis_user.id} => #{current_hmis_user.id}") if impersonating?

    user = Hmis::User.with_hmis_access_in_data_source(current_hmis_user.hmis_data_source_id).find(params[:user_id])

    return render_error('Cannot impersonate current user') if user.id == current_hmis_user.id

    # Use the instance policy to confirm authorization for impersonating *this* user.
    # In practice this is a redundant check, since we already checked global permission (in the authorize_action),
    # confirmed the user to be impersonated is in the current data source, and confirmed it isn't the current user.
    return not_authorized! unless current_hmis_user.policy_for(user, policy_type: :hmis_user).can_impersonate?

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
    return not_authorized! unless true_hmis_user.policy_for(Hmis::User, policy_type: :hmis_user).can_impersonate_users?
  end

  def render_success
    render json: current_user_payload
  end

  def render_error(message)
    render status: :bad_request, json: { error: message }
  end
end
