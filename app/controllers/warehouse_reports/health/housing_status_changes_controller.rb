###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class HousingStatusChangesController < ApplicationController
    include AjaxModalRails::Controller

    before_action :require_can_view_aggregate_health!
    before_action :setup_report

    def index
      @pdf_export = Health::DocumentExports::HousingStatusChangesExport.new(query_string: @report_params.to_query)

      respond_to do |format|
        format.html do
          @html = true
          @pdf = false
        end
        format.pdf do
          @html = false
          @pdf = true
        end
      end
    end

    def detail
      @report_data = @report.details_for(params)

      @clients = GrdaWarehouse::Hud::Client.destination.where(id: @report_data.keys)
      @category = @report.allowed_status(params)
    end

    private def setup_report
      @report_params = report_params
      @end_date = (report_params[:end_date] || Date.current).to_date
      @start_date = (report_params[:start_date] || @end_date - 1.year).to_date
      @acos = report_params[:aco]&.select { |id| id.present? }
      @report = WarehouseReport::Health::HousingStatusChanges.new(@start_date, @end_date, @acos, user: current_user)
    end

    def report_params
      return {} unless params[:filter].present?

      params.require(:filter).permit(
        :start_date,
        :end_date,
        aco: [],
      )
    end
  end
end
