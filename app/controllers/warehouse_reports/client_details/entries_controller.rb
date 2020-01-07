###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::ClientDetails
  class EntriesController < ApplicationController
    include ArelHelper
    include ApplicationHelper
    include WarehouseReportAuthorization
    before_action :set_limited, only: [:index]
    before_action :set_projects
    before_action :set_organizations

    CACHE_EXPIRY = Rails.env.production? ? 8.hours : 20.seconds

    def index
      @sub_population = (params.try(:[], :range).try(:[], :sub_population).presence || :all_clients).to_sym
      date_range_options = params.permit(range: [:start, :end, :sub_population])[:range]
      @range = ::Filters::DateRangeWithSubPopulation.new(date_range_options)
      @project_type_codes = params.try(:[], :range).try(:[], :project_type)&.map(&:presence)&.compact&.map(&:to_sym) || [:es]
      @project_type = []
      @project_type_codes.each do |code|
        @project_type += GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[code]
      end

      @start_date = @range.start
      @end_date = @range.end

      @enrollments = enrollments_by_client(@project_type)
      # put clients in buckets
      @buckets = bucket_clients(@enrollments)

      @data = setup_data_structure(start_date: @start_date)
      respond_to do |format|
        format.html {}
        format.xlsx do
          require_can_view_clients!
        end
      end
    end

    def service_scope(project_type)
      homeless_service_history_source.
        with_service_between(start_date: @range.start, end_date: @range.end).
        in_project_type(project_type)
    end

    def enrollments_by_client(project_type)
      # limit to clients with an entry within the range and service within the range in the type
      involved_client_ids = homeless_service_history_source.
        entry.
        started_between(start_date: @range.start, end_date: @range.end).
        in_project_type(project_type).
        with_service_between(start_date: @range.start, end_date: @range.end).
        distinct.
        select(:client_id)
      # get all of their entry records regardless of date range
      homeless_service_history_source.
        entry.
        joins(:client, :organization).
        where(client_id: involved_client_ids).
        where(she_t[:first_date_in_program].lteq(@range.end)).
        in_project_type(project_type).
        order(first_date_in_program: :desc).
        pluck(*entered_columns.values).
        map do |row|
        Hash[entered_columns.keys.zip(row)]
      end.
        group_by { |row| row[:client_id] }
    end

    def history_scope(scope, sub_population)
      scope_hash = {
        all_clients: scope,
        veteran: scope.veteran,
        youth: scope.unaccompanied_youth,
        parenting_youth: scope.parenting_youth,
        parenting_children: scope.parenting_juvenile,
        individual_adults: scope.individual_adult,
        non_veteran: scope.non_veteran,
        family: scope.family,
        children: scope.children_only,
      }
      scope_hash[sub_population.to_sym]
    end

    def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(current_user))
    end

    def homeless_service_history_source
      scope = service_history_source.
        in_project_type(@project_type)
      hsh_scope = history_scope(scope, @sub_population)
      hsh_scope = hsh_scope.joins(:organization).merge(GrdaWarehouse::Hud::Organization.where(id: @organization_ids)) if @organization_ids.any?
      hsh_scope = hsh_scope.joins(:project).merge(GrdaWarehouse::Hud::Project.where(id: @project_ids)) if @project_ids.any?
      hsh_scope
    end

    def entered_columns
      {
        project_type: she_t[service_history_source.project_type_column].as('project_type').to_sql,
        first_date_in_program: she_t[:first_date_in_program].as('first_date_in_program').to_sql,
        last_date_in_program: she_t[:last_date_in_program].as('last_date_in_program').to_sql,
        client_id: she_t[:client_id].as('client_id').to_sql,
        project_name: she_t[:project_name].as('project_name').to_sql,
        first_name: c_t[:FirstName].as('first_name').to_sql,
        last_name: c_t[:LastName].as('last_name').to_sql,
        organization_name: o_t[:OrganizationName].as('organization_name').to_sql,
      }
    end

    def setup_data_structure(start_date:)
      month_name = start_date.to_time.strftime('%B')
      {
        first_time: {
          label: 'First time clients in the project type',
          data: [],
          backgroundColor: '#288BE4',
        },
        less_than_thirty: {
          label: "Clients with an entry in #{month_name} and an entry within 30 days prior to their most recent entry in #{month_name}",
          data: [],
          backgroundColor: '#704C70',
        },
        thirty_to_sixty: {
          label: "Clients with an entry in #{month_name} and between 30 and 60 days prior",
          data: [],
          backgroundColor: '#5672AA',
        },
        sixty_plus: {
          label: "Clients with an entry in #{month_name} and 60+ days prior",
          data: [],
          backgroundColor: '#45789C',
        },
      }
    end

    def bucket_clients(enrollments)
      buckets = {
        sixty_plus: Set.new,
        thirty_to_sixty: Set.new,
        less_than_thirty: Set.new,
        first_time: Set.new,
      }

      enrollments.each do |client_id, entries|
        if entries.count == 1
          buckets[:first_time] << client_id
        else
          days = days_since_last_entry(entries)
          if days < 30
            buckets[:less_than_thirty] << client_id
          elsif (30..60).cover?(days)
            buckets[:thirty_to_sixty] << client_id
          else # days > 60
            buckets[:sixty_plus] << client_id
          end
        end
      end
      buckets
    end

    def days_since_last_entry(enrollments)
      enrollments.first(2).map { |m| m[:first_date_in_program] }.reduce(:-).abs
    end

    def set_organizations
      @organization_ids = begin
                            params[:range][:organization_ids].map(&:presence).compact.map(&:to_i)
                          rescue StandardError
                            []
                          end
    end

    def set_projects
      @project_ids = begin
                       params[:range][:project_ids].map(&:presence).compact.map(&:to_i)
                     rescue StandardError
                       []
                     end
    end
  end
end
