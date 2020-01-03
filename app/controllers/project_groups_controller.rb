###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class ProjectGroupsController < ApplicationController
  before_action :require_can_edit_project_groups!
  before_action :set_project_group, only: [:edit, :update]
  before_action :set_access, only: [:edit, :update]

  def index
    @project_groups = project_group_scope
  end

  def new
    @project_group = project_group_source.new
    set_access
  end

  def create
    @project_group = project_group_source.new
    begin
      @project_group.assign_attributes(name: group_params[:name])
      @project_group.project_ids = group_params[:projects]
      @project_group.save
      @project_group.update_access(user_params[:users].reject(&:empty?).map(&:to_i))
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
      @project_group.update_access(user_params[:users].reject(&:empty?).map(&:to_i))
    rescue Exception => e
      flash[:error] = e.message
      render action: :edit
      return
    end
    redirect_to action: :index
  end

  def destroy
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
    @project_group = project_group_source.find(params[:id].to_i)
  end

  def set_access
    @groups = @project_group.access_groups
    @group_ids = @project_group.access_group_ids
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
