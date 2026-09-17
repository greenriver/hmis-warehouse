###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReports
  class LsasController < ApplicationController
    include WarehouseReportAuthorization
    include HudReports::ReportUrls

    def related_report
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: 'hud_reports/lsas')
    end

    def index
      @reports = report_scope.order(weight: :asc, type: :desc)
      @reports = group_reports(@reports)
      @report_urls = report_urls
    end

    def report_scope
      report_source.active.for_type('Lsa')
    end

    def report_source
      Report
    end

    def group_reports(reports)
      grouped_reports = {}
      reports.each do |r|
        report_category = r.report_group_name
        report_year = r.type.split('::')[0...-1].join('::')
        grouped_reports[report_category] ||= {}
        grouped_reports[report_category][report_year] ||= []
        grouped_reports[report_category][report_year] << r
      end

      grouped_reports
    end
  end
end
