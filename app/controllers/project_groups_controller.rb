###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ProjectGroupsController < ApplicationController
  before_action :require_can_edit_project_groups!
  before_action :require_can_import_project_groups!, only: [:maintenance, :import]
  before_action :set_project_group, only: [:edit, :update, :destroy]
  before_action :set_access, only: [:edit, :update]

  def index
    @project_groups = project_group_scope
    @project_groups = @project_groups.text_search(params[:q]) if params[:q].present?
    @pagy, @project_groups = pagy(@project_groups)
  end

  def new
    @project_group = project_group_source.new
    set_access
  end

  def create
    @project_group = project_group_source.new
    begin
      @project_group.assign_attributes(name: group_params[:name])
      @project_group.options = ::Filters::HudFilterBase.new(user_id: current_user.id, project_type_numbers: []).update(filter_params).to_h
      @project_group.save
      users = user_params[:users]&.reject(&:empty?)
      @project_group.update_access(users.map(&:to_i)) if users.present?
      @project_group.maintain_projects!
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
      @project_group.options = ::Filters::HudFilterBase.new(user_id: current_user.id, project_type_numbers: []).update(filter_params).to_h
      @project_group.save
      if user_params.key?(:users)
        users = user_params[:users]&.reject(&:empty?)
        @project_group.update_access(users.map(&:to_i))
      end
      @project_group.maintain_projects!
    rescue Exception => e
      flash[:error] = e.message
      render action: :edit
      return
    end
    redirect_to action: :index
  end

  def destroy
    @project_group.destroy
    respond_with(@project_group, location: project_groups_path)
  end

  def maintenance
  end

  def import
    file = maintenance_params[:file]
    errors = project_group_source.import_csv(file)
    if errors.any?
      @errors = errors
      render action: :maintenance
    else
      flash[:notice] = 'Project groups imported'
      redirect_to action: :index
    end
  end

  private def maintenance_params
    params.require(:import).permit(:file)
  end

  def filter_params
    params.require(:filters).permit(::Filters::HudFilterBase.new(user_id: current_user.id).known_params)
  end

  def group_params
    params.require(:filters).
      permit(
        :name,
      )
  end

  def user_params
    params.require(:filters).
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

  def flash_interpolation_options
    { resource_name: 'Project Group' }
  end
end
