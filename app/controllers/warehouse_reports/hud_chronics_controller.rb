module WarehouseReports
  class HudChronicsController < ApplicationController
    include ArelHelper
    include HudChronic
    include WarehouseReportAuthorization
    before_action :load_filter, :set_sort

    def index
      @clients = @clients.includes(:hud_chronics).
        preload(source_clients: :data_source).
        merge(GrdaWarehouse::HudChronic.on_date(date: @filter.date)).
        order( @order )

      @so_clients = service_history_source.entry.so.ongoing(on_date: @filter.date).distinct.pluck(:client_id)

      # Rails really wants to preload things we don't want, stop that.
      @clients.preload_values = [source_clients: :data_source]
      respond_to do |format|
        format.html do
          @clients = @clients.page(params[:page]).per(100)
        end
        format.xlsx do
          @most_recent_services = service_history_source.service.where(
            client_id: @clients.select(:id),
            project_type: GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
          ).group(:client_id).
          pluck(:client_id, nf('MAX', [sh_t[:date]]).to_sql).to_h
          @chronics = GrdaWarehouse::HudChronic.where(date: @filter.date).index_by(&:client_id)
          
        end
      end
    end

    # Present a chart of the counts from the previous three years
    def summary
      @range = ::Filters::DateRange.new({start: 3.years.ago, end: 1.day.ago})
      ct = chronic_source.arel_table
      @counts = chronic_source.
        where(date: @range.range)
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

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end

  end
end
