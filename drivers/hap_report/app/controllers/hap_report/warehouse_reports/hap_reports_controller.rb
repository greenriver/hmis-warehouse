###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HapReport::WarehouseReports
  class HapReportsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_report, only: [:show, :destroy]

    def index
      @reports = report_scope.page(params[:page]).per(25)
      @report = report_scope.build
    end

    def create
      @report = report_scope.create(user_id: current_user.id, status: :pending, options: report_options)
      @reports = report_scope.page(params[:page]).per(25)
      @report.delay.build_report if @report.valid?

      render :index
    end

    def show
    end

    def destroy
      @report.destroy
      flash[:notice] = 'Report removed.'
      redirect_to action: :index
    end

    def report_scope
      HapReport::Report.viewable_by(current_user)
    end

    private def report_options
      return [] unless params[:hap_report_report].present?

      params.require(:hap_report_report).permit(
        :start_date,
        :end_date,
        project_ids: [],
      )
    end

    private def set_report
      @report = report_scope.find(params[:id].to_i)
    end
  end
end
