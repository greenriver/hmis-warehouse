###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class OutflowController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper

    before_action :set_report

    def index

    end

    def details
      raise 'Key required' if params[:key].blank?
      @key = metrics.keys.detect { |key| key.to_s == params[:key] }
      @enrollments = enrollment_scope.where(client_id: @report.send(@key)).group_by{ |e| e.client_id }
    end

    def metrics
      {
        clients_to_ph: 'Clients exiting to PH',
        psh_clients_to_stabilization: 'PSH Clients entering Stabilization',
        rrh_clients_to_stabilization: 'RRH Clients entering Stabilization',
        clients_to_stabilization: 'All Clients entering Stabilization',
        clients_without_recent_service: 'Clients without recent service',
        client_outflow: 'Total Outflow',
      }
    end
    helper_method :metrics

    private def set_report
      @filter = ::Filters::DateRangeWithSubPopulation.new(filter_options)
      @report = GrdaWarehouse::WarehouseReports::OutflowReport.new(@filter)
    end

    private def filter_options
      if params[:filter].present?
        opts = params.require(:filter).permit(:start, :end, :sub_population)
        if opts[:start].to_date > opts[:end].to_date
          start = opts[:end]
          opts[:end] = opts[:start]
          opts[:start] = start
        end
        opts
      else
        {
          start: default_start.to_date,
          end: default_end.to_date,
        }
      end
    end

    private def default_start
      3.months.ago.beginning_of_month
    end

    private def default_end
      1.months.ago.end_of_month
    end

    def enrollment_scope
      GrdaWarehouse::ServiceHistoryEnrollment.
        entry.
        joins(:client).
        open_between(start_date: @filter.start, end_date: @filter.end).
        order(c_t[:LastName], c_t[:FirstName])
    end
  end
end