class ProjectGroupsController < ApplicationController
  before_action :require_can_edit_project_groups!
  before_action :set_project_group, only: [:edit, :update]

  def index
    @project_groups = GrdaWarehouse::ProjectGroup.
      includes(:projects).order(name: :asc)
  end

  def new
    @project_group = GrdaWarehouse::ProjectGroup.new
  end

  def create
      @project_group = GrdaWarehouse::ProjectGroup.new
    begin
      @project_group.assign_attributes(name: group_params[:name])
      @project_group.project_ids = group_params[:projects]
      @project_group.save
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
        projects: []
      )
  end

  def set_project_group
    @project_group = GrdaWarehouse::ProjectGroup.find(params[:id].to_i)
  end
end
