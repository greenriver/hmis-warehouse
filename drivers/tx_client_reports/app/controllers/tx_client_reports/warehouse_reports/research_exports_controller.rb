###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TxClientReports::WarehouseReports
  class ResearchExportsController < ApplicationController
    include AjaxModalRails::Controller
    include WarehouseReportAuthorization
    include ArelHelper

    before_action :filter

    def index
      respond_to do |format|
        format.html do
          @reports = report_class.viewable_by(current_user).ordered
          show_validations

          # Set default filter to prior run
          previous_report = @reports.last
          @filter.update(previous_report.options['filters'].with_indifferent_access) if previous_report

          @pagy, @reports = pagy(@reports)
        end
        format.xlsx do
          @report = report_class.new(options: @filter.for_params, user_id: @filter.user_id)
          filename = "Research Export  #{Time.current.to_s(:db)}.xlsx"
          headers['ContentDisposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def show
      filename = "Research Export - #{Time.current.to_s(:db)}.xlsx"
      headers['Content-Disposition'] = "attachment; filename=#{filename}"
      export = report.export
      send_data(export.content, type: export.content_type, filename: filename)
    end

    def create
      @filter.update(filter_params)
      @report = report_class.create(options: @filter.for_params, user_id: @filter.user_id)

      ::WarehouseReports::GenericReportJob.perform_later(
        user_id: current_user.id,
        report_class: @report.class.name,
        report_id: @report.id,
      )
      respond_with(@report, location: tx_client_reports_warehouse_reports_research_exports_path)
    end

    private def show_validations
      return unless params[:commit].present?

      flash[:error] = 'You must select a project or project group' unless show_report?
    end

    private def filter
      @filter ||= begin
        f = ::Filters::FilterBase.new(
          user_id: current_user.id,
          project_type_numbers: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS,
          enforce_one_year_range: false,
        )
        f.update(filter_params)
        f
      end
    end

    private def report
      @report ||= report_class.find(params[:id].to_i)
    end

    private def report_class
      TxClientReports::ResearchExport
    end

    private def filter_params
      return {} unless params[:filters].present?

      params.require(:filters).permit(::Filters::FilterBase.new.known_params)
    end

    private def flash_interpolation_options
      { resource_name: @report.title }
    end
  end
end
