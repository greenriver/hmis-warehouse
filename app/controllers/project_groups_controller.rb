###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class ProjectGroupsController < ApplicationController
  before_action :require_can_edit_project_groups!
  before_action :set_project_group, only: [:edit, :update]
  before_action :set_users_with_access, only: [:edit, :update]

  def index
    @project_groups = project_group_scope
  end

  def new
    @project_group = project_group_source.new
  end

  def create
    @project_group = project_group_source.new
    begin
      @project_group.assign_attributes(name: group_params[:name])
      @project_group.project_ids = group_params[:projects]
      @project_group.save
      update_permissions(@project_group)
    rescue Exception => e
      flash[:error] = e.message
      render action: :new
      return
    end
    redirect_to action: :index
  end

  def edit
    @reports = @project_group.data_quality_reports.order(started_at: :desc)
  end

  def update
    begin
      @project_group.assign_attributes(name: group_params[:name])
      @project_group.project_ids = group_params[:projects]
      @project_group.save
      update_permissions(@project_group)
    rescue Exception => e
      flash[:error] = e.message
      render action: :edit
      return
    end
    redirect_to action: :index
  end

  def destroy
  end

  def update_permissions(_project_group)
    user_ids = user_params[:users].reject(&:empty?).map(&:to_i) + [current_user.id]
    # add new user permissions
    added_users = user_ids - @project_group.user_viewable_entities.pluck(:user_id)
    added_users.each do |id|
      @project_group.user_viewable_entities.create(user_id: id)
    end
    # remove users that were removed from the permissions
    @project_group.user_viewable_entities.where.not(user_id: user_ids).destroy_all
  end

  def group_params
    params.require(:grda_warehouse_project_group).
      permit(
        :name,
        projects: [],
      )
  end

  def user_params
    params.require(:grda_warehouse_project_group).
      permit(
        users: [],
      )
  end

  def set_project_group
    @project_group = project_group_source.find(params[:id])
  end

  def set_users_with_access
    @user_ids_with_access = @project_group.user_viewable_entities.pluck(:user_id)
  end

  def project_group_source
    GrdaWarehouse::ProjectGroup
  end

  def project_group_scope
    project_group_source.
      editable_by(current_user).
      includes(:projects).order(name: :asc)
  end
end
