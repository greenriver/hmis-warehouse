###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class BedUtilizationController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    include BaseFilters

    before_action :set_report
    before_action :set_pdf_export

    def index
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "Bed Utilization #{Time.current.to_s.delete(',')}.xlsx"
          render(xlsx: 'index', filename: filename)
        end
      end
    end

    private def set_pdf_export
      @pdf_export = GrdaWarehouse::DocumentExports::BedUtilizationExport.new
    end

    private def set_report
      # On multi-coc installations, not having CoC on the form was causing all visible projects to be included
      # make sure these are blanked out since we'll never be choosing them
      @filter.coc_codes = []
      @report = WarehouseReport::BedUtilization.new(filter: @filter)
    end

    private def filter_class
      ::Filters::FilterBase
    end

    def filter_params
      params.permit(filters: @filter.known_params)
    end
    helper_method :filter_params
  end
end
