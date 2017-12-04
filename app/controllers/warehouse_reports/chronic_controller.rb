module WarehouseReports
  class ChronicController < ApplicationController
    include ArelHelper
    include Chronic
    include WarehouseReportAuthorization
    before_action :load_filter
    before_action :set_sort, except: [:index, :show]

    def index
      if params[:commit].present?
        WarehouseReports::RunChronicJob.perform_later(params.merge(current_user_id: current_user.id))
      end
      @jobs = Delayed::Job.where(queue: 'chronic_report').order(run_at: :desc)
      @reports = report_source.ordered
    end

    def show
      @report = report_source.find(params[:id])
      @clients = @report.data
      @sort_options = sort_options

      sort_clients

      respond_to do |format|
        format.xlsx do
          @client_ids = @clients.map { |client| client['id'] }
          @most_recent_services = service_history_source.service
            .where(client_id: @client_ids, project_type: GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES)
            .group(:client_id)
            .pluck(:client_id, nf('MAX', [sh_t[:date]]).to_sql)
            .to_h
          @chronics = GrdaWarehouse::Chronic.where(date: @filter.date).index_by(&:client_id)
        end
        format.html
      end
    end

    # Present a chart of the counts from the previous three years
    def summary
      @range = ::Filters::DateRange.new({start: 3.years.ago, end: 1.day.ago})
      ct = chronic_source.arel_table
      @counts = chronic_source.
        where(date: @range.range).
        where(ct[:days_in_last_three_years].gteq(@filter.min_days_homeless.presence || 0))
      if @filter.individual
        @counts = @counts.where(individual: true)
      end
      if @filter.dmh
        @counts = @counts.where(dmh: true)
      end
      if @filter.veteran
        @counts = @counts.joins(:client).where(Client: {VeteranStatus: true})
      end
      @counts = @counts.group(:date).
        order(date: :asc).
        count
      render json: @counts
    end

    def report_source
      GrdaWarehouse::WarehouseReports::ChronicReport
    end
    
    def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    private 

    def sort_clients
      @column, @direction = params.slice(:column, :direction).values 
      @column, @direction = %w(chronic.homeless_since desc) if @column.nil? || @direction.nil?
      chronic_sort = @column.split('.')
      @clients = @clients.sort_by do |client|
        if chronic_sort.size == 2
          client['chronic'][chronic_sort.last]
        else
          client[@column]
        end
      end
      @clients.reverse! if @direction=='desc'
    end

    def sort_options
      [
        {title: 'Last name A-Z', column: 'LastName', direction: 'asc'},
        {title: 'Last name Z-A', column: 'LastName', direction: 'desc'},
        {title: 'First name A-Z', column: 'FirstName', direction: 'asc'},
        {title: 'First name Z-A', column: 'FirstName', direction: 'desc'},
        {title: 'Age (asc)', column: 'age', direction: 'asc'},
        {title: 'Age (desc)', column: 'age', direction: 'desc'},
        {title: 'Homeless since (asc)', column: 'chronic.homeless_since', direction: 'asc'},
        {title: 'Homeless since (desc)', column: 'chronic.homeless_since', direction: 'desc'},
        {title: 'Days in 3 yrs (asc)', column: 'chronic.days_in_last_three_years', direction: 'asc'},
        {title: 'Days in 3 yrs (desc)', column: 'chronic.days_in_last_three_years', direction: 'desc'},
        {title: 'Months in 3 yrs (asc)', column: 'chronic.months_in_last_three_years', direction: 'asc'},
        {title: 'Months in 3 yrs (desc)', column: 'chronic.months_in_last_three_years', direction: 'desc'},
      ]
    end

  end
end
