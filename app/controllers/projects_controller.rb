###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ProjectsController < ApplicationController
  before_action :require_can_view_projects!
  before_action :require_can_delete_projects_or_data_sources!, only: [:destroy]
  before_action :require_can_edit_projects!, only: [:edit, :update]
  before_action :set_project, only: [:show, :update, :edit, :destroy]
  before_action :set_census_params, only: [:show]
  before_action :set_location_params, only: [:show]
  before_action :require_can_view_confidential_project_names!, if: -> { !can_edit_projects? && @project.confidential? }

  include ArelHelper

  def show
    @clients = @project.service_history_enrollments.entry.
      joins(:enrollment).
      preload(:client).
      order(she_t[:first_date_in_program].desc, she_t[:last_date_in_program].desc)
    @pagy, @clients = pagy(@clients)
  end

  def edit
  end

  def update
    @project.update(project_params)
    respond_with @project, location: project_path(@project)
  end

  def destroy
    name = @project.ProjectName
    DeleteItemJob.perform_later(item_id: @project.id, item_class: @project.class.name)
    flash[:notice] = "Project: #{name} was successfully queued for removal.  Please check back in a few minutes."
    respond_with @project, location: data_source_path(@project.data_source)
  end

  private def project_params
    params.require(:project).permit(
      :confidential,
      :active_homeless_status_override,
      :include_in_days_homeless_override,
      :extrapolate_contacts,
    )
  end

  private def set_census_params
    @show_census = GrdaWarehouse::WarehouseReports::ReportDefinition.
      where(url: 'censuses').
      viewable_by(current_user).exists?

    return unless @show_census

    @census_filter_params = {
      project_ids: [@project.id],
      start: Date.current - 3.years,
      end: Date.current - 1.day,
      aggregation_level: :by_project,
      aggregation_type: :inventory,
    }
  end

  private def set_location_params
    return unless RailsDrivers.loaded.include?(:client_location_history)

    @locations = @project.enrollment_location_histories.where(located_on: location_filter.range)
    @markers = @locations.map { |l| l.as_marker_for_project(current_user) }
    @bounds = ClientLocationHistory::Location.bounds(@locations)
    @options = {
      bounds: @bounds,
      cluster: true,
      marker_color: ClientLocationHistory::Location::MARKER_COLOR,
    }
  end

  private def location_filter
    @location_filter ||= filter_class.new(
      user_id: current_user.id,
      enforce_one_year_range: false,
    ).set_from_params(location_filter_params[:location_filters])
  end

  def location_filter_params
    opts = params
    opts[:location_filters] ||= {}
    opts[:location_filters][:enforce_one_year_range] = false
    opts[:location_filters][:start] ||= 1.year.ago
    opts[:location_filters][:end] ||= Date.current
    opts.permit(
      location_filters: [
        :start,
        :end,
      ],
    )
  end
  helper_method :location_filter_params

  private def filter_class
    ::Filters::FilterBase
  end

  private def project_scope
    project_source.viewable_by(current_user, confidential_scope_limiter: :all, permission: :can_view_projects)
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
