module WarehouseReports
  class ChronicController < ApplicationController
    include ArelHelper
    before_action :require_can_view_reports!, :load_filter, :set_sort

    def index
      @clients = @clients.includes(:chronics).
        preload(source_clients: :data_source).
        merge(GrdaWarehouse::Chronic.on_date(date: @filter.date)).
        order( @order )
      @so_clients = service_history_source.entry.so.ongoing(on_date: @filter.date).distinct.pluck(:client_id)
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
        end
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

    def load_filter
      @filter = ChronicFilter.new(params[:filter])
      ct = chronic_source.arel_table
      client_table = client_source.arel_table
      filter_query = ct[:age].gt(@filter.min_age).
        and(ct[:days_in_last_three_years].gteq(@filter.min_days_homeless.presence || 0))
      if @filter.individual
        filter_query = filter_query.and(ct[:individual].eq(@filter.individual))
      end
      if @filter.dmh
        filter_query = filter_query.and(ct[:dmh].eq(@filter.dmh))
      end
      if @filter.veteran
        filter_query = filter_query.and(client_table[:VeteranStatus].eq(@filter.veteran))
      end
      @clients = client_source.joins(:chronics).
        preload(:chronics).
        preload(:source_disabilities).
        where(filter_query).
        has_homeless_service_between_dates(start_date: (@filter.date - @filter.last_service_after.days), end_date: @filter.date)
      if @filter.name&.present?
        @clients = @clients.text_search(@filter.name, client_scope: GrdaWarehouse::Hud::Client.source)
      end
    end

    private def set_sort
      chronic_at = chronic_source.arel_table
      client_at = client_source.arel_table
      @column = params[:sort] || 'homeless_since'
      @direction = params[:direction] || 'asc'
      table = %w(FirstName LastName).include?( @column ) ? client_at : chronic_at
      @order = table[@column].send(@direction)
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    private def chronic_source
      GrdaWarehouse::Chronic
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end

    def sh_t
      GrdaWarehouse::ServiceHistory.arel_table
    end

    class ChronicFilter < ModelForm
      attribute :on, Date, default: GrdaWarehouse::Chronic.most_recent_day
      attribute :min_age, Integer, default: 0
      attribute :min_days_homeless,  Integer, default: 0
      attribute :individual, Boolean, default: false
      attribute :dmh, Boolean, default: false
      attribute :veteran, Boolean, default: false
      attribute :last_service_after, Integer, default: 30
      attribute :name, String

      def dates
        @dates ||= GrdaWarehouse::Chronic.select(:date).distinct.order(date: :desc).pluck(:date)
      end

      def ages
        [0, 18, 24]
      end

      def date
        @date ||= begin
          if dates.include?(on)
            on
          else
            use = on
            dates.each do |d|
              if d < on
                use = d
                break
              end
            end
            use
          end
        end
      end

      def chronic_days
        dates
      end

      def date_ranges
        {
          '0 days before chronic date' => 0,
          '30 days before chronic date' => 30,
          '60 days before chronic date' => 60,
          '90 days before chronic date' => 90,
        }
      end
    end
  end
end
