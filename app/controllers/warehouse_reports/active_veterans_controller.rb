###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class ActiveVeteransController < ApplicationController
    include WarehouseReportAuthorization

    before_action :set_jobs, only: [:index, :running]
    before_action :sort_options, only: :index
    before_action :set_report, only: [:show, :destroy]

    def index
      @range = ::Filters::DateRangeAndProject.new(report_params[:range])
      WarehouseReports::RunActiveVeteransJob.perform_later(params.merge(current_user_id: current_user.id)) if params[:commit].present?
      @reports = report_scope.select(report_scope.column_names - ['data']).ordered.limit(50)
    end

    def show
      @clients = @report.data
      @sort_options = sort_options

      respond_to do |format|
        format.html do
          sort_clients if @clients&.any?
        end
        format.xlsx do
          # range = @report.parameters['range'] || {}
          # start_date = range['start']
          # end_date = range['end']
          filename = 'Homeless Veterans.xlsx'
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def destroy
      @report.destroy
      respond_with(@report, location: warehouse_reports_active_veterans_path)
    end

    def running
      @reports = report_scope.ordered.limit(50)
    end

    def report_source
      GrdaWarehouse::WarehouseReports::ActiveVeteransReport
    end

    # If you can see all data sources etc, then show all copies of the report,
    # otherwise just show your own
    def report_scope
      if can_edit_anything_super_user?
        report_source
      else
        report_source.where(user_id: current_user.id)
      end
    end

    private

    def set_jobs
      @jobs = Delayed::Job.where(queue: 'active_veterans_report').order(run_at: :desc)
    end

    def set_report
      @report = report_source.find params[:id].to_i
    end

    def report_params
      params.permit(
        range: [:start, :end, project_type: []],
      )
    end

    def sort_clients
      @column, @direction = params.slice(:column, :direction).values
      if @column.nil? || @direction.nil?
        @column = 'LastName'
        @direction = 'asc'
      end
      option = sort_options.detect do |row, _|
        row[:column] == @column && row[:direction].to_s == @direction
      end.last
      @clients = @clients.sort_by do |client|
        client[@column] || option[:default]
      end
      @clients.reverse! if @direction == 'desc'
    end

    def sort_options
      @sort_options ||= begin
        ct = GrdaWarehouse::Hud::Client.arel_table
        wcpt = GrdaWarehouse::WarehouseClientsProcessed.arel_table

        {
          { column: 'LastName', direction: :asc } => {
            title: 'Last name A-Z',
            column: ct[:LastName].asc,
            param: 'LastName',
            default: 'Z',
          },
          { column: 'LastName', direction: :desc } => {
            title: 'Last name Z-A',
            column: ct[:LastName].desc,
            param: 'LastName',
            default: 'A',
          },
          { column: 'days_served', direction: :desc } => {
            title: 'Most served',
            column: wcpt[:days_served].desc,
            param: 'days_served',
            default: 0,
          },
          { column: 'first_date_served', direction: :asc } => {
            title: 'Longest standing',
            column: wcpt[:first_date_served].asc,
            param: 'first_date_served',
            default: Date.current.to_s,
          },
        }
      end
    end

    def flash_interpolation_options
      { resource_name: 'Active Veterans Report' }
    end
  end
end
