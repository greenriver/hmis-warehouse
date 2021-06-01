###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HapReport::WarehouseReports
  class HapReportsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_report, only: [:show, :destroy, :details]

    def index
      @reports = report_scope.page(params[:page]).per(25)
      @report = report_scope.build
    end

    def create
      @report = report_scope.create(user_id: current_user.id, status: :pending, options: report_options)
      @reports = report_scope.page(params[:page]).per(25)
      if @report.valid?
        ::WarehouseReports::GenericReportJob.perform_later(
          user_id: current_user.id,
          report_class: @report.class.name,
          report_id: @report.id,
        )
        redirect_to action: :index
      else
        render :index # Show validation errors
      end
    end

    def show
    end

    def destroy
      @report.destroy
      flash[:notice] = 'Report removed.'
      redirect_to action: :index
    end

    def details
      @cell = params[:cell].humanize
      @members = @report.cell(params[:cell]).members
    end

    def report_scope
      HapReport::Report.viewable_by(current_user).order(id: :desc)
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
