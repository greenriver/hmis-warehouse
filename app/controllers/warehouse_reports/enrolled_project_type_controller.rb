###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class EnrolledProjectTypeController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper

    before_action :set_date_range
    before_action :set_project_type
    before_action :set_projects
    before_action :set_organizations
    before_action :set_sub_population

    def index
      @enrollments = service_history_scope.entry.
        open_between(start_date: @start, end_date: @end).
        joins(:client).
        preload(:client).
        distinct.
        select(:client_id)

      @clients = client_source.where(id: @enrollments).order(:LastName, :FirstName)

      respond_to do |format|
        format.html do
          @clients = @clients.page(params[:page]).per(25)
        end
        format.xlsx do
          @clients
        end
      end
    end

    def set_date_range
      @start = (params.try(:[], :range).try(:[], :start) || 1.month.ago.beginning_of_month).to_date
      @end   = (params.try(:[], :range).try(:[], :end) || 1.month.ago.end_of_month).to_date
    end

    def set_project_type
      @project_type_codes = params.try(:[], :range).try(:[], :project_type)&.map(&:presence)&.compact&.map(&:to_sym) || [:es, :sh, :so, :th]
      @project_types = []
      @project_type_codes.each do |code|
        @project_types += GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[code]
      end
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

    def set_sub_population
      @sub_population = (params.try(:[], :range).try(:[], :sub_population).presence || :all_clients).to_sym
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    private def project_source
      GrdaWarehouse::Hud::Project.viewable_by(current_user)
    end

    private def service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    private def service_history_scope
      sh_scope = service_history_source.joins(:project).merge(project_source).where(computed_project_type: @project_types)

      sh_scope = sh_scope.merge(project_source.where(id: @project_ids)) if @project_ids.any?
      sh_scope = sh_scope.joins(:organization).merge(GrdaWarehouse::Hud::Organization.where(id: @organization_ids)) if @organization_ids.any?

      history_scope(sh_scope, @sub_population)
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
        parents: scope.family_parents,
        children: scope.children_only,
      }
      scope_hash[sub_population.to_sym]
    end
  end
end
