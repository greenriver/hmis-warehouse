###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class YouthIntakesController < ApplicationController
    include PjaxModalController

    before_action :set_filter
    before_action :set_report

    def index
    end

    def details
      raise 'Key required' if params[:key].blank?

      @key = @report.report_whitelist.detect { |key| key.to_s == params[:key] }
      client_ids = @report.send(@key)
      @clients = GrdaWarehouse::Hud::Client.
        destination.
        where(id: client_ids).
        order(:first_name, :last_name).
        pluck(:id, :first_name, :last_name)
    end

    private def set_filter
      @filter = ::Filters::DateRange.new(report_params[:filter])
    end

    private def set_report
      @report = GrdaWarehouse::WarehouseReports::Youth::HomelessYouthReport.new(@filter)
    end

    private def report_params
      params.permit(
        filter: [
          :start,
          :end,
        ],
      )
    end

    private def data_link(data_point)
      helpers.link_to @report.send(data_point).count, details_warehouse_reports_youth_intakes_path(filter: { start: @filter.start, end: @filter.end }, key: data_point), data: { loads_in_pjax_modal: true }
    end
    helper_method :data_link
  end
end
