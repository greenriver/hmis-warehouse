###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CensusesController < ApplicationController
  include WarehouseReportAuthorization
  include BaseFilters

  before_action :require_can_view_clients!, only: [:details]
  before_action :set_report, only: [:date_range, :details]
  prepend_before_action :parse_filter_params, only: [:date_range, :details]
  # skip_before_action :report_visible?, only: [:date_range]
  # skip_before_action :require_can_view_any_reports!, only: [:date_range]
  include ArelHelper

  def index
  end

  def details
    @date = params[:date].to_date

    population = :clients
    if @filter.aggregation_type.to_sym == :veteran
      population = params[:dataset] == 'Veteran Count' ? :veterans : :non_veterans
    end

    # parse slug <datasource-or-ptype>-<org>-<proj>
    data_source_or_project_type, organization, project = params[:census_detail_slug].split('-')
    if @filter.aggregation_level.to_sym == :by_project_type
      project_type = data_source_or_project_type.to_sym
      data_source = 'all'
    else
      project_type = 'all'
      data_source = data_source_or_project_type
    end

    census_details = [project_type, data_source, organization, project]
    @clients = @report.clients_for_date(@date, *census_details, population)
    @yesterday_client_count = @report.clients_for_date(@date - 1.day, *census_details, population).size
    @prior_year_averages = @report.prior_year_averages(@date.year - 1, *census_details, population)

    # Note: ProjectName is already confidentialized here
    @involved_projects = @clients.map { |row| [row['project_id'], row['ProjectName']] }.to_h

    @census_detail_name = @report.detail_name(@involved_projects.count, *census_details)
    @census_detail_name.prepend('Veterans in ') if population == :veterans
    @census_detail_name.prepend('Non-Veterans in ') if population == :non_veterans

    respond_to do |format|
      format.html {}
      format.xlsx {}
    end
  end

  def date_range
    render json: @report.for_date_range
  end

  private def project_scope
    GrdaWarehouse::Hud::Project.all
  end

  def available_aggregation_levels
    {
      'By Project' => :by_project,
      'By Organization' => :by_organization,
      'By Data Source' => :by_data_source,
      'By Project Type' => :by_project_type,
    }
  end
  helper_method :available_aggregation_levels

  def available_aggregation_types
    {
      'Nightly Client Count vs Available Beds' => :inventory,
      'Nightly Veteran vs Non-Veteran' => :veteran,
    }
  end
  helper_method :available_aggregation_types

  private def set_report
    @report = Censuses::CensusReport.new(@filter)
  end

  private def set_filter
    @filter = filter_class.new(
      filter_params.merge(
        user_id: current_user.id,
        default_start: 1.month.ago,
        default_end: 1.day.ago,
      ),
    )
  end

  private def parse_filter_params
    params[:filters] = JSON.parse(params[:filters]) if params[:filters].instance_of?(String)
  end

  def filter_params
    return {} unless params[:filters]

    params.require(:filters).permit(filter_class.new(user_id: current_user.id).known_params)
  end
  helper_method :filter_params

  private def filter_class
    ::Filters::CensusReportFilter
  end
end
