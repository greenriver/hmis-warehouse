###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class FirstTimeHomelessController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_limited, only: [:index]
    before_action :set_projects
    before_action :set_organizations

    def index
      date_range_options = params.require(:first_time_homeless).permit(:start, :end) if params[:first_time_homeless].present?
      @range = ::Filters::DateRange.new(date_range_options)
      @sub_population = (params.try(:[], :first_time_homeless).try(:[], :sub_population) || :all_clients).to_sym

      if @range.valid?
        @first_time_client_ids = Set.new
        @project_type_codes = params[:first_time_homeless].try(:[], :project_types)&.map(&:presence)&.compact&.map(&:to_sym) || [:es, :sh, :so, :th]
        @project_types = []
        @project_type_codes.each do |code|
          @project_types += GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[code]
        end

        set_first_time_homeless_client_ids

        @clients = client_source.joins(first_service_history: [project: :organization]).
          merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
          preload(:first_service_history, first_service_history: [:organization, :project], source_clients: :data_source).
          where(she_t[:record_type].eq('first')).
          where(id: @first_time_client_ids.to_a).
          distinct.
          select(:id, :FirstName, :LastName, she_t[:date], :VeteranStatus, :DOB).
          order(she_t[:date], :LastName, :FirstName)
        @clients = @clients.merge(GrdaWarehouse::Hud::Organization.where(id: @organization_ids)) if @organization_ids.any?
        @clients = @clients.merge(GrdaWarehouse::Hud::Project.where(id: @project_ids)) if @project_ids.any?
      else
        @clients = client_source.none
      end
      respond_to do |format|
        format.html do
          @clients = @clients.page(params[:page]).per(25)
        end
        format.xlsx {}
      end
    end

    def set_first_time_homeless_client_ids
      @project_types.each do |project_type|
        @first_time_client_ids += first_time_homeless_within_range(project_type).distinct.pluck(:client_id)
      end
    end

    def first_time_homeless_within_range(project_type)
      first_scope = enrollment_source.entry.in_project_type(project_type).
        with_service_between(start_date: @range.start, end_date: @range.end).
        where(client_id: enrollment_source.first_date.
          started_between(start_date: @range.start, end_date: @range.end).
          in_project_type(project_type).select(:client_id))

      history_scope(first_scope, @sub_population)
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    # Present a chart of the counts from the previous year
    def summary
      @first_time_client_ids = Set.new
      start_date = params[:start] || 1.year.ago
      end_date = params[:end] || 1.day.ago
      @project_types = params.try(:[], :project_types) || '[]'
      @project_types = JSON.parse(params[:project_types])
      @project_types.map!(&:to_i)
      @project_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS if @project_types.empty?
      @sub_population = (params.try(:[], :sub_population) || :all_clients).to_sym

      @range = ::Filters::DateRange.new(start: start_date, end: end_date)

      set_first_time_homeless_client_ids

      @counts = enrollment_source.first_date.
        select(:date, :client_id).
        where(client_id: @first_time_client_ids.to_a).
        where(date: @range.range).
        in_project_type(@project_types).
        order(date: :asc).pluck(:date, :client_id).
        group_by { |date, _client_id| date }.
        map { |date, clients| [date, clients.count] }.to_h
      render json: @counts
    end

    def history_scope(scope, sub_population)
      scope_hash = {
        all_clients: scope,
        veteran: scope.veteran,
        youth: scope.unaccompanied_youth,
        parenting_youth: scope.parenting_youth,
        parenting_children: scope.parenting_juvenile,
        unaccompanied_minors: scope.unaccompanied_minors,
        individual_adults: scope.individual_adult,
        non_veteran: scope.non_veteran,
        family: scope.family,
        youth_families: scope.youth_families,
        children: scope.children_only,
      }
      scope_hash[sub_population.to_sym]
    end

    def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def service_source
      GrdaWarehouse::ServiceHistoryService
    end

    def set_organizations
      @organization_ids = begin
                            params[:first_time_homeless][:organization_ids].map(&:presence).compact.map(&:to_i)
                          rescue StandardError
                            []
                          end
    end

    def set_projects
      @project_ids = begin
                       params[:first_time_homeless][:project_ids].map(&:presence).compact.map(&:to_i)
                     rescue StandardError
                       []
                     end
    end
  end
end
