###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClaimsReporting::WarehouseReports
  class EngagementTrendsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_view_member_health_reports!
    before_action :set_report, only: [:show, :destroy]

    def index
      @reports = report_class.ordered.visible_to(current_user)
      @reports = @reports.page(params[:page]).per(25)
      @report = report_class.new
      @filter = ::Filters::EngagementFilter.new(user_id: current_user.id)
    end

    def create
      dates = report_class.max_date_range

      @report = report_class.new(
        user_id: current_user.id,
        options: {
          start_date: dates.min.iso8601,
          end_date: dates.max.iso8601,
        }.merge(report_params),
      )
      @report.save
      ::WarehouseReports::GenericReportJob.perform_later(
        user_id: current_user.id,
        report_class: @report.class.name,
        report_id: @report.id,
      )
      respond_with(@report, location: claims_reporting_warehouse_reports_engagement_trends_path)
    end

    def show
      respond_to do |format|
        format.html
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=Patient Engagement Trends #{Time.current.to_s(:db)}.xlsx"
        end
      end
    end

    private def set_report
      @report = report_class.visible_to(current_user).find(params[:id].to_i)
    end

    def destroy
      @report.destroy
      respond_with(@report, location: claims_reporting_warehouse_reports_engagement_trends_path)
    end

    private def report_class
      ClaimsReporting::EngagementTrends
    end

    private def flash_interpolation_options
      { resource_name: @report.title }
    end

    private def report_params
      params.require(:filters).permit(
        :food_insecurity, # FIXME
        :cohort_type,
        age_ranges: [],
        races: [],
        ethnicities: [],
        genders: [],
        acos: [],
      )
    end
  end
end
