###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Admin::AccessControlsController < ApplicationController
  include ViewableEntities
  include ArelHelper

  before_action :require_can_edit_users!
  before_action :set_access_control, only: [:edit, :update, :destroy]

  def index
    @access_controls = access_control_scope.
      joins(:role, :collection).
      order(r_t[:name].asc, collection_t[:name].asc).
      filtered(params[:filter])
    @pagy, @access_controls = pagy(@access_controls)
    @active_filter = filter_params[:filter]&.values&.any?(&:present?)
  end

  def new
    @access_control = access_control_scope.new
  end

  def create
    @access_control = access_control_scope.new
    @access_control.update(access_control_params)
    @access_control.save
    respond_with(@access_control, location: admin_access_controls_path)
  end

  def edit
  end

  def update
    @access_control.update(access_control_params)
    @access_control.save

    respond_with(@access_control, location: admin_access_controls_path)
  end

  def destroy
    @access_control.destroy
    respond_with(@access_control, location: admin_access_controls_path)
  end

  def assign
    # TODO: this isn't built
    flash[:notice] = "TODO #{user.name} was added to selected Access Controls"
    redirect_to action: :index
  end

  private def access_control_scope
    AccessControl.all
  end

  private def filter_params
    params.permit(
      filter: [
        :user_group_id,
        :collection_id,
        :role_id,
        :user_id,
      ],
    )
  end

  private def access_control_params
    params.require(:access_control).permit(
      :role_id,
      :collection_id,
      :user_group_id,
    )
  end

  private def set_access_control
    @access_control = access_control_scope.find(params[:id].to_i)
  end
end
