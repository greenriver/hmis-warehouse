###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ProjectsController < ApplicationController
  before_action :require_can_view_projects!
  before_action :require_can_delete_projects_or_data_sources!, only: [:destroy]
  before_action :require_can_edit_projects!, only: [:edit, :update]
  before_action :set_project, only: [:show, :update, :edit, :destroy]
  before_action :require_can_view_confidential_project_names!, if: -> { !can_edit_projects? && @project.confidential? }

  include ArelHelper

  def show
    @clients = @project.service_history_enrollments.entry.
      preload(:client).
      order(she_t[:first_date_in_program].desc, she_t[:last_date_in_program].desc)
    @pagy, @clients = pagy(@clients)
    url = 'censuses'
    @show_census = GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).viewable_by(current_user).exists?
  end

  def edit
  end

  def update
    @project.update(project_params)
    respond_with @project, location: project_path(@project)
  end

  def destroy
    name = @project.ProjectName
    @project.destroy_dependents!
    @project.destroy
    flash[:notice] = "Project: #{name} was successfully removed."
    respond_with @project, location: data_source_path(@project.data_source)
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
      :extrapolate_contacts,
      :hmis_participating_project_override,
      :operating_end_date_override,
      :tracking_method_override,
      :target_population_override,
    )
  end

  private def project_scope
    project_source.viewable_by(current_user, confidential_scope_limiter: :all)
  end

  private def project_source
    GrdaWarehouse::Hud::Project
  end

  private def set_project
    @project = project_scope.
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
