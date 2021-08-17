###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# (pick universe from any combination of Project Type, CoC Code, Data Source, Organization, Project, Project Group)
# Date Range
# Show:
#   ES/SO/SH/TH (whatever the top level of the universe is)
#     Overall Utilization Rate
#       Show each project
#     UDE total failed project count
#       Show each Project
#     Timeliness Average timeliness
#       Show each Project

module ProjectPassFail::WarehouseReports
  class ProjectPassFailController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters

    before_action :set_report, except: [:create]
    before_action :set_pdf_export

    def index
      # Handle arriving from the Document Export list
      redirect_to(action: :show, id: params[:id]) if params[:id]

      @reports = report_scope.ordered.
        page(params[:page]).per(25)
    end

    def create
      @filter.update(filter_params)
      @report = report_class.create(options: @filter.for_params, user_id: @filter.user_id)

      ::WarehouseReports::GenericReportJob.perform_later(
        user_id: current_user.id,
        report_class: @report.class.name,
        report_id: @report.id,
      )
      respond_with(@report, location: project_pass_fail_warehouse_reports_project_pass_fail_index_path)
    end

    def show
      respond_to do |format|
        format.html do
          @pdf = false
        end
        format.pdf do
          @pdf = true
        end
      end
    end

    def destroy
      @report.destroy
      respond_with(@report, location: project_pass_fail_warehouse_reports_project_pass_fail_index_path)
    end

    def filter_params
      params.permit(
        filters: [
          :start,
          :end,
          coc_codes: [],
          project_types: [],
          project_type_numbers: [],
          data_source_ids: [],
          organization_ids: [],
          project_ids: [],
          project_group_ids: [],
        ],
      )
    end
    helper_method :filter_params

    private def set_report
      @report = if params[:id]
        report_class.find(params[:id].to_i)
      else
        report_class.new(options: @filter.for_params)
      end
    end

    private def report_class
      ProjectPassFail::ProjectPassFail
    end

    private def report_scope
      report_class.viewable_by(current_user)
    end

    private def filter_class
      ::Filters::FilterBase
    end

    private def set_filter
      @filter = filter_class.new(user_id: current_user.id, project_type_codes: [])
      @filter.set_from_params(filter_params[:filters]) if filter_params[:filters].present?
    end

    private def set_pdf_export
      @pdf_export = ProjectPassFail::DocumentExports::ProjectPassFailExport.new
    end

    private def flash_interpolation_options
      { resource_name: @report.title }
    end
  end
end
