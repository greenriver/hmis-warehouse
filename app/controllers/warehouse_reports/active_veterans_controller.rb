module WarehouseReports
  class ActiveVeteransController < ApplicationController
    # include WarehouseReportAuthorization

    before_action :set_jobs, only: [:index, :running]
    before_action :sort_options, only: :index

    def index
      @range = ::Filters::DateRangeAndProject.new(report_params[:range])
      if params[:commit].present?
        WarehouseReports::RunActiveVeteransJob.perform_later(params.merge(current_user_id: current_user.id))
      end
      @reports = report_source.select(report_source.column_names - ['data']).ordered.limit(50)
    end

    def show
      @report = report_source.find params[:id]
      @clients = @report.data
      @sort_options = sort_options

      respond_to do |format|
        format.html do
          sort_clients if @clients&.any?
        end
        format.xlsx do
          range = @report.parameters['range'] || {}
          start_date, end_date = range['start'], range['end']
          filename = 'Homeless Veterans.xlsx'
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def running
      @reports = report_source.ordered.limit(50)
    end

    def report_source
      GrdaWarehouse::WarehouseReports::ActiveVeteransReport
    end

    private

    def set_jobs
      @jobs = Delayed::Job.where(queue: 'active_veterans_report').order(run_at: :desc)
    end

    def report_params
      params.permit(
        range: [:start, :end, project_type: []]
      )
    end

    def sort_clients
      @column, @direction = params.slice(:column, :direction).values
      @column, @direction = %w(LastName asc) if @column.nil? || @direction.nil?
      option = sort_options.detect do |row, _|
        row[:column] == @column && row[:direction].to_s == @direction
      end.last
      veteran_sort = @column.split('.')
      @clients = @clients.sort_by do |client|
        client[@column] || option[:default]
      end
      @clients.reverse! if @direction=='desc'
    end

    def sort_options
      @sort_options ||= begin
        ct = GrdaWarehouse::Hud::Client.arel_table
        wcpt = GrdaWarehouse::WarehouseClientsProcessed.arel_table

        {
          {column: 'LastName', direction: :asc} => {
            title: 'Last name A-Z',
            column: ct[:LastName].asc,
            param: 'LastName',
            default: 'Z',
          },
          {column: 'LastName', direction: :desc} => {
            title: 'Last name Z-A',
            column: ct[:LastName].desc,
            param: 'LastName',
            default: 'A',
          },
          {column: 'days_served', direction: :desc} => {
            title: 'Most served',
            column: wcpt[:days_served].desc,
            param: 'days_served',
            default: 0,
          },
          {column: 'first_date_served', direction: :asc} => {
            title: 'Longest standing',
            column: wcpt[:first_date_served].asc,
            param: 'first_date_served',
            default: Date.today.to_s,
          },
        }

      end
    end
  end
end
