###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class FirstTimeHomelessController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    include SubpopulationHistoryScope
    include ClientDetailReports

    before_action :set_limited, only: [:index]
    before_action :set_filter

    def index
      @clients = client_source.joins(:first_service_history).
        where(id: first_time_homeless_client_ids).
        preload(
          :first_service_history,
          first_service_history: [:organization, :project],
          source_clients: :data_source,
        ).distinct.
        select(:id, :FirstName, :LastName, she_t[:date], :VeteranStatus, :DOB).
        order(she_t[:date], :LastName, :FirstName)

      respond_to do |format|
        format.html do
          @clients = @clients.page(params[:page]).per(25)
        end
        format.xlsx {}
      end
    end

    def first_time_homeless_client_ids
      @filter.project_type_codes = GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPE_CODES unless @filter.project_type_ids.present?
      @first_time_homeless_client_ids ||= begin
        ids = []
        # Ensure first project also has services in the correct project type
        @filter.project_type_ids.each do |project_type|
          ids += first_time_homeless_within_range(project_type).distinct.pluck(:client_id)
        end
        ids
      end
    end

    def first_time_homeless_within_range(project_type)
      scope = service_history_source.entry.in_project_type(project_type).
        with_service_between(start_date: @filter.start, end_date: @filter.end).
        where(client_id: service_history_source.first_date.
          started_between(start_date: @filter.start, end_date: @filter.end).
          in_project_type(project_type).select(:client_id))

      scope = history_scope(scope, @filter.sub_population)
      scope = filter_for_age_ranges(scope)
      scope = filter_for_hoh(scope)
      scope = filter_for_coc_codes(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope = scope.joins(:project).merge(GrdaWarehouse::Hud::Project.viewable_by(current_user))
      scope
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    # Present a chart of the counts from the previous year
    def summary
      @filter.start = 1.years.ago.to_date
      @filter.end = 1.days.ago.to_date
      @counts = service_history_source.first_date.
        select(:date, :client_id).
        where(client_id: first_time_homeless_client_ids).
        where(date: @filter.range).
        in_project_type(@filter.project_type_ids).
        order(date: :asc).pluck(:date, :client_id).
        group_by { |date, _client_id| date }.
        transform_values(&:count)

      render json: @counts
    end

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
        coc_codes: [],
      )
    end
  end
end
