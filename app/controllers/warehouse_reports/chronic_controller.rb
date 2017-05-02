module WarehouseReports
  class ChronicController < ApplicationController
    before_action :require_can_view_reports!, :load_filter
    def index
      at = chronic_source.arel_table
      @clients = @clients.
        where(chronics: {date: @filter.date}).
        order( at[:homeless_since].asc, at[:days_in_last_three_years].desc )
      @so_clients = GrdaWarehouse::ServiceHistory.entry.so.ongoing(on_date: @filter.date).distinct.pluck(:client_id)
      respond_to do |format|
        format.html do
          @clients = @clients.page(params[:page]).per(100)
        end
        format.xlsx {}
      end
    end

    # Present a chart of the counts from the previous three years
    def summary
      @range = DateRange.new({start: 3.years.ago, end: 1.day.ago})
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
        @counts = @counts.where(VeteranStatus: true)
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
        where(filter_query)
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    private def chronic_source
      GrdaWarehouse::Chronic
    end

    class ChronicFilter < ModelForm
      attribute :on, Date, default: GrdaWarehouse::Chronic.most_recent_day
      attribute :min_age, Integer, default: 0
      attribute :min_days_homeless,  Integer, default: 0
      attribute :individual, Boolean, default: false
      attribute :dmh, Boolean, default: false
      attribute :veteran, Boolean, default: false

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
    end
  end
end