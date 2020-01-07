###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::ClientDetails
  class ExitsController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_limited, only: [:index]
    before_action :set_projects
    before_action :set_organizations

    def index
      @sub_population = (params.try(:[], :range).try(:[], :sub_population).presence || :all_clients).to_sym
      date_range_options = params.permit(range: [:start, :end, :sub_population])[:range]
      # Also handle month based requests from javascript
      if params[:month].present?
        @sub_population = (params.try(:[], :sub_population).presence || :all_clients).to_sym
        month = params.permit(:month)
        @range = ::Filters::DateRangeWithSubPopulation.new(
          start: Date.strptime(month[:month], '%B %Y').beginning_of_month,
          end: Date.strptime(month[:month], '%B %Y').end_of_month,
          sub_population: @sub_population,
        )
      else
        @range = ::Filters::DateRangeWithSubPopulation.new(date_range_options)
      end
      columns = {
        client_id: she_t[:client_id].as('client_id').to_sql,
        date: she_t[:date].as('date').to_sql,
        destination: she_t[:destination].as('destination').to_sql,
        first_name: c_t[:FirstName].as('first_name').to_sql,
        last_name: c_t[:LastName].as('last_name').to_sql,
        project_name: she_t[:project_name].as('project_name').to_sql,
      }
      @buckets = Hash.new(0)

      @clients = exits_from_homelessness
      @clients = @clients.where(destination: ::HUD.permanent_destinations) if params[:ph]
      @clients = @clients.ended_between(start_date: @range.start, end_date: @range.end + 1.day).
        order(date: :asc).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end.each do |row|
          destination = row[:destination]
          destination = 99 unless HUD.valid_destinations.key?(row[:destination])
          @buckets[destination] += 1
        end

      respond_to do |format|
        format.html {}
        format.xlsx do
          require_can_view_clients!
        end
      end
    end

    def exits_from_homelessness
      scope = service_history_source.exit.
        joins(:client).
        homeless.
        order(:last_date_in_program)
      hsh_scope = history_scope(scope, @sub_population)
      hsh_scope = hsh_scope.joins(:organization).merge(GrdaWarehouse::Hud::Organization.where(id: @organization_ids)) if @organization_ids.any?
      hsh_scope = hsh_scope.joins(:project).merge(GrdaWarehouse::Hud::Project.where(id: @project_ids)) if @project_ids.any?
      hsh_scope
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
