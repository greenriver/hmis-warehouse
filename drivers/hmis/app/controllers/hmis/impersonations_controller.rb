###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ImpersonationsController < Hmis::BaseController
  before_action :attach_data_source_id
  before_action :authorize_action

  def create
    return render_error("Already impersonating #{true_hmis_user.id} => #{current_hmis_user.id}") if impersonating?

    scope = Hmis::Hud::User.viewable_by(current_hmis_user)
    hud_user = scope.find(params[:user])
    user = Hmis::User.from_hud_user(hud_user)

    return render_error('Cannot impersonate current user') if user.id == current_hmis_user.id

    impersonate_user(user)
    render_success
  end

  def destroy
    return render_error('Not impersonating') unless impersonating?

    stop_impersonating_user
    render_success
  end

  protected

  def impersonating?
    true_hmis_user != current_hmis_user
  end

  def authorize_action
    return not_authorized! unless true_hmis_user.can_impersonate_users?
  end

  def render_success
    head :ok
  end

  def render_error(message)
    render status: :bad_request, json: {error: message}
  end
end
