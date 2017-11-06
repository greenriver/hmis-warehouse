module HudChronic
  extend ActiveSupport::Concern

  included do
    def load_filter
      @filter = ::Filters::HudChronic.new(params[:filter])
      ct = chronic_source.arel_table
      client_table = client_source.arel_table
      filter_query = ct[:age].gt(@filter.min_age)
      if @filter.individual
        filter_query = filter_query.and(ct[:individual].eq(@filter.individual))
      end
      if @filter.dmh
        filter_query = filter_query.and(ct[:dmh].eq(@filter.dmh))
      end
      if @filter.veteran
        filter_query = filter_query.and(client_table[:VeteranStatus].eq(@filter.veteran))
      end
      @clients = client_source.joins(:hud_chronics).
        preload(:hud_chronics).
        preload(:source_disabilities).
        where(filter_query).
        has_homeless_service_between_dates(start_date: (@filter.date - @filter.last_service_after.days), end_date: @filter.date)
      if @filter.name&.present?
        @clients = @clients.text_search(@filter.name, client_scope: GrdaWarehouse::Hud::Client.source)
      end
    end

    def set_sort
      chronic_at = chronic_source.arel_table
      client_at = client_source.arel_table
      @column = params[:sort] || 'homeless_since'
      @direction = params[:direction] || 'asc'
      table = %w(FirstName LastName).include?( @column ) ? client_at : chronic_at
      @order = table[@column].send(@direction)
    end

    def chronic_source
      GrdaWarehouse::HudChronic
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end
  end
end