###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class CensusesController < ApplicationController
  include WarehouseReportAuthorization
  include BaseFilters

  before_action :require_can_view_clients!, only: [:details]
  before_action :set_report, only: [:index, :details]
  prepend_before_action :parse_filter_params, only: [:date_range]
  # skip_before_action :report_visible?, only: [:date_range]
  # skip_before_action :require_can_view_any_reports!, only: [:date_range]
  include ArelHelper

  def index
  end

  def details
    klass = Censuses::Base.available_census_types.detect { |m| m.to_s == params[:type] } || Censuses::CensusByProgram
    census = klass.new
    @date = params[:date].to_date
    if params[:project].present?
      @census_detail_name = census.detail_name(params[:project], user: current_user)
      ds_id, org_id, p_id = params[:project].split('-')
      @clients = census.clients_for_date(current_user, @date, ds_id, org_id, p_id)

      @yesterday_client_count = census.clients_for_date(current_user, @date - 1.day, ds_id, org_id, p_id).size
      @prior_year_averages = census.prior_year_averages(@date.year - 1, ds_id, org_id, p_id, user: current_user)

    elsif params[:project_type].present?
      # Whitelist project_types
      project_type = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.keys.detect { |m| m == params[:project_type].downcase.to_sym }

      @census_detail_name = census.detail_name(project_type)

      if params[:veteran].present?
        if params[:veteran] == 'Veteran Count'
          @census_detail_name = "Veterans in #{@census_detail_name}"
          @clients = census.clients_for_date(current_user, @date, project_type, :veterans)
          @yesterday_client_count = census.clients_for_date(current_user, @date - 1.day, project_type, :veterans).size
          @prior_year_averages = census.prior_year_averages(@date.year - 1, project_type, :veterans, user: current_user)
        else
          @census_detail_name = "Non-Veterans in #{@census_detail_name}"
          @clients = census.clients_for_date(current_user, @date, project_type, :non_veterans)
          @yesterday_client_count = census.clients_for_date(current_user, @date - 1.day, project_type, :non_veterans).size
          @prior_year_averages = census.prior_year_averages(@date.year - 1, project_type, :non_veterans, user: current_user)
        end
      else
        @clients = census.clients_for_date(current_user, @date, project_type)
        @yesterday_client_count = census.clients_for_date(current_user, @date - 1.day, project_type).size
        @prior_year_averages = census.prior_year_averages(@date.year - 1, project_type, :all_clients, user: current_user)
      end
    else
      @census_detail_name = 'All'
      @clients = census.clients_for_date(current_user, @date)
      @yesterday_client_count = census.clients_for_date(current_user, @date - 1.day).size
    end

    # Note: ProjectName is already confidentialized here
    @involved_projects = @clients.map { |row| [row['project_id'], row['ProjectName']] }.to_h
    respond_to do |format|
      format.html {}
      format.xlsx {}
    end
  end

  private def set_report
    @report = Censuses::CensusByProgram.new(@filter)
  end

  def date_range
    @census = Censuses::CensusByProgram.new(@filter)

    render json: @census.for_date_range
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
      'Nightly Client Count and Available Beds' => :inventory,
      'Nightly Veteran vs Non-Veteran' => :veteran,
    }
  end
  helper_method :available_aggregation_types

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
    params[:filters] = JSON.parse(params[:filters])
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
