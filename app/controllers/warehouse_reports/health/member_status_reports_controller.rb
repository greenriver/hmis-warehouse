module WarehouseReports::Health
  class MemberStatusReportsController < ApplicationController
    before_action :require_can_view_member_health_reports!

    helper HealthOverviewHelper

    def index
      if params[:report].present?
        options = report_params
      else
        options = default_options
      end
      @report = Health::MemberStatusReport.new(options)

    end

    def show
    end

    def create
    end

    def destroy

    end

    def default_options
      {
        report_start_date: 1.months.ago.to_date,
        report_end_date: 1.days.ago.to_date,
      }
    end

    def report_params
      params.require(:report).permit(
        :report_start_date,
        :report_end_date
      )
    end
  end
end