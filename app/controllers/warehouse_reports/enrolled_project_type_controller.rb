###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class EnrolledProjectTypeController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    include SubpopulationHistoryScope
    include ClientDetailReports
    include Filter::FilterScopes

    before_action :set_filter

    def index
      @enrollments = service_history_scope.entry.
        open_between(start_date: @filter.start, end_date: @filter.end).
        joins(:client).
        preload(client: :processed_service_history).
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

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    private def service_history_scope
      @project_types = @filter.project_type_ids
      scope = history_scope(service_history_source.in_project_type(@filter.project_type_ids), @filter.sub_population)
      scope = filter_for_project_type(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope = filter_for_age(scope)
      scope = filter_for_head_of_household(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_gender(scope)
      scope = filter_for_race(scope)
      scope = filter_for_ethnicity(scope)
      scope
    end
  end
end
