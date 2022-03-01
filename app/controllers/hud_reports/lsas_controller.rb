###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudReports
  class LsasController < ApplicationController
    before_action :require_can_view_hud_reports!

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

    def report_urls
      @report_urls ||= Rails.application.config.hud_reports.values.map { |report| [report[:title], public_send(report[:helper])] }.uniq
    end
  end
end
