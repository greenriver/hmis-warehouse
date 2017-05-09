class CensusesController < ApplicationController
  before_action :require_can_view_censuses!
  include ArelHelper
  # default view grouped by project
  def index
    # Whitelist census types
    klass = Censuses::Base.available_census_types.detect{|m| m.to_s == params[:type]} || Censuses::CensusBedNightProgram
    @census = klass.new
    @start_date = params[:start_date].try(:to_date) || 1.month.ago.to_date
    @end_date = params[:end_date].try(:to_date) || 1.day.ago.to_date
    @types = census_types
  end

  def details
    klass = Censuses::Base.available_census_types.detect{|m| m.to_s == params[:type]} || Censuses::CensusByProgram
    census = klass.new
    @date = params[:date].to_date

    if params[:project].present?
      @census_detail_name = census.detail_name(params[:project])
      ds_id, org_id, p_id = params[:project].split('-')
      scope = service_history_scope_by_project(ds_id, org_id, p_id)
      @clients = census.for_date(@date, scope: scope)
      @yesterday_client_count = census.for_date(@date - 1.day, scope: scope).size
      @prior_year_averages = load_prior_year_averages_by_project(@date.year - 1, ds_id, org_id, p_id)
      @involved_projects = project_scope.where(data_source_id: ds_id, ProjectID: p_id)
    elsif params[:project_type].present?
      project_type = params[:project_type].downcase.to_sym
      pt_codes = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[project_type]
      @census_detail_name = census.detail_name(project_type)
      scope = service_history_scope.joins(:client).where(project_type: pt_codes)
      sh_scope = scope.where(warehouse_client_service_history: {date: @date})

      base_project_scope = project_scope.joins(:service_history).distinct

      if params[:veteran].present?
        @involved_projects = base_project_scope.merge(sh_scope.joins(:client).where(Client: {VeteranStatus: 1}))
        if params[:veteran] == 'Veteran Count'
          @census_detail_name = "Veterans in #{@census_detail_name}"
          scope = scope.where(Client: {VeteranStatus: 1})
          @prior_year_averages = load_prior_year_averages_by_project_type(@date.year - 1, project_type, true)
        else
          @census_detail_name = "Non-Veterans in #{@census_detail_name}"
          scope = scope.where.not(Client: {VeteranStatus: 1})
          @prior_year_averages = load_prior_year_averages_by_project_type(@date.year - 1, project_type, false)
        end
      else
        @involved_projects = base_project_scope.merge(sh_scope)
      end
      @clients = census.for_date(@date, scope: scope)
      @yesterday_client_count = census.for_date(@date - 1.day, scope: scope).size
      @prior_year_averages ||= load_prior_year_averages_by_project_type(@date.year - 1, project_type)
    else
      @census_detail_name = 'All'
      @clients = census.for_date(@date)
      @yesterday_client_count = census.for_date(@date - 1.day, scope: scope).size
    end
    respond_to do |format|
      format.html {}
      format.xlsx {}
    end
  end

  def date_range
    klass = Censuses::Base.available_census_types.detect{|m| m.to_s == params[:type]} || Censuses::CensusByProgram
    @census = klass.new
    start_date = params[:start_date]
    end_date = params[:end_date]
    scope = nil
    # Allow single program display
    if params[:project_id].present? && params[:data_source_id].present?
      scope = GrdaWarehouse::CensusByProject.where(ProjectID: params[:project_id].to_i, data_source_id: params[:data_source_id].to_i)
    end
    render json: @census.for_date_range(start_date, end_date, scope: scope)
  end

  private def project_scope
    GrdaWarehouse::Hud::Project
  end

  private def client_scope
    GrdaWarehouse::Hud::Client.destination
  end

  private def census_by_year_scope
    GrdaWarehouse::CensusByYear.residential
  end

  private def service_history_scope
    GrdaWarehouse::ServiceHistory.service
  end

  private def census_by_year_project_type_scope
    GrdaWarehouse::CensusByProjectType.residential
  end

  private def census_types
    {
      'ES Bed-night only shelters': 'Censuses::CensusBedNightProgram',
      'By Project Type': 'Censuses::CensusByProjectType',
      'By Program': 'Censuses::CensusByProgram',
      'Veteran': 'Censuses::CensusVeteran',
    }
  end

  private def load_prior_year_averages_by_project year, ds_id, org_id, p_id
    scope = census_by_year_scope.where(year: year)
    if ds_id != 'all'
      scope = scope.where(data_source_id: ds_id.to_i)
    end
    if org_id != 'all'
      scope = scope.where(OrganizationID: org_id)
    end
    if p_id != 'all'
      scope = scope.where(ProjectID: p_id)
    end
    client_count = scope.map{|m| m[:client_count]}.compact.reduce(0, :+)
    ave_days_of_service_count = scope.map{|m| m[:days_of_service]}.compact.reduce(0, :+)/scope.size.to_f
    ave_client_count = 0
    if scope.map{|m| m[:days_of_service]}.compact.reduce(0, :+)/scope.size.to_f > 0
      ave_client_count = (client_count/ave_days_of_service_count.to_f).round(2)
    end

    {}.tap do |m|
      m[:year] = year
      m[:ave_client_count] = ave_client_count
      m[:ave_bed_inventory] = scope.map{|m| m[:bed_inventory]}.reduce(0, :+)/scope.size.to_f
      m[:ave_seasonal_inventory] = scope.map{|m| m[:seasonal_inventory]}.compact.reduce(0, :+)/scope.size.to_f
      m[:ave_overflow_inventory] = scope.map{|m| m[:overflow_inventory]}.compact.reduce(0, :+)/scope.size.to_f
    end
  end

  private def load_prior_year_averages_by_project_type year, project_type, veteran=nil
    scope = census_by_year_project_type_scope
    if census_by_year_project_type_scope.engine.postgres?
      scope = scope.where(['extract(year from date) = ?', year])
    else
      scope = scope.where(['year(date) = ?', year])
    end
    scope = scope.
      where(ProjectType: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[project_type])
    if veteran.present?
      scope = scope.where(veteran: veteran)
    end
    client_count = scope.map{|m| m[:client_count].to_i}.compact.reduce(0, :+)
    ave_days_of_service_count = scope.map{|m| m[:date]}.uniq.size

    {}.tap do |m|
      m[:year] = year
      m[:ave_client_count] = (client_count/ave_days_of_service_count.to_f).round(2)
      m[:ave_bed_inventory] = nil
      m[:ave_seasonal_inventory] = nil
      m[:ave_overflow_inventory] = nil
    end
  end

  private def service_history_scope_by_project ds_id, org_id, p_id
    scope = service_history_scope
    if ds_id != 'all'
      scope = scope.where(data_source_id: ds_id.to_i)
    end
    if org_id != 'all'
      scope = scope.where(organization_id: org_id)
    end
    if p_id != 'all'
      scope = scope.where(project_id: p_id)
    end
    return scope
  end
end
