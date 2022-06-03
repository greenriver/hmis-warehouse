###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class YouthIntakeExportController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_filter, only: [:index, :create]

    def index
    end

    def create
      @intakes = GrdaWarehouse::YouthIntake::Base.ordered.
        visible_by?(current_user).
        open_between(start_date: @filter.start, end_date: @filter.end)
      @referrals = GrdaWarehouse::Youth::YouthReferral.ordered.
        joins(:client).
        preload(:client, :youth_intakes).
        visible_by?(current_user).
        between(start_date: @filter.start, end_date: @filter.end)
      @dfas = GrdaWarehouse::Youth::DirectFinancialAssistance.ordered.
        joins(:client).
        preload(:client, :youth_intakes).
        visible_by?(current_user).
        between(start_date: @filter.start, end_date: @filter.end)
      @case_managements = GrdaWarehouse::Youth::YouthCaseManagement.ordered.
        joins(:client).
        preload(:client, :youth_intakes).
        visible_by?(current_user).
        between(start_date: @filter.start, end_date: @filter.end)
      @follow_ups = GrdaWarehouse::Youth::YouthFollowUp.ordered.
        joins(:client).
        preload(:client, :youth_intakes).
        visible_by?(current_user).
        between(start_date: @filter.start, end_date: @filter.end)

      commit = params[:commit]
      respond_to do |format|
        format.xlsx do
          case commit
          when 'Download Data'
            xlsx_filename = "Youth Intake Export #{Time.current.to_s.delete(',')}.xlsx"
            render(xlsx: 'index', filename: xlsx_filename)
          when 'Download Per-Client Data'
            zip_filename = "Youth Intake Exports #{Time.current.to_s.delete(',')}.zip"
            zip_exporter = GrdaWarehouse::Youth::ZipExporter.new(
              intakes: @intakes,
              referrals: @referrals,
              dfas: @dfas,
              case_managements: @case_managements,
              follow_ups: @follow_ups,
              controller: self,
            )
            send_data(zip_exporter.export!, filename: zip_filename)
          end
        end
      end
    end

    private def set_filter
      @filter = ::Filters::DateRangeAndSources.new(filter_params)
    end

    private def filter_params
      @filter_params = { user_id: current_user.id }
      @filter_params.merge!(report_params[:filter]) if report_params[:filter].present?
      @filter_params['start'] ||= (Date.current - 1.months).beginning_of_month
      @filter_params['end'] ||= (Date.current - 1.months).end_of_month
      @filter_params
    end

    private def report_scope
      GrdaWarehouse::WarehouseReports::Youth::Export.where(user_id: current_user.id)
    end

    private def report_params
      params.permit(
        filter: [
          :start,
          :end,
          :start_age,
          :end_age,
          project_ids: [],
          organization_ids: [],
          data_source_ids: [],
          cohort_ids: [],
        ],
      )
    end

    def flash_interpolation_options
      { resource_name: 'Youth Export' }
    end
  end
end
