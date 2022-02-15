###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class SupportController < ApplicationController
    include AjaxModalRails::Controller
    before_action :require_can_view_all_reports!
    before_action :set_report

    # Requires a key to fetch the appropriate chunk of support
    def index
      raise 'Key required' if params[:key].blank?
      raise 'Section required' if params[:section].blank?

      @key = params[:key].to_s
      @section = params[:section].to_s
      @data = OpenStruct.new(@report[@section])
      if params[:title].present?
        @title = params[:title].to_s
      else
        @title = "#{@data.title} for: #{@key.gsub('__', '—')}"
      end
      @headers = @data.headers
      @counts = @data.counts[@key]
      respond_to do |format|
        format.xlsx do
          render xlsx: 'index', filename: "support-#{@section}-#{@key}.xlsx"
        end
        format.html {}
      end
    end

    def set_report
      report_id = params[:warehouse_report_id].to_i
      @report = report_source.where(id: report_id).limit(1).pluck(:support)&.first
    end

    def report_source
      GrdaWarehouse::WarehouseReports::Base
    end
  end
end
