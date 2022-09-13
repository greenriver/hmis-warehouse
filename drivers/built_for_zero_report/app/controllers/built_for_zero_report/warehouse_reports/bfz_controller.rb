###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BuiltForZeroReport::WarehouseReports
  class BfzController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    before_action :set_report

    def index
      @show_api_button = BuiltForZeroReport::Credential.exists? && params[:report].present?
      return unless params[:commit] == 'Submit Report'

      BuiltForZeroReport.delay.submit_via_api!(@start_date, @end_date, user: current_user)
      flash[:notice] = 'Report queued, please check the BFZ website to confirm delivery.'
    end

    def details
      @key =  report_params[:key]
      @data = case @key.to_sym
      when :actively_homeless, # allowlist for methods
        :housed,
        :lot_to_housing,
        :inactive,
        :ineligible,
        :newly_identified,
        :returned_from_housing,
        :returned_from_inactivity
        @section.data.public_send(report_params[:key])
      end
    end

    def set_report
      @start_date = report_params[:start_date]&.to_date || Date.current.prev_month.beginning_of_month
      @end_date = report_params[:end_date]&.to_date || Date.current.prev_month.end_of_month
      @section_key = report_params[:section]
      @section = sections[@section_key]&.new(@start_date, @end_date, user: current_user)
    end

    def report_params
      return {} unless params[:report].present?

      params.require(:report).permit(
        :start_date,
        :end_date,
        :section,
        :key,
      )
    end
    helper_method :report_params

    def sections
      BuiltForZeroReport.section_classes
    end
  end
end
