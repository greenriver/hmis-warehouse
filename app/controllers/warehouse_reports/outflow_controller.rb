###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class OutflowController < ApplicationController
    include PjaxModalController
    include WarehouseReportAuthorization
    include ArelHelper

    before_action :set_report
    before_action :set_modal_size

    def index

    end

    def details
      raise 'Key required' if params[:key].blank?
      @key = metrics.keys.detect { |key| key.to_s == params[:key] }
      @enrollments = enrollment_scope.where(client_id: @report.send(@key)).group_by{ |e| e.client_id }

      respond_to do |format|
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=outflow-#{@key.to_s}.xlsx"
        end
        format.html {}
      end
    end

    def metrics
      {
        clients_to_ph: 'Clients exiting to PH',
        psh_clients_to_stabilization: "PSH Clients entering #{_"Housing"}",
        rrh_clients_to_stabilization: "RRH Clients entering #{_"Stabilization"}",
        clients_to_stabilization: "All Clients entering #{_"Stabilization"}",
        clients_without_recent_service: 'Clients without recent service',
        client_outflow: 'Total Outflow',
      }
    end
    helper_method :metrics

    def describe_computations
      path = "app/views/warehouse_reports/outflow/README.md"
      description = File.read(path)
      markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
      markdown.render(description)
    end
    helper_method :describe_computations

    private def set_report
      @filter = ::Filters::DateRangeWithSourcesAndSubPopulation.new(filter_options)
      @report = GrdaWarehouse::WarehouseReports::OutflowReport.new(@filter, current_user)
    end

    private def filter_options
      if params[:filter].present?
        opts = params.require(:filter).permit(:start, :end, :sub_population, organization_ids: [], project_ids: [])
        if opts[:start].to_date > opts[:end].to_date
          start = opts[:end]
          opts[:end] = opts[:start]
          opts[:start] = start
        end
        opts[:project_ids] = cleanup_ids(opts[:project_ids])
        opts[:organization_ids] = cleanup_ids(opts[:organization_ids])
        opts
      else
        {
          start: default_start.to_date,
          end: default_end.to_date,
        }
      end
    end

    private def cleanup_ids(array)
      array.select{ |id| id.present? }.map{ |id| id.to_i }
    end

    private def default_start
      3.months.ago.beginning_of_month
    end

    private def default_end
      1.months.ago.end_of_month
    end

    def enrollment_scope
      @report.entries_scope.
        joins(:client).
        order(c_t[:LastName], c_t[:FirstName])
    end

    private def set_modal_size
      @modal_size = :xl
    end
  end
end