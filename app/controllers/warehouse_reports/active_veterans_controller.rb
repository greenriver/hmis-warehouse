module WarehouseReports
  class ActiveVeteransController < ApplicationController
    include WarehouseReportAuthorization

    before_action :set_jobs, only: [:index, :running]
    before_action :sort_options, only: :index

    def index
      @range = ::Filters::DateRangeAndProject.new(report_params[:range])
      if params[:commit].present?
        WarehouseReports::RunActiveVeteransJob.perform_later(params.merge(current_user_id: current_user.id))
      end
      @reports = GrdaWarehouse::WarehouseReports::ActiveVeteransReport.ordered.limit(50)
    end

    def show
      @report = GrdaWarehouse::WarehouseReports::ActiveVeteransReport.find params[:id]
      @clients = @report.data
      @sort_options = sort_options

      sort_clients if @clients&.any?

      respond_to do |format|
        format.html
        format.xlsx do
          range = @report.parameters['range'] || {}
          start_date, end_date = range['start'], range['end']
          headers['Content-Disposition'] = "attachment; filename=Homeless Veterans from #{start_date} to #{end_date}.xlsx"
        end
      end
    end

    def running
      @reports = GrdaWarehouse::WarehouseReports::ActiveVeteransReport.ordered.limit(50)
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
      @column, @direction = %w(chronic.homeless_since desc) if @column.nil? || @direction.nil?
      veteran_sort = @column.split('.')
      @clients = @clients.sort_by do |client|
        client[@column]
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
          },
          {column: 'LastName', direction: :desc} => {
            title: 'Last name Z-A', 
            column: ct[:LastName].desc,
            param: 'LastName',
          },
          {column: 'days_served', direction: :desc} => {
            title: 'Most served', 
            column: wcpt[:days_served].desc, 
            param: 'days_served',
          },
          {column: 'first_date_served', direction: :asc} => {
            title: 'Longest standing', 
            column: wcpt[:first_date_served].asc, 
            param: 'first_date_served',
          },
        }
        
      end
    end
  end
end
