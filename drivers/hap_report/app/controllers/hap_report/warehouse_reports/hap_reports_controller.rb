###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HapReport::WarehouseReports
  class HapReportsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_report, only: [:show, :destroy, :details]

    def index
      @pagy, @reports = pagy(report_scope)
      @filter = HapReport::HapFilter.new(user_id: current_user.id)
    end

    def create
      @filter = HapReport::HapFilter.new(user_id: current_user.id).set_from_params(filter_params)

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
      HapReport::Report
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

    def report_options(filter)
      filter.for_params[:filters].select { |k, _| report_class.report_options.include?(k) }
    end

    private def set_report
      @report = report_scope.find(params[:id].to_i)
    end
  end
end
