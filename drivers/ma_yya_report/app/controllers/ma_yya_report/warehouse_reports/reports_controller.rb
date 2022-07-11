###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaYyaReport::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_report, only: [:show, :destroy, :details]

    def index
      @pagy, @reports = pagy(report_scope)
      @filter = ::Filters::FilterBase.new(user_id: current_user.id, **default_filter_params)
    end

    def create
      @filter = ::Filters::FilterBase.new(user_id: current_user.id).update(filter_params)

      if @filter.valid?
        @report = report_scope.create(user_id: @filter.user_id, options: report_options(@filter))
        ::WarehouseReports::GenericReportJob.perform_later(
          user_id: @filter.user_id,
          report_class: @report.class.name,
          report_id: @report.id,
        )
        redirect_to action: :index
      else
        @pagy, @reports = pagy(report_scope)
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

    def report_class
      MaYyaReport::Report
    end

    def report_scope
      report_class.viewable_by(current_user).order(id: :desc)
    end

    private def filter_params
      return [] unless params[:filter].present?

      params.require(:filter).permit(
        :start,
        :end,
        project_ids: [],
      )
    end

    private def default_filter_params
      prior_project_ids = MaYyaReport::Report.last&.options.try(:[], 'project_ids')
      day_in_last_quarter = Date.current - 90.days
      {
        start: day_in_last_quarter.beginning_of_quarter,
        end: day_in_last_quarter.end_of_quarter,
        project_ids: prior_project_ids,
      }
    end

    def report_options(filter)
      filter.to_h.slice(*report_class.report_options)
    end

    private def set_report
      @report = report_scope.find(params[:id].to_i)
    end
  end
end
