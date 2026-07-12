###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module WarehouseReports
  class ClientLookupsController < ApplicationController
    include WarehouseReportAuthorization

    def index
      @filter = ::Filters::ClientLookup.new(user_id: current_user.id, enforce_one_year_range: false)
      @filter.update(report_params)
      @map_enrollments = map_enrollments?
      respond_to do |format|
        format.html {}
        format.xlsx do
          unless @filter.any_effective_project_ids?
            message = 'At least one Data Source, Organization, or Project must be selected'
            redirect_to warehouse_reports_client_lookups_path(report: redirect_report_params), alert: message
            next
          end

          @report = WarehouseReports::ClientLookups::Report.new(
            filter: @filter,
            user: current_user,
            map_enrollments: @map_enrollments,
          )
          unless @report.any_authorized_projects?
            message = 'you do not have permission to view the selected project(s) for this report'
            redirect_to warehouse_reports_client_lookups_path(report: redirect_report_params), alert: message
            next
          end

          @rows = @report.rows
          send_data @report.to_xlsx(@rows), filename: 'client_lookups.xlsx', type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        end
      end
    end

    private def report_params
      return nil unless params[:report].present?

      params.require(:report).permit(@filter.known_params)
    end

    private def map_enrollments?
      ActiveModel::Type::Boolean.new.cast(params.dig(:report, :map_enrollments))
    end

    # `map_enrollments` isn't part of `@filter.known_params`, so `report_params` drops it.
    # Carry it through the guard-clause redirects so the checkbox re-renders in the state
    # the user submitted instead of silently reverting to unchecked.
    private def redirect_report_params
      report_params.to_h.merge(map_enrollments: @map_enrollments)
    end
  end
end
