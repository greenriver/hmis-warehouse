###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::ClientDetails
  class ActivesController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_limited, only: [:index]
    before_action :set_projects
    before_action :set_organizations

    def index
      @sub_population = (params.try(:[], :range).try(:[], :sub_population).presence || :all_clients).to_sym
      date_range_options = params.permit(range: [:start, :end, :sub_population])[:range]
      @range = ::Filters::DateRangeWithSubPopulation.new(date_range_options)

      @start_date = @range.start
      @end_date = @range.end

      @enrollments = active_client_service_history(range: @range)
      @clients = GrdaWarehouse::Hud::Client.where(id: @enrollments.keys).preload(:source_clients).index_by(&:id)

      respond_to do |format|
        format.html {}
        format.xlsx do
          require_can_view_clients!
        end
      end
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

    def service_history_columns
      {
        client_id: she_t[:client_id].to_sql,
        project_id: she_t[:project_id].to_sql,
        first_date_in_program: she_t[:first_date_in_program].to_sql,
        last_date_in_program: she_t[:last_date_in_program].to_sql,
        project_name: she_t[:project_name].to_sql,
        project_type: she_t[service_history_source.project_type_column].to_sql,
        organization_id: she_t[:organization_id].to_sql,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
        enrollment_group_id: she_t[:enrollment_group_id].to_sql,
        destination: she_t[:destination].to_sql,
        living_situation: e_t[:LivingSituation].to_sql,
      }
    end

    def active_client_service_history(range:)
      homeless_service_history_source.joins(:client, :enrollment).
        with_service_between(start_date: range.start, end_date: range.end).
        open_between(start_date: range.start, end_date: range.end).
        distinct.
        order(first_date_in_program: :asc).
        pluck(*service_history_columns.values).
        map do |row|
          Hash[service_history_columns.keys.zip(row)]
        end.
        group_by { |m| m[:client_id] }
    end

    def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(current_user))
    end

    def homeless_service_history_source
      hsh_scope = history_scope(service_history_source.homeless, @sub_population)
      hsh_scope = hsh_scope.joins(:organization).merge(GrdaWarehouse::Hud::Organization.where(id: @organization_ids)) if @organization_ids.any?
      hsh_scope = hsh_scope.joins(:project).merge(GrdaWarehouse::Hud::Project.where(id: @project_ids)) if @project_ids.any?
      hsh_scope
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
