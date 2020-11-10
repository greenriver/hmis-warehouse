###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
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

    before_action :require_can_view_clients, only: [:detail]
    before_action :set_report
    before_action :set_pdf_export

    def index
    end

    def filter_params
      params.permit(
        filters: [
          :start,
          :end,
          coc_codes: [],
          project_types: [],
          project_type_codes: [],
          data_source_ids: [],
          organization_ids: [],
          project_ids: [],
          project_group_ids: [],
        ],
      )
    end
    helper_method :filter_params

    private def set_report
      @report = report_class.new(@filter)
    end

    private def report_class
      ProjectPassFail::ProjectPassFail
    end

    private def filter_class
      ::Filters::FilterBase
    end

    private def set_pdf_export
      @pdf_export = ProjectPassFail::DocumentExports::ProjectPassFailExport.new
    end
  end
end
