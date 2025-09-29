###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module MaYyaReport::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :set_report, only: [:show, :destroy, :details]

    def index
      if params[:filter].present?
        @filter = ::Filters::FilterBase.new(user_id: current_user.id)
        @filter.update(filter_params.merge(user_id: current_user.id))
      else
        @filter = ::Filters::FilterBase.new(user_id: current_user.id, **default_filter_params)
      end
      @pagy, @reports = pagy(report_scope)
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
      cell = params[:cell].to_sym
      @cell = @report.label(cell)

      text = @report.cell_label(cell)
      @cell = "#{@cell}: #{text}" if text.present?

      @members = @report.cell(params[:cell]).members.preload(universe_membership: { service_history_enrollment: [:project] })

      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "#{@report.title} #{@cell}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def report_class
      MaYyaReport::Report
    end

    def report_scope
      report_class.viewable_by(current_user).order(id: :desc)
    end
    helper_method :report_scope

    private def filter_params
      return [] unless params[:filter].present?

      params.require(:filter).permit(*::Filters::FilterBase.new(user_id: current_user.id).known_params)
    end

    private def default_filter_params
      last_report = MaYyaReport::Report.last
      day_in_last_quarter = Date.current - 90.days
      {
        start: day_in_last_quarter.beginning_of_quarter,
        end: day_in_last_quarter.end_of_quarter,
      }.merge(last_report&.options&.symbolize_keys)
    end

    def report_options(filter)
      filter.to_h.slice(*report_class.report_options)
    end

    private def set_report
      @report = report_scope.find(params[:id].to_i)
    end
  end
end
