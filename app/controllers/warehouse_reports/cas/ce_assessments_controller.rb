###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Cas
  class CeAssessmentsController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_filter

    def index
      @report = assessment_source.new(filter: @filter)
      respond_to do |format|
        format.html do
          @client_page = @report.clients.
            page(params[:page].to_i).
            per(50)
          @clients = @client_page.
            select(@report.columns).
            order(@report.order)
        end
        format.xlsx do
          filename = 'CE Assessments.xlsx'
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def set_filter
      options = filter_params[:filter] || {}
      options[:user] = current_user
      @filter = OpenStruct.new(options)
    end

    def filter_params
      params.permit(
        filter: [
          :days_homeless,
          :no_assessment_in,
          :project_id,
          :sub_population,
        ],
      )
    end
    helper_method :filter_params

    def assessment_source
      GrdaWarehouse::WarehouseReports::Cas::CeAssessment
    end
  end
end
