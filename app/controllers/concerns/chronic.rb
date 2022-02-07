###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Chronic
  extend ActiveSupport::Concern
  included do
    def load_chronic_filter
      @filter = ::Filters::Chronic.new(filter_params[:filter])
      ct = chronic_source.arel_table
      client_table = client_source.arel_table
      filter_query = ct[:age].gt(@filter.min_age).
        and(ct[:days_in_last_three_years].gteq(@filter.min_days_homeless.presence || 0))
      filter_query = filter_query.and(ct[:individual].eq(@filter.individual)) if @filter.individual
      filter_query = filter_query.and(ct[:dmh].eq(@filter.dmh)) if @filter.dmh
      filter_query = filter_query.and(client_table[:VeteranStatus].eq(@filter.veteran)) if @filter.veteran
      @clients = client_source.joins(:chronics).
        preload(:chronics).
        preload(:source_disabilities).
        where(filter_query).
        has_homeless_service_between_dates(start_date: (@filter.date - @filter.last_service_after.days), end_date: @filter.date)
      @clients = @clients.text_search(@filter.name, client_scope: GrdaWarehouse::Hud::Client.source) if @filter.name&.present?
    end
    alias_method :load_filter, :load_chronic_filter

    def set_chronic_sort
      chronic_at = chronic_source.arel_table
      client_at = client_source.arel_table
      @column = params[:sort] || 'homeless_since'
      # whitelist for sort direction
      @direction = if ['asc', 'desc'].include?(params[:direction])
        params[:direction]
      else
        'asc'
      end
      # whitelist for column
      table = if ['FirstName', 'LastName'].include?(@column)
        client_at
      elsif chronic_source.column_names.include?(@column)
        chronic_at
      else
        @column = 'homeless_since'
        chronic_at
      end
      @order = table[@column].send(@direction)
    end
    alias_method :set_sort, :set_chronic_sort

    def filter_params
      params.permit(filter: Filters::Chronic.attribute_set.map(&:name))
    end

    def potentially_chronic_source
      GrdaWarehouse::Chronic
    end
    alias_method :chronic_source, :potentially_chronic_source

    def chronic_service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end
    alias_method :service_history_source, :chronic_service_history_source
  end
end
