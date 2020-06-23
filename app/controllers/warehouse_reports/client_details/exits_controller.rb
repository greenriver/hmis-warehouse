###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::ClientDetails
  class ExitsController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    include SubpopulationHistoryScope
    include ClientDetailReports

    before_action :set_limited, only: [:index]
    before_action :set_filter

    def index
      columns = {
        client_id: she_t[:client_id].as('client_id'),
        date: she_t[:date].as('date'),
        destination: she_t[:destination].as('destination'),
        first_name: c_t[:FirstName].as('first_name'),
        last_name: c_t[:LastName].as('last_name'),
        project_name: she_t[:project_name].as('project_name'),
      }
      @buckets = Hash.new(0)

      @clients = exits_from_homelessness
      @clients = @clients.where(destination: ::HUD.permanent_destinations) if filter_params[:ph]
      @clients = @clients.ended_between(start_date: @filter.start, end_date: @filter.end + 1.day).
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
      hsh_scope = history_scope(scope, @filter.sub_population)
      hsh_scope = filter_for_project_types(hsh_scope)
      hsh_scope = filter_for_organizations(hsh_scope)
      hsh_scope = filter_for_projects(hsh_scope)
      hsh_scope = filter_for_age_ranges(hsh_scope)
      hsh_scope = filter_for_hoh(hsh_scope)
      hsh_scope
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
