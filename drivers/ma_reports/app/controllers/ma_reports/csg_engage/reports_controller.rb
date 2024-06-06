###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class ReportsController < ApplicationController
    before_action :require_can_view_imports!
    before_action :set_report, only: [:show]

    def index
      @pagy, @reports = pagy(report_scope)
    end

    def show
    end

    def report_scope
      MaReports::CsgEngage::Report.all.order(id: :desc).preload(:agency, :program_reports)
    end

    private def set_report
      @report = report_scope.preload(:agency).preload(program_reports: [:program_mapping]).find(params[:id].to_i)
    end
  end
end
