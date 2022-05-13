###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class YouthIntakesController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller

    before_action :set_filter
    before_action :set_report

    def index
    end

    def details
      raise 'Key required' if params[:key].blank?

      # FIXME: allowed_report keys should be simplified, maybe all methods should start with q_
      @key = @report.allowed_report_keys.detect { |key| key.to_s == params[:key] }
      @agency = params[:agency]
      raise 'Key required' unless @key

      client_ids = case @key
      when :two_c, :five_n, :six_q, :follow_up_two_d
        @report.public_send(@key).values.flatten.uniq
      when :total_client_ids_served
        if @agency
          @report.all_served_ids_by_agency[@agency]
        else
          @report.public_send(:total_client_ids_served)
        end
      else
        @report.public_send(@key)
      end
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
      count = case data_point
      when :two_c, :five_o, :six_q, :follow_up_two_d
        @report.send(data_point).values.flatten.uniq.count
      else
        @report.send(data_point).count
      end
      helpers.link_to count, details_warehouse_reports_youth_intakes_path(filter: { start: @filter.start, end: @filter.end }, key: data_point), data: { loads_in_pjax_modal: true }
    end
    helper_method :data_link
  end
end
