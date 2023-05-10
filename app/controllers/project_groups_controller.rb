###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ProjectGroupsController < ApplicationController
  before_action :require_can_edit_some_project_groups!
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
    project_group_source.transaction do
      @project_group.assign_attributes(name: group_params[:name])
      filter = ::Filters::HudFilterBase.new(user_id: current_user.id, project_type_numbers: []).update(filter_params.merge(coc_codes: []))
      filter.coc_codes = []
      @project_group.options = filter.to_h
      if @project_group.save
        users = user_params[:editor_ids]&.reject(&:blank?)&.map(&:to_i)
        # If the user can't edit all project groups, make sure we add the user so they can access it later
        users << current_user.id
        @project_group.replace_access(User.find(users), scope: :editor)
        @project_group.maintain_projects!
        AccessGroup.maintain_system_groups(group: :project_groups)
      end
    end
    respond_with(@project_group, location: project_groups_path)
  end

  def edit
    @reports = @project_group.data_quality_reports.order(started_at: :desc)
  end

  def update
    project_group_source.transaction do
      @project_group.assign_attributes(name: group_params[:name])
      filter = ::Filters::HudFilterBase.new(user_id: current_user.id, project_type_numbers: []).update(filter_params)
      filter.coc_codes = []
      @project_group.options = filter.to_h
      @project_group.save
      if user_params.key?(:editor_ids)
        users = user_params[:editor_ids]&.reject(&:empty?)&.map(&:to_i)
        @project_group.replace_access(User.find(users), scope: :editor)
      end
      @project_group.maintain_projects!
    end

    respond_with(@project_group, location: project_groups_path)
  end

  def destroy
    @project_group.destroy
    AccessGroup.maintain_system_groups(group: :project_groups)
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
        editor_ids: [],
      )
  end

  def set_project_group
    @project_group = project_group_source.find(params[:id].to_i)
  end

  def set_access
    @editor_ids = @project_group.editable_access_control.user_ids
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
