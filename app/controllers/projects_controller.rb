###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class ProjectsController < ApplicationController
  before_action :require_can_view_projects!
  before_action :require_can_edit_projects!, only: [:edit, :update]
  before_action :set_project, only: [:show, :update, :edit]

  include ArelHelper

  def index
    # search
    @projects = if params[:q].present?
      project_source.text_search(params[:q])
    else
      project_scope
    end
    # sort / paginate
    at = project_scope.arel_table
    column = at[sort_column.to_sym]
    column = o_t[:OrganizationName] if sort_column == 'organization_id'
    sort = column.send(sort_direction)
    # Filter
    @projects = @projects.filter(filter_columns) if params[:project].present?
    @projects = @projects.
      includes(:organization).
      preload(:geographies).
      preload(:inventories).
      order(sort).
      page(params[:page]).per(50)
  end

  def show
    @clients = @project.service_history_enrollments.entry.
      preload(:client).
      order(she_t[:first_date_in_program].desc, she_t[:last_date_in_program].desc).
      page(params[:page]).per(25)
  end

  def edit
  end

  def update
    @project.update(project_params)
    respond_with @project, location: project_path(@project)
  end

  private def project_params
    params.require(:project).permit(
      :act_as_project_type,
      :hud_continuum_funded,
      :housing_type_override,
      :uses_move_in_date,
      :confidential,
      :operating_start_date_override,
      :active_homeless_status_override,
      :include_in_days_homeless_override,
    )
  end

  private def project_scope
    project_source.viewable_by current_user
  end

  private def project_source
    GrdaWarehouse::Hud::Project
  end

  private def set_project
    @project = project_source.
      includes(:organization, :geographies, :inventories, :funders).
      find(params[:id].to_i)
  end

  # whitelist filter-able columns
  private def filter_columns
    params.require(:project).
      permit(ProjectType: [], OrganizationID: [], data_source_id: [])
  end

  def sort_column
    project_source.column_names.include?(params[:sort]) ? params[:sort] : 'ProjectName'
  end

  def sort_direction
    ['asc', 'desc'].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def flash_interpolation_options
    { resource_name: 'Project' }
  end
end
