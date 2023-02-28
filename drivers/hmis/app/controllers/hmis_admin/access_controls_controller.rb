###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisAdmin::AccessControlsController < ApplicationController
  include ViewableEntities
  include EnforceHmisEnabled

  before_action :require_hmis_admin_access!
  before_action :set_access_control, only: [:edit, :update, :destroy]

  def index
    @access_controls = access_control_scope.order(:role_id)
    @pagy, @access_controls = pagy(@access_controls)
  end

  def new
    @acl = access_control_scope.new
  end

  def create
    @acl = access_control_scope.new
    @acl.update(access_control_params)
    @acl.save
    respond_with(@acl, location: hmis_admin_access_controls_path)
  end

  def edit
  end

  def destroy
    @acl.destroy
    redirect_to({ action: :index }, notice: 'Access Control List removed.')
  end

  private def access_control_scope
    Hmis::AccessControl
  end

  private def access_control_params
    params.require(:access_control).permit(
      :role_id,
      :access_group_id,
    )
  end

  private def set_access_control
    @acl = access_control_scope.find(params[:id].to_i)
    # Set a name to be used by the user_members_table partial
    @acl.define_singleton_method(:name) { "Access Control List #{id}" }
  end
end
