###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class EnrolledProjectTypeController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    include SubpopulationHistoryScope
    include ClientDetailReports

    before_action :set_filter

    def index
      @enrollments = service_history_scope.entry.
        open_between(start_date: @filter.start, end_date: @filter.end).
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

    # def set_project_type
    #   @project_type_codes = params.try(:[], :range).try(:[], :project_type)&.map(&:presence)&.compact&.map(&:to_sym) || [:es, :sh, :so, :th]
    #   @project_types = []
    #   @project_type_codes.each do |code|
    #     @project_types += GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[code]
    #   end
    # end

    private def filter_params
      return {} unless params[:filter].present?

      params.require(:filter).permit(
        :start,
        :end,
        :sub_population,
        :heads_of_household,
        :ph,
        age_ranges: [],
        organization_ids: [],
        project_ids: [],
        project_type_codes: [],
      )
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    private def service_history_scope
      scope = history_scope(service_history_source.in_project_type(@filter.project_type_ids), @filter.sub_population)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope = filter_for_age_ranges(scope)
      scope = filter_for_hoh(scope)
      scope
    end
  end
end
