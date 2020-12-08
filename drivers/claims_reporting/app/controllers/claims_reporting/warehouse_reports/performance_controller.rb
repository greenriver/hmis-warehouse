###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
module ClaimsReporting::WarehouseReports
  class PerformanceController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_view_member_health_reports!

    def index
      @report = ClaimsReporting::PerformanceReport.new

      @report.attributes = params.fetch(:f, {}).permit(@report.available_filters).to_h
    end

    private def available_months
      @available_months ||= begin
        dates = if ::Health::Claim.none?
          ::Health::QualifyingActivity.distinct.pluck(:date_of_activity)
        else
          ::Health::Claim.distinct.pluck(:max_date)
        end
        dates.map(&:beginning_of_month).sort.uniq.reverse
      end
    end
    helper_method :available_months

    private def filter_params
      params.fetch(:f, {}).permit(
        :month,
      ).tap do |filter|
        filter[:month] = available_months.detect { |m| m.iso8601 == filter[:month] } || available_months.first
      end.to_h.symbolize_keys
    end
  end
end
