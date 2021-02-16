###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::ClientDetails
  class ActivesController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    include SubpopulationHistoryScope
    include ClientDetailReports

    before_action :set_limited, only: [:index]
    before_action :set_filter

    def index
      @enrollments = active_client_service_history
      @clients = GrdaWarehouse::Hud::Client.where(id: @enrollments.keys).preload(:source_clients).index_by(&:id)

      respond_to do |format|
        format.html {}
        format.xlsx do
          require_can_view_clients!
        end
      end
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

    def service_history_columns
      {
        client_id: she_t[:client_id],
        project_id: she_t[:project_id],
        first_date_in_program: she_t[:first_date_in_program],
        last_date_in_program: she_t[:last_date_in_program],
        project_name: she_t[:project_name],
        project_type: she_t[service_history_source.project_type_column],
        organization_id: she_t[:organization_id],
        first_name: c_t[:FirstName],
        last_name: c_t[:LastName],
        enrollment_group_id: she_t[:enrollment_group_id],
        destination: she_t[:destination],
        living_situation: e_t[:LivingSituation],
        ethnicity: c_t[:Ethnicity].as('Ethnicity'),
      }.merge(GrdaWarehouse::Hud::Client.race_fields.map { |f| [f.to_sym, c_t[f].as(f.to_s)] }.to_h)
    end

    def active_client_service_history
      enrollment_scope.pluck(*service_history_columns.values).
        map do |row|
        Hash[service_history_columns.keys.zip(row)]
      end.
        group_by { |m| m[:client_id] }
    end

    private def enrollment_scope
      residential_service_history_source.joins(:client, :enrollment).
        with_service_between(start_date: @filter.start, end_date: @filter.end).
        open_between(start_date: @filter.start, end_date: @filter.end).
        distinct.
        order(first_date_in_program: :asc)
    end

    def residential_service_history_source
      res_scope = history_scope(service_history_source.residential, @filter.sub_population)
      res_scope = filter_for_project_types(res_scope)
      res_scope = filter_for_organizations(res_scope)
      res_scope = filter_for_projects(res_scope)
      res_scope = filter_for_age_ranges(res_scope)
      res_scope = filter_for_hoh(res_scope)
      res_scope = filter_for_coc_codes(res_scope)
      res_scope = filter_for_gender(res_scope)
      res_scope = filter_for_race(res_scope)
      res_scope = filter_for_ethnicity(res_scope)
      res_scope
    end
  end
end
