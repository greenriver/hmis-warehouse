###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudChronic
  extend ActiveSupport::Concern
  include ArelHelper
  # hc_t => GrdaWarehouse::HudChronic.arel_table

  included do
    def load_hud_chronic_filter
      @filter = ::Filters::HudChronic.new(filter_params[:filter])
      filter_query = hc_t[:age].gt(@filter.min_age)
      filter_query = filter_query.and(hc_t[:individual].eq(@filter.individual)) if @filter.individual
      filter_query = filter_query.and(hc_t[:dmh].eq(@filter.dmh)) if @filter.dmh
      filter_query = filter_query.and(c_t[:VeteranStatus].eq(@filter.veteran)) if @filter.veteran
      @clients = client_source.joins(:hud_chronics).
        preload(:hud_chronics).
        preload(:source_disabilities).
        where(filter_query).
        has_homeless_service_between_dates(start_date: (@filter.date - @filter.last_service_after.days), end_date: @filter.date)
      @clients = @clients.text_search(@filter.name, client_scope: GrdaWarehouse::Hud::Client.source) if @filter.name&.present?
    end
    alias_method :load_filter, :load_hud_chronic_filter

    def set_hud_chronic_sort
      client_at = client_source.arel_table
      @column = params[:sort] || 'months_in_last_three_years'
      @direction = if ['asc', 'desc'].include?(params[:direction])
        params[:direction]
      else
        'desc'
      end
      # whitelist for column
      table = if ['FirstName', 'LastName'].include?(@column)
        client_at
      elsif chronic_source.column_names.include?(@column)
        hc_t
      else
        @column = 'months_in_last_three_years'
        hc_t
      end
      @order = table[@column].send(@direction)
    end
    alias_method :set_sort, :set_hud_chronic_sort

    def filter_params
      params.permit(filter: Filters::HudChronic.attribute_set.map(&:name))
    end

    def hud_chronic_source
      GrdaWarehouse::HudChronic
    end
    alias_method :chronic_source, :hud_chronic_source

    def hud_chronic_service_history_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end
    alias_method :service_history_source, :hud_chronic_service_history_source
  end
end
