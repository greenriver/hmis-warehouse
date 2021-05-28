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
    include Filter::FilterScopes

    before_action :set_limited, only: [:index]
    before_action :set_filter

    def index
      @show_ph_destinations = true
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
      @project_types = @filter.project_type_ids
      scope = service_history_source.exit.
        joins(:client).
        homeless.
        order(:last_date_in_program)

      scope = history_scope(scope, @filter.sub_population)
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
