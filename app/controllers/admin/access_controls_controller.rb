###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Admin::AccessControlsController < ApplicationController
  include ViewableEntities
  include ArelHelper

  before_action :require_can_edit_users!
  before_action :set_access_control, only: [:edit, :update, :destroy]

  def index
    @access_controls = access_control_scope.joins(:role, :access_group).order(r_t[:name].asc, ag_t[:name].asc)
    @pagy, @access_controls = pagy(@access_controls)
  end

  def new
    @acl = access_control_scope.new
  end

  def create
    @acl = access_control_scope.new
    @acl.update(access_control_params)
    @acl.save
    respond_with(@acl, location: admin_access_controls_path)
  end

  def edit
  end

  def update
    @acl.update(access_control_params)
    @acl.save

    redirect_to({ action: :index }, notice: 'Access Control List updated.')
  end

  def destroy
    @acl.destroy
    redirect_to({ action: :index }, notice: 'Access Control List removed.')
  end

  private def access_control_scope
    AccessControl.selectable
  end

  private def access_control_params
    params.require(:access_control).permit(
      :role_id,
      :access_group_id,
    )
  end

  private def set_access_control
    @acl = access_control_scope.find(params[:id].to_i)
  end
end
