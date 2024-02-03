###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::WarehouseReports
  class MonthlyProjectUtilizationsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_report, only: [:show, :destroy, :details]
    before_action :require_can_access_some_version_of_clients!, only: [:details]

    def index
      @pagy, @reports = pagy(report_scope)
      @filter = filter_class.new(user_id: current_user.id, enforce_one_year_range: false)
      # Set default filter to prior run
      previous_report = @reports.first
      @filter.update(previous_report.filter.to_h) if previous_report
    end

    def create
      @filter = filter_class.new(user_id: current_user.id, enforce_one_year_range: false).set_from_params(filter_params)

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
      respond_to do |format|
        format.html {}
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=#{@report.title}.xlsx"
        end
      end
    end

    def destroy
      @report.destroy
      flash[:notice] = 'Report removed.'
      redirect_to action: :index
    end

    def details
      @key = params[:key]
      @sub_key = params[:sub_key]
    end

    def report_class
      MaReports::MonthlyPerformance::Report
    end
    helper_method :report_class

    def filter_class
      ::Filters::FilterBase
    end

    def report_scope
      report_class.viewable_by(current_user).order(id: :desc)
    end

    private def filter_params
      return [] unless params[:filter].present?

      params.require(:filter).permit(filter_class.new.known_params)
    end

    def report_options(filter)
      filter.for_params[:filters].select { |k, _| report_class.report_options.include?(k) }
    end

    private def set_report
      @report = report_scope.find(params[:id].to_i)
    end
  end
end
