###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
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
        client_id: she_t[:client_id],
        date: she_t[:date],
        destination: she_t[:destination],
        first_name: c_t[:FirstName],
        last_name: c_t[:LastName],
        project_name: she_t[:project_name],
        ethnicity: c_t[:Ethnicity],
      }.merge(GrdaWarehouse::Hud::Client.race_fields.map { |f| [f.to_sym, c_t[f]] }.to_h)
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
      hsh_scope = filter_for_coc_codes(hsh_scope)
      hsh_scope = filter_for_gender(hsh_scope)
      hsh_scope = filter_for_race(hsh_scope)
      hsh_scope = filter_for_ethnicity(hsh_scope)
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
        :gender,
        :race,
        :ethnicity,
        age_ranges: [],
        organization_ids: [],
        project_ids: [],
        project_type_codes: [],
        coc_codes: [],
      )
    end
  end
end
