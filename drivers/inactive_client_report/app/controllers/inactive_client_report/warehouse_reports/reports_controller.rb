###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module InactiveClientReport::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters
    extend BackgroundRenderAction

    before_action :set_report

    background_render_action(:render_section, ::BackgroundRender::InactiveClientReportJob) do
      {
        filters: params[:filter].to_json,
        user_id: current_user.id,
        page: params[:query_string][:page],
      }
    end

    def index
      @excel_export = ::InactiveClientReport::DocumentExports::ReportExcelExport.new
      respond_to do |format|
        format.html {}
        format.xlsx do
          @report.client_ids = @report.clients.map(&:id)
          filename = "#{@report.name} - #{Time.current.to_fs(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def data
      @pagy, @clients = pagy_array(@report.clients.sort_by { |c| [c.last_name, c.first_name] }, page: page, params: @filter.for_params)
    end

    private def set_report
      @report = report_class.new(@filter)
    end

    private def report_class
      InactiveClientReport::Report
    end

    def filter_params
      return default_filter_options unless params[:filters].present?

      params.permit(filters: @filter.known_params)
    end
    helper_method :filter_params

    private def default_filter_options
      {
        filters: {
          require_service_during_range: false,
          project_type_codes: ['ce'],
          end_date: Date.yesterday,
          start_date: 3.months.ago.to_date,
          days_since_contact_min: 30,
          days_since_contact_max: 90,
        },
      }
    end
    helper_method :default_filter_options

    private def filter_class
      ::Filters::FilterBase
    end
  end
end
