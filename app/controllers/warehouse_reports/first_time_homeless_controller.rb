###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
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
      @clients = client_source.joins(first_service_history: [project: :organization]).
        merge(GrdaWarehouse::Hud::Project.viewable_by(current_user)).
        preload(
          :first_service_history,
          first_service_history: [:organization, :project],
          source_clients: :data_source,
        ).
        where(she_t[:record_type].eq('first')).
        where(id: first_time_homeless_client_ids).
        distinct.
        select(:id, :FirstName, :LastName, she_t[:date], :VeteranStatus, :DOB).
        order(she_t[:date], :LastName, :FirstName)

      # NOTE: not using filter_for_organizations as @clients are GrdaWarehouse::Hud::Client not SHE
      @clients = @clients.merge(GrdaWarehouse::Hud::Organization.where(id: @filter.organization_ids)) if @filter.organization_ids.any?
      @clients = @clients.merge(GrdaWarehouse::Hud::Project.where(id: @filter.project_ids)) if @filter.project_ids.any?

      respond_to do |format|
        format.html do
          @clients = @clients.page(params[:page]).per(25)
        end
        format.xlsx {}
      end
    end

    def first_time_homeless_client_ids
      @first_time_homeless_client_ids ||= begin
        ids = []
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
      )
    end
  end
end
