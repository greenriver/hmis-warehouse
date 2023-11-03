###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
module BostonReports::WarehouseReports
  class CommunityOfOriginsController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include BaseFilters

    before_action :set_report
    before_action :set_pdf_export

    def index
      # Enable to test PDF generation
      # render 'index_pdf', layout: 'layouts/pdf_with_map'
    end

    private def set_report
      @report = report_class.new(@filter)
    end

    private def report_class
      BostonReports::CommunityOfOrigin
    end

    def filter_params
      return report_class.default_filter_options unless params[:filters].present?

      params.permit(filters: @filter.known_params)
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end

    private def set_pdf_export
      @pdf_export = BostonReports::DocumentExports::CommunityOfOriginPdfExport.new
    end
  end
end
